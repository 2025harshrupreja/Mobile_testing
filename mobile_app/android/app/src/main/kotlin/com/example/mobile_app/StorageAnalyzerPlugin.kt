package com.example.mobile_app

import android.app.usage.StorageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Environment
import android.os.StatFs
import android.os.storage.StorageManager
import android.provider.MediaStore
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.security.MessageDigest
import java.util.UUID
import java.util.concurrent.Executors

/**
 * Handles all storage-analysis method calls from Flutter via the
 * `storage_analyzer` MethodChannel.
 *
 * Runs heavy work on a background thread pool so it does not block the UI.
 */
class StorageAnalyzerPlugin(private val context: Context) {

    private val executor = Executors.newCachedThreadPool()

    fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "getStorageTotals" -> async(result) { getStorageTotals() }
            "getCategoryBreakdowns" -> async(result) { getCategoryBreakdowns() }
            "getLargeFiles" -> {
                val topN = (call.argument<Int>("topN") ?: 50)
                async(result) { getLargeFiles(topN) }
            }
            "getDuplicates" -> async(result) { getDuplicates() }
            "getAppStorage" -> async(result) { getAppStorage() }
            else -> result.notImplemented()
        }
    }

    // ── Helpers ──────────────────────────────────────────────────────────────

    private fun async(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val data = block()
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    result.success(data)
                }
            } catch (e: Exception) {
                android.os.Handler(android.os.Looper.getMainLooper()).post {
                    result.error("STORAGE_ERROR", e.message, null)
                }
            }
        }
    }

    // ── 1. Storage totals ─────────────────────────────────────────────────────

    private fun getStorageTotals(): Map<String, Long> {
        val stat = StatFs(Environment.getExternalStorageDirectory().path)
        val total = stat.blockCountLong * stat.blockSizeLong
        val free = stat.availableBlocksLong * stat.blockSizeLong
        return mapOf("totalBytes" to total, "freeBytes" to free)
    }

    // ── 2. Category breakdowns ────────────────────────────────────────────────

    private fun getCategoryBreakdowns(): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()

        data class CatSpec(
            val name: String,
            val uri: Uri,
            val mimeFilter: String?
        )

        val specs = listOf(
            CatSpec("Images", MediaStore.Images.Media.EXTERNAL_CONTENT_URI, null),
            CatSpec("Videos", MediaStore.Video.Media.EXTERNAL_CONTENT_URI, null),
            CatSpec("Audio", MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, null),
            CatSpec("Documents", MediaStore.Files.getContentUri("external"), null)
        )

        for (spec in specs) {
            val projection = arrayOf(
                MediaStore.MediaColumns._ID,
                MediaStore.MediaColumns.SIZE,
                MediaStore.MediaColumns.MIME_TYPE
            )
            val selection: String? = if (spec.name == "Documents") {
                "(${MediaStore.Files.FileColumns.MEDIA_TYPE} = ${MediaStore.Files.FileColumns.MEDIA_TYPE_NONE} " +
                    "OR ${MediaStore.Files.FileColumns.MIME_TYPE} LIKE 'application/%' " +
                    "OR ${MediaStore.Files.FileColumns.MIME_TYPE} LIKE 'text/%')"
            } else null

            var count = 0
            var totalBytes = 0L
            context.contentResolver.query(
                spec.uri, projection, selection, null, null
            )?.use { cursor ->
                val sizeIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
                while (cursor.moveToNext()) {
                    count++
                    totalBytes += cursor.getLong(sizeIdx)
                }
            }
            results.add(
                mapOf(
                    "category" to spec.name,
                    "fileCount" to count,
                    "totalBytes" to totalBytes
                )
            )
        }
        return results
    }

    // ── 3. Large files ────────────────────────────────────────────────────────

    private fun getLargeFiles(topN: Int): List<Map<String, Any?>> {
        val results = mutableListOf<Map<String, Any?>>()
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.DATE_MODIFIED
        )
        val uri = MediaStore.Files.getContentUri("external")
        val sortOrder = "${MediaStore.MediaColumns.SIZE} DESC"

        context.contentResolver.query(
            uri, projection, null, null, sortOrder
        )?.use { cursor ->
            val idIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val dataIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
            val sizeIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            val mimeIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
            val dateIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)

            var fetched = 0
            while (cursor.moveToNext() && fetched < topN) {
                val sizeBytes = cursor.getLong(sizeIdx)
                if (sizeBytes <= 0) continue
                results.add(
                    mapOf(
                        "id" to cursor.getString(idIdx),
                        "name" to (cursor.getString(nameIdx) ?: ""),
                        "path" to (cursor.getString(dataIdx) ?: ""),
                        "sizeBytes" to sizeBytes,
                        "mimeType" to (cursor.getString(mimeIdx) ?: ""),
                        "dateModifiedMs" to cursor.getLong(dateIdx) * 1000L
                    )
                )
                fetched++
            }
        }
        return results
    }

    // ── 4. Duplicates (two-pass) ──────────────────────────────────────────────

    private fun getDuplicates(): List<Map<String, Any?>> {
        // Pass 1: group by size
        val projection = arrayOf(
            MediaStore.MediaColumns._ID,
            MediaStore.MediaColumns.DISPLAY_NAME,
            MediaStore.MediaColumns.DATA,
            MediaStore.MediaColumns.SIZE,
            MediaStore.MediaColumns.MIME_TYPE,
            MediaStore.MediaColumns.DATE_MODIFIED
        )
        val uri = MediaStore.Files.getContentUri("external")

        val bySize = mutableMapOf<Long, MutableList<Map<String, Any?>>>()
        context.contentResolver.query(
            uri, projection, null, null, null
        )?.use { cursor ->
            val idIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
            val nameIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DISPLAY_NAME)
            val dataIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATA)
            val sizeIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.SIZE)
            val mimeIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.MIME_TYPE)
            val dateIdx = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns.DATE_MODIFIED)

            while (cursor.moveToNext()) {
                val size = cursor.getLong(sizeIdx)
                if (size <= 0) continue
                val item = mapOf(
                    "id" to cursor.getString(idIdx),
                    "name" to (cursor.getString(nameIdx) ?: ""),
                    "path" to (cursor.getString(dataIdx) ?: ""),
                    "sizeBytes" to size,
                    "mimeType" to (cursor.getString(mimeIdx) ?: ""),
                    "dateModifiedMs" to cursor.getLong(dateIdx) * 1000L
                )
                bySize.getOrPut(size) { mutableListOf() }.add(item)
            }
        }

        // Pass 2: hash the candidates
        val groups = mutableListOf<Map<String, Any?>>()
        for ((size, candidates) in bySize) {
            if (candidates.size < 2) continue
            val byHash = mutableMapOf<String, MutableList<Map<String, Any?>>>()
            for (item in candidates) {
                val path = item["path"] as? String ?: continue
                val file = File(path)
                if (!file.exists() || !file.canRead()) {
                    // Accessible via MediaStore URI only — hash not possible
                    byHash.getOrPut("__size_only_$size") { mutableListOf() }.add(item)
                    continue
                }
                val hash = sha256(file) ?: continue
                byHash.getOrPut(hash) { mutableListOf() }.add(item)
            }
            for ((hashKey, items) in byHash) {
                if (items.size < 2) continue
                val isSizeOnly = hashKey.startsWith("__size_only_")
                val itemsWithHash = if (isSizeOnly) items else items.map { it + mapOf("sha256" to hashKey) }
                groups.add(
                    mapOf(
                        "sizeBytes" to size,
                        "sha256" to (if (isSizeOnly) null else hashKey),
                        "items" to itemsWithHash
                    )
                )
            }
        }
        return groups
    }

    private fun sha256(file: File): String? {
        return try {
            val digest = MessageDigest.getInstance("SHA-256")
            file.inputStream().use { stream ->
                val buffer = ByteArray(8192)
                var read: Int
                while (stream.read(buffer).also { read = it } != -1) {
                    digest.update(buffer, 0, read)
                }
            }
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (_: Exception) {
            null
        }
    }

    // ── 5. Per-app storage ────────────────────────────────────────────────────

    private fun getAppStorage(): List<Map<String, Any>> {
        val results = mutableListOf<Map<String, Any>>()
        try {
            val storageManager =
                context.getSystemService(Context.STORAGE_SERVICE) as StorageManager
            val statsManager =
                context.getSystemService(Context.STORAGE_STATS_SERVICE) as StorageStatsManager
            val pm = context.packageManager
            val storageUuid: UUID = StorageManager.UUID_DEFAULT

            val packages = pm.getInstalledPackages(0)
            for (pkg in packages) {
                try {
                    val stats = statsManager.queryStatsForPackage(
                        storageUuid, pkg.packageName, android.os.Process.myUserHandle()
                    )
                    val label = pm.getApplicationLabel(pkg.applicationInfo).toString()
                    results.add(
                        mapOf(
                            "packageName" to pkg.packageName,
                            "appName" to label,
                            "appBytes" to stats.appBytes,
                            "dataBytes" to stats.dataBytes,
                            "cacheBytes" to stats.cacheBytes
                        )
                    )
                } catch (_: Exception) {
                    // skip packages we can't query
                }
            }
        } catch (_: Exception) {
            // StorageStatsManager unavailable — return empty list; UI shows banner
        }
        return results.sortedByDescending { (it["appBytes"] as Long) + (it["dataBytes"] as Long) }
    }
}
