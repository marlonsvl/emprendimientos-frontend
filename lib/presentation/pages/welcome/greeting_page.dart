import 'package:flutter/material.dart';
import '../../widgets/common/custom_button.dart';

class GreetingPage extends StatefulWidget {
  const GreetingPage({Key? key}) : super(key: key);

  @override
  State<GreetingPage> createState() => _GreetingPageState();
}

class _GreetingPageState extends State<GreetingPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Start animations
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Buenos días!';
    } else if (hour < 17) {
      return 'Buenas tardes!';
    } else {
      return 'Buenas noches!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;
    
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.secondary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom - (isSmallScreen ? 32 : 48),
                  ),
                  child: Column(
                    children: [
                      // Top spacing
                      SizedBox(height: isSmallScreen ? 20 : 40),
                      
                      // Welcome Icon with Animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 2000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              height: isSmallScreen ? 100 : 140,
                              width: isSmallScreen ? 100 : 140,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    theme.colorScheme.primary,
                                    theme.colorScheme.secondary,
                                  ],
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.celebration,
                                size: isSmallScreen ? 50 : 70,
                                color: Colors.white,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      SizedBox(height: isSmallScreen ? 24 : 40),
                      
                      // Greeting Message
                      Text(
                        _getGreetingMessage(),
                        style: (isSmallScreen 
                          ? theme.textTheme.headlineMedium 
                          : theme.textTheme.displaySmall)?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 12 : 16),
                      
                      // Welcome Message
                      Text(
                        'Bienvenido a',
                        style: (isSmallScreen 
                          ? theme.textTheme.titleLarge 
                          : theme.textTheme.headlineSmall)?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w300,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      SizedBox(height: isSmallScreen ? 4 : 8),
                      
                      // App Name with Gradient
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            theme.colorScheme.primary,
                            theme.colorScheme.secondary,
                          ],
                        ).createShader(bounds),
                        child: Text(
                          'Emprendimientos Gastronómicos',
                          style: (isSmallScreen 
                            ? theme.textTheme.headlineSmall 
                            : theme.textTheme.headlineMedium)?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      
                      // Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '¡Ya está todo listo! Exploremos las startups culinarias más innovadoras y descubramos juntos experiencias gastronómicas increíbles.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.6,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      
                      // Features Preview
                      _buildFeaturesSection(context, isSmallScreen),
                      
                      SizedBox(height: isSmallScreen ? 32 : 48),
                      
                      // Action Buttons
                      _buildActionButtons(context, isSmallScreen),
                      
                      // Bottom spacing
                      SizedBox(height: isSmallScreen ? 20 : 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context, bool isSmallScreen) {
    if (isSmallScreen) {
      // Stack features vertically on small screens
      return Column(
        children: [
          _buildFeatureItem(
            context,
            Icons.restaurant,
            'Descubre',
            'Comida increíble',
            isSmallScreen,
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            context,
            Icons.trending_up,
            'Explora',
            'Las mejores startups',
            isSmallScreen,
          ),
          const SizedBox(height: 24),
          _buildFeatureItem(
            context,
            Icons.favorite,
            'Conectar',
            'Con los fundadores',
            isSmallScreen,
          ),
        ],
      );
    } else {
      // Keep horizontal layout for larger screens
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildFeatureItem(
            context,
            Icons.restaurant,
            'Descubre',
            'Comida increíble',
            isSmallScreen,
          ),
          _buildFeatureItem(
            context,
            Icons.trending_up,
            'Explora',
            'Las mejores startups',
            isSmallScreen,
          ),
          _buildFeatureItem(
            context,
            Icons.favorite,
            'Conectar',
            'Con los fundadores',
            isSmallScreen,
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Continue Button
        CustomButton(
          text: '¡Comencemos!',
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/emprendimientos');
          },
          width: double.infinity,
          icon: const Icon(Icons.arrow_forward),
        ),
        
        const SizedBox(height: 16),
        
        // Skip Button
        /*TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacementNamed('/main');
          },
          child: Text(
            'Skip for now',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ),*/
      ],
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    bool isSmallScreen,
  ) {
    final theme = Theme.of(context);
    
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1000 + (title.hashCode % 500)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: isSmallScreen ? double.infinity : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: isSmallScreen ? 50 : 60,
                    width: isSmallScreen ? 50 : 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 6 : 8),
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}