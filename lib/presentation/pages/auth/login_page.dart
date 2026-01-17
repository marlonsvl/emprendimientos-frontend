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

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Responsive breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade animation for smoother transitions
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthBloc>().add(AuthStatusChecked());
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
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

  DeviceType _getDeviceType(double width) {
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  ResponsiveConfig _getResponsiveConfig(DeviceType deviceType) {
    switch (deviceType) {
      case DeviceType.mobile:
        return ResponsiveConfig(
          horizontalPadding: 24.0,
          verticalSpacing: 20.0,
          logoSize: 120.0,
          maxWidth: double.infinity,
          topSpacing: 40.0,
        );
      case DeviceType.tablet:
        return ResponsiveConfig(
          horizontalPadding: 48.0,
          verticalSpacing: 28.0,
          logoSize: 140.0,
          maxWidth: 500.0,
          topSpacing: 60.0,
        );
      case DeviceType.desktop:
        return ResponsiveConfig(
          horizontalPadding: 64.0,
          verticalSpacing: 32.0,
          logoSize: 160.0,
          maxWidth: 480.0,
          topSpacing: 80.0,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFF59D), // Light yellow
              Color(0xFFFDD835), // Bright yellow
              Color(0xFFFDB913), // Golden yellow
              Color(0xFFF39C12), // Deep gold
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(child: Text(state.message)),
                    ],
                  ),
                  backgroundColor: theme.colorScheme.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
            } else if (state is AuthAuthenticated || state is AuthGuest) {
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/greeting',
                (route) => false,
              );
            }
          },
          builder: (context, state) {
            if (state is AuthInitial || 
                (state is AuthLoading && 
                 _usernameController.text.isEmpty && 
                 _passwordController.text.isEmpty)) {
              return _buildLoadingScreen(theme);
            }
            
            return _buildAdaptiveLoginForm(context, theme, state);
          },
        ),
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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated logo with gradient
                Container(
                  width: config.logoSize * 1.4,
                  height: config.logoSize * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'lib/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                
                SizedBox(height: config.verticalSpacing * 2),
                
                CircularProgressIndicator(
                  color: theme.colorScheme.onSurfaceVariant,
                  strokeWidth: 5,
                ),
                
                SizedBox(height: config.verticalSpacing),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: config.horizontalPadding),
                  child: Text(
                    'Comprobando autenticación...',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
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

        if (isLandscape) {
          return _buildLandscapeLayout(context, theme, state, config);
        }

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
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: config.maxWidth),
              child: _buildLoginFormContent(context, theme, state, config),
            ),
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
          // Left side - Branding with gradient
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF59D), // Light yellow
                    Color(0xFFFDD835), // Bright yellow
                    Color(0xFFFDB913), // Golden yellow
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: config.logoSize * 1.8,
                        height: config.logoSize * 1.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              'lib/images/logo.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: config.verticalSpacing * 1.5),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Column(
                          children: [
                            Text(
                              '¡Descubre!',
                              style: const TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1.2,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    offset: Offset(0, 3),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Increíbles startups\ngastronómicas',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withValues(alpha: 0.95),
                                letterSpacing: 0.6,
                                height: 1.4,
                                shadows: const [
                                  Shadow(
                                    color: Colors.black45,
                                    offset: Offset(0, 2),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right side - Form
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(config.horizontalPadding),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _buildLoginFormContent(context, theme, state, config, isCompact: true),
              ),
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
            
            // Logo with shadow
            Center(
              child: Container(
                width: config.logoSize * 1.4,
                height: config.logoSize * 0.8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Image.asset(
                      'lib/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: config.verticalSpacing * 2.5),
          ] else
            SizedBox(height: config.verticalSpacing),
          
          // Welcome text (splash page style)
          Text(
            '¡Bienvenido!',
            style: TextStyle(
              fontSize: _getAdaptiveFontSize(46, config),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 1.5,
              height: 1.0,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  offset: Offset(0, 4),
                  blurRadius: 20,
                ),
                Shadow(
                  color: Colors.black45,
                  offset: Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          
          if (!isCompact) ...[
            SizedBox(height: config.verticalSpacing * 0.75),
            
            Text(
              'Descubre las mejores startups gastronómicas\ny conecta con innovación culinaria',
              style: TextStyle(
                fontSize: _getAdaptiveFontSize(15, config),
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.95),
                letterSpacing: 0.8,
                height: 1.5,
                shadows: const [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(0, 2),
                    blurRadius: 8,
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          
          SizedBox(height: config.verticalSpacing * 2.5),
          
          // Username Field with icon and styling
          CustomTextField(
            controller: _usernameController,
            hintText: 'Introduce tu nombre de usuario',
            labelText: 'Usuario',
            keyboardType: TextInputType.text,
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.person_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            validator: Validators.username,
          ),
          
          SizedBox(height: config.verticalSpacing * 1.2),
          
          // Password Field
          CustomTextField(
            controller: _passwordController,
            hintText: 'Introduce tu contraseña',
            labelText: 'Contraseña',
            obscureText: true,
            prefixIcon: Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock_outline,
                color: theme.colorScheme.primary,
                size: 20,
              ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              child: Text(
                '¿Olvidaste tu contraseña?',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w700,
                  fontSize: _getAdaptiveFontSize(14, config),
                  shadows: const [
                    Shadow(
                      color: Colors.black45,
                      offset: Offset(0, 1),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          SizedBox(height: config.verticalSpacing * 2),
          
          // Login Button (splash page style)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (state is AuthLoading && 
                      (_usernameController.text.isNotEmpty || 
                        _passwordController.text.isNotEmpty))
                  ? null
                  : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFFDB913),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 10,
                shadowColor: Colors.black.withValues(alpha: 0.4),
              ),
              child: (state is AuthLoading && 
                    (_usernameController.text.isNotEmpty || 
                      _passwordController.text.isNotEmpty))
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFDB913)),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Iniciar sesión',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 24),
                      ],
                    ),
            ),
          ),
          
          SizedBox(height: config.verticalSpacing * 2),
          
          // Divider with text
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: config.horizontalPadding * 0.5),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'O',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: config.verticalSpacing * 2),
          
          // Register Button
          OutlinedButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/register');
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.person_add_outlined, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Crear cuenta nueva',
                  style: TextStyle(
                    fontSize: _getAdaptiveFontSize(17, config),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: config.verticalSpacing * 1.5),

          // Guest login button
          OutlinedButton(
            onPressed: () {
              context.read<AuthBloc>().add(GuestLoginRequested());
            },
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.4), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.visibility_outlined, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Explorar como invitado',
                  style: TextStyle(
                    fontSize: _getAdaptiveFontSize(17, config),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: config.verticalSpacing),
        ],
      ),
    );
  }

  double _getAdaptiveFontSize(double baseSize, ResponsiveConfig config) {
    if (config.logoSize <= 120) {
      return baseSize * 0.9;
    } else if (config.logoSize <= 140) {
      return baseSize;
    } else {
      return baseSize * 1.1;
    }
  }
}

// Helper classes
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