<p align="center">
  <img src="screenshots/app_icon.png" width="100" alt="Money Tracker Icon"/>
</p>

<h1 align="center">💰 Money Tracker</h1>

<p align="center">
  A personal finance tracker built with Flutter — dark, minimal, and designed for Indian users.
  <br/>
  Track expenses, income, credit card bills, and auto-detect bank transactions from SMS.
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

### 9 Expense Categories
`Food` · `Vehicle` · `Fuel` · `Clothes` · `Groceries` · `Loan` · `Savings` · `Investments` · `Other`

Each category has its own icon and color for visual clarity.

### Charts & Insights
- **Pie Chart** — Monthly spending breakdown by category with touch interaction (tap a slice to see details)
- **Bar Chart** — 6-month income vs expense trend with savings insight
- **Smart Insights** — Auto-generated tips like "You saved ₹5K this month" or "Top spending: Food (42%)"

### SMS Auto-Entry (Android)
- **Scan SMS Inbox** — Reads last 30 days of bank SMS and detects transactions automatically
- **Auto-detect on Resume** — When you return to the app after a payment, it checks for new bank SMS
- **Indian Bank Support** — Parses SMS from AU Bank, Axis, SBI, HDFC, ICICI, Kotak, PNB, and 15+ other banks
- **Unicode Normalization** — Handles bold/styled characters (𝐂𝐫𝐞𝐝𝐢𝐭𝐞𝐝, 𝐃𝐞𝐛𝐢𝐭𝐞𝐝) commonly used in Indian bank SMS
- **Review & Confirm** — All detected transactions are shown for review before adding

### Screens
- **Home** — Hero balance card, quick stats, recent transactions, pie chart, bar chart
- **Today Detail** — All transactions for today, grouped and editable
- **Month Detail** — Full month breakdown with edit/delete support
- **Calendar** — Visual calendar with daily expense markers
- **Account** — Developer login for advanced access

### Other
- **Pull to Refresh** — Swipe down on home screen to reload data
- **Developer Mode** — Hidden login for full edit access (change dates, edit/delete any transaction)
- **Dark UI** — Premium dark theme with purple accent, designed for comfortable use
- **Currency** — Indian Rupees (₹)
- **Local Storage** — All data stored locally on device using SQLite (no cloud, no servers)
- **Legacy Migration** — Auto-migrates data from SharedPreferences to SQLite on first run

---

## 🏗️ Project Structure

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── transaction.dart               # Transaction, TransactionType, PaidVia, ExpenseCategory
├── screens/
│   ├── home_screen.dart               # Main dashboard with charts and SMS integration
│   ├── today_detail_screen.dart       # Today's transactions (grouped, editable)
│   ├── month_detail_screen.dart       # Monthly transactions (grouped, editable)
│   ├── calendar_screen.dart           # Calendar view with daily markers
│   └── account_screen.dart            # Developer login screen
└── services/
    ├── transaction_service.dart        # CRUD operations, balance calculations
    ├── database_helper.dart            # SQLite setup and migration
    ├── sms_service.dart                # SMS scanning, polling, permission handling
    ├── sms_parser.dart                 # Bank SMS parsing with Unicode normalization
    └── auth_service.dart               # Developer authentication (ChangeNotifier)
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
git clone https://github.com/YOUR_USERNAME/money_tracker.git
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

> SMS data is processed entirely on-device. Nothing is sent to any server.

---

## 🎨 Design

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#0F0F1A` | Main app background |
| Surface | `#1A1A2E` | Cards, sheets, app bar |
| Accent | `#6C63FF` | Primary purple accent |
| Gradient | `#5B54E0` → `#3D2FB5` | Hero card gradient |
| Green | `#2ECC71` | Income, positive values |
| Red | `#FF6B6B` | Expenses, negative values |
| Orange | `#E67E22` | Bill payments, warnings |

---

## 🔒 Privacy

- **100% Offline** — No internet connection required, no data leaves your device
- **Local SQLite** — All transactions stored in local database
- **SMS Processing** — Bank SMS is parsed on-device only, never uploaded
- **No Analytics** — No tracking, no telemetry, no third-party SDKs

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

<p align="center">
  Built with ❤️ using Flutter
</p>
