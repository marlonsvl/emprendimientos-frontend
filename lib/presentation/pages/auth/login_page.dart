import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/custom_text_field.dart';
import '../../widgets/common/custom_button.dart';
import '../../../core/utils/validators.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Responsive breakpoints following Flutter best practices
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthStatusChecked());
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(LoginRequested(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      ));
    }
  }

  // Determine device type based on width
  DeviceType _getDeviceType(double width) {
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  // Get responsive values based on device type
  ResponsiveConfig _getResponsiveConfig(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return ResponsiveConfig(
          horizontalPadding: 24.0,
          verticalSpacing: 16.0,
          logoSize: 100.0,
          maxWidth: double.infinity,
          topSpacing: 40.0,
        );
      case DeviceType.tablet:
        return ResponsiveConfig(
          horizontalPadding: 48.0,
          verticalSpacing: 24.0,
          logoSize: 120.0,
          maxWidth: 500.0,
          topSpacing: 60.0,
        );
      case DeviceType.desktop:
        return ResponsiveConfig(
          horizontalPadding: 64.0,
          verticalSpacing: 32.0,
          logoSize: 140.0,
          maxWidth: 450.0,
          topSpacing: 80.0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: theme.colorScheme.error,
              ),
            );
          } else if (state is AuthAuthenticated) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/greeting',
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          // Show loading screen while checking authentication status
          if (state is AuthInitial || 
              (state is AuthLoading && 
               _usernameController.text.isEmpty && 
               _passwordController.text.isEmpty)) {
            return _buildLoadingScreen(theme);
          }
          
          // Show login form if user is not authenticated or there's an error
          return _buildAdaptiveLoginForm(context, theme, state);
        },
      ),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final deviceType = _getDeviceType(size.width);
        final config = _getResponsiveConfig(deviceType);

        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo while loading
              Container(
                height: config.logoSize,
                width: config.logoSize,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.restaurant,
                  size: config.logoSize * 0.5,
                  color: theme.colorScheme.primary,
                ),
              ),
              
              SizedBox(height: config.verticalSpacing * 2),
              
              // Loading indicator
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
              
              SizedBox(height: config.verticalSpacing),
              
              Padding(
                padding: EdgeInsets.symmetric(horizontal: config.horizontalPadding),
                child: Text(
                  'Comprobando la autenticación...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdaptiveLoginForm(BuildContext context, ThemeData theme, AuthState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = MediaQuery.sizeOf(context);
        final deviceType = _getDeviceType(size.width);
        final config = _getResponsiveConfig(deviceType);
        final isLandscape = size.width > size.height && size.width < tabletBreakpoint;

        // For landscape on mobile, use a scrollable row layout
        if (isLandscape) {
          return _buildLandscapeLayout(context, theme, state, config);
        }

        // Standard portrait/tablet/desktop layout
        return _buildPortraitLayout(context, theme, state, config);
      },
    );
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ThemeData theme,
    AuthState state,
    ResponsiveConfig config,
  ) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: config.horizontalPadding,
            vertical: 24.0,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: config.maxWidth),
            child: _buildLoginFormContent(context, theme, state, config),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ThemeData theme,
    AuthState state,
    ResponsiveConfig config,
  ) {
    return SafeArea(
      child: Row(
        children: [
          // Left side - Branding
          Expanded(
            flex: 2,
            child: Container(
              color: theme.colorScheme.primary.withValues(alpha: 0.05),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: config.logoSize * 1.2,
                      width: config.logoSize * 1.2,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.restaurant,
                        size: config.logoSize * 0.6,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(height: config.verticalSpacing),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text(
                        'Descubre increíbles startups gastronómicas',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Right side - Form
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(config.horizontalPadding),
              child: _buildLoginFormContent(context, theme, state, config, isCompact: true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginFormContent(
    BuildContext context,
    ThemeData theme,
    AuthState state,
    ResponsiveConfig config, {
    bool isCompact = false,
  }) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!isCompact) ...[
            SizedBox(height: config.topSpacing),
            
            // Logo/Icon
            Center(
              child: Container(
                height: config.logoSize,
                width: config.logoSize,
                decoration: BoxDecoration(
                  //color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: /*Image.asset(
                  'lib/images/gastroicon.png',
                  height: config.logoSize * 0.5,
                  width: config.logoSize * 0.5, 
                  fit: BoxFit.contain,
                ),*/
                
                Icon(
                  Icons.restaurant,
                  size: config.logoSize * 0.5,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            
            SizedBox(height: config.verticalSpacing * 2),
          ] else
            SizedBox(height: config.verticalSpacing),
          
          // Title
          Text(
            'Bienvenido de nuevo!',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
              fontSize: _getAdaptiveFontSize(
                theme.textTheme.headlineMedium?.fontSize ?? 28,
                config,
              ),
            ),
            textAlign: TextAlign.center,
          ),
          
          if (!isCompact) ...[
            SizedBox(height: config.verticalSpacing * 0.5),
            
            Text(
              'Inicia sesión para descubrir increíbles startups gastronómicas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          SizedBox(height: config.verticalSpacing * 2),
          
          // Username Field
          CustomTextField(
            controller: _usernameController,
            hintText: 'Introduce tu nombre de usuario',
            labelText: 'Username',
            keyboardType: TextInputType.text,
            prefixIcon: Icon(
              Icons.alternate_email,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            validator: Validators.username,
          ),
          
          SizedBox(height: config.verticalSpacing),
          
          // Password Field
          CustomTextField(
            controller: _passwordController,
            hintText: 'Introduce tu password',
            labelText: 'Password',
            obscureText: true,
            prefixIcon: Icon(
              Icons.lock_outline,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            validator: Validators.password,
          ),
          
          SizedBox(height: config.verticalSpacing * 0.5),
          
          // Forgot Password
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/password-recovery');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: config.horizontalPadding * 0.5,
                  vertical: 8,
                ),
              ),
              child: Text(
                '¿Has olvidado tu contraseña?',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                  fontSize: _getAdaptiveFontSize(14, config),
                ),
              ),
            ),
          ),
          
          SizedBox(height: config.verticalSpacing * 1.5),
          
          // Login Button
          CustomButton(
            text: 'Sign In',
            onPressed: _handleLogin,
            isLoading: state is AuthLoading && 
                     (_usernameController.text.isNotEmpty || 
                      _passwordController.text.isNotEmpty),
            icon: const Icon(Icons.login),
          ),
          
          SizedBox(height: config.verticalSpacing * 1.5),
          
          // Divider
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: config.horizontalPadding * 0.5),
                child: Text(
                  'OR',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          
          SizedBox(height: config.verticalSpacing * 1.5),
          
          // Register Button
          CustomButton(
            text: 'Crear cuenta',
            onPressed: () {
              Navigator.of(context).pushNamed('/register');
            },
            isOutlined: true,
            icon: const Icon(Icons.person_add),
          ),
          
          SizedBox(height: config.verticalSpacing * 2),
        ],
      ),
    );
  }

  // Helper method to get adaptive font size
  double _getAdaptiveFontSize(double baseSize, ResponsiveConfig config) {
    if (config.logoSize <= 100) {
      return baseSize * 0.9; // Mobile - slightly smaller
    } else if (config.logoSize <= 120) {
      return baseSize; // Tablet - normal
    } else {
      return baseSize * 1.1; // Desktop - slightly larger
    }
  }
}

// Helper classes for responsive configuration
enum DeviceType { mobile, tablet, desktop }

class ResponsiveConfig {
  final double horizontalPadding;
  final double verticalSpacing;
  final double logoSize;
  final double maxWidth;
  final double topSpacing;

  ResponsiveConfig({
    required this.horizontalPadding,
    required this.verticalSpacing,
    required this.logoSize,
    required this.maxWidth,
    required this.topSpacing,
  });
}