import 'package:emprendegastroloja/core/constants/api_constants.dart';
import 'package:emprendegastroloja/data/datasources/local/auth_local_datasource.dart';
import 'package:emprendegastroloja/domain/repositories/auth_repository.dart';
import 'package:emprendegastroloja/domain/repositories/comment_repository.dart';
import 'package:emprendegastroloja/domain/usecases/auth/get_current_user_usecase.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/emprendimiento_model.dart';
import '../../../data/models/comment_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_video_player_plus/cached_video_player_plus.dart';

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
  late final CachedVideoPlayerPlus _player;

  int _currentImageIndex = 0;

  // Add these new variables for the map:
  MapController? _mapController;
  String _currentMapStyle = 'osm'; // 'osm', 'satellite', 'topo'

  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;

  // Add a key for the NestedScrollView to access its controllers
  final GlobalKey<NestedScrollViewState> _nestedScrollKey = GlobalKey();

  CommentRepository? _commentRepository;
  late final GetCurrentUserUseCase _getCurrentUserUseCase;

  final TextEditingController _commentController = TextEditingController();

  List<Comment> _comments = [];
  bool _isLoadingComments = false;
  bool _isLiked = false;
  int _likesCount = 0;
  bool _isFavorited = false;
  double _userRating = 0.0;
  bool _showFullDescription = false;
  String? _errorMessage;
  int? _currentUserId;

  @override
  void initState() {
    super.initState();
    _setupControllers();

    _player = CachedVideoPlayerPlus.networkUrl(
      Uri.parse(
        "https://res.cloudinary.com/djl0e1p6e/video/upload/v1762564764/samples/dance-2.mp4".replaceFirst('/upload/', '/upload/f_mp4/'),
      ),
      invalidateCacheIfOlderThan: const Duration(minutes: 69), // Nice!
    );

    _player.initialize().then((_) {
      setState(() {});
      _player.controller.play();
    });

    _initializeData();
    _carouselController = CarouselSliderController();
    _mapController = MapController();
    _getCurrentUserUseCase = GetCurrentUserUseCase(widget.authRepository);
    _getCurrentUserUseCase.repository.getCurrentUser().then((result) {
      result.fold((failure) {}, (user) {
        setState(() {
          _currentUserId = user?.id;
        });
      });
    });

    // Initialize repository immediately
    _initializeCommentRepository().then((repo) {
      _commentRepository = repo;
      _loadComments();
    });
  }

  /*Future<void> _initializeVideo() async {
  if (widget.emprendimiento.videoUrl == null) return;

  _controllerVideo = VideoPlayerController.networkUrl(
    Uri.parse("https://res.cloudinary.com/djl0e1p6e/video/upload/v1762564764/samples/dance-2.mp4".replaceFirst('/upload/', '/upload/f_mp4/')),
  );

  try {
    await _controllerVideo.initialize();
    setState(() {});
  } catch (e) {
    print("Video init error: $e");
  }
}*/

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
    _mapController?.dispose();
    _tabController.dispose();
    //_scrollController.dispose();
    _player.dispose();
    _fabAnimationController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 4,
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              _buildSliverAppBar(),
              _buildInfoHeader(),
              SliverOverlapAbsorber(
                handle: NestedScrollView.sliverOverlapAbsorberHandleFor(
                  context,
                ),
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
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildDetailsTabSafe() {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('details_tab'),
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

  // Safe wrapper for Menu tab
  /*
Widget _buildMenuTabSafe() {
  return Builder(
    builder: (context) {
      return CustomScrollView(
        key: const PageStorageKey<String>('menu_tab'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (widget.emprendimiento.hasMenu) ...[
                  Text(
                    'Menú',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
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
                _buildSection('Tipo de Servicio', Icons.room_service, [
                  _buildDetailText(widget.emprendimiento.tipoServicio),
                ]),
                // Add other sections...
              ]),
            ),
          ),
        ],
      );
    },
  );
}
*/

  // Safe wrapper for Location tab
  /*
Widget _buildLocationTabSafe() {
  return Builder(
    builder: (context) {
      return CustomScrollView(
        key: const PageStorageKey<String>('location_tab'),
        slivers: [
          SliverOverlapInjector(
            handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Your map and location content
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: _getMapTileUrl(),
                        userAgentPackageName: 'com.example.emprendimientos',
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
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Add rest of location content...
              ]),
            ),
          ),
        ],
      );
    },
  );
}
*/

  // Safe wrapper for Reviews tab
  Widget _buildReviewsTabSafe() {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: const PageStorageKey<String>('reviews_tab'),
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
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
                              widget.emprendimiento.averageRating
                                  .toStringAsFixed(1),
                              style: Theme.of(context).textTheme.displaySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
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
                                      : index <
                                            widget.emprendimiento.averageRating
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoadingComments)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_comments.isEmpty)
              SliverFillRemaining(
                child: Center(
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
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sé el primero en dejar una reseña',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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

  /*Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Main image
            Image.network(
              widget.emprendimiento.photoUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant, size: 64, color: Colors.grey[600]),
                      const SizedBox(height: 8),
                      Text(
                        'Imagen no disponible',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
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

            // Gallery indicator
            if (widget.emprendimiento.hasGallery)
              Positioned(
                bottom: 16,
                right: 16,
                child: GestureDetector(
                  onTap: _showImageGallery,
                  child: Container(
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
                          '+${widget.emprendimiento.galleryUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
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
        ),
      ],
    );
  }*/

  // In _buildSliverAppBar() method, update the CarouselOptions:

/*
  Widget _buildSliverAppBar() {
    // Combine main photo with gallery images
    final List<String> allImages = [
      ...widget.emprendimiento.galleryUrls,
    ];

    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
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
                enableInfiniteScroll: allImages.length > 1,
                autoPlay: false, 
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: allImages.map((imageUrl) {
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
            if (allImages.length > 1)
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
                            '${_currentImageIndex + 1}/${allImages.length}',
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
                      onTap: () => _showFullscreenCarousel(allImages),
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

            // ✅ ADD THESE: Navigation arrows for manual control
            if (allImages.length > 1) ...[
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

            // Carousel navigation dots (same as before)
            if (allImages.length > 1)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: allImages.asMap().entries.map((entry) {
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
                              color: Colors.black.withOpacity(0.3),
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
        ),
      ],
    );
  } */

 Widget _buildSliverAppBar() {
    // Combine main photo with gallery images
    final List<String> allImages = widget.emprendimiento.galleryUrls.
                                    toSet().toList();
    allImages[0] = allImages[0].replaceFirst("{", "");
    allImages[allImages.length-1] = allImages[allImages.length-1].replaceFirst("}", "");
    return SliverAppBar(
      expandedHeight: 300,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
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
                disableCenter: true, // ✅ ADD THIS: Disables Center widget wrapping
                enlargeCenterPage: false, // ✅ ADD THIS: Disable enlargement
                clipBehavior: Clip.none, // ✅ ADD THIS: Prevents clipping
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentImageIndex = index;
                  });
                },
              ),
              items: allImages.map((imageUrl) {
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
            if (allImages.isNotEmpty)
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
                            '${_currentImageIndex + 1}/${allImages.length}',
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
                      onTap: () => _showFullscreenCarousel(allImages),
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
            if (allImages.isNotEmpty) ...[
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
            if (allImages.isNotEmpty)
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: allImages.asMap().entries.map((entry) {
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
        ),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and rating
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.emprendimiento.nombre,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Por ${widget.emprendimiento.propietario}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    _buildRatingDisplay(),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(
                          widget.emprendimiento.categoria,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        widget.emprendimiento.categoryDisplayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Description
            Text(
              widget.emprendimiento.oferta,
              style: Theme.of(context).textTheme.bodyLarge,
              maxLines: _showFullDescription ? null : 3,
              overflow: _showFullDescription ? null : TextOverflow.ellipsis,
            ),
            if (widget.emprendimiento.oferta.length > 150)
              TextButton(
                onPressed: () => setState(
                  () => _showFullDescription = !_showFullDescription,
                ),
                child: Text(_showFullDescription ? 'Ver menos' : 'Ver más'),
              ),

            const SizedBox(height: 16),

            // Quick info cards
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard(
                    Icons.location_on,
                    'Ubicación',
                    '${widget.emprendimiento.parroquia}, ${widget.emprendimiento.sector}',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    Icons.access_time,
                    'Horario',
                    widget.emprendimiento.horario,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (widget.emprendimiento.precioPromedio > 0)
                  Expanded(
                    child: _buildInfoCard(
                      Icons.attach_money,
                      'Precio promedio',
                      '\$${widget.emprendimiento.precioPromedio.toStringAsFixed(2)}',
                    ),
                  ),
                if (widget.emprendimiento.precioPromedio > 0)
                  const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard(
                    Icons.table_restaurant,
                    'Capacidad',
                    '${widget.emprendimiento.plazas} plazas',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone),
                    label: const Text('Llamar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _sendWhatsApp,
                    icon: const Icon(Icons.message),
                    label: const Text('WhatsApp'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Like and comment stats
            Row(
              children: [
                IconButton(
                  onPressed: _toggleLike,
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                ),
                Text('$_likesCount me gusta'),
                const SizedBox(width: 16),
                Icon(
                  Icons.comment,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text('${_comments.length} comentarios'),
              ],
            ),
          ],
        ),
      ),
    );
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
        color: Theme.of(context).colorScheme.surface,
        child: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Detalles', icon: Icon(Icons.info)),
            Tab(text: 'Menú', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Ubicación', icon: Icon(Icons.map)),
            Tab(text: 'Reseñas', icon: Icon(Icons.reviews)),
          ],
        ),
      ),
    );
  }

  /*
  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildDetailsTab(),
        _buildMenuTab(),
        _buildLocationTab(),
        _buildReviewsTab(),
      ],
    );
  }*/

  /*
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Video section
          if (widget.emprendimiento.hasVideo) _buildVideoSection(),

          // Contact info section
          _buildSection('Información de Contacto', Icons.contact_phone, [
            _buildDetailRow('Teléfono', widget.emprendimiento.telefono),
            _buildDetailRow('Email', widget.emprendimiento.email),
            _buildDetailRow(
              'Horario de atención',
              widget.emprendimiento.horario,
            ),
          ]),

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
            _buildDetailRow('Baños disponibles', widget.emprendimiento.banio),
            _buildDetailRow(
              'Tiempo trabajando',
              '${widget.emprendimiento.tiempoTrabajando} años',
            ),
          ]),

          // Services section
          if (widget.emprendimiento.serviciosProduccion.isNotEmpty)
            _buildSection('Servicios y Producción', Icons.build, [
              _buildDetailText(widget.emprendimiento.serviciosProduccion),
            ]),

          // Equipment section
          if (widget.emprendimiento.equipos.isNotEmpty)
            _buildSection('Equipos y Herramientas', Icons.kitchen, [
              _buildDetailText(widget.emprendimiento.equipos),
            ]),

          // Complementary services
          if (widget.emprendimiento.complementarios.isNotEmpty)
            _buildSection('Servicios Complementarios', Icons.star, [
              _buildDetailText(widget.emprendimiento.complementarios),
            ]),

          // Certifications section
          _buildSection('Certificaciones y Permisos', Icons.verified, [
            _buildDetailRow('RUC', widget.emprendimiento.ruc),
            _buildDetailRow(
              'Licencia GAD Loja',
              widget.emprendimiento.licenciaGadLoja,
            ),
            _buildDetailRow('ARCSA', widget.emprendimiento.arcsa),
            _buildDetailRow(
              'Registro de Turismo',
              widget.emprendimiento.turismo,
            ),
            _buildDetailRow('Asociación', widget.emprendimiento.asociacion),
          ]),

          // Social media section
          if (widget.emprendimiento.socialMediaLinks.isNotEmpty)
            _buildSection('Redes Sociales', Icons.share, [
              Wrap(
                spacing: 8,
                children: widget.emprendimiento.socialMediaLinks.map((
                  platform,
                ) {
                  return Chip(
                    label: Text(platform),
                    avatar: Icon(_getSocialIcon(platform), size: 16),
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                  );
                }).toList(),
              ),
            ]),

          // Staff section
          _buildSection('Información del Personal', Icons.group, [
            _buildDetailRow(
              'Personal capacitado',
              widget.emprendimiento.personalCapacitado,
            ),
            _buildDetailRow(
              'Frecuencia de capacitación',
              widget.emprendimiento.frecuenciaCapacitacion,
            ),
            if (widget.emprendimiento.numeroMujeres > 0 ||
                widget.emprendimiento.numeroHombres > 0)
              _buildDetailRow(
                'Empleados',
                '${widget.emprendimiento.numeroMujeres} mujeres, ${widget.emprendimiento.numeroHombres} hombres',
              ),
          ]),

          // Owner information
          _buildSection('Información del Propietario', Icons.person, [
            _buildDetailRow('Género', widget.emprendimiento.genero),
            _buildDetailRow('Edad', '${widget.emprendimiento.edad} años'),
            _buildDetailRow('Estado civil', widget.emprendimiento.estadoCivil),
            _buildDetailRow(
              'Nivel de educación',
              widget.emprendimiento.nivelEducacion,
            ),
            _buildDetailRow(
              'Dependencia de ingresos',
              widget.emprendimiento.dependenciaIngresos,
            ),
          ]),
        ],
      ),
    );
  }*/

  Widget _buildVideoSection() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.play_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Video del Emprendimiento',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
            child: Center(
              child: _player.isInitialized
                  ? AspectRatio(
                      aspectRatio: _player.controller.value.aspectRatio,
                      child: VideoPlayer(
                        _player.controller,
                      ), // Note: VideoPlayer from video_player package!
                    )
                  : const CircularProgressIndicator.adaptive(),
            ),
          ),

          /*
          GestureDetector(
            onTap: () {
              if (_player.isInitialized) {
                setState(() {
                  if (_player.controller.value.isPlaying) {
                    _player.controller.pause();
                  } else {
                    _player.controller.play();
                  }
                });
              }
            },
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 🔹 Background gradient (placeholder)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Colors.grey[900]!, Colors.grey[800]!],
                      ),
                    ),
                  ),

                  // 🔥 Centered Play Button
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),*/

          const SizedBox(height: 12),

          Center(
            child: Text(
              'Toca para reproducir',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
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
              color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
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
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _changeMapStyle('osm'),
                icon: Icon(
                  Icons.map,
                  size: 16,
                  color: _currentMapStyle == 'osm'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                label: Text('Estándar'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _currentMapStyle == 'osm'
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _changeMapStyle('topo'),
                icon: Icon(
                  Icons.terrain,
                  size: 16,
                  color: _currentMapStyle == 'topo'
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                label: Text('Topográfico'),
                style: OutlinedButton.styleFrom(
                  backgroundColor: _currentMapStyle == 'topo'
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _centerMapOnLocation,
              icon: const Icon(Icons.my_location),
              tooltip: 'Centrar en ubicación',
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
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodySmall),
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
        // Always show scroll to top FAB
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
  }

  void _scrollToTop() {
    // Get the outer scroll controller from NestedScrollView
    final nestedState = _nestedScrollKey.currentState;
    if (nestedState != null) {
      // Access the outer controller
      final outerController = nestedState.outerController;
      if (outerController.hasClients) {
        outerController.animateTo(
          0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

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
  void _toggleFavorite() {
    setState(() {
      _isFavorited = !_isFavorited;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorited ? 'Agregado a favoritos' : 'Removido de favoritos',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _toggleLike() {
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

  void _showRatingDialog() {
    if (_commentRepository == null) {
      _showErrorSnackbar('Sistema de comentarios no disponible');
      return;
    }

    double tempRating = 0.0;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Escribir reseña'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tu calificación:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return GestureDetector(
                      onTap: () {
                        setDialogState(() {
                          tempRating = index + 1.0;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          index < tempRating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 36,
                        ),
                      ),
                    );
                  }),
                ),
                if (tempRating > 0) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      '${tempRating.toInt()} estrella${tempRating > 1 ? 's' : ''}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: commentController,
                  decoration: const InputDecoration(
                    hintText: 'Escribe tu comentario...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
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
              onPressed:
                  tempRating > 0 && commentController.text.trim().isNotEmpty
                  ? () async {
                      Navigator.pop(context); // Close dialog first
                      await _submitRating(
                        tempRating,
                        commentController.text.trim(),
                      );
                    }
                  : null,
              child: const Text('Enviar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(Comment comment) {
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

  Future<void> _submitRating(double rating, String comment) async {
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

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
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
