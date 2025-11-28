import 'package:EmprendeGastronLoja/presentation/pages/main/emprendimientos_search_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'injection_container.dart' as di;
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/pages/welcome/splash_page.dart';
import 'presentation/pages/welcome/welcome_page.dart';
import 'presentation/pages/welcome/greeting_page.dart';
import 'presentation/pages/auth/login_page.dart';
import 'presentation/pages/auth/register_page.dart';
import 'presentation/pages/auth/password_recovery_page.dart';
import 'core/themes/app_theme.dart';
import 'package:EmprendeGastronLoja/domain/repositories/auth_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => di.sl<AuthBloc>(),
      child: MaterialApp(
        title: 'Gastronomic Startups',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashPage(),
          '/welcome': (context) => const WelcomePage(),
          '/login': (context) => const LoginPage(),
          '/greeting': (context) => const GreetingPage(),
          '/register': (context) => const RegisterPage(),
          '/main': (context) => const WelcomePage(),
          '/emprendimientos': (context) => EmprendimientosSearchPage(
                authRepository: di.sl<AuthRepository>(),
              ),
          '/password-recovery': (context) => const PasswordRecoveryPage(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}