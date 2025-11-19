import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'models/novel.dart';
import 'providers/novel_provider.dart';
import 'screens/home_screen.dart';
import 'screens/saved_novels_screen.dart';
import 'screens/novel_details_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment (on web this must be assets/.env)
  await dotenv.load(fileName: 'assets/.env');

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NovelAdapter());

  // Open boxes
  await Hive.openBox<Novel>('savedNovels');
  await Hive.openBox('pendingSaves');
  await Hive.openBox('aiCache');

  // Create and init provider
  final novelProvider = NovelProvider();
  await novelProvider.init();

  runApp(BookApp(novelProvider: novelProvider));
}

class BookApp extends StatelessWidget {
  final NovelProvider novelProvider;
  const BookApp({Key? key, required this.novelProvider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<NovelProvider>.value(
      value: novelProvider,
      child: MaterialApp(
        title: 'Book App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true),
        initialRoute: '/',
        routes: {
          '/': (context) => const HomeScreen(),
          '/saved': (context) => const SavedNovelsScreen(),
          '/details': (context) => NovelDetailsScreen(),
        },
      ),
    );
  }
}
