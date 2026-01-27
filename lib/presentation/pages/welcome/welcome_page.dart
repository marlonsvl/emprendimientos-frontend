import 'package:emprendegastroloja/presentation/bloc/auth/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/common/custom_button.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({Key? key}) : super(key: key);

  // Responsive breakpoints following Material Design guidelines
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated || state is AuthGuest) {
          Navigator.of(context).pushReplacementNamed('/greeting');
        }
      },
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = MediaQuery.sizeOf(context);
            final deviceType = _getDeviceType(size.width);
            final config = _getResponsiveConfig(deviceType, size);
            final isLandscape = size.width > size.height;

            return Container(
              width: double.infinity,
              height: double.infinity,
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
              child: SafeArea(
                child: _buildAdaptiveLayout(
                  context,
                  theme,
                  config,
                  isLandscape,
                  size,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  DeviceType _getDeviceType(double width) {
    if (width < mobileBreakpoint) return DeviceType.mobile;
    if (width < tabletBreakpoint) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  ResponsiveConfig _getResponsiveConfig(DeviceType deviceType, Size size) {
    final isCompactHeight = size.height < 600;
    final isSmallHeight = size.height < 700 && !isCompactHeight;

    switch (deviceType) {
      case DeviceType.mobile:
        return ResponsiveConfig(
          horizontalPadding: 24.0,
          verticalPadding: isCompactHeight ? 16.0 : (isSmallHeight ? 24.0 : 32.0),
          logoSize: isCompactHeight ? 80.0 : (isSmallHeight ? 100.0 : 120.0),
          titleSize: isCompactHeight ? 32.0 : (isSmallHeight ? 36.0 : 40.0),
          spacingMultiplier: isCompactHeight ? 0.6 : (isSmallHeight ? 0.8 : 1.0),
          maxContentWidth: double.infinity,
          borderRadius: 24.0,
          showSubtitle: !isCompactHeight,
        );
      case DeviceType.tablet:
        return ResponsiveConfig(
          horizontalPadding: 48.0,
          verticalPadding: isCompactHeight ? 24.0 : 40.0,
          logoSize: isCompactHeight ? 100.0 : 140.0,
          titleSize: 44.0,
          spacingMultiplier: isCompactHeight ? 0.7 : 1.0,
          maxContentWidth: 600.0,
          borderRadius: 32.0,
          showSubtitle: true,
        );
      case DeviceType.desktop:
        return ResponsiveConfig(
          horizontalPadding: 64.0,
          verticalPadding: 48.0,
          logoSize: 160.0,
          titleSize: 48.0,
          spacingMultiplier: 1.2,
          maxContentWidth: 500.0,
          borderRadius: 32.0,
          showSubtitle: true,
        );
    }
  }

  Widget _buildAdaptiveLayout(
    BuildContext context,
    ThemeData theme,
    ResponsiveConfig config,
    bool isLandscape,
    Size size,
  ) {
    // For landscape on mobile/tablet, use side-by-side layout
    if (isLandscape && size.width < tabletBreakpoint) {
      return _buildLandscapeLayout(context, theme, config);
    }

    // Standard portrait or desktop layout
    return _buildPortraitLayout(context, theme, config, size);
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    ThemeData theme,
    ResponsiveConfig config,
    Size size,
  ) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: size.height - MediaQuery.paddingOf(context).vertical,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Section - Logo and Text
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: config.maxContentWidth,
                ),
                child: _buildTopSection(context, theme, config),
              ),
            ),
            
            // Bottom Section - Buttons
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: config.maxContentWidth,
              ),
              child: _buildBottomSection(context, theme, config),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    ThemeData theme,
    ResponsiveConfig config,
  ) {
    return Row(
      children: [
        // Left side - Branding
        Expanded(
          flex: 3,
          child: Center(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(config.horizontalPadding),
              child: _buildBrandingContent(context, theme, config, isCompact: true),
            ),
          ),
        ),
        
        // Right side - Action buttons
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFFFDB913).withValues(alpha: 0.3),
                  const Color(0xFFF39C12).withValues(alpha: 0.3),
                ],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(config.borderRadius),
                bottomLeft: Radius.circular(config.borderRadius),
              ),
            ),
            child: Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: EdgeInsets.all(config.horizontalPadding),
                child: _buildActionButtons(context, theme, config, isCompact: true),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopSection(
    BuildContext context,
    ThemeData theme,
    ResponsiveConfig config,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: config.horizontalPadding,
        vertical: config.verticalPadding,
      ),
      child: _buildBrandingContent(context, theme, config),
    );
  }

  Widget _buildBrandingContent(
    BuildContext context,
    ThemeData theme,
    ResponsiveConfig config, {
    bool isCompact = false,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: isCompact ? 0 : 20 * config.spacingMultiplier),
        
        // Logo
        Hero(
          tag: 'app_logo',
          child: Container(
            width: config.logoSize * 1.4,
            height: config.logoSize * 0.8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: const Color(0xFFFDB913).withValues(alpha: 0.5),
                  blurRadius: 40,
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
        
        SizedBox(height: 32 * config.spacingMultiplier),
        
        // Title
        // Title (splash page style)
        Text(
          'EmprendeGastroLoja',
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
        
        if (config.showSubtitle && !isCompact) ...[
          SizedBox(height: 16 * config.spacingMultiplier),
          
          // Subtitle
          Text(
            'Descubre increíbles emprendimientos gastronómicos\ne innovaciones culinarias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.5,
              height: 1.5,
              shadows: const [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 1),
                  blurRadius: 4,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ],
        
        SizedBox(height: isCompact ? 0 : 40 * config.spacingMultiplier),
      ],
    );
  }

  Widget _buildBottomSection(
      BuildContext context,
      ThemeData theme,
      ResponsiveConfig config,
    ) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: config.horizontalPadding,
          vertical: config.verticalPadding,
        ),
        child: _buildActionButtons(context, theme, config),
      );
  }

  Widget _buildActionButtons(
  BuildContext context,
  ThemeData theme,
  ResponsiveConfig config, {
  bool isCompact = false,
}) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      if (!isCompact) SizedBox(height: 8 * config.spacingMultiplier),
      
      // Sign In Button (splash page style)
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/login');
          },
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Iniciar sesión',
                style: TextStyle(
                  fontSize: isCompact ? 17 : 19,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.arrow_forward_rounded, size: 24),
            ],
          ),
        ),
      ),
      
      SizedBox(height: 16 * config.spacingMultiplier),
      
      // Create Account Button (splash page style)
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
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
                'Crear cuenta',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
      
      SizedBox(height: 16 * config.spacingMultiplier),

      // Guest Button (splash page style)
      SizedBox(
        width: double.infinity,
        child: OutlinedButton(
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
                'Continuar como invitado',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),

      SizedBox(height: 24 * config.spacingMultiplier),
      
      // Terms and Privacy (splash page style)
      Text(
        'Al continuar, aceptas nuestros Términos de servicio\ny Política de privacidad.',
        style: TextStyle(
          fontSize: isCompact ? 11 : 12,
          fontWeight: FontWeight.w500,
          color: Colors.white.withValues(alpha: 0.7),
          height: 1.4,
          letterSpacing: 0.3,
          shadows: const [
            Shadow(
              color: Colors.black26,
              offset: Offset(0, 1),
              blurRadius: 2,
            ),
          ],
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
      ),
      
      if (!isCompact) SizedBox(height: 8 * config.spacingMultiplier),
    ],
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

// Helper classes for responsive configuration
enum DeviceType { mobile, tablet, desktop }

class ResponsiveConfig {
  final double horizontalPadding;
  final double verticalPadding;
  final double logoSize;
  final double titleSize;
  final double spacingMultiplier;
  final double maxContentWidth;
  final double borderRadius;
  final bool showSubtitle;

  ResponsiveConfig({
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.logoSize,
    required this.titleSize,
    required this.spacingMultiplier,
    required this.maxContentWidth,
    required this.borderRadius,
    required this.showSubtitle,
  });
}