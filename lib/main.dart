import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_better_auth/flutter_better_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import 'core/app_theme.dart';
import 'features/auth/auth_bloc/auth_bloc.dart';
import 'features/auth/auth_repository.dart';
import 'features/auth/login_page.dart';
import 'features/auth/splash_page.dart';
import 'features/stock/home_page.dart';
import 'features/stock/stock_bloc/tenant_bloc.dart';
import 'features/stock/stock_bloc/inventory_bloc.dart';
import 'features/stock/stock_bloc/sync_bloc.dart';
import 'features/stock/stock_count_update_page.dart';
import 'features/stock/stock_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final String betterAuthUrl = const String.fromEnvironment(
    'BETTER_AUTH_URL',
    defaultValue: 'https://stock-track-hazel.vercel.app/api/auth',
  );

  final uri = Uri.parse(betterAuthUrl);
  final origin = '${uri.scheme}://${uri.host}';

  await FlutterBetterAuth.initialize(
    url: betterAuthUrl,
    dio: Dio(
      BaseOptions(
        headers: {
          'content-type': 'application/json',
          'user-agent': 'FlutterBetterAuth/1.0.0',
          'flutter-origin': 'flutter://',
          'expo-origin': 'exp://',
          'x-skip-oauth-proxy': true,
          'Origin': origin,
        },
        validateStatus: (status) => status != null && status < 300,
      ),
    ),
  );

  await GoogleSignIn.instance.initialize(
    serverClientId: const String.fromEnvironment(
      'GOOGLE_CLIENT_ID',
      defaultValue: '892429331679-e1capv5tj20dhl21kql0pe25dmucecgl.apps.googleusercontent.com',
    ),
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
          BlocProvider<TenantBloc>(
            create: (context) => TenantBloc(
              stockRepository: context.read<StockRepository>(),
            ),
          ),
          BlocProvider<InventoryBloc>(
            create: (context) => InventoryBloc(
              stockRepository: context.read<StockRepository>(),
            ),
          ),
          BlocProvider<SyncBloc>(
            create: (context) => SyncBloc(
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
