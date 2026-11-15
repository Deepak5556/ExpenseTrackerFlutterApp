# Expense Journal & Budget

Android Flutter app with five destinations: Home, Journal, Add, Analytics and Settings. Google Sheets is the system of record. The app has **no backend and no database**; transaction data is held in memory while the app is open and is fetched from the connected spreadsheet. SharedPreferences stores only the workbook ID and device notification preferences.

## Google setup

1. In Google Cloud, enable **Google Sheets API** and **Google Drive API**.
2. Configure the OAuth consent screen and create an Android OAuth client for package `com.app.tracker.expense_journal_budget` using your debug/release signing SHA-1.
3. Create a Web application OAuth client ID. The app uses that public client ID only; do not add a client secret to Flutter.
4. Run with the web client ID supplied as a Dart define:

   ```powershell
   flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
   ```

The sign-in asks only for `https://www.googleapis.com/auth/drive.file`. The app can create and edit its own workbook and can use an existing workbook only when Google has made that file available to this app. A pasted spreadsheet ID does not grant access by itself. Broader Drive or Sheets scopes are not requested.

The app-created workbook has four tabs:

- `Transactions`: ID, type, title, amount in paise, category, ISO date/time, payment method, notes and soft-delete timestamp.
- `Categories`: categories and their active state.
- `Settings`: currency and monthly salary.
- `Budgets`: month/category spending limits.

## Run and verify

This machine has Java 26 first on `PATH`; Android Studio includes the Java 21 runtime that this Android build supports. Point Flutter at that runtime once:

```powershell
flutter config --jdk-dir="C:\Program Files\Android\Android Studio\jbr"
```

Restart the terminal after changing the Flutter setting.

```powershell
cd D:\ExpenseTracker
flutter pub get
flutter analyze
flutter test
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

Use a physical Android device with USB debugging or an Android Studio emulator with a Google Play image. Notification toggles are currently saved as device preferences; this version does not schedule background notifications.
