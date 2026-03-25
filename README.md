<p align="center">
  <img src="screenshots/app_icon.png" width="100" alt="Money Tracker Icon"/>
</p>

<h1 align="center">💰 Money Tracker</h1>

<p align="center">
  A personal finance tracker built with Flutter — dark &amp; light themes, minimal, and designed for Indian users.
  <br/>
  Track expenses, income, credit card bills, and auto-detect bank transactions from SMS &amp; Gmail.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart" alt="Dart"/>
  <img src="https://img.shields.io/badge/Platform-Android-3DDC84?logo=android" alt="Android"/>
  <img src="https://img.shields.io/badge/Storage-SQLite-003B57?logo=sqlite" alt="SQLite"/>
</p>

---

## 📱 Screenshots

<p align="center">
  <img src="screenshots/home.jpg" width="220" alt="Home Screen"/>
  &nbsp;&nbsp;
  <img src="screenshots/add_expense.jpg" width="220" alt="Add Expense"/>
  &nbsp;&nbsp;
  <img src="screenshots/pie_chart.jpg" width="220" alt="Spending Breakdown"/>
</p>

<p align="center">
  <img src="screenshots/today.jpg" width="220" alt="Today Detail"/>
  &nbsp;&nbsp;
  <img src="screenshots/month.jpg" width="220" alt="Month Detail"/>
  &nbsp;&nbsp;
  <img src="screenshots/calendar.jpg" width="220" alt="Calendar View"/>
</p>

<p align="center">
  <img src="screenshots/sms_scan.jpg" width="220" alt="SMS Scan Results"/>
  &nbsp;&nbsp;
  <img src="screenshots/bar_chart.jpg" width="220" alt="Monthly Bar Chart"/>
  &nbsp;&nbsp;
  <img src="screenshots/drawer.jpg" width="220" alt="Navigation Drawer"/>
</p>

> **Note:** To add screenshots, take them from your device and place them in a `screenshots/` folder at the project root.

---

## ✨ Features

### Core Finance Tracking
- **Expense Tracking** — Log expenses with amount, label, category, and payment method (Bank / Credit Card)
- **Income Tracking** — Record salary, freelance earnings, or any income
- **Credit Card Management** — Track outstanding balance, pay full or partial bills
- **Bank Balance** — Auto-calculated from all income, expenses, and bill payments

### Budget & Spending Limits
- **Monthly Budget** — Set an overall monthly spending limit with progress bar on home screen
- **Category Budgets** — Set individual limits per category (Food, Fuel, etc.)
- **Smart Alerts** — Warning at 80% usage, alert when budget is exceeded
- **Toggle On/Off** — Enable budget tracking from Settings, manage budgets from the drawer menu

### 9 Expense Categories
`Food` · `Vehicle` · `Fuel` · `Clothes` · `Groceries` · `Loan` · `Savings` · `Investments` · `Other`

Each category has its own icon and color for visual clarity.

### Charts & Insights
- **Pie Chart** — Monthly spending breakdown by category with touch interaction
- **Bar Chart** — 6-month income vs expense trend with savings insight
- **Smart Insights** — Auto-generated tips like "You saved ₹5K this month" or "Top spending: Food (42%)"

### SMS Auto-Entry (Android)
- **Scan SMS Inbox** — Reads last 30 days of bank SMS and detects transactions automatically
- **Auto-detect on Resume** — Checks for new bank SMS when you return to the app
- **Indian Bank Support** — Parses SMS from AU Bank, Axis, SBI, HDFC, ICICI, Kotak, PNB, SBM, and 15+ other banks
- **Credit Card Detection** — Identifies credit card transactions from SMS and routes them correctly
- **Unicode Normalization** — Handles bold/styled characters (𝐂𝐫𝐞𝐝𝐢𝐭𝐞𝐝, 𝐃𝐞𝐛𝐢𝐭𝐞𝐝) commonly used in Indian bank SMS
- **Review & Confirm** — All detected transactions shown for review before adding

### Gmail Auto-Entry
- **Google Sign-In** — Connect your Gmail account with one tap
- **Scan Gmail Inbox** — Finds bank transaction emails from the last 30 days
- **Auto-detect** — Checks for new bank emails automatically when enabled
- **Parallel Fetching** — Fetches emails in batches of 10 for speed
- **Proximity-based CC Detection** — Credit card detection only triggers near the amount mention to avoid false positives
- **Multi-select Confirm** — Review scan results with select all / individual selection
- **Sign Out** — Disconnect Gmail anytime from Settings with one tap

### All Transactions
- **Search** — Search by label, category, or amount
- **Filter** — Filter by type (Expense / Income / Bill) and payment method (Bank / Credit Card)
- **Swipe to Delete** — Swipe left on any transaction to delete with confirmation
- **Tap to Edit** — Edit label, amount, and date for any transaction

### Screens
- **Home** — Hero balance card, budget progress, quick stats, recent transactions, pie chart, bar chart
- **Today Detail** — All transactions for today with swipe-to-delete and tap-to-edit
- **Month Detail** — Full month breakdown with expandable days, swipe-to-delete, tap-to-edit
- **Calendar** — Visual calendar with daily expense markers
- **All Transactions** — Searchable, filterable list of all transactions
- **Settings** — Theme toggle, app lock, budget toggle, SMS/Gmail configuration

### Dark & Light Theme
- **Toggle** — Switch between dark and light mode from Settings
- **Persisted** — Theme preference saved and restored on app restart
- **Adaptive** — All screens, cards, charts, and drawer adapt to the selected theme

### Privacy & Security
- **App Lock** — Lock the app with device PIN, pattern, password, or biometric (fingerprint/face)
- **Auto-lock** — Re-locks when the app goes to background
- **Device Authentication** — Uses the system lock screen, no separate PIN to remember

### Other
- **Pull to Refresh** — Swipe down on home screen to reload data
- **Edit & Delete for All** — Every user can edit/delete any transaction type and change dates
- **Currency** — Indian Rupees (₹)
- **Local Storage** — All data stored locally on device using SQLite
- **Legacy Migration** — Auto-migrates data from SharedPreferences to SQLite on first run

---

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point with theme & lock
├── models/
│   └── transaction.dart               # Transaction, TransactionType, PaidVia, ExpenseCategory
├── screens/
│   ├── home_screen.dart               # Main dashboard with charts, budget, SMS & Gmail
│   ├── today_detail_screen.dart       # Today's transactions (swipe-to-delete, tap-to-edit)
│   ├── month_detail_screen.dart       # Monthly transactions (expandable, editable)
│   ├── calendar_screen.dart           # Calendar view with daily markers
│   ├── all_transactions_screen.dart   # Search, filter & manage all transactions
│   ├── settings_screen.dart           # App settings (theme, lock, budget, SMS, Gmail)
│   ├── lock_screen.dart               # App lock screen with biometric/PIN auth
│   └── account_screen.dart            # Developer login screen
└── services/
    ├── transaction_service.dart        # CRUD operations, balance calculations
    ├── database_helper.dart            # SQLite setup and migration
    ├── sms_service.dart                # SMS scanning, polling, permission handling
    ├── sms_parser.dart                 # Bank SMS parsing with Unicode normalization
    ├── gmail_service.dart              # Gmail API integration, email parsing
    ├── gmail_parser.dart               # Bank email body parsing
    ├── budget_service.dart             # Budget management (overall & per-category)
    ├── theme_service.dart              # Dark/light theme with AppColors
    ├── lock_service.dart               # App lock with local_auth
    └── auth_service.dart               # Developer authentication
```

---

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x |
| Language | Dart 3.x |
| Database | SQLite (`sqflite`) |
| Charts | `fl_chart` |
| Calendar | `table_calendar` |
| Date Formatting | `intl` |
| Preferences | `shared_preferences` |
| SMS Reading | Native Android `MethodChannel` |
| Gmail | `google_sign_in` + `googleapis` |
| Authentication | `local_auth` (biometric/PIN/pattern) |
| State Management | `StatefulWidget` + Service singletons |
| Architecture | Simple service-based (no BLoC/Riverpod) |

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.x+
- Android Studio / VS Code
- Android device or emulator (SMS features require a real device)

### Installation

```bash
# Clone the repository
git clone https://github.com/Parthrokde03/money_tracker.git
cd money_tracker

# Install dependencies
flutter pub get

# Run on connected device
flutter run
```

### SMS Permissions (Android)
The app requests these permissions for SMS auto-entry:
- `READ_SMS` — To scan inbox for bank transaction messages
- `RECEIVE_SMS` — To detect new SMS on app resume

### Gmail Setup
1. Create a project in [Google Cloud Console](https://console.cloud.google.com/)
2. Enable the Gmail API
3. Configure OAuth consent screen
4. Create Android OAuth client ID with your app's SHA-1 fingerprint
5. Connect Gmail from Settings in the app

> SMS and email data is processed entirely on-device. Nothing is sent to any external server.

---

## 🎨 Design

Supports both dark and light themes. Colors adapt automatically.

| Token | Dark | Light | Usage |
|-------|------|-------|-------|
| Background | `#0F0F1A` | `#F2F3F7` | Main app background |
| Surface | `#1A1A2E` | `#FFFFFF` | Cards, sheets, app bar |
| Accent | `#6C63FF` | `#6C63FF` | Primary purple accent |
| Gradient | `#5B54E0` → `#3D2FB5` | Same | Hero card gradient |
| Green | `#2ECC71` | `#2ECC71` | Income, positive values |
| Red | `#FF6B6B` | `#FF6B6B` | Expenses, negative values |
| Orange | `#E67E22` | `#E67E22` | Bill payments, warnings |

---

## 🔒 Privacy

- **100% Offline** — No internet required for core features (Gmail sync is optional)
- **Local SQLite** — All transactions stored in local database
- **SMS Processing** — Bank SMS is parsed on-device only, never uploaded
- **Gmail Processing** — Email content parsed on-device, only Gmail API used for fetching
- **App Lock** — Optional device-level authentication (PIN/pattern/biometric)
- **No Analytics** — No tracking, no telemetry, no third-party analytics SDKs

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  Built with ❤️ using Flutter
</p>
