
$ErrorActionPreference = "Stop"

# Replace this with your actual Google Web OAuth Client ID
$GoogleClientId = "1009502761295-dfhpo72p2i4fupeocufk9l0ke57nc0pv.apps.googleusercontent.com"

Write-Host "Getting Flutter dependencies..."
flutter pub get

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running Flutter analyzer..."
flutter analyze

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Running Flutter tests..."
flutter test

if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host "Launching Android application..."
flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=$GoogleClientId
