import 'dart:async';
import 'package:emprendegastroloja/core/constants/api_constants.dart';
import 'package:emprendegastroloja/presentation/bloc/auth/auth_bloc.dart';
import 'package:emprendegastroloja/presentation/bloc/auth/auth_event.dart';
import 'package:emprendegastroloja/presentation/bloc/auth/auth_state.dart';
import 'package:emprendegastroloja/presentation/pages/main/widgets/filter_bottom_sheet.dart';
import 'package:emprendegastroloja/presentation/pages/main/widgets/emprendimientos_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/emprendimiento_model.dart';
import '../../../data/datasources/remote/emprendimientos_remote_datasource.dart';
import '../../../data/datasources/local/emprendimientos_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/emprendimientos_repository.dart';
import 'emprendimiento_detail_page.dart';
import 'package:emprendegastroloja/domain/repositories/auth_repository.dart';
import 'dart:math' show min;

// Brand Colors matching splash
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

// MARK: - Main Page Widget
class EmprendimientosSearchPage extends StatefulWidget {
  final AuthRepository authRepository;
  
  const EmprendimientosSearchPage({
    super.key,
    required this.authRepository,
  });

  @override
  State<EmprendimientosSearchPage> createState() => 
      _EmprendimientosSearchPageState();
}

class _EmprendimientosSearchPageState extends State<EmprendimientosSearchPage>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  
  // MARK: - Dependencies
  late EmprendimientosRepository _repository;
  String? _authToken;
  
  // MARK: - Controllers
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  
  // MARK: - State
  final _searchState = SearchState();
  final _filterState = FilterState();
  Timer? _debounce;
  int _currentPageIndex = 0;
  bool _showSearchBar = false;
  
  @override
  bool get wantKeepAlive => true;

  bool get _isGuestUser {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthGuest;
  }

  @override
  void initState() {
    super.initState();
    _setupControllers();
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    await _initializeRepository();
    await _loadData();
  }

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

  void _setupControllers() {
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _fabAnimationController.forward();
      }
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchState.currentQuery = _searchController.text;
          _filterEmprendimientos();
        });
      }
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset > 100 && !_fabAnimationController.isCompleted) {
      _fabAnimationController.forward();
    } else if (offset < 100 && !_fabAnimationController.isDismissed) {
      _fabAnimationController.reverse();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() => _searchState.isLoading = true);

      final authState = context.read<AuthBloc>().state;
      final isGuest = authState is AuthGuest;

      if (isGuest) {
        _authToken = null;
        debugPrint('Loading data as guest user');
      } else {
        final tokenResult = await widget.authRepository.getAuthToken();
        _authToken = tokenResult.fold(
          (failure) {
            debugPrint('Token retrieval failed: ${failure.toString()}');
            return null;
          },
          (token) {
            debugPrint('Token retrieved successfully');
            return token;
          },
        );
  
        
        if (_authToken == null || _authToken!.isEmpty) {
          _showErrorSnackbar('Error de autenticación. Inicia sesión nuevamente.');
          await widget.authRepository.logout();
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/login');
          }
          return;
        }
      }

      await _loadFilterPreferences();
      _searchState.searchHistory = await _repository.getSearchHistory();

      try {
        _filterState.parroquias = await _repository.getParroquias();
      } catch (e) {
        debugPrint('Error loading parroquias: $e');
        final allData = await _repository.getEmprendimientos(
          ordenarPor: _filterState.sortBy,
          token: _authToken,
          forceRefresh: false,
          pageSize: 100,
        );
        _filterState.parroquias = 
            _repository.getUniqueParroquias(allData).toList();
      }

      final allData = await _repository.getEmprendimientos(
        ordenarPor: _filterState.sortBy,
        token: _authToken,
        forceRefresh: true,
        pageSize: 100,
      );

      _searchState.allEmprendimientos = allData;
      _filterState.categories = 
          _repository.getUniqueCategories(_searchState.allEmprendimientos);
      
      if (_filterState.parroquias.isEmpty) {
        _filterState.parroquias = 
            _repository.getUniqueParroquias(_searchState.allEmprendimientos)
                .toList();
      }

      _filterEmprendimientos();

    } catch (e) {
      String errorMessage = 'Error al cargar datos: $e';
      
      if (!_isGuestUser && 
          (e.toString().contains('No autorizado') || 
          e.toString().contains('401'))) {
        errorMessage = 'Sesión expirada. Inicia sesión nuevamente.';
        await widget.authRepository.logout();
      }
      _showErrorSnackbar(errorMessage);
    } finally {
      if (mounted) {
        setState(() => _searchState.isLoading = false);
      }
    }
  }
  

  Future<void> _loadFilterPreferences() async {
    final preferences = await _repository.getFilterPreferences();
    
    _filterState.selectedCategory = preferences['categoria'] ?? 'Todas';
    _filterState.sortBy = preferences['ordenar_por'] ?? 'categoria';
    
    final savedParroquias = preferences['parroquia'] ?? 'Todas';
    if (savedParroquias != 'Todas' && savedParroquias.isNotEmpty) {
      _filterState.selectedParroquias = savedParroquias.split(',').toSet();
    } else {
      _filterState.selectedParroquias.clear();
    }
  }

  void _filterEmprendimientos() {
    var filtered = List<Emprendimiento>.from(_searchState.allEmprendimientos);

    if (_searchState.currentQuery.isNotEmpty) {
      filtered = _repository.searchEmprendimientos(
        filtered, 
        _searchState.currentQuery,
      );
    }

    if (_filterState.selectedCategory != 'Todas') {
      filtered = _repository.filterByCategory(
        filtered, 
        _filterState.selectedCategory,
      );
    }

    if (_filterState.selectedParroquias.isNotEmpty) {
      filtered = filtered
          .where((e) => _filterState.selectedParroquias.contains(e.parroquia))
          .toList();
    }

    if (_filterState.maxPrice != null) {
      filtered = filtered
          .where((e) => e.precioPromedio <= _filterState.maxPrice!)
          .toList();
    }

    if (mounted) {
      setState(() {
        _searchState.filteredEmprendimientos = filtered;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: message.contains('inicia sesión')
            ? SnackBarAction(
                label: 'Iniciar Sesión',
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    return SafeArea(
      child: Column(
        children: [
          _buildTopBar(),
          if (_showSearchBar) _buildSearchBar(),
          Expanded(
            child: _searchState.isLoading
                ? const LoadingStateWidget()
                : PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _currentPageIndex = index);
                    },
                    children: [
                      _buildEmprendimientosList(_searchState.filteredEmprendimientos),
                      _buildEmprendimientosList(_getPremiumEmprendimientos()),
                      _buildFavoritesList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      decoration: BoxDecoration(
        gradient: BrandColors.gradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Logo
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'lib/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Title
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'EmprendeGastroLoja',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 195, 176, 1),
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Descubre emprendimientos',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 88, 80, 3),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            
            // Search Toggle
            IconButton(
              icon: Icon(
                _showSearchBar ? Icons.close : Icons.search,
                color: Colors.white,
              ),
              onPressed: () {
                setState(() {
                  _showSearchBar = !_showSearchBar;
                  if (!_showSearchBar) {
                    _searchController.clear();
                  }
                });
              },
            ),
            
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              onSelected: (value) {
                switch (value) {
                  case 'logout':
                    _showLogoutDialog();
                    break;
                  case 'delete':
                    _handleDeleteAccount();
                    break;
                }
              },
              itemBuilder: (context) => [
                if (!_isGuestUser)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Text('Eliminar cuenta'),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout),
                      const SizedBox(width: 12),
                      Text(_isGuestUser ? 'Salir' : 'Cerrar sesión'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'Buscar emprendimientos...',
          prefixIcon: const Icon(Icons.search, color: BrandColors.goldenYellow),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
              : null,
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.restaurant_menu,
                label: 'Todos',
                index: 0,
              ),
              _buildNavItem(
                icon: Icons.star,
                label: 'Premium',
                index: 1,
              ),
              _buildNavItem(
                icon: Icons.favorite,
                label: 'Favoritos',
                index: 2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
  }) {
    final isSelected = _currentPageIndex == index;
    
    return GestureDetector(
      onTap: () {
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        setState(() => _currentPageIndex = index);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: isSelected ? BrandColors.gradient : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[600],
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[600],
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Filter FAB
        if (_filterState.hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: FloatingActionButton(
              mini: true,
              heroTag: 'clear_filters',
              backgroundColor: Colors.red.shade400,
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _filterState.reset();
                  _filterEmprendimientos();
                });
              },
              child: const Icon(Icons.filter_alt_off, size: 20),
            ),
          ),
        
        // Main Filter FAB
        FloatingActionButton(
          heroTag: 'filter',
          onPressed: _showFilterDialog,
          backgroundColor: Colors.white,
          child: Container(
            decoration: BoxDecoration(
              gradient: BrandColors.gradient,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                Icons.tune,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        
        // Scroll to top FAB
        if (_fabAnimationController.isCompleted)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _fabAnimationController,
                  curve: Curves.easeOut,
                ),
              ),
              child: FloatingActionButton(
                mini: true,
                heroTag: 'scroll_top',
                backgroundColor: Colors.white,
                onPressed: () {
                  _scrollController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Icon(
                  Icons.keyboard_arrow_up,
                  color: BrandColors.goldenYellow,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmprendimientosList(List<Emprendimiento> emprendimientos) {
    if (emprendimientos.isEmpty) {
      return EmptyStateWidget(
        onClearFilters: () {
          _searchController.clear();
          setState(() {
            _filterState.reset();
            _filterEmprendimientos();
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      color: BrandColors.goldenYellow,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: emprendimientos.length,
        itemBuilder: (context, index) {
          return _buildEnhancedCard(emprendimientos[index]);
        },
      ),
    );
  }

  Widget _buildEnhancedCard(Emprendimiento emprendimiento) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _navigateToDetail(emprendimiento),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with premium badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(
                        emprendimiento.photoUrl ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant,
                            size: 48,
                            color: BrandColors.goldenYellow,
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  // Premium badge
                  if (emprendimiento.categoryPriority == 3)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: BrandColors.gradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  
                  // Favorite button
                  Positioned(
                    top: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () => _toggleFavorite(emprendimiento),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          emprendimiento.isFavoritedByUser
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: emprendimiento.isFavoritedByUser
                              ? Colors.red
                              : Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Content
              // Content
Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title
      Text(
        emprendimiento.nombre,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      const SizedBox(height: 8),
      
      // Category and location (EXISTING - keep as is)
      Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: BrandColors.lightYellow.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              emprendimiento.categoria,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: BrandColors.deepGold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    emprendimiento.parroquia,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      
      // NEW: Propietario and Tipo row
      const SizedBox(height: 8),
      Row(
        children: [
          const Icon(Icons.person, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              emprendimiento.propietario ?? 'No especificado',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200, width: 1),
            ),
            child: Text(
              emprendimiento.tipo ?? 'N/A',
              style: TextStyle(
                fontSize: 11,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      
      // NEW: Oferta (if exists)
      if (emprendimiento.oferta?.isNotEmpty ?? false) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange.shade100, Colors.orange.shade50],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade300, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer, size: 14, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  emprendimiento.oferta!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
      
      // NEW: Price, Stars, Likes, Comments row
      const SizedBox(height: 10),
      Row(
        children: [
          // Precio Promedio
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '\$',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  emprendimiento.precioPromedio.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Stars (convert categoryPriority to stars)
          Text(
            _getStarsFromPriority(emprendimiento.categoryPriority),
            style: const TextStyle(fontSize: 14),
          ),
          
          const Spacer(),
          
          // Likes
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, size: 14, color: Colors.red),
              const SizedBox(width: 4),
              Text(
                '${emprendimiento.likesCount ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          
          const SizedBox(width: 12),
          
          // Comments
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.comment, size: 14, color: Colors.blue),
              const SizedBox(width: 4),
              Text(
                '${emprendimiento.commentsCount ?? 0}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      
      // Description (EXISTING - keep as is)
      
    ],
  ),
)
            ],
          ),
        ),
      ),
    );
  }

  // Helper method to convert priority to stars
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

  List<Emprendimiento> _getPremiumEmprendimientos() {
    return _searchState.filteredEmprendimientos
        .where((e) => e.categoryPriority == 3)
        .toList();
  }

  Widget _buildFavoritesList() {
    if (_isGuestUser) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: BrandColors.gradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_border,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Inicia sesión para guardar favoritos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Crea una cuenta para marcar tus emprendimientos favoritos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: BrandColors.gradient,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.login, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Iniciar sesión',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final favorites = _searchState.filteredEmprendimientos
        .where((e) => e.isFavoritedByUser)
        .toList();

    if (favorites.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.favorite_border,
                  size: 50,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No tienes favoritos aún',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Explora y marca tus emprendimientos favoritos',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (_filterState.hasActiveFilters) ...[
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _filterState.reset();
                      _filterEmprendimientos();
                    });
                  },
                  icon: const Icon(Icons.filter_alt_off),
                  label: const Text('Limpiar filtros'),
                  style: TextButton.styleFrom(
                    foregroundColor: BrandColors.goldenYellow,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return _buildEmprendimientosList(favorites);
  }

  void _showFilterDialog() {
    final filterStateCopy = _filterState.copy();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        filterState: filterStateCopy,
        allEmprendimientos: _searchState.allEmprendimientos,
        onApply: (newState) {
          setState(() {
            _filterState.updateFrom(newState);
          });
          
          _repository.saveFilterPreferences(
            categoria: _filterState.selectedCategory,
            parroquia: _filterState.selectedParroquias.isEmpty
                ? 'Todas'
                : _filterState.selectedParroquias.join(','),
            ordenarPor: _filterState.sortBy,
          );
          
          _filterEmprendimientos();
        },
      ),
    );
  }

  void _showLogoutDialog() {
    final isGuest = _isGuestUser;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(isGuest ? 'Salir como invitado' : 'Cerrar sesión'),
        content: Text(
          isGuest 
            ? '¿Deseas salir del modo invitado? Podrás iniciar sesión después.'
            : '¿Estás seguro de que deseas cerrar sesión?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              if (isGuest) {
                Navigator.pushReplacementNamed(context, '/login');
              } else {
                try {
                  await widget.authRepository.logout();
                  if (mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                } catch (e) {
                  if (mounted) {
                    _showErrorSnackbar('Error al cerrar sesión: $e');
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(isGuest ? 'Salir' : 'Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('¿Eliminar cuenta?'),
        content: const Text(
          'Esta acción es permanente y borrará todos tus datos. ¿Estás seguro?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Eliminar',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      setState(() => _searchState.isLoading = true);
      
      final result = await widget.authRepository.deleteAccount();

      result.fold(
        (failure) {
          if (mounted) {
            setState(() => _searchState.isLoading = false);
            _showErrorSnackbar('Error al eliminar cuenta: ${failure.toString()}');
          }
        },
        (_) {
          if (mounted) {
            context.read<AuthBloc>().add(LogoutRequested());
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/login',
              (route) => false,
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tu cuenta ha sido eliminada.'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
      );
    }
  }

  Future<void> _navigateToDetail(Emprendimiento emprendimiento) async {
  final result = await Navigator.push<Map<String, dynamic>>(
    context,
    MaterialPageRoute(
      builder: (context) => EmprendimientoDetailPage(
        emprendimiento: emprendimiento,
        authRepository: widget.authRepository,
      ),
    ),
  );
  
  // Update the emprendimiento if data was returned
  if (result != null && mounted) {

    //await _loadData();

    final emprendimientoId = result['emprendimiento_id'] as int;
    final isFavorited = result['is_favorited'] as bool;
    final isLiked = result['is_liked'] as bool;
    final likesCount = result['likes_count'] as int;
    
    setState(() {
      final index = _searchState.allEmprendimientos
          .indexWhere((e) => e.id == emprendimientoId);
      
      if (index != -1) {
        _searchState.allEmprendimientos[index] = 
            _searchState.allEmprendimientos[index].copyWith(
          isFavoritedByUser: isFavorited,
          isLikedByUser: isLiked,
          likesCount: likesCount,
        );
      }
      
      // Re-filter to update all tabs
      _filterEmprendimientos();
    });
  }
}

  void _showLoginPrompt(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text('Inicia sesión'),
        content: Text('Necesitas iniciar sesión para $action'),
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
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Future<bool> _ensureValidToken() async {
  if (_isGuestUser) return false;
  
  if (_authToken == null || _authToken!.isEmpty) {
    final tokenResult = await widget.authRepository.getAuthToken();
    _authToken = tokenResult.fold(
      (failure) => null,
      (token) => token,
    );
  }
  
  return _authToken != null && _authToken!.isNotEmpty;
}

  Future<void> _toggleFavorite(Emprendimiento emprendimiento) async {
  debugPrint('=== Toggle Favorite Debug ===');
  debugPrint('Is Guest: $_isGuestUser');
  debugPrint('Token exists: ${_authToken != null}');
  debugPrint('Token value: ${_authToken?.substring(0, min(20, _authToken?.length ?? 0))}...');
  debugPrint('Emprendimiento ID: ${emprendimiento.id}');
  // Check if user is guest
  if (_isGuestUser) {
    _showLoginPrompt('marcar favoritos');
    return;
  }
  
  // Try to get fresh token if current one is invalid
  if (_authToken == null || _authToken!.isEmpty) {
    final tokenResult = await widget.authRepository.getAuthToken();
    _authToken = tokenResult.fold(
      (failure) {
        _showErrorSnackbar('Error de autenticación. Inicia sesión nuevamente.');
        return null;
      },
      (token) => token,
    );
    
    // If still no token, show error and return
    if (_authToken == null || _authToken!.isEmpty) {
      _showErrorSnackbar('Necesitas iniciar sesión para marcar favoritos');
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
  }

  // Show optimistic UI update
  final originalFavoritedState = emprendimiento.isFavoritedByUser;
  
  try {
    // Update UI optimistically (before API call)
    setState(() {
      final index = _searchState.allEmprendimientos
          .indexWhere((e) => e.id == emprendimiento.id);
      
      if (index != -1) {
        _searchState.allEmprendimientos[index] =
            _searchState.allEmprendimientos[index].copyWith(
          isFavoritedByUser: !_searchState.allEmprendimientos[index].isFavoritedByUser,
        );
      }
      _filterEmprendimientos();
    });

    // Make API call
    final success = await _repository.toggleLike(
      emprendimiento.id,
      _authToken!,
    );

    if (!success) {
      // Revert if API call failed
      if (mounted) {
        setState(() {
          final index = _searchState.allEmprendimientos
              .indexWhere((e) => e.id == emprendimiento.id);
          
          if (index != -1) {
            _searchState.allEmprendimientos[index] =
                _searchState.allEmprendimientos[index].copyWith(
              isFavoritedByUser: originalFavoritedState,
            );
          }
          _filterEmprendimientos();
        });
      }
      _showErrorSnackbar('Error al actualizar favoritos');
    } else {
      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  originalFavoritedState ? Icons.favorite_border : Icons.favorite,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  originalFavoritedState 
                    ? 'Removido de favoritos' 
                    : 'Agregado a favoritos',
                ),
              ],
            ),
            backgroundColor: originalFavoritedState ? Colors.grey[700] : Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  } catch (e) {
    // Revert on exception
    if (mounted) {
      setState(() {
        final index = _searchState.allEmprendimientos
            .indexWhere((e) => e.id == emprendimiento.id);
        
        if (index != -1) {
          _searchState.allEmprendimientos[index] =
              _searchState.allEmprendimientos[index].copyWith(
            isFavoritedByUser: originalFavoritedState,
          );
        }
        _filterEmprendimientos();
      });
    }
    
    // Handle specific error cases
    final errorMessage = e.toString().toLowerCase();
    
    if (errorMessage.contains('token') || 
        errorMessage.contains('401') || 
        errorMessage.contains('unauthorized') ||
        errorMessage.contains('autenticación')) {
      
      _showErrorSnackbar('Sesión expirada. Por favor inicia sesión nuevamente.');
      
      // Clear the invalid token
      _authToken = null;
      
      // Optional: Auto logout and redirect to login
      await widget.authRepository.logout();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      _showErrorSnackbar('Error al actualizar favoritos: ${e.toString()}');
    }
  }
}
}

// MARK: - State Management Classes
class SearchState {
  List<Emprendimiento> allEmprendimientos = [];
  List<Emprendimiento> filteredEmprendimientos = [];
  List<String> searchHistory = [];
  String currentQuery = '';
  bool isLoading = true;
  bool showHistory = false;
}

class FilterState {
  List<String> parroquias = [];
  Set<String> categories = {};
  String selectedCategory = 'Todas';
  Set<String> selectedParroquias = {};
  String sortBy = 'categoria';
  double? maxPrice;

  bool get hasActiveFilters =>
      selectedParroquias.isNotEmpty ||
      selectedCategory != 'Todas' ||
      maxPrice != null;

  FilterState copy() {
    return FilterState()
      ..parroquias = List.from(parroquias)
      ..categories = Set.from(categories)
      ..selectedCategory = selectedCategory
      ..selectedParroquias = Set.from(selectedParroquias)
      ..sortBy = sortBy
      ..maxPrice = maxPrice;
  }

  void updateFrom(FilterState other) {
    selectedCategory = other.selectedCategory;
    selectedParroquias = other.selectedParroquias;
    sortBy = other.sortBy;
    maxPrice = other.maxPrice;
  }

  void reset() {
    selectedCategory = 'Todas';
    selectedParroquias.clear();
    sortBy = 'categoria';
    maxPrice = null;
  }
}
