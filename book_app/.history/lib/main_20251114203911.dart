import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'providers/novel_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // <- REQUIRED

  // Load env
  await dotenv.load(fileName: ".env");

  // Init Hive
  await Hive.initFlutter();

  // Register adapters
  Hive.registerAdapter(NovelAdapter());

  // Open boxes
  await Hive.openBox('novels');
  await Hive.openBox('pending_queue');
  await Hive.openBox('ai_cache'); // if used

  runApp(const MyApp());
}
