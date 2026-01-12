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
              color: theme.colorScheme.surface,
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
            height: config.logoSize,
            width: config.logoSize,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.restaurant_menu,
              size: config.logoSize * 0.5,
              color: Colors.white,
            ),
          ),
        ),
        
        SizedBox(height: 32 * config.spacingMultiplier),
        
        // Title
        Text(
          'Emprendimientos\nGastronómicos',
          style: theme.textTheme.displayMedium?.copyWith(
            fontSize: config.titleSize,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        
        if (config.showSubtitle && !isCompact) ...[
          SizedBox(height: 16 * config.spacingMultiplier),
          
          // Subtitle
          Text(
            'Descubra increíbles startups gastronómicos\ne innovaciones culinarias',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
              fontSize: 16,
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(config.borderRadius),
          topRight: Radius.circular(config.borderRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: config.horizontalPadding,
          vertical: config.verticalPadding,
        ),
        child: _buildActionButtons(context, theme, config),
      ),
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
        
        // Sign In Button
        CustomButton(
          text: 'Iniciar sesión',
          onPressed: () {
            Navigator.of(context).pushNamed('/login');
          },
          width: double.infinity,
        ),
        
        SizedBox(height: 16 * config.spacingMultiplier),
        
        // Create Account Button
        CustomButton(
          text: 'Crear cuenta',
          onPressed: () {
            Navigator.of(context).pushNamed('/register');
          },
          isOutlined: true,
          width: double.infinity,
        ),
        
        SizedBox(height: 16 * config.spacingMultiplier),

        CustomButton(
          text: 'Continuar como invitado',
          onPressed: () {
            context.read<AuthBloc>().add(GuestLoginRequested());
          },
          isOutlined: true,
          icon: const Icon(Icons.visibility),
          width: double.infinity,
        ),

        SizedBox(height: 24 * config.spacingMultiplier),
        
        
        // Terms and Privacy
        Text(
          'Al continuar, aceptas nuestros Términos de servicio\ny Política de privacidad.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.4,
            fontSize: isCompact ? 11 : 12,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        
        if (!isCompact) SizedBox(height: 8 * config.spacingMultiplier),
      ],
    );
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