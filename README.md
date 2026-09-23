# Ace Assignment Helps (AAH) - Mobile Portal Application

A modern, high-performance cross-platform Flutter mobile application for the **Ace Assignment Helps (AAH)** portal ecosystem. The application connects directly to the live **AWS RDS MySQL** database (`aceassignmenthelp_db`) through a dedicated REST API bridge, providing real-time data synchronization with the web portal.

---

## 📱 Supported Portals & Features

The app features a **Single Unified Login** with automatic role detection matching the web portal's `login.php`. Users simply enter their email and password; the system automatically authenticates them, detects their role, and routes them to their dedicated workspace:

### 🎓 1. Student Portal
* **Dashboard Overview**: Active orders, SLA deadline indicators, and quick action shortcuts.
* **Submit New Assignment**: Multi-discipline selector (loaded dynamically from courses), assignment type picker, reference style, deadline date/time picker, and **live price calculation** across currencies (`USD`, `INR`, `GBP`, `EUR`, `AUD`, `CAD`).
* **My Assignments**: Comprehensive order tracking with search and status filters (*All*, *In Progress*, *Under Review*, *Completed*).
* **Invoices & Payments**: Financial investment tracker, payment history, invoice breakdown, and transaction status (*Paid* vs *Pending*).
* **Support Tickets & Messages**: In-app ticketing system to submit inquiries and receive updates from the allocation team.
* **Profile & Security**: Student profile information management and modern password hashing updates.

### ⚡ 2. Allocator Portal
* **Command Center**: Real-time KPI counters for unallocated orders, active assignments, and expert workloads.
* **Pending Queue**: Unallocated orders queue with **1-Tap "Allocate Expert" Modal Bottom Sheet**:
  * Browse active academic experts with ratings and current task workloads.
  * Set customized expert deadlines.
  * Instant assignment and notification dispatch.
* **Allocated & Active**: Track orders currently in production with SLA countdowns.
* **Expert Roster Directory**: Directory of PhD academic experts with qualifications, ratings, and workload availability (*Available* vs *Busy*).

### 🔬 3. Expert Workspace
* **Dashboard Overview**: Active tasks counter, in-progress drafts, tasks under review, and completed count.
* **Assigned Tasks**:
  * **"Start Working"**: Update task status to *In Progress*.
  * **"Submit for QA"**: Submit completed solution drafts to the allocator for quality assurance.
  * **"View Brief"**: Review detailed student requirements, rubrics, and attachments.
* **Completed Solutions Archive**: Complete history of verified solutions delivered to students.
* **Profile & Qualifications**: Manage expert specialties and change passwords.

### 🛡️ 4. Executive Admin Portal
* **Executive Dashboard**: Live revenue metrics, total orders, active production, and database sync status.
* **Master Assignments Manager**: Global assignment database with full status filtering and inspection.
* **Registered Students Directory**: Student search, total orders placed, total spent, and **1-Tap Block / Unblock** security controls.
* **Financial Ledger**: Platform-wide transaction stream across Stripe, cards, and bank payments.
* **Coupons & Discounts System**: Active discount coupons management and **"Create Coupon"** dialog with customizable percentages, usage caps, and expiration dates.

---

## 🛠️ Tech Stack & Requirements

* **Framework**: Flutter 3.24+ / Dart 3.5+
* **State & Networking**: `http`, `shared_preferences`
* **Typography & UI**: Google Fonts (`Outfit` & `Plus Jakarta Sans`), Material 3 Design
* **Backend Bridge**: PHP 8.1+ REST API (`portal_api.php`)
* **Database**: AWS RDS MySQL (`database-1.c1o0ygcs2cex.ap-south-1.rds.amazonaws.com`)
* **Java Runtime**: JDK 17 or JDK 21

---

## 💻 Running on Windows

Follow these steps to set up and run the application on **Windows 10 / 11**.

### 1. Install Prerequisites
1. **Git for Windows**: Download and install from [git-scm.com](https://git-scm.com/download/win).
2. **Flutter SDK**:
   * Download Flutter Windows SDK from [flutter.dev](https://docs.flutter.dev/get-started/install/windows/mobile).
   * Extract the zip (e.g. to `C:\src\flutter`).
   * Add `C:\src\flutter\bin` to your User `PATH` environment variable.
3. **Java Development Kit (JDK 21 or JDK 17)**:
   * Download from [Adoptium Eclipse Temurin](https://adoptium.net/temurin/releases/?version=21).
   * Set Environment Variable `JAVA_HOME` (e.g. `C:\Program Files\Eclipse Adoptium\jdk-21.x.x`).
   * Add `%JAVA_HOME%\bin` to your `PATH`.
4. **Android Studio**:
   * Download from [developer.android.com/studio](https://developer.android.com/studio).
   * In Android Studio Settings (`SDK Manager`), ensure the following are checked:
     * **Android SDK Platform** (API 34 or 35)
     * **Android SDK Command-line Tools (latest)**
     * **Android SDK Build-Tools**
     * **Android SDK Platform-Tools**

### 2. Verify Environment
Open PowerShell or Command Prompt and run:
```powershell
flutter doctor
```
Ensure Flutter, Android toolchain, and Java show green checkmarks. (Accept Android licenses if prompted: `flutter doctor --android-licenses`).

### 3. Clone Repository
```powershell
git clone https://github.com/Rajsaro-IT-Solutions/Ace-Assignment-Helps-Mobile.git
cd Ace-Assignment-Helps-Mobile
```

### 4. Install Dependencies
```powershell
flutter pub get
```

### 5. Backend Server Connection
The application is pre-configured to communicate with the live cloud endpoint:
* Check `lib/core/config/api_config.dart`.
* By default, it connects to the live public endpoint, allowing physical devices and emulators to work instantly without configuring local ports.
* To change the server endpoint at runtime, tap the **Settings icon** (⚙️) on the top right of the Login screen.

### 6. Run the App
* **To run on an Android Emulator**:
  Start your emulator from Android Studio Device Manager, then execute:
  ```powershell
  flutter run
  ```
* **To run on a Physical Phone via USB**:
  1. Enable **Developer Options** and **USB Debugging** on your Android phone.
  2. Connect your phone to your PC via USB.
  3. Verify connection: `flutter devices`
  4. Run:
     ```powershell
     flutter run -d <your-device-id>
     ```

### 7. Build Debug or Release APK
To generate a standalone `.apk` to install on any Android phone:
```powershell
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release
```
The compiled APK will be located at:
`build\app\outputs\flutter-apk\app-debug.apk`

---

## 🍏 Running on macOS

Follow these steps to set up and run the application on **macOS (Apple Silicon M1/M2/M3 or Intel)**.

### 1. Install Prerequisites
1. **Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. **Flutter SDK**:
   ```bash
   brew install --cask flutter
   ```
3. **Java JDK 21**:
   ```bash
   brew install openjdk@21
   sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk
   export JAVA_HOME=$(/usr/libexec/java_home -v 21)
   ```
   Add `export JAVA_HOME=$(/usr/libexec/java_home -v 21)` to your `~/.zshrc`.

4. **Android Setup**:
   * Install **Android Studio for Mac**: `brew install --cask android-studio`.
   * Open Android Studio ➔ Preferences ➔ Languages & Frameworks ➔ Android SDK ➔ install **Android SDK Command-line Tools** and **Platform-Tools**.

5. **iOS Setup (Optional - for running on iOS Simulator / iPhone)**:
   * Install **Xcode** from the Mac App Store.
   * Configure Xcode command-line tools:
     ```bash
     sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer
     sudo xcodebuild -runFirstLaunch
     ```
   * Install **CocoaPods**:
     ```bash
     brew install cocoapods
     ```

### 2. Verify Environment
Run:
```bash
flutter doctor
```
Accept any missing Android licenses:
```bash
flutter doctor --android-licenses
```

### 3. Clone Repository
```bash
git clone https://github.com/Rajsaro-IT-Solutions/Ace-Assignment-Helps-Mobile.git
cd Ace-Assignment-Helps-Mobile
```

### 4. Install Dependencies
```bash
flutter pub get
```

### 5. Run the App

#### On Android (Emulator or Connected USB Phone):
```bash
flutter run
```

#### On iOS Simulator:
1. Open the Simulator:
   ```bash
   open -a Simulator
   ```
2. Run the Flutter app:
   ```bash
   flutter run -d iPhone
   ```

### 6. Build Android APK
```bash
flutter build apk --debug
```
The output APK is at:
`build/app/outputs/flutter-apk/app-debug.apk`

---

## 🔑 Demo & Test Accounts

You can test every role immediately using these pre-configured accounts (or tap the **Quick Fill Demo Accounts** buttons on the Login screen):

| Role | Email Address | Password | Target Dashboard |
| :--- | :--- | :--- | :--- |
| **Student** | `gokulmarwal1627@gmail.com` | `password` | Student Dashboard, Orders & Invoices |
| **Admin** | `gokulmarwal16@gmail.com` | `password` | Executive Admin & Financial Ledger |
| **Allocator** | `allocator@aceassign.com` | `password` | Allocator Command Center & Pending Queue |
| **Expert** | `michael.zhang@experts.com` | `password` | Expert Task Management & Solutions |

---

## 🌐 Backend Architecture & API Configuration

The mobile app communicates via JSON REST requests with `/portal_api.php` located on your web server:

```text
Flutter Mobile App  <─── HTTPS ───>  portal_api.php  <─── MySQL PDO ───>  AWS RDS MySQL
(Android / iOS)                     (PHP Backend)                         (aceassignmenthelp_db)
```

### API Endpoints Overview:
* `action=login`: Auto-role unified login.
* `action=dashboard`: Computes role-specific KPIs.
* `action=assignments`: Filtered order lists with SLA calculations.
* `action=submit_assignment`: Inserts new order and creates pending invoice in AWS RDS.
* `action=allocate_expert`: Allocator expert assignment & notification.
* `action=allocator_review`: Allocator QA approve or request revision.
* `action=expert_action`: Expert marks task in-progress or submits solution.
* `action=payments_list`: Financial logs and transaction receipts.
* `action=students_list`: Student directory with block/unblock action.
* `action=experts_list`: Expert roster with workload metrics.
* `action=coupons`: Fetch and create discount coupons.
* `action=courses`: Active coursework subject disciplines.
* `action=support_tickets`: Ticketing system.

### Server Connection Switcher:
You can switch backend endpoints on the fly without recompiling:
1. Open the app to the **Login Screen**.
2. Tap the **Settings icon** (⚙️ / DNS) in the top-right corner of the AppBar.
3. Choose a preset (**Cloud Endpoint**, **Android Emulator**, **Local Wi-Fi**, or **Localhost**) or enter a custom URL.
4. Tap **Test Server Connection** ➔ **Save & Apply**.

---

## ❓ Troubleshooting

### 1. "Network issue / Cannot connect to server" on Physical Phone
* **Cause**: Connecting to `http://10.0.2.2:8000` or `http://localhost:8000`. `10.0.2.2` is a loopback alias only valid inside an Android emulator. Physical phones cannot reach it.
* **Fix**: Ensure your app is using the public Cloud Endpoint (or your local computer's Wi-Fi IP e.g. `http://192.168.x.x:8000`). You can verify and update this in `lib/core/config/api_config.dart` or via the in-app server settings dialog.

### 2. Gradle Build Timeout or Lock Issues
* If Gradle hangs while downloading dependencies:
  ```bash
  cd android
  ./gradlew --stop
  cd ..
  flutter clean
  flutter pub get
  flutter build apk --debug
  ```

### 3. Java Version Mismatch
* Flutter requires JDK 17 or JDK 21. If you encounter Java toolchain issues, verify your Java installation:
  ```bash
  java -version
  ```
  And confirm your `JAVA_HOME` environment variable points to a valid JDK directory.

---

## 📄 License
Copyright © 2026 Ace Assignment Helps. All rights reserved.
