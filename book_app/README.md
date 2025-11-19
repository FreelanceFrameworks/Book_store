
Book App - Complete Project
===========================

Contents:
- Flutter app implementing offline-first book saving, OpenAI integration, Pexels image lookup.
- Hive typed adapter (manual), Provider state management, connectivity-based sync, and example widget test.
- Safe initialization for Flutter Web (assets/.env) and desktop/mobile.

How to use:
1. Copy this folder into your Flutter workspace (or unzip somewhere).
2. Create a file at assets/.env (copy from .env.example and fill your keys for local testing only).
   - WARNING: Do not put production secrets in web builds unless you know the risks.
3. Run: flutter pub get
4. Run: flutter run -d chrome (or your device)
5. Backend: Point BACKEND_BASE_URL in assets/.env to your running backend (e.g. http://localhost:3000)

Files included:
- lib/main.dart
- lib/models/novel.dart
- lib/services/api_service.dart
- lib/providers/novel_provider.dart
- lib/screens/home_screen.dart
- lib/screens/saved_novels_screen.dart
- lib/screens/novel_details_screen.dart
- assets/.env.example
- test/widget_test.dart
