import 'dart:math';

import 'package:emprendegastroloja/core/constants/api_constants.dart';
import 'package:emprendegastroloja/data/datasources/local/auth_local_datasource.dart';
import 'package:emprendegastroloja/data/datasources/local/emprendimientos_local_datasource.dart';
import 'package:emprendegastroloja/data/datasources/remote/emprendimientos_remote_datasource.dart';
import 'package:emprendegastroloja/domain/repositories/auth_repository.dart';
import 'package:emprendegastroloja/domain/repositories/comment_repository.dart';
import 'package:emprendegastroloja/domain/repositories/emprendimientos_repository.dart';
import 'package:emprendegastroloja/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:emprendegastroloja/presentation/bloc/auth/auth_bloc.dart';
import 'package:emprendegastroloja/presentation/bloc/auth/auth_state.dart';
import 'package:emprendegastroloja/presentation/pages/main/widgets/video_player_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/emprendimiento_model.dart';
import '../../../data/models/comment_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

// Add after imports, before the class definition
class BrandColors {
  static const lightYellow = Color(0xFFFFF59D);
  static const brightYellow = Color(0xFFFDD835);
  static const goldenYellow = Color(0xFFFDB913);
  static const deepGold = Color(0xFFF39C12);
  
  static const gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightYellow, brightYellow, goldenYellow, deepGold],
    stops: [0.0, 0.3, 0.6, 1.0],
  );
}


class EmprendimientoDetailPage extends StatefulWidget {
  final Emprendimiento emprendimiento;
  final AuthRepository authRepository;

  const EmprendimientoDetailPage({
    Key? key,
    required this.emprendimiento,
    required this.authRepository,
  }) : super(key: key);

  @override
  State<EmprendimientoDetailPage> createState() =>
      _EmprendimientoDetailPageState();
}

class _EmprendimientoDetailPageState extends State<EmprendimientoDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late CarouselSliderController _carouselController;
  CachedVideoPlayerPlus? _player;

  int _currentImageIndex = 0;

  // Add these new variables for the map:
  MapController? _mapController;
  String _currentMapStyle = 'osm'; // 'osm', 'satellite', 'topo'

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  late final List<String> _allImages;
  String? _authToken;
  

  CommentRepository? _commentRepository;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  final TextEditingController _commentController = TextEditingController();

  bool get _isGuestUser {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthGuest;
  }

  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isFavorited = false;
  double _userRating = 0.0;
  late Emprendimiento _currentEmprendimiento;
  bool _showFullDescription = false;
  String? _errorMessage;
  int? _currentUserId;
  EmprendimientosRepository? _repository;

  final ValueNotifier<bool> _isLikedNotifier = ValueNotifier(false);
  final ValueNotifier<int> _likesCountNotifier = ValueNotifier(0);
  final ValueNotifier<bool> _isFavoritedNotifier = ValueNotifier(false);

  Future<void> _initializeRepository() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final tokenResult = await widget.authRepository.getAuthToken();
    
    _authToken = tokenResult.fold(
      (failure) {
        debugPrint('Auth token error: ${failure.toString()}');
        return null;
      },
      (token) => token,
    );

    _repository = EmprendimientosRepository(
      remoteDataSource: EmprendimientosRemoteDataSource(
        baseUrl: ApiConstants.baseUrl,
      ),
      localDataSource: EmprendimientosLocalDataSource(
        sharedPreferences: prefs,
      ),
    );
  } catch (e) {
    debugPrint('Repository initialization error: $e');
    rethrow;
  }
}

  @override
  void initState() {
    super.initState();
    _currentEmprendimiento = widget.emprendimiento;
    _allImages = widget.emprendimiento.galleryUrls
      .map((url) => url.replaceAll(RegExp(r'[{}]'), '').trim())
      .where((url) => url.isNotEmpty)
      .toList();
    _setupControllers();
    _initializeVideoPlayer();
    _initializeRepository();
    _initializeData();

    _carouselController = CarouselSliderController();
    _mapController = MapController();

    _initializeAuth();

    _getCurrentUserUseCase = GetCurrentUserUseCase(widget.authRepository);
    _getCurrentUserUseCase.repository.getCurrentUser().then((result) {
      result.fold((failure) {}, (user) {
        setState(() {
          _currentUserId = user?.id;
        });
      });
    });

    _initializeCommentRepository().then((repo) {
      _commentRepository = repo;
      _loadComments();
    });

    _isLikedNotifier.value = widget.emprendimiento.isLikedByUser;
    _likesCountNotifier.value = widget.emprendimiento.likesCount;
    _isFavoritedNotifier.value = widget.emprendimiento.isFavoritedByUser;

  }

  Future<void> _initializeAuth() async {
  if (_isGuestUser) {
    _authToken = null;
    return;
  }
  
  final tokenResult = await widget.authRepository.getAuthToken();
  _authToken = tokenResult.fold(
    (failure) {
      debugPrint('Auth token error: ${failure.toString()}');
      return null;
    },
    (token) {
      debugPrint('Token loaded successfully');
      return token;
    },
  );
}

Future<bool> _ensureValidToken() async {
  if (_isGuestUser) return false;
  
  if (_authToken == null || _authToken!.isEmpty) {
    final tokenResult = await widget.authRepository.getAuthToken();
    _authToken = tokenResult.fold(
      (failure) {
        debugPrint('Token refresh failed: ${failure.toString()}');
        return null;
      },
      (token) {
        debugPrint('Token refreshed successfully');
        return token;
      },
    );
  }
  
  return _authToken != null && _authToken!.isNotEmpty;
}

  // Better initialization with proper error handling
void _initializeVideoPlayer() {
  if (!widget.emprendimiento.hasVideo) return;
  
  _player = CachedVideoPlayerPlus.networkUrl(
    Uri.parse(
      //widget.emprendimiento.videoUrl!.replaceFirst('/upload/', '/upload/f_mp4/'),
      "https://res.cloudinary.com/djl0e1p6e/video/upload/v1762564764/samples/dance-2.mp4".replaceFirst('/upload/', '/upload/f_mp4/'),
    ),
    invalidateCacheIfOlderThan: const Duration(hours: 1),
  );

  _player?.initialize().then((_) {
    if (!mounted) return;
    _player?.controller.addListener(_controllerListener);
    if (mounted) {
      setState(() {});
      _player?.controller.play();
    }
  }).catchError((error) {
    if (mounted) {
      setState(() {
        _errorMessage = 'Error al cargar video: ${error.toString()}';
      });
    }
  });
}

  void _controllerListener() {
  if (_player!.controller.value.isInitialized) {
    setState(() {});
  }
}


  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<CommentRepository> _initializeCommentRepository() async {
    final prefs = await SharedPreferences.getInstance();
    final authLocalDataSource = AuthLocalDataSourceImpl(
      sharedPreferences: prefs,
    );

    return CommentRepository(
      baseUrl: ApiConstants.baseUrl,
      localDataSource: authLocalDataSource,
    );
  }

  Future<void> _loadComments() async {
    // Add null check
    if (_commentRepository == null) return;

    setState(() {
      _isLoadingComments = true;
      _errorMessage = null;
    });

    try {
      final comments = await _commentRepository!.getComments(
        widget.emprendimiento.id,
      );

      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoadingComments = false;
      });
    } catch (e) {
      if (!mounted) return;
      final errorMsg = 'Error al cargar comentarios: ${e.toString()}';
      setState(() {
        _errorMessage = errorMsg;
        _isLoadingComments = false;
      });
      _showErrorSnackbar(errorMsg);
    }
  }

  void _setupControllers() {
    _tabController = TabController(length: 4, vsync: this);

    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
    // Listen to tab changes
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {}); // Rebuild to show/hide appropriate FABs
      }
    });
  }

  void _initializeData() {
    _isLiked = widget.emprendimiento.isLikedByUser;
    _likesCount = widget.emprendimiento.likesCount;
    _isFavorited = widget.emprendimiento.isFavoritedByUser;
  }

  @override
  void dispose() {
    _player?.controller.removeListener(_controllerListener);
    _player?.controller.pause();
    _player?.controller.dispose();

    _mapController?.dispose();
    _tabController.dispose();
    _fabAnimationController.dispose();
    _commentController.dispose();

    _isLikedNotifier.dispose();
    _likesCountNotifier.dispose();
    _isFavoritedNotifier.dispose();
    super.dispose();
  }

  

  @override
  Widget build(BuildContext context) {
    return 
    
    Scaffold(
      backgroundColor: Colors.grey[50], 
      body: NotificationListener<ScrollNotification>(
        child: DefaultTabController(
          length: 4,
          child: NestedScrollView(
            // NO controller here
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                _buildSliverAppBar(),
                _buildInfoHeader(),
                SliverOverlapAbsorber(
                  handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: _buildTabBar(),
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildDetailsTabSafe(),
                _buildMenuTab(),
                _buildLocationTab(),
                _buildReviewsTabSafe(),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildDetailsTabSafe() {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('details_tab'),
          primary: false,
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Video section
                  if (widget.emprendimiento.hasVideo) _buildVideoSection(),

                  // Contact info section
                  _buildSection(
                    'Información de Contacto',
                    Icons.contact_phone,
                    [
                      _buildDetailRow(
                        'Teléfono',
                        widget.emprendimiento.telefono,
                      ),
                      _buildDetailRow('Email', widget.emprendimiento.email),
                      _buildDetailRow(
                        'Horario de atención',
                        widget.emprendimiento.horario,
                      ),
                    ],
                  ),

                  // Basic info section
                  _buildSection('Información General', Icons.info, [
                    _buildDetailRow(
                      'Tipo de turismo',
                      widget.emprendimiento.tipoTurismo,
                    ),
                    _buildDetailRow(
                      'Tipo de establecimiento',
                      widget.emprendimiento.tipo,
                    ),
                    _buildDetailRow(
                      'Años de experiencia',
                      '${widget.emprendimiento.experiencia} años',
                    ),
                    _buildDetailRow(
                      'Estado del local',
                      widget.emprendimiento.estadoLocal,
                    ),
                    if (widget.emprendimiento.mesas > 0)
                      _buildDetailRow(
                        'Número de mesas',
                        '${widget.emprendimiento.mesas}',
                      ),
                    _buildDetailRow(
                      'Capacidad total',
                      '${widget.emprendimiento.plazas} personas',
                    ),
                    _buildDetailRow(
                      'Baños disponibles',
                      widget.emprendimiento.banio,
                    ),
                    _buildDetailRow(
                      'Tiempo trabajando',
                      '${widget.emprendimiento.tiempoTrabajando} años',
                    ),
                  ]),

                  // Services section
                  // ocultar servicios y produccion
                  /*
                if (widget.emprendimiento.serviciosProduccion.isNotEmpty)
                  _buildSection('Servicios y Producción', Icons.build, [
                    _buildDetailText(widget.emprendimiento.serviciosProduccion),
                  ]),

                // Equipment section
                if (widget.emprendimiento.equipos.isNotEmpty)
                  _buildSection('Equipos y Herramientas', Icons.kitchen, [
                    _buildDetailText(widget.emprendimiento.equipos),
                  ]),
                  */

                  // Continue with all other sections...
                ]),
              ),
            ),
          ],
        );
      },
    );
  }


  Widget _buildReviewsTabSafe() {
    return Builder(
    builder: (context) {
      return CustomScrollView(
        key: const PageStorageKey<String>('reviews_tab'),
        primary: false,
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rating display
                  
                  /*Row(
                    children: [
                      Text(
                        widget.emprendimiento.averageRating.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(5, (index) {
                                return Icon(
                                  index < widget.emprendimiento.averageRating.floor()
                                      ? Icons.star
                                      : index < widget.emprendimiento.averageRating
                                          ? Icons.star_half
                                          : Icons.star_border,
                                  color: Colors.amber,
                                  size: 18,
                                );
                              }),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.emprendimiento.ratingCount} reseñas',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),*/
                  
                  const SizedBox(height: 12),
                  
                  // Write button - full width
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Escribir reseña'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Rest of the content (loading, empty, comments)
          if (_isLoadingComments)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_comments.isEmpty)
            SliverFillRemaining(
              child: SingleChildScrollView( 
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay comentarios aún',
                          style: Theme.of(context).textTheme.titleLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sé el primero en dejar una reseña',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showRatingDialog,
                          icon: const Icon(Icons.rate_review),
                          label: const Text('Escribir primera reseña'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildCommentCard(_comments[index]),
                  childCount: _comments.length,
                ),
              ),
            ),
        ],
      );
    },
  );
  }


  

  

 Widget _buildSliverAppBar() {
    // Combine main photo with gallery images
    //final List<String> allImages = widget.emprendimiento.galleryUrls.
    //                                toSet().toList();
    //allImages[0] = allImages[0].replaceFirst("{", "");
    //allImages[allImages.length-1] = allImages[allImages.length-1].replaceFirst("}", "");
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () {
          // Return updated data when back button is pressed
          Navigator.of(context).pop({
            'emprendimiento_id': widget.emprendimiento.id,
            'is_favorited': _isFavoritedNotifier.value,
            'is_liked': _isLikedNotifier.value,
            'likes_count': _likesCountNotifier.value,
          });
        },
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Carousel with all images
            CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: 300,
                viewportFraction: 1.0,
                enableInfiniteScroll: false,
                autoPlay: false,
                disableCenter: true,  
                enlargeCenterPage: false, 
                clipBehavior: Clip.none, 
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: _allImages.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 64,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Imagen no disponible',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: Colors.grey[300],
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }).toList(),
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Image counter and navigation arrows
            if (_allImages.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Image counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_currentImageIndex + 1}/${_allImages.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Fullscreen button
                    GestureDetector(
                      onTap: () => _showFullscreenCarousel(_allImages),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fullscreen,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Navigation arrows for manual control
            if (_allImages.isNotEmpty) ...[
              // Left arrow
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _carouselController.previousPage(),
                  ),
                ),
              ),
              // Right arrow
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () => _carouselController.nextPage(),
                  ),
                ),
              ),
            ],

            // Carousel navigation dots
            if (_allImages.isNotEmpty)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _allImages.asMap().entries.map((entry) {
                    return GestureDetector(
                      onTap: () => _carouselController.animateToPage(entry.key),
                      child: Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentImageIndex == entry.key
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
      actions: [
        ValueListenableBuilder<bool>(
          valueListenable: _isFavoritedNotifier,
          builder: (context, isFavorited, child) {
            return IconButton(
              icon: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.red : Colors.white,
              ),
              onPressed: _toggleFavorite,
            );
          },
        ),
        
        /*
        IconButton(
          icon: Icon(
            _isFavorited ? Icons.favorite : Icons.favorite_border,
            color: _isFavorited ? Colors.red : Colors.white,
          ),
          onPressed: _toggleFavorite,
        ),
        IconButton(
          icon: const Icon(Icons.share, color: Colors.white),
          onPressed: _shareEmprendimiento,
        ),*/
      ],
    );
  }

  void _showFullscreenCarousel(List<String> images) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullscreenCarouselPage(
          images: images,
          initialIndex: _currentImageIndex,
        ),
      ),
    );
  }

  Widget _buildInfoHeader() {
  return SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.emprendimiento.nombre,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 24,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          
          // Owner and Category Row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        widget.emprendimiento.propietario,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: BrandColors.gradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: BrandColors.goldenYellow.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _getStarsFromPriority(widget.emprendimiento.categoryPriority),
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.emprendimiento.categoryDisplayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Tipo and Oferta
          if (widget.emprendimiento.tipo?.isNotEmpty ?? false)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store, size: 16, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Text(
                    widget.emprendimiento.tipo!,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Oferta/Description
          if (widget.emprendimiento.oferta.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade50, Colors.orange.shade100],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.local_offer, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Oferta Especial',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.emprendimiento.oferta,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange.shade900,
                            height: 1.4,
                          ),
                          maxLines: _showFullDescription ? null : 3,
                          overflow: _showFullDescription ? null : TextOverflow.ellipsis,
                        ),
                        if (widget.emprendimiento.oferta.length > 100)
                          TextButton(
                            onPressed: () => setState(() => 
                              _showFullDescription = !_showFullDescription
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: const Size(0, 30),
                            ),
                            child: Text(
                              _showFullDescription ? 'Ver menos' : 'Ver más',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Stats Row: Price, Likes, Comments
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Price
                _buildStatItem(
                  icon: Icons.attach_money,
                  label: 'Precio',
                  value: '\$${widget.emprendimiento.precioPromedio.toStringAsFixed(2)}',
                  color: Colors.green,
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                
                // Likes
                ValueListenableBuilder<int>(
                  valueListenable: _likesCountNotifier,
                  builder: (context, likesCount, child) {
                    return _buildStatItem(
                      icon: Icons.favorite,
                      label: 'Me gusta',
                      value: '$likesCount',
                      color: Colors.red,
                    );
                  },
                ),
                Container(width: 1, height: 40, color: Colors.grey.shade300),
                
                // Comments
                _buildStatItem(
                  icon: Icons.comment,
                  label: 'Comentarios',
                  value: '${_comments.length}',
                  color: Colors.blue,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Quick Info Grid
          Row(
            children: [
              Expanded(
                child: _buildEnhancedInfoCard(
                  Icons.location_on,
                  'Ubicación',
                  '${widget.emprendimiento.parroquia}',
                  '${widget.emprendimiento.sector}',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedInfoCard(
                  Icons.access_time,
                  'Horario',
                  widget.emprendimiento.horario,
                  null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildEnhancedInfoCard(
                  Icons.table_restaurant,
                  'Capacidad',
                  '${widget.emprendimiento.plazas} personas',
                  widget.emprendimiento.mesas > 0 
                    ? '${widget.emprendimiento.mesas} mesas'
                    : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildEnhancedInfoCard(
                  Icons.timer,
                  'Experiencia',
                  '${widget.emprendimiento.experiencia} años',
                  widget.emprendimiento.tiempoTrabajando > 0
                    ? '${widget.emprendimiento.tiempoTrabajando} años operando'
                    : null,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _makePhoneCall,
                  icon: const Icon(Icons.phone, size: 20),
                  label: const Text('Llamar'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    backgroundColor: BrandColors.goldenYellow,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sendWhatsApp,
                  icon: const Icon(Icons.message, size: 20),
                  label: const Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: BrandColors.goldenYellow, width: 2),
                    foregroundColor: BrandColors.goldenYellow,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Like Button (Full Width)
          SizedBox(
            width: double.infinity,
            child: ValueListenableBuilder<bool>(
              valueListenable: _isLikedNotifier,
              builder: (context, isLiked, child) {
                return OutlinedButton.icon(
                  onPressed: _toggleLike,
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? Colors.red : Colors.grey[600],
                  ),
                  label: Text(
                    isLiked ? 'Te gusta' : 'Me gusta',
                    style: TextStyle(
                      color: isLiked ? Colors.red : Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: BorderSide(
                      color: isLiked ? Colors.red : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

// Helper method for stats
Widget _buildStatItem({
  required IconData icon,
  required String label,
  required String value,
  required Color color,
}) {
  return Column(
    children: [
      Icon(icon, color: color, size: 24),
      const SizedBox(height: 6),
      Text(
        value,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
      Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: Colors.grey[600],
        ),
      ),
    ],
  );
}

// Enhanced info card
Widget _buildEnhancedInfoCard(
  IconData icon,
  String label,
  String value,
  String? subtitle,
) {
  return Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: BrandColors.lightYellow.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18,
                color: BrandColors.deepGold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    ),
  );
}

// Add helper for stars
String _getStarsFromPriority(int priority) {
  switch (priority) {
    case 1:
      return '⭐';
    case 2:
      return '⭐⭐';
    case 3:
      return '⭐⭐⭐';
    default:
      return '';
  }
}

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRatingDisplay() {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Icon(
              index < widget.emprendimiento.averageRating.floor()
                  ? Icons.star
                  : index < widget.emprendimiento.averageRating
                  ? Icons.star_half
                  : Icons.star_border,
              size: 20,
              color: Colors.amber,
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${widget.emprendimiento.averageRating.toStringAsFixed(1)} (${widget.emprendimiento.ratingCount})',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildTabBar() {
  return SliverToBoxAdapter(
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: BrandColors.goldenYellow,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: BrandColors.goldenYellow,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        tabs: const [
          Tab(text: 'Detalles', icon: Icon(Icons.info_outline, size: 20)),
          Tab(text: 'Menú', icon: Icon(Icons.restaurant_menu, size: 20)),
          Tab(text: 'Ubicación', icon: Icon(Icons.map_outlined, size: 20)),
          Tab(text: 'Reseñas', icon: Icon(Icons.reviews_outlined, size: 20)),
        ],
      ),
    ),
  );
}
  Widget _buildVideoSection() {
    return VideoPlayerSection(videoUrl: widget.emprendimiento.videoUrl ?? '');
  }

  Widget _buildMenuTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (widget.emprendimiento.hasMenu) ...[
          Text(
            'Menú',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.emprendimiento.menu!,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ] else ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'Menú no disponible',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Contacta directamente para conocer el menú',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _makePhoneCall,
                        icon: const Icon(Icons.phone),
                        label: const Text('Llamar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _sendWhatsApp,
                        icon: const Icon(Icons.message),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 24),

        // Service type and processes
        _buildSection('Tipo de Servicio', Icons.room_service, [
          _buildDetailText(widget.emprendimiento.tipoServicio),
        ]),

        /*
        if (widget.emprendimiento.procesos.isNotEmpty)
          _buildSection('Procesos de Preparación', Icons.psychology, [
            _buildDetailText(widget.emprendimiento.procesos),
          ]),

        if (widget.emprendimiento.materiaPrima.isNotEmpty)
          _buildSection('Materia Prima y Proveedores', Icons.agriculture, [
            _buildDetailText(widget.emprendimiento.materiaPrima),
            const SizedBox(height: 12),
            _buildDetailRow('Proveedores', widget.emprendimiento.proveedores),
            _buildDetailRow(
              'Número de proveedores',
              '${widget.emprendimiento.numeroProveedores}',
            ),
          ]),*/
      ],
    );
  }

  Widget _buildLocationTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Interactive OpenStreetMap
        Container(
          height: 300,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                widget.emprendimiento.latitude,
                widget.emprendimiento.longitude,
              ),
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapTileUrl(),
                userAgentPackageName: 'com.example.emprendimientos',
                maxZoom: 19,
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.emprendimiento.latitude,
                      widget.emprendimiento.longitude,
                    ),
                    width: 40,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        _showMarkerInfo();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () =>
                        _launchUrl('https://www.openstreetmap.org/copyright'),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Map controls
        // Map controls
Row(
  children: [
    Expanded(
      child: _buildMapStyleButton(
        label: 'Estándar',
        icon: Icons.map,
        style: 'osm',
        isSelected: _currentMapStyle == 'osm',
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: _buildMapStyleButton(
        label: 'Topográfico',
        icon: Icons.terrain,
        style: 'topo',
        isSelected: _currentMapStyle == 'topo',
      ),
    ),
    const SizedBox(width: 8),
    Container(
      decoration: BoxDecoration(
        gradient: BrandColors.gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: BrandColors.goldenYellow.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        onPressed: _centerMapOnLocation,
        icon: const Icon(Icons.my_location, color: Colors.white),
        tooltip: 'Centrar en ubicación',
      ),
    ),
  ],
),

        const SizedBox(height: 24),

        _buildSection('Dirección Completa', Icons.location_on, [
          _buildDetailRow('Parroquia', widget.emprendimiento.parroquia),
          _buildDetailRow('Sector', widget.emprendimiento.sector),
          _buildDetailRow(
            'Coordenadas',
            '${widget.emprendimiento.latitude.toStringAsFixed(6)}, ${widget.emprendimiento.longitude.toStringAsFixed(6)}',
          ),
        ]),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _openInMaps,
                icon: const Icon(Icons.directions),
                label: const Text('Cómo llegar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _copyCoordinates,
                icon: const Icon(Icons.copy),
                label: const Text('Copiar ubicación'),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Información de Ubicación',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Este establecimiento se encuentra en ${widget.emprendimiento.parroquia}, sector ${widget.emprendimiento.sector}. '
                'Puedes usar las coordenadas para navegación GPS o abrir directamente en tu aplicación de mapas favorita.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMapStyleButton({
  required String label,
  required IconData icon,
  required String style,
  required bool isSelected,
}) {
  return Container(
    decoration: BoxDecoration(
      gradient: isSelected ? BrandColors.gradient : null,
      borderRadius: BorderRadius.circular(12),
      boxShadow: isSelected ? [
        BoxShadow(
          color: BrandColors.goldenYellow.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ] : null,
    ),
    child: OutlinedButton.icon(
      onPressed: () => _changeMapStyle(style),
      icon: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : Colors.grey.shade700,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          fontSize: 13,
        ),
      ),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.transparent : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.grey.shade700,
        side: BorderSide(
          color: isSelected ? Colors.transparent : Colors.grey.shade300,
          width: 1.5,
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  );
}

  // Add helper method to get map tile URL based on style:
  String _getMapTileUrl() {
    switch (_currentMapStyle) {
      case 'topo':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'osm':
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  // Add method to change map style:
  void _changeMapStyle(String style) {
    setState(() {
      _currentMapStyle = style;
    });
  }

  // Add method to center map on location:
  void _centerMapOnLocation() {
    _mapController?.move(
      LatLng(widget.emprendimiento.latitude, widget.emprendimiento.longitude),
      15.0,
    );
  }

  // Add method to show marker info:
  void _showMarkerInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.emprendimiento.nombre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.emprendimiento.oferta,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${widget.emprendimiento.parroquia}, ${widget.emprendimiento.sector}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openInMaps();
            },
            icon: const Icon(Icons.directions, size: 16),
            label: const Text('Ir'),
          ),
        ],
      ),
    );
  }

  // Update the _showFullscreenMap method:
  void _showFullscreenMap() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullscreenMapPage(
          emprendimiento: widget.emprendimiento,
          onDirections: _openInMaps,
          onCopy: _copyCoordinates,
        ),
      ),
    );
  }

  // Helper method to launch URLs:
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      _showErrorSnackbar('No se puede abrir el enlace');
    }
  }

  Widget _buildReviewsTab() {
    return CustomScrollView(
      // Remove any controller - let NestedScrollView handle it
      slivers: [
        // Rating summary as a sliver
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.all(16),
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.emprendimiento.averageRating.toStringAsFixed(
                            1,
                          ),
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(5, (index) {
                            return Icon(
                              index <
                                      widget.emprendimiento.averageRating
                                          .floor()
                                  ? Icons.star
                                  : index < widget.emprendimiento.averageRating
                                  ? Icons.star_half
                                  : Icons.star_border,
                              color: Colors.amber,
                              size: 18,
                            );
                          }),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.emprendimiento.ratingCount} reseñas',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Align(
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.rate_review, size: 16),
                      label: const Text('Escribir'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Loading state
        if (_isLoadingComments)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          ),

        // Empty state
        if (!_isLoadingComments && _comments.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.comment,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay comentarios aún',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sé el primero en dejar una reseña',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: _showRatingDialog,
                      icon: const Icon(Icons.rate_review),
                      label: const Text('Escribir primera reseña'),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Comments list
        if (!_isLoadingComments && _comments.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return _buildCommentCard(_comments[index]);
              }, childCount: _comments.length),
            ),
          ),
      ],
    );
  }

  Widget _buildCommentCard(Comment comment) {
    final isOwner = _currentUserId != null && comment.userId == _currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info and rating
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(comment.userAvatar),
                  radius: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        comment.timeAgo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Delete button for owner
                if (isOwner)
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    onPressed: () => _confirmDeleteComment(comment),
                    tooltip: 'Eliminar comentario',
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Comment content
            Text(
              comment.content,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 12),

            // Actions
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => _toggleCommentLike(comment),
                  icon: Icon(
                    comment.isLikedByUser
                        ? Icons.thumb_up
                        : Icons.thumb_up_outlined,
                    size: 16,
                    color: comment.isLikedByUser
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  ),
                  label: Text('${comment.likesCount}'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                const SizedBox(width: 16),
                TextButton.icon(
                  onPressed: () => _showReplyDialog(comment),
                  icon: const Icon(Icons.reply, size: 16),
                  label: const Text('Responder'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),

            // Replies
            if (comment.hasReplies) ...[
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.only(left: 32),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: comment.replies
                      .map((reply) => _buildReplyCard(reply, comment))
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReplyCard(CommentReply reply, Comment parentComment) {
    final isOwner = _currentUserId != null && reply.userId == _currentUserId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundImage: NetworkImage(reply.userAvatar),
            radius: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            reply.userName,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            reply.timeAgo,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    if (isOwner)
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 16,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            _confirmDeleteReply(reply, parentComment),
                        tooltip: 'Eliminar respuesta',
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  reply.content,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteComment(Comment comment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar comentario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que deseas eliminar este comentario?'),
            if (comment.hasReplies) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'También se eliminarán ${comment.replies.length} respuesta(s)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteComment(comment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteReply(CommentReply reply, Comment parentComment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar respuesta'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar esta respuesta?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteReply(reply, parentComment);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    if (_commentRepository == null) {
      _showErrorSnackbar('Error: Sistema de comentarios no disponible');
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Pass both emprendimiento ID and comment ID
      await _commentRepository!.deleteComment(
        widget.emprendimiento.id,
        comment.id,
      );

      if (mounted) Navigator.of(context).pop();

      setState(() {
        _comments.removeWhere((c) => c.id == comment.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              comment.hasReplies
                  ? 'Comentario y ${comment.replies.length} respuesta(s) eliminados'
                  : 'Comentario eliminado exitosamente',
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      _showErrorSnackbar('Error al eliminar comentario: ${e.toString()}');
    }
  }

  Future<void> _deleteReply(CommentReply reply, Comment parentComment) async {
    if (_commentRepository == null) {
      _showErrorSnackbar('Error: Sistema de comentarios no disponible');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use the correct deleteReply method with both commentId and replyId
      await _commentRepository!.deleteReply(parentComment.id, reply.id);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Remove reply from parent comment
      setState(() {
        final index = _comments.indexOf(parentComment);
        if (index != -1) {
          final updatedReplies = _comments[index].replies
              .where((r) => r.id != reply.id)
              .toList();
          _comments[index] = _comments[index].copyWith(replies: updatedReplies);
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respuesta eliminada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      _showErrorSnackbar('Error al eliminar respuesta: ${e.toString()}');
    }
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                BrandColors.lightYellow.withOpacity(0.2),
                BrandColors.brightYellow.withOpacity(0.1),
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: BrandColors.gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Content
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDetailRow(String label, String value) {
  if (value.isEmpty || value == 'null') return const SizedBox.shrink();
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    ),
  );
}

  Widget _buildDetailText(String text) {
    return Text(text, style: Theme.of(context).textTheme.bodyMedium);
  }

  
  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show navigation FAB only on Location tab
        if (_tabController.index == 1) ...[
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: 'navigate',
              onPressed: _openInMaps,
              child: const Icon(Icons.navigation),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Always show scroll to top FAB
        /*ScaleTransition(
          scale: _fabAnimation,
          child: FloatingActionButton(
            heroTag: 'scroll_top',
            onPressed: _scrollToTop,
            child: const Icon(Icons.keyboard_arrow_up),
          ),
        ),*/
      ],
    );
  }
  /*Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_tabController.index == 2) ...[
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: 'navigate',
              onPressed: _openInMaps,
              child: const Icon(Icons.navigation),
            ),
          ),
          const SizedBox(height: 12),
        ],
        // Only show if scrolled down
        if (_showScrollToTop)
          ScaleTransition(
            scale: _fabAnimation,
            child: FloatingActionButton(
              heroTag: 'scroll_top',
              onPressed: _scrollToTop,
              child: const Icon(Icons.keyboard_arrow_up),
            ),
          ),
      ],
    );
  }*/

  /*void _scrollToTop() {
    try {
    final scrollable = Scrollable.maybeOf(context);
    
    if (scrollable != null && scrollable.position.hasPixels) {
      scrollable.position.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  } catch (e) {
    // Silently fail if scrolling not possible
    debugPrint('Scroll to top failed: $e');
  }
  }*/

  // Helper methods
  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'premium':
      case 'gold':
      case '5 estrellas':
        return Colors.amber;
      case 'platinum':
      case '4 estrellas':
        return Colors.purple;
      case 'silver':
      case '3 estrellas':
        return Colors.blueGrey;
      case 'bronze':
      case '2 estrellas':
        return Colors.orange;
      case 'basic':
      case '1 estrellas':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getSocialIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'facebook':
        return Icons.facebook;
      case 'instagram':
        return Icons.camera_alt;
      case 'tiktok':
        return Icons.music_note;
      case 'whatsapp':
        return Icons.message;
      default:
        return Icons.share;
    }
  }

  // Action methods
  Future<void> _toggleFavorite() async {
  debugPrint('=== Toggle Favorite Debug ===');
  debugPrint('Is Guest: $_isGuestUser');
  debugPrint('Token exists: ${_authToken != null}');
  
  if (_isGuestUser) {
    _showLoginPrompt('agregar a favoritos');
    return;
  }
  
  // Ensure we have a valid token
  final hasValidToken = await _ensureValidToken();
  if (!hasValidToken) {
    _showErrorSnackbar('Error de autenticación. Inicia sesión nuevamente.');
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  // Store original state
  final originalFavoritedState = _isFavoritedNotifier.value;
  
  try {
    // Optimistic update
    _isFavoritedNotifier.value = !_isFavoritedNotifier.value;
    _isLikedNotifier.value = _isFavoritedNotifier.value; // Add this line
    _likesCountNotifier.value += _isFavoritedNotifier.value ? 1 : -1; // Add this line
    
    // Update the local emprendimiento object
    setState(() {
      _currentEmprendimiento = _currentEmprendimiento.copyWith(
        isFavoritedByUser: _isFavoritedNotifier.value,
        
      );
    });
    
    debugPrint('About to call toggleLike with:');
    debugPrint('  - Emprendimiento ID: ${_currentEmprendimiento.id}');
    debugPrint('  - Token: ${_authToken?.substring(0, min(20, _authToken?.length ?? 0))}...');
    debugPrint('  - Repository initialized: ${_repository != null}');
    final success = await _repository!.toggleLike(
      _currentEmprendimiento.id, 
      _authToken!,
    );
    
    if (!success) {
      // Revert on failure
      _isFavoritedNotifier.value = originalFavoritedState;
      _isLikedNotifier.value = originalFavoritedState; // Add this line
      _likesCountNotifier.value -= _isFavoritedNotifier.value ? 1 : -1; // Add this line
      setState(() {
        _currentEmprendimiento = _currentEmprendimiento.copyWith(
          isFavoritedByUser: originalFavoritedState,
        );
      });
      _showErrorSnackbar('Error al actualizar favoritos');
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isFavoritedNotifier.value ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  _isFavoritedNotifier.value 
                    ? 'Agregado a favoritos' 
                    : 'Removido de favoritos',
                ),
              ],
            ),
            backgroundColor: _isFavoritedNotifier.value ? Colors.red : Colors.grey[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  } catch (e) {
    // Revert on exception
    _isFavoritedNotifier.value = originalFavoritedState;
    _isLikedNotifier.value = originalFavoritedState; // Add this line
    _likesCountNotifier.value -= _isFavoritedNotifier.value ? 1 : -1; // Add this line
    setState(() {
      _currentEmprendimiento = _currentEmprendimiento.copyWith(
        isFavoritedByUser: originalFavoritedState,
      );
    });
    
    debugPrint('Toggle favorite error: $e');
    
    final errorMessage = e.toString().toLowerCase();
    
    if (errorMessage.contains('token') || 
        errorMessage.contains('401') || 
        errorMessage.contains('unauthorized')) {
      
      _showErrorSnackbar('Sesión expirada. Por favor inicia sesión nuevamente.');
      _authToken = null;
      await widget.authRepository.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      _showErrorSnackbar('Error al actualizar favoritos: ${e.toString()}');
    }
  }
}

  /*void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likesCount += _isLiked ? 1 : -1;
    });

    // Optional: Show a subtle feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isLiked
              ? 'Te gusta este emprendimiento'
              : 'Ya no te gusta este emprendimiento',
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }*/

  Future<void> _toggleLike() async {
  debugPrint('=== Toggle Like Debug ===');
  debugPrint('Is Guest: $_isGuestUser');
  debugPrint('Token exists: ${_authToken != null}');
  
  // Check if user is guest
  if (_isGuestUser) {
    _showLoginPrompt('dar like');
    return;
  }
  
  // Ensure we have a valid token
  final hasValidToken = await _ensureValidToken();
  if (!hasValidToken) {
    _showErrorSnackbar('Error de autenticación. Inicia sesión nuevamente.');
    Navigator.pushReplacementNamed(context, '/login');
    return;
  }

  // Store original state for rollback
  final originalLikedState = _isLikedNotifier.value;
  final originalLikesCount = _likesCountNotifier.value;
  
  try {
    // Optimistic UI update
    _isLikedNotifier.value = !_isLikedNotifier.value;
    _isFavoritedNotifier.value = _isLikedNotifier.value; 
    _likesCountNotifier.value += _isLikedNotifier.value ? 1 : -1;
    
    // Make API call (you'll need to implement this in your repository)
    final success =  await _repository!.toggleLike(widget.emprendimiento.id, _authToken!);
    
    if (!success) {
      // Revert on failure
      _isLikedNotifier.value = originalLikedState;
      _isFavoritedNotifier.value = originalLikedState; 
      _likesCountNotifier.value = originalLikesCount;
      _showErrorSnackbar('Error al actualizar like');
    } else {
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _isLikedNotifier.value ? Icons.favorite : Icons.favorite_border,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(_isLikedNotifier.value ? 'Te gusta' : 'Ya no te gusta'),
              ],
            ),
            backgroundColor: _isLikedNotifier.value ? Colors.red : Colors.grey[700],
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  } catch (e) {
    // Revert on exception
    _isLikedNotifier.value = originalLikedState;
    _isFavoritedNotifier.value = originalLikedState; 
    _likesCountNotifier.value = originalLikesCount;
    
    debugPrint('Toggle like error: $e');
    
    // Handle specific error cases
    final errorMessage = e.toString().toLowerCase();
    
    if (errorMessage.contains('token') || 
        errorMessage.contains('401') || 
        errorMessage.contains('unauthorized') ||
        errorMessage.contains('autenticación')) {
      
      _showErrorSnackbar('Sesión expirada. Por favor inicia sesión nuevamente.');
      
      // Clear the invalid token
      _authToken = null;
      
      // Auto logout and redirect
      await widget.authRepository.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      _showErrorSnackbar('Error al actualizar like: ${e.toString()}');
    }
  }
}



  Future<void> _toggleCommentLike(Comment comment) async {
    if (_commentRepository == null) {
      _showErrorSnackbar('Error: Sistema de comentarios no disponible');
      return;
    }

    try {
      // Optimistic UI update
      setState(() {
        final index = _comments.indexOf(comment);
        if (index != -1) {
          _comments[index] = _comments[index].copyWith(
            isLikedByUser: !_comments[index].isLikedByUser,
            likesCount:
                _comments[index].likesCount +
                (_comments[index].isLikedByUser ? -1 : 1),
          );
        }
      });

      // Call API
      await _commentRepository!.toggleCommentLike(comment.id);
    } catch (e) {
      // Revert on error
      setState(() {
        final index = _comments.indexOf(comment);
        if (index != -1) {
          _comments[index] = _comments[index].copyWith(
            isLikedByUser: !_comments[index].isLikedByUser,
            likesCount:
                _comments[index].likesCount +
                (_comments[index].isLikedByUser ? 1 : -1),
          );
        }
      });

      _showErrorSnackbar('Error al actualizar like: ${e.toString()}');
    }
  }

  void _shareEmprendimiento() {
    // Implement share functionality
    final shareText =
        'Te recomiendo ${widget.emprendimiento.nombre} en ${widget.emprendimiento.parroquia}. '
        '${widget.emprendimiento.oferta}';

    // For now, just copy to clipboard
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Información copiada al portapapeles'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _makePhoneCall() async {
    final phoneNumber = widget.emprendimiento.telefono;
    final uri = Uri.parse('tel:$phoneNumber');

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        _showErrorSnackbar('No se puede realizar la llamada');
      }
    } catch (e) {
      _showErrorSnackbar('Error al intentar llamar: $e');
    }
  }

  void _sendWhatsApp() async {
    final phoneNumber = widget.emprendimiento.telefono.replaceAll(
      RegExp(r'[^\d]'),
      '',
    );
    final message =
        'Hola, me interesa conocer más sobre ${widget.emprendimiento.nombre}. '
        'Vi su información y me gustaría obtener más detalles.';
    final uri = Uri.parse(
      'https://wa.me/593$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackbar('No se puede abrir WhatsApp');
      }
    } catch (e) {
      _showErrorSnackbar('Error al abrir WhatsApp: $e');
    }
  }

  void _openInMaps() async {
    final lat = widget.emprendimiento.latitude;
    final lng = widget.emprendimiento.longitude;
    final label = Uri.encodeComponent(widget.emprendimiento.nombre);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng&query_place_id=$label',
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackbar('No se puede abrir el mapa');
      }
    } catch (e) {
      _showErrorSnackbar('Error al abrir el mapa: $e');
    }
  }

  void _copyCoordinates() {
    final coordinates =
        '${widget.emprendimiento.latitude}, ${widget.emprendimiento.longitude}';
    Clipboard.setData(ClipboardData(text: coordinates));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coordenadas copiadas al portapapeles'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoginPrompt(String action) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.login,
        size: 48,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Inicia sesión'),
      content: Text(
        'Necesitas iniciar sesión para $action.\n\n'
        'Crea una cuenta gratis para acceder a todas las funciones.',
        textAlign: TextAlign.center,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushReplacementNamed(context, '/login');
          },
          child: const Text('Iniciar sesión'),
        ),
      ],
    ),
  );
}

  void _showRatingDialog() {
  if (_isGuestUser) {
    _showLoginPrompt('escribir una reseña');
    return;
  }

  if (_commentRepository == null) {
    _showErrorSnackbar('Sistema de comentarios no disponible');
    return;
  }

  // Define the controller inside the method
  final commentController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Escribir reseña'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                // STEP 1: Add onChanged to trigger the rebuild
                onChanged: (value) {
                  setDialogState(() {
                    // This empty call forces the StatefulBuilder to 
                    // re-evaluate the button's 'onPressed' condition.
                  });
                },
                decoration: const InputDecoration(
                  hintText: 'Escribe tu comentario...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                maxLength: 500,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            // STEP 2: This will now update in real-time
            onPressed: commentController.text.trim().isNotEmpty
                ? () async {
                    String comment = commentController.text.trim();
                    Navigator.pop(context);
                    await _submitRating(comment);
                  }
                : null,
            child: const Text('Enviar'),
          ),
        ],
      ),
    ),
  ).then((_) => commentController.dispose()); // Clean up memory
}

  void _showReplyDialog(Comment comment) {
    if (_isGuestUser) {
      _showLoginPrompt('responder comentarios');
      return;
    }
    
    final replyController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Responder a ${comment.userName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                comment.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: replyController,
              decoration: const InputDecoration(
                hintText: 'Escribe tu respuesta...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 300,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (replyController.text.trim().isNotEmpty) {
                _submitReply(comment, replyController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Responder'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitRating(String comment) async {
    if (_commentRepository == null) {
      _showErrorSnackbar('Error: Sistema de comentarios no disponible');
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create the comment using the repository
      final newComment = await _commentRepository!.createComment(
        widget.emprendimiento.id,
        comment,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Add the new comment to the list
      setState(() {
        _comments.insert(0, newComment);
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reseña enviada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      _showErrorSnackbar('Error al enviar reseña: ${e.toString()}');
    }
  }

  Future<void> _submitReply(Comment comment, String replyText) async {
    if (_commentRepository == null) {
      _showErrorSnackbar('Error: Sistema de comentarios no disponible');
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Create the reply using the repository
      final newReply = await _commentRepository!.createReply(
        comment.id,
        replyText,
      );

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Update the comment with the new reply
      setState(() {
        final index = _comments.indexOf(comment);
        if (index != -1) {
          _comments[index] = _comments[index].copyWith(
            replies: [..._comments[index].replies, newReply],
          );
        }
      });

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Respuesta enviada exitosamente'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      _showErrorSnackbar('Error al enviar respuesta: ${e.toString()}');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    });
  }
}

// Add this new widget for fullscreen map at the end of the file:
class _FullscreenMapPage extends StatefulWidget {
  final Emprendimiento emprendimiento;
  final VoidCallback onDirections;
  final VoidCallback onCopy;

  const _FullscreenMapPage({
    required this.emprendimiento,
    required this.onDirections,
    required this.onCopy,
  });

  @override
  State<_FullscreenMapPage> createState() => _FullscreenMapPageState();
}

class _FullscreenMapPageState extends State<_FullscreenMapPage> {
  late final MapController _mapController;
  String _currentMapStyle = 'osm';

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  

  String _getMapTileUrl() {
    switch (_currentMapStyle) {
      case 'topo':
        return 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png';
      case 'osm':
      default:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ubicación - ${widget.emprendimiento.nombre}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.directions),
            onPressed: () {
              widget.onDirections();
            },
            tooltip: 'Abrir en Google Maps',
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(
                widget.emprendimiento.latitude,
                widget.emprendimiento.longitude,
              ),
              initialZoom: 15.0,
              minZoom: 5.0,
              maxZoom: 18.0,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: _getMapTileUrl(),
                userAgentPackageName: 'com.example.emprendimientos',
                maxZoom: 19,
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      widget.emprendimiento.latitude,
                      widget.emprendimiento.longitude,
                    ),
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              RichAttributionWidget(
                attributions: [
                  TextSourceAttribution(
                    'OpenStreetMap contributors',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'map_style',
                  onPressed: () {
                    setState(() {
                      _currentMapStyle = _currentMapStyle == 'osm'
                          ? 'topo'
                          : 'osm';
                    });
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    _currentMapStyle == 'osm' ? Icons.terrain : Icons.map,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom + 1);
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  onPressed: () {
                    final zoom = _mapController.camera.zoom;
                    _mapController.move(_mapController.camera.center, zoom - 1);
                  },
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.remove,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'directions_full',
            onPressed: () {
              widget.onDirections();
            },
            child: const Icon(Icons.directions),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'copy_coords',
            onPressed: () {
              widget.onCopy();
            },
            child: const Icon(Icons.copy),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'center',
            onPressed: () {
              _mapController.move(
                LatLng(
                  widget.emprendimiento.latitude,
                  widget.emprendimiento.longitude,
                ),
                15.0,
              );
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

class _FullscreenCarouselPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullscreenCarouselPage({
    required this.images,
    required this.initialIndex,
  });

  @override
  State<_FullscreenCarouselPage> createState() =>
      _FullscreenCarouselPageState();
}

class _FullscreenCarouselPageState extends State<_FullscreenCarouselPage> {
  late int _currentIndex;
  late CarouselSliderController _carouselController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _carouselController = CarouselSliderController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Center(
            child: CarouselSlider(
              carouselController: _carouselController,
              options: CarouselOptions(
                height: MediaQuery.of(context).size.height,
                viewportFraction: 1.0,
                enableInfiniteScroll: widget.images.length > 1,
                initialPage: widget.initialIndex,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: widget.images.map((imageUrl) {
                return Builder(
                  builder: (BuildContext context) {
                    return InteractiveViewer(
                      panEnabled: true,
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.error,
                              color: Colors.white,
                              size: 64,
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ),
          ),

          // Navigation arrows (optional)
          if (widget.images.length > 1) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => _carouselController.previousPage(),
                ),
              ),
            ),
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () => _carouselController.nextPage(),
                ),
              ),
            ),
          ],

          // Page indicator dots
          if (widget.images.length > 1)
            Positioned(
              bottom: 32,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: widget.images.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == entry.key
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
