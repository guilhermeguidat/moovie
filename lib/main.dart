import 'package:flutter/material.dart';
import 'package:moovie/providers/user_provider.dart';
import 'package:moovie/providers/movie_provider.dart';
import 'package:moovie/database/database_helper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:moovie/ui/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Arquivo .env não encontrado, usando configurações padrão');
  }

  final DatabaseHelper dbHelper = DatabaseHelper();
  await dbHelper.database;

  final userProvider = UserProvider(dbHelper);
  await userProvider.loadCurrentUser();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => userProvider),
        ChangeNotifierProxyProvider<UserProvider, MovieProvider>(
          create: (context) => MovieProvider(dbHelper),
          update: (context, userProvider, movieProvider) {
            movieProvider!.setCurrentUserId(userProvider.user?.id);
            return movieProvider;
          },
        ),
      ],
      child: const MoovieApp(),
    ),
  );
}

class MoovieApp extends StatelessWidget {
  const MoovieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moovie',
      theme: _buildTheme(),
      home: const SplashScreen(),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      fontFamily: 'Montserrat',
      scaffoldBackgroundColor: const Color(0xFF191221),
      appBarTheme: const AppBarTheme(
        color: Color(0xFF191221),
        elevation: 0,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6B45A1)
      ).copyWith(
        surface: const Color(0xFF191221),
      ),
    );
  }
}