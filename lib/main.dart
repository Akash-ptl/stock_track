import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/app_theme.dart';
import 'core/firebase_options.dart';
import 'features/auth/auth_bloc/auth_bloc.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_page.dart';
import 'features/auth/splash_page.dart';
import 'features/stock/home_page.dart';
import 'features/stock/stock_bloc/stock_bloc.dart';
import 'features/stock/stock_count_update_page.dart';
import 'features/stock/stock_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase using options generated from google-services.json
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepository>(create: (context) => AuthRepository()),
        RepositoryProvider<StockRepository>(create: (context) => StockRepository()),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider<StockBloc>(
            create: (context) => StockBloc(
              stockRepository: context.read<StockRepository>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Stock Track',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light, // Forces light theme to match mockup design
          initialRoute: '/',
          routes: {
            '/': (context) => const SplashPage(),
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/update-count': (context) => const StockCountUpdatePage(),
          },
        ),
      ),
    );
  }
}
