# Storage Analyzer — Android Flutter App

An **Android-only**, 100 % offline Flutter application that gives you an
accurate, detailed breakdown of storage usage on your device.

---

## Features

| Screen | What it shows |
|---|---|
| **Dashboard** | Total / Free / Used gauge + category tiles |
| **Categories** | Images, Videos, Audio, Documents — count & size |
| **Large Files** | Top-50 largest files, sorted by size |
| **Duplicates** | Files detected as duplicates via two-pass scan |
| **Apps** | Per-app storage (app code + data + cache) |

---

## Requirements

| Requirement | Value |
|---|---|
| Minimum Android version | **Android 9 (API 28)** |
| Target Android SDK | 34 |
| Flutter | ≥ 3.10.0 |
| Dart | ≥ 3.0.0 |
| Language (Android) | Kotlin |

---

## Permissions

The app declares the following permissions in `AndroidManifest.xml`:

| Permission | Purpose |
|---|---|
| `READ_MEDIA_IMAGES` | Scan images via MediaStore (Android 13+) |
| `READ_MEDIA_VIDEO` | Scan videos via MediaStore (Android 13+) |
| `READ_MEDIA_AUDIO` | Scan audio via MediaStore (Android 13+) |
| `READ_EXTERNAL_STORAGE` (maxSdk 32) | Fallback for Android 9–12 |
| `PACKAGE_USAGE_STATS` | Per-app storage via StorageStatsManager (optional) |

**No network permissions are declared** — the app is fully offline.

> **Deletion** is only enabled where MediaStore or SAF (Storage Access
> Framework) permits. Files in private app directories cannot be deleted
> without explicit permission and the UI shows a banner explaining this
> limitation.

---

## Android Version Limitations

| Feature | Android 9–12 | Android 13+ |
|---|---|---|
| Media scan | `READ_EXTERNAL_STORAGE` | Granular `READ_MEDIA_*` |
| Per-app storage | `StorageStatsManager` (needs `PACKAGE_USAGE_STATS`) | Same |
| File hash (pass 2) | Readable if `DATA` column accessible | May fail for scoped-storage paths |

On Android 10+ (scoped storage), files outside `MediaStore` columns cannot
be read directly. The app degrades gracefully: if a file is unreachable for
SHA-256 hashing it is still included in the **size-only** duplicate group
(Pass 1) but marked as unverified.

---

## Two-Pass Duplicate Detection Logic

```
Pass 1 — Metadata (MediaStore)
  ├─ Query MediaStore.Files for all files
  ├─ Group by exact file size
  └─ Any group with ≥ 2 files → candidate set

Pass 2 — Hash Verification
  For each candidate set:
    ├─ If file is accessible (path readable):
    │     Compute SHA-256 → sub-group by hash
    │     Group with ≥ 2 matching hashes → confirmed duplicate
    └─ If file is NOT accessible (scoped storage):
          Keep as size-only group (unverified duplicate)
```

Result: `DuplicateGroup` objects with:
- `sizeBytes` — file size shared by the group
- `sha256` — hash string if verified; `null` if size-only
- `items` — list of `FileItem`s (name, path, id)
- `wastedBytes` = `sizeBytes × (count − 1)`

---

## Project Structure

```
mobile_app/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       └── kotlin/com/example/mobile_app/
│           ├── MainActivity.kt          ← registers MethodChannel
│           └── StorageAnalyzerPlugin.kt ← all platform implementations
├── lib/
│   ├── main.dart
│   ├── models/
│   │   ├── storage_totals.dart
│   │   ├── category_breakdown.dart
│   │   ├── file_item.dart
│   │   ├── duplicate_group.dart
│   │   └── app_storage_item.dart
│   ├── services/
│   │   ├── storage_analyzer.dart        ← abstract interface
│   │   └── storage_analyzer_impl.dart   ← MethodChannel implementation
│   ├── providers/
│   │   └── storage_provider.dart        ← ChangeNotifier state
│   ├── screens/
│   │   ├── home_screen.dart
│   │   ├── categories_screen.dart
│   │   ├── large_files_screen.dart
│   │   ├── duplicates_screen.dart
│   │   └── apps_screen.dart
│   ├── widgets/
│   │   ├── bytes_text.dart
│   │   └── limitations_banner.dart
│   └── utils/
│       └── format.dart
├── test/
│   ├── models_test.dart   ← model serialization tests
│   └── grouping_test.dart ← duplicate grouping logic tests
└── pubspec.yaml
```

---

## Run Instructions

### Prerequisites
1. Install [Flutter](https://docs.flutter.dev/get-started/install) (≥ 3.10).
2. Connect an Android device (API 28+) or launch an emulator.
3. Grant storage permissions when the app first requests them.

### Steps

```bash
cd mobile_app

# Fetch dependencies
flutter pub get

# Run on connected Android device
flutter run

# Run unit tests
flutter test
```

> **iOS is not supported.** The platform channel is Android-only.

---

## Architecture Notes

- **MethodChannel**: A single channel named `storage_analyzer` bridges Dart
  and Kotlin. Heavy work (MediaStore queries, file I/O for hashing) runs on
  a background thread pool in Kotlin, results are posted back to the main
  looper.
- **State management**: `provider` package with a single `StorageProvider`
  (`ChangeNotifier`). All five data sources are fetched in parallel via
  `Future.wait`.
- **No third-party analytics or network calls** of any kind.
