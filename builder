$timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
flutter build apk --release --dart-define=BUILD_TIMESTAMP=$timestamp