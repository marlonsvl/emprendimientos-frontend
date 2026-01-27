import 'package:emprendegastroloja/presentation/pages/auth/login_page.dart';
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
        );

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
      return '¡Buenos días!';
    } else if (hour < 17) {
      return '¡Buenas tardes!';
    } else {
      return '¡Buenas noches!';
    }
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
              Color(0xFFFFF59D), // Light yellow
              Color(0xFFFDD835), // Bright yellow
              Color(0xFFFDB913), // Golden yellow
              Color(0xFFF39C12), // Deep gold
            ],
            stops: [0.0, 0.3, 0.6, 1.0],
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
                    minHeight:
                        size.height -
                        MediaQuery.of(context).padding.top -
                        MediaQuery.of(context).padding.bottom -
                        (isSmallScreen ? 32 : 48),
                  ),
                  child: Column(
                    children: [
                      // Top spacing
                      SizedBox(height: isSmallScreen ? 20 : 40),

                      // Welcome Icon with Animation
                      // Logo with Animation
                      TweenAnimationBuilder<double>(
                        duration: const Duration(milliseconds: 2000),
                        tween: Tween(begin: 0.0, end: 1.0),
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Container(
                              width: isSmallScreen ? 140 : 196,
                              height: isSmallScreen ? 80 : 112,
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
                                    color: const Color(
                                      0xFFFDB913,
                                    ).withValues(alpha: 0.5),
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
                          );
                        },
                      ),

                      SizedBox(height: isSmallScreen ? 24 : 40),

                      // Greeting Message
                      // Greeting Message (splash page style)
                      Text(
                        _getGreetingMessage(),
                        style: TextStyle(
                          fontSize: isSmallScreen ? 22 : 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 1.2,
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

                      SizedBox(height: isSmallScreen ? 12 : 16),

                      // Welcome Message
                      // Welcome Message (splash page style)
                      Text(
                        'Bienvenido a',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 18 : 22,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.5,
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

                      SizedBox(height: isSmallScreen ? 4 : 8),

                      // App Name with Gradient
                      // App Name (splash page style)
                      Text(
                        'EmprendeGastroLoja',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 26 : 36,
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

                      SizedBox(height: isSmallScreen ? 16 : 24),

                      // Subtitle
                      // Subtitle (splash page style)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          '¡Ya está todo listo! Exploremos los emprendimientos culinarios más innovadores y descubramos juntos experiencias gastronómicas increíbles.',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                            letterSpacing: 0.5,
                            height: 1.6,
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
            'Los mejores emprendimientos',
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
            'Los mejores emprendimientos',
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
          backgroundColor: Colors.white,
          textColor: Theme.of(context).colorScheme.primary,
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
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 1000 + (title.hashCode % 500)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: Container(
              width: isSmallScreen ? double.infinity : 110,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: isSmallScreen ? 50 : 60,
                    width: isSmallScreen ? 50 : 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFDB913).withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFFFDB913),
                      size: isSmallScreen ? 26 : 30,
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 8 : 12),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 15 : 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: const [
                        Shadow(
                          color: Colors.black45,
                          offset: Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 12 : 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.85),
                      letterSpacing: 0.3,
                      height: 1.3,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 4,
                        ),
                      ],
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
