# Upastithi Pramaan (उपस्थिति प्रमाण)

<div align="center">

**Offline-first · Multi-modal · Anti-Fraud Attendance Verification System**

*Built with Flutter & Native Kotlin — for educational institutions*

</div>

---

## 📌 Overview

**Upastithi Pramaan** (Attendance Proof) is an advanced mobile attendance system engineered to eliminate proxy/fraudulent marking. It enforces physical presence through a **triple-factor verification engine**:

| # | Factor | Technology | Threshold |
|---|--------|------------|-----------|
| 1 | **BLE Proximity** | Native Kotlin BLE Advertiser/Scanner | RSSI ≥ −65 dBm (7-packet sliding window) |
| 2 | **On-Device Face Match** | MobileFaceNet via TensorFlow Lite | Euclidean distance < 0.45 |
| 3 | **Rolling 2FA Code** | Server-side rotating 6-char code | Expires every 40–50 seconds |

A **Fraud Score** (0–100) is computed on every attendance submission and stored in Supabase for admin review:

```
Fraud Score = (BLE Failed × 40) + (Face Failed × 40) + (Code Failed × 20)
```

---

## ✨ Key Features

- 🔌 **Offline-first** — attendance is cached locally in Drift (SQLite) when offline and auto-synced on reconnect
- 📡 **Native BLE** — custom Kotlin module handles BLE advertising (teacher) and scanning (student), bypassing Flutter plugin limitations on Android 12+
- 🧠 **On-device AI** — face recognition runs entirely on-device using MobileFaceNet; no images are ever sent to a server
- 👤 **Three user roles** — Student, Faculty (Teacher), Admin — each with separate login flows and dashboards
- 🔒 **SHA-256 password hashing** — passwords are never stored in plaintext; all authentication is done via Supabase PostgreSQL
- 🗄️ **Reactive state** — entire app state is managed via Riverpod (`NotifierProvider`, `StreamProvider`, `StateProvider`)

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter / Dart Layer                     │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  Auth    │  │ Student  │  │ Teacher  │  │    Admin     │   │
│  │ Feature  │  │ Feature  │  │ Feature  │  │   Feature    │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       │              │              │               │            │
│  ┌────▼──────────────▼──────────────▼───────────────▼───────┐  │
│  │              Services (Riverpod Providers)                │  │
│  │  AuthService · SessionService · FaceMLService · BleService│  │
│  └──────────────────────────┬────────────────────────────────┘  │
│                             │                                   │
│  ┌──────────────────────────▼────────────────────────────────┐  │
│  │                  Data Layer                               │  │
│  │  AppDatabase (Drift/SQLite)  ·  Supabase Client           │  │
│  └───────────────────────────────────────────────────────────┘  │
│                             │                                   │
│  ┌──────────────────────────▼────────────────────────────────┐  │
│  │          Platform Bridge: BleChannel (ble_channel.dart)   │  │
│  │     MethodChannel: com.upastithi/ble                      │  │
│  │     EventChannel: com.upastithi/ble_scan_events           │  │
│  └──────────────────────────┬────────────────────────────────┘  │
└─────────────────────────────┼───────────────────────────────────┘
                              │
┌─────────────────────────────▼───────────────────────────────────┐
│               Native Android / Kotlin Layer                     │
│   MainActivity.kt · BleAdvertiser.kt · BleScanner.kt           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Tech Stack

### Framework & Language
| | Detail |
|---|---|
| **Flutter SDK** | `>=3.22.0` |
| **Dart SDK** | `>=3.3.0 <4.0.0` |
| **Android minSdk** | `26` (Android 8.0) |
| **Android targetSdk** | `34` |
| **Android compileSdk** | `36` |
| **Kotlin** | `1.9.22` (JVM target: 17) |
| **NDK** | `28.2.13676358` |
| **ABI targets** | `arm64-v8a`, `armeabi-v7a`, `x86_64` |

### Flutter Dependencies

| Package | Version | Role |
|---------|---------|------|
| `supabase_flutter` | `^2.5.0` | Remote auth, cloud PostgreSQL, session management |
| `go_router` | `^14.2.0` | Declarative, URL-based routing with role guards |
| `flutter_riverpod` | `^2.5.1` | Reactive state management |
| `riverpod_annotation` | `^2.3.5` | Code-gen annotations for Riverpod |
| `drift` | `^2.18.0` | Type-safe SQLite ORM for offline storage |
| `drift_flutter` | `^0.2.0` | Flutter-specific Drift helpers |
| `path_provider` | `^2.1.3` | Platform-specific file paths |
| `camera` | `^0.11.0+2` | Live camera stream for face capture |
| `google_mlkit_face_detection` | `^0.11.0` | On-device face bounding box detection |
| `tflite_flutter` | `^0.11.0` | Native TFLite interpreter (MobileFaceNet) |
| `flutter_blue_plus` | `^1.32.12` | BLE support (supplementary; core BLE is native Kotlin) |
| `permission_handler` | `^11.3.1` | Runtime Camera, BLE, Location permissions |
| `dio` | `^5.4.3` | HTTP client for any custom REST calls |
| `connectivity_plus` | `^6.0.3` | Network status monitoring for sync trigger |
| `crypto` | `^3.0.3` | SHA-256 password hashing |
| `uuid` | `^4.4.0` | Session UUID generation |
| `freezed_annotation` | `^2.4.1` | Immutable data class annotations |
| `json_annotation` | `^4.9.0` | JSON serialisation annotations |
| `logger` | `^2.3.0` | Structured console logging |
| `intl` | `^0.19.0` | Date/time formatting |

### Dev Dependencies

| Package | Role |
|---------|------|
| `build_runner` | Code generation runner |
| `drift_dev` | Drift schema + DAO code generator |
| `riverpod_generator` | Riverpod provider code generator |
| `freezed` | Immutable class boilerplate generator |
| `json_serializable` | JSON encode/decode boilerplate |
| `flutter_lints` | Lint rules |

---

## 📂 Project Structure

```
upastithi_pramaan/
│
├── android/
│   └── app/
│       ├── build.gradle.kts             # Android build config (minSdk 26, compileSdk 36)
│       ├── proguard-rules.pro
│       └── src/
│           ├── main/
│           │   ├── AndroidManifest.xml  # Permissions: BLE, Camera, Internet
│           │   ├── kotlin/com/upastithi/upastithi_pramaan/
│           │   │   ├── MainActivity.kt  # Flutter engine setup, channel wiring, permissions
│           │   │   ├── BleAdvertiser.kt # BLE peripheral: low-latency advertising
│           │   │   └── BleScanner.kt    # BLE central: scanning + RSSI sliding window
│           │   └── res/                 # Launcher icons, themes, drawables
│           ├── debug/AndroidManifest.xml
│           └── profile/AndroidManifest.xml
│
├── assets/
│   ├── models/
│   │   └── mobilefacenet.tflite         # Pre-trained 128-d face embedding model
│   └── images/                          # Static UI assets
│
├── lib/
│   ├── main.dart                        # Entry point: Supabase.initialize + ProviderScope
│   │
│   ├── app/
│   │   ├── app.dart                     # MaterialApp.router + AppTheme wiring
│   │   └── routes.dart                  # GoRouter with all named routes
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_constants.dart       # Thresholds, route names, model path, session timing
│   │   │   ├── ble_constants.dart       # Channel names, service UUID, manufacturer ID
│   │   │   └── supabase_constants.dart  # Supabase URL, anon key, table names
│   │   ├── theme/
│   │   │   └── app_theme.dart           # Material ThemeData (light)
│   │   └── utils/
│   │       ├── app_logger.dart          # Wrapper around `logger` package
│   │       └── session_code_generator.dart  # Generates rotating 6-char alphanumeric codes
│   │
│   ├── data/
│   │   ├── local/
│   │   │   ├── app_database.dart        # Drift @DriftDatabase declaration + helpers
│   │   │   ├── app_database.g.dart      # Generated DAO / query code
│   │   │   └── models/
│   │   │       ├── student_embedding.dart  # Drift table: student face embeddings (BLOB)
│   │   │       └── attendance_log.dart     # Drift table: attendance cache with sync flag
│   │   ├── models/
│   │   │   ├── app_user.dart            # AppUser model (student / faculty / admin)
│   │   │   └── session_model.dart       # SessionModel from Supabase sessions table
│   │   └── sync/                        # (Reserved) Background sync logic
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── login_screen.dart        # Tab-based login: Student / Faculty / Admin
│   │   │   └── register_screen.dart     # Student self-registration + face enrollment
│   │   ├── student/
│   │   │   ├── student_dashboard.dart   # Session list, attendance stats, verification flow
│   │   │   ├── face_verification_widget.dart  # Camera stream → ML Kit → TFLite pipeline
│   │   │   ├── proximity_indicator.dart       # Live RSSI strength visualiser
│   │   │   └── code_entry_widget.dart         # 6-char code input + server validation
│   │   ├── teacher/
│   │   │   ├── teacher_dashboard.dart   # Session creation, BLE start, attendance list
│   │   │   └── session_code_widget.dart # Auto-rotating 2FA code display (40–50 s)
│   │   └── admin/
│   │       ├── admin_dashboard.dart     # Admin portal entry
│   │       ├── add_faculty_screen.dart  # Register new faculty members
│   │       ├── view_faculty_screen.dart # Browse / remove faculty
│   │       ├── manage_subjects_screen.dart  # Create / assign subjects to faculty
│   │       └── view_students_screen.dart    # Browse registered students
│   │
│   ├── platform/
│   │   └── ble_channel.dart            # Dart-side MethodChannel + EventChannel bridge;
│   │                                   # BleScanResult model; bleScanStreamProvider;
│   │                                   # nearbyTeachersProvider (MAC-deduped map)
│   │
│   └── services/
│       ├── auth_service.dart           # SHA-256 login for Student / Faculty / Admin
│       ├── ble_service.dart            # BleServiceNotifier (idle/advertising/scanning/error)
│       ├── face_ml_service.dart        # TFLite model load, YUV→RGB, inference, L2 norm
│       └── session_service.dart        # Supabase CRUD: create/update/end session, verify code, submit attendance
│
├── test/
│   └── widget_test.dart
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 📡 Native BLE Module (Kotlin)

The core proximity engine is implemented natively in Kotlin to work around Android BLE stack limitations.

### Channel Map

```
Dart (BleChannel)                    Kotlin (MainActivity)
─────────────────────────────────────────────────────────
MethodChannel: com.upastithi/ble
  startAdvertising(sessionUuid, ──────────────────────► BleAdvertiser.start()
                   teacherName, roomCode)
  stopAdvertising()               ──────────────────────► BleAdvertiser.stop()
  startScan()                     ──────────────────────► BleScanner.start()
  stopScan()                      ──────────────────────► BleScanner.stop()

EventChannel: com.upastithi/ble_scan_events
  Stream<BleScanResult> ◄── { mac, rssi(avg), isNear, sessionUuid(prefix) }
```

### `BleAdvertiser.kt`

- **Mode:** `ADVERTISE_MODE_LOW_LATENCY` / `ADVERTISE_TX_POWER_HIGH` / non-connectable
- **Primary packet:** Manufacturer data only (Company ID `0x05AC`) to stay within the BLE 31-byte budget
  - Payload: 3-byte prefix of session UUID hex (`"293790fd-..."` → `[0x29, 0x37, 0x90]`)
- **Scan response:** Service UUID `4fafc201-1fb5-459e-8fcc-c5c9c331914b` — placed here to avoid primary packet size overruns and Android 12+ UUID drop bugs
- Guards: checks `isEnabled`, `isMultipleAdvertisementSupported`; maps all `ADVERTISE_FAILED_*` codes to error strings

### `BleScanner.kt`

- **Scan mode:** `SCAN_MODE_LOW_LATENCY`, no hardware filters (intentional — fixes Android 16 scan-response drop bugs)
- **Software filter:** checks for Manufacturer ID `0x05AC` in each `ScanRecord`
- **RSSI Sliding Window:** per-MAC `ArrayDeque<Int>` of size 7; proximity confirmed when `avg ≥ −65 dBm`
- **Session prefix parsing:** reads 3 manufacturer bytes → formats as 6-char hex string for cross-referencing with Supabase sessions
- Handles both `onScanResult` and `onBatchScanResults`; logs all `SCAN_FAILED_*` error codes

### `MainActivity.kt`

- Sets up both channels inside `configureFlutterEngine`
- **Pending-call queue**: if BLE permissions are not yet granted when `startAdvertising`/`startScan` arrives, the method arguments and `Result` are cached; `onRequestPermissionsResult` resumes them after the user grants permissions
- **Permission split:**
  - Android ≥ 12 (API 31): `BLUETOOTH_SCAN` + `BLUETOOTH_ADVERTISE` + `BLUETOOTH_CONNECT`
  - Android ≤ 11: `ACCESS_FINE_LOCATION`
- `onDestroy()` cleans up both advertiser and scanner to prevent battery drain

---

## 👁️ On-Device Face Recognition Pipeline (`FaceMLService`)

All biometric processing is local — no images leave the device.

```
CameraImage (YUV420)
       │
       ▼
ML Kit FaceDetector ──► Face.boundingBox
       │
       ▼  _preprocessFaceSync()
  Crop bbox from Y/U/V planes
  Bilinear resize → 112×112
  YUV → RGB:
    R = clamp(Y + 1.402*(V−128))
    G = clamp(Y − 0.344136*(U−128) − 0.714136*(V−128))
    B = clamp(Y + 1.772*(U−128))
  Normalize → [−1, 1]:
    pixel_norm = (pixel − 127.5) / 127.5
       │
       ▼  Input tensor: [1, 112, 112, 3] float32
  mobilefacenet.tflite (2 threads)
       │
       ▼  Output: [1, 128] float32
  L2 normalize → unit vector
       │
       ▼
  Euclidean distance vs. stored template
  d(a,b) = √Σ(aᵢ−bᵢ)²   →  match if d < 0.45
```

**Enrollment:** 5 captures are averaged (`averageEmbeddings`) and L2-normalised before storage. The template is serialised as 512 bytes (128 × float32) and stored as a BLOB in the local Drift database.

**Providers:** `faceMLServiceProvider` — lifecycle-managed via `ref.onDispose`.

---

## 🗄️ Database Schema

### Local (Drift / SQLite) — `upastithi_pramaan_db`

#### `student_embeddings`
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | Student UUID |
| `student_name` | TEXT | Display name |
| `student_roll_number` | TEXT (nullable) | University roll number |
| `embedding` | BLOB | 512 bytes = 128 × float32 face vector |
| `enrolled_at` | INTEGER | Epoch milliseconds |
| `synced` | BOOLEAN | `false` until uploaded to Supabase |

#### `attendance_logs`
| Column | Type | Notes |
|--------|------|-------|
| `id` | TEXT PK | Record UUID |
| `student_id` | TEXT | FK → Student UUID |
| `session_uuid` | TEXT | Target class session ID |
| `teacher_name` | TEXT | Cached teacher display name |
| `room_code` | TEXT | Classroom identifier |
| `proximity_verified` | BOOLEAN | BLE RSSI passed threshold |
| `face_verified` | BOOLEAN | Face match passed |
| `code_verified` | BOOLEAN | 2FA code matched |
| `captured_at` | INTEGER | Epoch milliseconds |
| `synced` | BOOLEAN | `false` until pushed to Supabase |

### Cloud (Supabase PostgreSQL)

| Table | Purpose |
|-------|---------|
| `users` | Base user record with `role`, `password_hash` |
| `students` | Student profile: `roll`, `name`, `division`, `semester`, `department` |
| `faculty` | Faculty profile: `emp_id`, `name`, `department` |
| `subjects` | Subject catalogue: `name`, `code` |
| `sessions` | Active class sessions: `twofa_code`, `twofa_code_expires_at`, `active`, `faculty_id`, `subject_id` |
| `attendance_records` | Final records: `ble_verified`, `ble_rssi`, `face_verified`, `mac_verified`, `fraud_score`, `marked_at` |

---

## 🔀 Application Routes

Managed by `go_router` via `routerProvider`:

| Route | Name | Screen |
|-------|------|--------|
| `/login` | `login` | `LoginScreen` — tab-based (Student / Faculty / Admin) |
| `/register` | `register` | `RegisterScreen` — student self-registration + face enrollment |
| `/student` | `student` | `StudentDashboard` |
| `/teacher` | `teacher` | `TeacherDashboard` |
| `/admin` | `admin` | `AdminDashboard` |
| `/admin/add-faculty` | `admin-add-faculty` | `AddFacultyScreen` |
| `/admin/subjects` | `admin-subjects` | `ManageSubjectsScreen` |
| `/admin/students` | `admin-students` | `ViewStudentsScreen` |
| `/admin/faculty` | `admin-faculty` | `ViewFacultyScreen` |

---

## 🔑 Authentication & Roles

Authentication (`AuthService`) does **not** use Supabase Auth — it queries the `users` table directly with SHA-256 hashed passwords, keeping all credential logic server-side within Supabase RLS.

| Role | Login credential | Redirected to |
|------|-----------------|---------------|
| **Student** | Roll number + password | `/student` |
| **Faculty** | Employee ID + password | `/teacher` |
| **Admin** | Password only (single account) | `/admin` |

Session state is held in `currentUserProvider` (`StateProvider<AppUser?>`).

---

## 📱 Android Permissions

Declared in `AndroidManifest.xml`:

| Permission | Reason |
|------------|--------|
| `BLUETOOTH`, `BLUETOOTH_ADMIN` | Legacy BLE support (API < 31) |
| `BLUETOOTH_SCAN` (`neverForLocation`) | BLE scanning on API 31+ without location |
| `BLUETOOTH_ADVERTISE` | BLE peripheral advertising (teacher) |
| `BLUETOOTH_CONNECT` | BLE connection management |
| `ACCESS_FINE_LOCATION` | Required for BLE scan on API 23–30 |
| `CAMERA` | Face capture for recognition |
| `INTERNET` | Supabase sync |
| `ACCESS_NETWORK_STATE` | Connectivity check for sync trigger |

Hardware features required: `bluetooth_le`, `camera`, `camera.front`.

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** `>=3.22.0` ([install](https://docs.flutter.dev/get-started/install))
- **Android Studio** with Android SDK (API 26+ device or emulator)
- **Physical Android device** recommended — BLE advertising/scanning does not work on most emulators
- TFLite model file at `assets/models/mobilefacenet.tflite` (included in repo)

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/upastithi_pramaan.git
   cd upastithi_pramaan
   ```

2. **Configure Supabase**

   Open `lib/core/constants/supabase_constants.dart` and replace the placeholder values:
   ```dart
   static const String supabaseUrl = 'https://<your-project>.supabase.co';
   static const String supabaseAnonKey = '<your-anon-key>';
   ```

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **Run code generators** (Drift DAO, Riverpod providers, Freezed models)
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

5. **Run on a connected device**
   ```bash
   flutter run
   ```

> **Note:** Run `flutter run --release` for full BLE performance. In debug mode, BLE advertising on some devices may be slightly degraded.

---

## ⚙️ Configuration Reference

All tunable constants live in `lib/core/constants/app_constants.dart`:

| Constant | Default | Description |
|----------|---------|-------------|
| `faceMatchThreshold` | `0.45` | Euclidean distance threshold for face match |
| `faceEmbeddingSize` | `128` | Dimensions of the MobileFaceNet output vector |
| `faceEnrollmentCaptures` | `5` | Number of frames averaged during enrollment |
| `rssiThreshold` | `−65` dBm | Minimum average RSSI for proximity confirmation |
| `rssiWindowSize` | `7` | Number of BLE packets in the sliding window |
| `sessionCodeLength` | `6` | Length of the rotating 2FA code |
| `sessionCodeRefreshMinSeconds` | `40` | Min code rotation interval |
| `sessionCodeRefreshMaxSeconds` | `50` | Max code rotation interval |
| `syncRetryInterval` | `5 min` | Interval between offline sync retries |
| `tfliteModelPath` | `assets/models/mobilefacenet.tflite` | TFLite model asset path |

BLE channel constants are in `lib/core/constants/ble_constants.dart`:

| Constant | Value |
|----------|-------|
| `serviceUuid` | `4fafc201-1fb5-459e-8fcc-c5c9c331914b` |
| `bleMethodChannel` | `com.upastithi/ble` |
| `bleScanEventChannel` | `com.upastithi/ble_scan_events` |

---

## 🔒 Security Considerations

- Passwords are hashed with **SHA-256** before storage — never stored or transmitted in plaintext
- Face embeddings are stored only as **mathematical vectors** (not images); no biometric image ever leaves the device
- The BLE payload carries only a **3-byte session prefix**, not the full UUID; the student app cross-references this against the Supabase active sessions list
- Fraud scores are **server-recorded** — the client cannot suppress or alter them
- Code rotation window (40–50 s) prevents session replay attacks

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Run `flutter pub run build_runner build --delete-conflicting-outputs` after editing Drift tables or Riverpod providers
4. Submit a pull request

---

## 📄 License

This project is for academic/educational purposes. See [LICENSE](LICENSE) for details.
