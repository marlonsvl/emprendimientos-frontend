import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:math' as math;
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _imageRotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _logoScaleAnimation;
  
  int _currentImageIndex = 0;
  
  // Curated selection of startup images
  final List<String> _startupImages = [
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1768359127/UnitedFalafel_Vilcabamba_ext_web_ftnujh.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1768359390/Vilkalitas_Vilcabamba_extfront_web__eez84d.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1766455965/CafeyComidadeHogar_Vilcabamba_Fachada_web__j7awu1.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1768357853/LaCreperiadeYannick_Vilcabamba_fachadahrzt_web__pnoq7w.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1766456477/Dumplings_Noodles_Vilcabamba_Fachada_web_tnkzku.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1768442774/BambuRestaurante_Vilcabamba_ext_web__k82l3w.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1767124216/Olivo_Yangana_fachada_web__ytjsxg.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1764381322/TruchasCurishiroYangana_Fachada_web1_btrywj.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1766457048/Molino_Tropical_Vilcabamba_Identidad_web__cx5vf4.jpg',
    'https://res.cloudinary.com/djl0e1p6e/image/upload/v1762997368/PiedraDuraVilcabamba_Fachada_web_yabily.jpg'
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startImageRotation();
    //_navigateToNext();
  }

  void _setupAnimations() {
    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _imageRotationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.7, curve: Curves.elasticOut),
      ),
    );

    _mainAnimationController.forward();
  }

  void _startImageRotation() {
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _currentImageIndex = (_currentImageIndex + 1) % _startupImages.length;
        });
        _imageRotationController.forward(from: 0.0);
        _startImageRotation();
      }
    });
  }

  /*void _navigateToNext() {
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    });

  }*/
  void _handleContinue() {
    Navigator.of(context).pushReplacementNamed('/welcome');
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _imageRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          Navigator.of(context).pushReplacementNamed('/main');
        }
      },
      child: Scaffold(
        body: Container(
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
          child: Stack(
            children: [
              // Background Image (fixed size, centered)
              _buildBackgroundImage(size),
              

              // Main Content
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    
                    // Logo and Branding
                    _buildBranding(),
                    
                    const Spacer(),
                    
                    // Continue Button
                    _buildContinueButton(size),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),

              // Decorative floating elements
              _buildFloatingElements(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(Size size) {
  // Calculate fixed dimensions for consistent image display
  final imageHeight = size.height * 0.50; // 50% of screen height
  final imageWidth = size.width; // Full width
  
  return Positioned(
    top: size.height * 0.30, // Position from top
    left: 0,
    right: 0,
    child: FadeTransition(
      opacity: _fadeAnimation,
      child: Center(
        child: Container(
          width: imageWidth,
          height: imageHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(0), // No border radius for full-width
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 2500),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: Image.network(
                _startupImages[_currentImageIndex],
                key: ValueKey<int>(_currentImageIndex),
                width: imageWidth,
                height: imageHeight,
                fit: BoxFit.cover, // Ensures consistent sizing
                opacity: const AlwaysStoppedAnimation(1.0),
                errorBuilder: (context, error, stackTrace) => SizedBox(
                  width: imageWidth,
                  height: imageHeight,
                  //color: Colors.black.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.restaurant,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

  

  Widget _buildBranding() {
  return 
  
  FadeTransition(
    opacity: _fadeAnimation,
    child: ScaleTransition(
      scale: _logoScaleAnimation,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        
        child: Column(
          children: [
            // Logo with animated pulse effect
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
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
            const SizedBox(height: 24),

            // App Name
            const Text(
              'GastroStart',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1.5,
                height: 1.0,
                shadows: [
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
            const SizedBox(height: 5),

            // Tagline with icon
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Emprendimientos Gastronómicos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.95),
                    letterSpacing: 0.8,
                    shadows: const [
                      Shadow(
                        color: Colors.black54,
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildContinueButton(Size size) {
  return FadeTransition(
    opacity: _fadeAnimation,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // Optional: Rotating business name indicator
          Text(
            'Descubre historias de éxito',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.9),
              letterSpacing: 0.5,
              shadows: const [
                Shadow(
                  color: Colors.black54,
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // Continuar Button
          SizedBox(
            width: size.width * 0.75,
            child: ElevatedButton(
              onPressed: _handleContinue,
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
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Continuar',
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
        ],
      ),
    ),
  );
}

 

  Widget _buildFloatingElements() {
    return Stack(
      children: [
        Positioned(
          top: 60,
          right: 25,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 140,
          left: 35,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              width: 35,
              height: 35,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}