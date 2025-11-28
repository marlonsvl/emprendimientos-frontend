import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/custom_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    final isVerySmallScreen = size.height < 600;
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      },
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary.withValues(alpha: 0.8),
                theme.colorScheme.secondary.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - 
                    MediaQuery.of(context).padding.top - 
                    MediaQuery.of(context).padding.bottom,
                ),
                child: Column(
                  children: [
                    // Top Section - Logo and Text
                    _buildTopSection(context, theme, isSmallScreen, isVerySmallScreen),
                    
                    // Bottom Section - Buttons
                    _buildBottomSection(context, theme, isSmallScreen, isVerySmallScreen),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopSection(BuildContext context, ThemeData theme, bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 24 : 32,
        vertical: isVerySmallScreen ? 20 : (isSmallScreen ? 32 : 48),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Top spacing
          SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 40 : 60)),
          
          // Logo
          Container(
            height: isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120),
            width: isVerySmallScreen ? 80 : (isSmallScreen ? 100 : 120),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: isVerySmallScreen ? 40 : (isSmallScreen ? 50 : 60),
              color: Colors.white,
            ),
          ),
          
          SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 32)),
          
          // Title
          Text(
            'Emprendimientos\nGastronómicos',
            style: (isVerySmallScreen 
              ? theme.textTheme.headlineLarge
              : isSmallScreen 
                ? theme.textTheme.displaySmall
                : theme.textTheme.displayMedium)?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 12 : 16)),
          
          // Subtitle
          Text(
            'Descubra increíbles startups gastronómicos\n e innovaciones culinarias',
            style: (isSmallScreen 
              ? theme.textTheme.bodyMedium 
              : theme.textTheme.bodyLarge)?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Bottom spacing for top section
          SizedBox(height: isVerySmallScreen ? 32 : (isSmallScreen ? 48 : 64)),
        ],
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, ThemeData theme, bool isSmallScreen, bool isVerySmallScreen) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmallScreen ? 24 : 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(isSmallScreen ? 24 : 32),
          topRight: Radius.circular(isSmallScreen ? 24 : 32),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top spacing in bottom section
          SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
          
          // Sign In Button
          CustomButton(
            text: 'Sign In',
            onPressed: () {
              Navigator.of(context).pushNamed('/login');
            },
            width: double.infinity,
          ),
          
          SizedBox(height: isSmallScreen ? 12 : 16),
          
          // Create Account Button
          CustomButton(
            text: 'Crear cuenta',
            onPressed: () {
              Navigator.of(context).pushNamed('/register');
            },
            isOutlined: true,
            width: double.infinity,
          ),
          
          SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
          
          // Terms and Privacy
          Text(
            'Al continuar, aceptas nuestros Términos de servicio\ny Política de privacidad.',
            style: (isSmallScreen 
              ? theme.textTheme.bodySmall?.copyWith(fontSize: 12)
              : theme.textTheme.bodySmall)?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          
          // Bottom spacing in bottom section
          SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 20 : 24)),
        ],
      ),
    );
  }
}