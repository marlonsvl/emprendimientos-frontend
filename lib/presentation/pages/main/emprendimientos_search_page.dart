/*import 'dart:async';

import 'package:emprendegastroloja/core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import '../../../data/models/emprendimiento_model.dart';
import '../../../data/datasources/remote/emprendimientos_remote_datasource.dart';
import '../../../data/datasources/local/emprendimientos_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/emprendimientos_repository.dart';
import 'emprendimiento_detail_page.dart';
import 'package:emprendegastroloja/domain/repositories/auth_repository.dart';

class EmprendimientosSearchPage extends StatefulWidget {
  final AuthRepository authRepository;
  
  const EmprendimientosSearchPage({
    Key? key,
    required this.authRepository,
  }) : super(key: key);

  @override
  State<EmprendimientosSearchPage> createState() => _EmprendimientosSearchPageState();
}

class _EmprendimientosSearchPageState extends State<EmprendimientosSearchPage>
    with TickerProviderStateMixin {
  late EmprendimientosRepository _repository;
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<double> _searchAnimation;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Emprendimiento> _allEmprendimientos = [];
  List<Emprendimiento> _filteredEmprendimientos = [];
  List<String> _searchHistory = [];
  List<String> _parroquias = [];
  Set<String> _categories = {};
  
  bool _isLoading = true;
  bool _showSearchHistory = false;
  String _selectedCategory = 'Todas';
  Set<String> _selectedParroquias = {}; // Changed to Set for multiple selection
  String _sortBy = 'categoria';
  String _currentQuery = '';
  String? _authToken;
  double? _maxPrice; 
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _initializeRepository();
    _setupControllers();
    _loadData();
  }

  Future<void> _initializeRepository() async {
    final prefs = await SharedPreferences.getInstance();
    
    final tokenResult = await widget.authRepository.getAuthToken();
    _authToken = tokenResult.fold(
      (failure) {
        print('Failed to get auth token: ${failure.toString()}');
        return null;
      },
      (token) => token,
    );
    
    _repository = EmprendimientosRepository(
      remoteDataSource: EmprendimientosRemoteDataSource(
        baseUrl: ApiConstants.baseUrl,
      ),
      localDataSource: EmprendimientosLocalDataSource(sharedPreferences: prefs),
    );
  }

  void _setupControllers() {
    _tabController = TabController(length: 3, vsync: this);
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.easeOut),
    );
    
    _searchAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _searchAnimationController, curve: Curves.easeInOut),
    );

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    Future.delayed(const Duration(milliseconds: 500), () {
      _fabAnimationController.forward();
      _searchAnimationController.forward();
    });
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
          _currentQuery = _searchController.text;
          _showSearchHistory = _searchController.text.isEmpty;
          _filterEmprendimientos();
        });
      });
    setState(() {
      _showSearchHistory = _searchController.text.isEmpty;
    });

  }

  void _onScroll() {
    if (_scrollController.offset < 100 && !_fabAnimationController.isDismissed) {
      _fabAnimationController.reverse();
    } else if (_scrollController.offset > 100 && !_fabAnimationController.isCompleted) {
      _fabAnimationController.forward();
    }
  }

  
  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final isSignedIn = await widget.authRepository.isSignedIn();
      if (!isSignedIn) {
        _showErrorSnackbar('No estás autenticado. Por favor, inicia sesión.');
        return;
      }

      if (_authToken == null || _authToken!.isEmpty) {
        final tokenResult = await widget.authRepository.getAuthToken();
        _authToken = tokenResult.fold(
          (failure) => null,
          (token) => token,
        );
        
        if (_authToken == null || _authToken!.isEmpty) {
          _showErrorSnackbar('Error de autenticación. Por favor, inicia sesión nuevamente.');
          return;
        }
      }
      
      // Load filter preferences
      final preferences = await _repository.getFilterPreferences();
      _selectedCategory = preferences['categoria'] ?? 'Todas';
      
      // Load multiple parroquias from preferences
      final savedParroquias = preferences['parroquia'] ?? 'Todas';
      if (savedParroquias != 'Todas' && savedParroquias.isNotEmpty) {
        _selectedParroquias = savedParroquias.split(',').toSet();
      } else {
        _selectedParroquias.clear();
      }
      
      _sortBy = preferences['ordenar_por'] ?? 'categoria';

      _searchHistory = await _repository.getSearchHistory();
      
      // First, load ALL parroquias from the backend (without filters)
      // This ensures we always have the complete list
      try {
        _parroquias = await _repository.getParroquias();
      } catch (e) {
        // If getParroquias fails, fetch all emprendimientos first to extract parroquias
        final allData = await _repository.getEmprendimientos(
          ordenarPor: _sortBy,
          token: _authToken,
          forceRefresh: false,
        );
        _parroquias = _repository.getUniqueParroquias(allData).toList();
      }
      
      // Now load filtered emprendimientos based on saved preferences
      _allEmprendimientos = await _repository.getEmprendimientos(
        ordenarPor: _sortBy,
        token: _authToken,
        categoria: _selectedCategory != 'Todas' ? _selectedCategory : null,
        parroquia: _selectedParroquias.isNotEmpty ? _selectedParroquias.join(',') : null,
        forceRefresh: true,
      );
      
      _categories = _repository.getUniqueCategories(_allEmprendimientos);
      _filterEmprendimientos();
      
    } catch (e) {
      String errorMessage = 'Error al cargar los datos: $e';
      if (e.toString().contains('No autorizado') || e.toString().contains('401')) {
        errorMessage = 'Sesión expirada. Por favor, inicia sesión nuevamente.';
        await widget.authRepository.logout();
      }
      _showErrorSnackbar(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterEmprendimientos() {
    var filtered = List<Emprendimiento>.from(_allEmprendimientos);
    
    if (_currentQuery.isNotEmpty) {
      filtered = _repository.searchEmprendimientos(filtered, _currentQuery);
    }
    
    if (_selectedCategory != 'Todas') {
      filtered = _repository.filterByCategory(filtered, _selectedCategory);
    }
    
    // Filter by multiple parroquias (client-side as backup)
    if (_selectedParroquias.isNotEmpty) {
      filtered = filtered.where((e) => _selectedParroquias.contains(e.parroquia)).toList();
    }
    
    // Filter by max price
    if (_maxPrice != null) {
      filtered = filtered.where((e) => e.precioPromedio <= _maxPrice!).toList();
    }
    
    setState(() {
      _filteredEmprendimientos = filtered;
    });
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          action: message.contains('inicia sesión') ? SnackBarAction(
            label: 'Iniciar Sesión',
            onPressed: () {},
          ) : null,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
            _buildSearchSection(),
            if (!_isLoading) _buildFilterTabs(),
          ];
        },
        body: _buildBody(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,
      flexibleSpace: FlexibleSpaceBar(
        title: FadeTransition(
          opacity: _searchAnimation,
          child: Text(
            'Emprendimientos Gastronómicos',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadData(),
        ),
        IconButton(
          icon: Badge(
            isLabelVisible: _selectedParroquias.isNotEmpty || _selectedCategory != 'Todas' || _maxPrice != null,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: _showFilterDialog,
        ),
        IconButton(
          onPressed: _showLogoutDialog, 
          icon: const Icon(Icons.logout)
        ),
      ],
    );
  }

  Widget _buildSearchSection() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(_searchAnimation),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar emprendimientos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _currentQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      _repository.addToSearchHistory(value);
                    }
                  },
                ),
              ),
              
              if (_showSearchHistory && _searchHistory.isNotEmpty)
                _buildSearchHistory(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Búsquedas recientes',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton(
                onPressed: () {
                  _repository.clearSearchHistory();
                  setState(() => _searchHistory.clear());
                },
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _searchHistory.take(5).map((term) {
              return GestureDetector(
                onTap: () {
                  _searchController.text = term;
                  _onSearchChanged();
                  setState(() => _showSearchHistory = false);
                },
                child: Chip(
                  label: Text(term),
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () {
                    setState(() => _searchHistory.remove(term));
                  },
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Todos', icon: Icon(Icons.restaurant)),
            Tab(text: 'Premium', icon: Icon(Icons.star)),
            Tab(text: 'Favoritos', icon: Icon(Icons.favorite)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildEmprendimientosList(_filteredEmprendimientos),
        _buildEmprendimientosList(_getPremiumEmprendimientos()),
        _buildFavoritesList(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Cargando emprendimientos...',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  Widget _buildEmprendimientosList(List<Emprendimiento> emprendimientos) {
    if (emprendimientos.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: emprendimientos.length,
        itemBuilder: (context, index) {
          return _buildEmprendimientoCard(emprendimientos[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron emprendimientos',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Intenta con otros términos de búsqueda',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _selectedCategory = 'Todas';
                _selectedParroquias.clear();
                _maxPrice = null;
                _loadData(); // Reload data without filters
              });
            },
            child: const Text('Limpiar filtros'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmprendimientoCard(Emprendimiento emprendimiento) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToDetail(emprendimiento),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                    ),
                    child: Image.network(
                      emprendimiento.photoUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.restaurant,
                                size: 48,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Imagen no disponible',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
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
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(emprendimiento.categoria).withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatCategoryDisplay(emprendimiento.categoryDisplayName),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        icon: Icon(
                          emprendimiento.isFavoritedByUser ? Icons.favorite : Icons.favorite_border,
                          color: emprendimiento.isFavoritedByUser ? Colors.red : Colors.white,
                        ),
                        onPressed: () => _toggleFavorite(emprendimiento),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              emprendimiento.nombre,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              emprendimiento.propietario,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          _buildRatingStars(emprendimiento.averageRating),
                          Text(
                            '${emprendimiento.averageRating.toStringAsFixed(1)} (${emprendimiento.ratingCount})',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
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
                          '${emprendimiento.parroquia} • ${emprendimiento.sector}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          emprendimiento.tipoTurismo,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Text(
                    emprendimiento.oferta,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      if (emprendimiento.precioPromedio > 0) ...[
                        Icon(
                          Icons.attach_money,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        Text(
                          '\$${emprendimiento.precioPromedio.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                      ] else const Spacer(),
                      
                      _buildSocialStat(Icons.favorite, emprendimiento.likesCount),
                      const SizedBox(width: 16),
                      _buildSocialStat(Icons.comment, emprendimiento.commentsCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? Icons.star : 
          index < rating ? Icons.star_half : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }

  Widget _buildSocialStat(IconData icon, int count) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _formatCategoryDisplay(String categoria) {
    // Convert text ratings to star symbols
    final starRatings = {
      //'5 estrellas': '⭐⭐⭐⭐⭐',
      //'4 estrellas': '⭐⭐⭐⭐',
      '3 estrellas': '⭐⭐⭐',
      '2 estrellas': '⭐⭐',
      '1 estrella': '⭐',
    };
    
    final lowerCategoria = categoria.toLowerCase();
    
    // Check if it's a star rating
    for (var entry in starRatings.entries) {
      if (lowerCategoria == entry.key) {
        return entry.value;
      }
    }
    
    // Return original if not a star rating
    return categoria;
  }

  Color _getCategoryColor(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'premium':
      case 'gold':
      case '3 estrellas':
        return Colors.amber;
      case 'platinum':
      case '2 estrellas':
        return Colors.purple;
      case 'silver':
      case '1 estrella':
        return Colors.blueGrey;
      case 'bronze':
      //case '2 estrellas':
      //  return Colors.orange;
      //case 'basic':
      //case '1 estrellas':
      //  return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Emprendimiento> _getPremiumEmprendimientos() {
    return _filteredEmprendimientos
        .where((e) => e.categoryPriority == 3)
        .toList();
  }

  Widget _buildFavoritesList() {
    final favorites = _filteredEmprendimientos
        .where((e) => e.isFavoritedByUser)
        .toList();
    
    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No tienes favoritos',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Marca tus emprendimientos favoritos',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    return _buildEmprendimientosList(favorites);
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: _fabAnimation,
      child: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.keyboard_arrow_up),
      ),
    );
  }

  void _showFilterDialog() {
    // Create temporary state variables for the dialog
    String tempSelectedCategory = _selectedCategory;
    Set<String> tempSelectedParroquias = Set.from(_selectedParroquias);
    String tempSortBy = _sortBy;
    double? tempMaxPrice = _maxPrice;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.outline,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Filtros',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () {
                                setModalState(() {
                                  tempSelectedCategory = 'Todas';
                                  tempSelectedParroquias.clear();
                                  tempSortBy = 'categoria';
                                  tempMaxPrice = null;
                                });
                              },
                              icon: const Icon(Icons.clear_all),
                              label: const Text('Limpiar todo'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Category Filter
                        _buildCategoryFilterSection(
                          tempSelectedCategory,
                          (value) {
                            setModalState(() {
                              tempSelectedCategory = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        // Multiple Parroquia Selection
                        _buildMultiParroquiaFilterSection(
                          tempSelectedParroquias,
                          (parroquia) {
                            setModalState(() {
                              if (tempSelectedParroquias.contains(parroquia)) {
                                tempSelectedParroquias.remove(parroquia);
                              } else {
                                tempSelectedParroquias.add(parroquia);
                              }
                            });
                          },
                          () {
                            setModalState(() {
                              tempSelectedParroquias.clear();
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        // Price Filter
                        _buildPriceFilterSection(
                          tempMaxPrice,
                          (value) {
                            setModalState(() {
                              tempMaxPrice = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 24),
                        
                        // Sort Section
                        _buildSortSection(
                          tempSortBy,
                          (value) {
                            setModalState(() {
                              tempSortBy = value;
                            });
                          },
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Cancelar'),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  // Apply filters and close dialog
                                  setState(() {
                                    _selectedCategory = tempSelectedCategory;
                                    _selectedParroquias = tempSelectedParroquias;
                                    _sortBy = tempSortBy;
                                    _maxPrice = tempMaxPrice;
                                  });
                                  
                                  // Save preferences
                                  _repository.saveFilterPreferences(
                                    categoria: _selectedCategory,
                                    parroquia: _selectedParroquias.isEmpty ? 'Todas' : _selectedParroquias.join(','),
                                    ordenarPor: _sortBy,
                                  );
                                  
                                  Navigator.pop(context);
                                  
                                  // Reload data with new filters
                                  _loadData();
                                },
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text('Aplicar Filtros'),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryFilterSection(
    String selectedValue,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Categoría',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['Todas', ..._categories.toList()].map((option) {
            final isSelected = option == selectedValue;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) => onChanged(option),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMultiParroquiaFilterSection(
    Set<String> selectedParroquias,
    ValueChanged<String> onToggle,
    VoidCallback onClear,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Parroquias',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (selectedParroquias.isNotEmpty)
              TextButton(
                onPressed: onClear,
                child: Text('Limpiar (${selectedParroquias.length})'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _parroquias.map((parroquia) {
            final isSelected = selectedParroquias.contains(parroquia);
            return FilterChip(
              label: Text(parroquia),
              selected: isSelected,
              onSelected: (selected) => onToggle(parroquia),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              selectedColor: Theme.of(context).colorScheme.secondaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.secondary,
              labelStyle: TextStyle(
                color: isSelected 
                    ? Theme.of(context).colorScheme.secondary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
        if (selectedParroquias.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${selectedParroquias.length} parroquia${selectedParroquias.length > 1 ? 's' : ''} seleccionada${selectedParroquias.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              
              // Show loading indicator
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
              
              try {
                // Perform logout
                await widget.authRepository.logout();
                
                // Close loading indicator
                if (mounted) Navigator.pop(context);
                
                // Navigate to login page
                // Replace '/login' with your actual login route
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                // Close loading indicator
                if (mounted) Navigator.pop(context);
                
                _showErrorSnackbar('Error al cerrar sesión: $e');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceFilterSection(
    double? maxPrice,
    ValueChanged<double?> onChanged,
  ) {
    // Calculate min and max prices from data
    final prices = _allEmprendimientos
        .where((e) => e.precioPromedio > 0)
        .map((e) => e.precioPromedio)
        .toList();
    
    if (prices.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPriceValue = prices.reduce((a, b) => a > b ? a : b);
    final currentMaxPrice = maxPrice ?? maxPriceValue;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.attach_money,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Precio máximo',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              currentMaxPrice.toStringAsFixed(2),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: currentMaxPrice,
          min: minPrice,
          max: maxPriceValue,
          divisions: 20,
          label: currentMaxPrice.toStringAsFixed(2),
          onChanged: (value) {
            onChanged(value);
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              minPrice.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              maxPriceValue.toStringAsFixed(2),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (maxPrice != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => onChanged(null),
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Quitar filtro de precio'),
          ),
        ],
      ],
    );
  }

  Widget _buildSortSection(
    String selectedSort,
    ValueChanged<String> onChanged,
  ) {
    final sortOptions = {
      'categoria': 'Categoría',
      'rating': 'Calificación',
      'likes': 'Popularidad',
      'precio_promedio': 'Precio (menor)',
      '-precio_promedio': 'Precio (mayor)',
      'nombre': 'Nombre A-Z',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.sort,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Ordenar por',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...sortOptions.entries.map((entry) {
          return RadioListTile<String>(
            title: Text(entry.value),
            value: entry.key,
            groupValue: selectedSort,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
      ],
    );
  }

  void _navigateToDetail(Emprendimiento emprendimiento) {
    Navigator.push(
      context, 
      MaterialPageRoute(
        builder: (context) => EmprendimientoDetailPage(
          emprendimiento: emprendimiento, 
          authRepository: widget.authRepository),
      ),
    );
  }

  Future<void> _toggleFavorite(Emprendimiento emprendimiento) async {
    if (_authToken == null || _authToken!.isEmpty) {
      _showErrorSnackbar('Necesitas iniciar sesión para marcar favoritos');
      return;
    }

    try {
      final success = await _repository.toggleLike(emprendimiento.id, _authToken!);
      
      if (success) {
        setState(() {
          final index = _allEmprendimientos.indexWhere((e) => e.id == emprendimiento.id);
          if (index != -1) {
            _allEmprendimientos[index] = _allEmprendimientos[index].copyWith(
              isFavoritedByUser: !_allEmprendimientos[index].isFavoritedByUser,
            );
          }
          _filterEmprendimientos();
        });
      } else {
        _showErrorSnackbar('Error al actualizar favoritos');
      }
    } catch (e) {
      _showErrorSnackbar('Error al actualizar favoritos: $e');
    }
  }
}

*/


/*
import 'dart:async';
import 'package:emprendegastroloja/core/constants/api_constants.dart';
import 'package:emprendegastroloja/presentation/pages/main/widgets/filter_bottom_sheet.dart';
import 'package:emprendegastroloja/presentation/pages/main/widgets/emprendimientos_widgets.dart';
import 'package:flutter/material.dart';
import '../../../data/models/emprendimiento_model.dart';
import '../../../data/datasources/remote/emprendimientos_remote_datasource.dart';
import '../../../data/datasources/local/emprendimientos_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/emprendimientos_repository.dart';
import 'emprendimiento_detail_page.dart';
import 'package:emprendegastroloja/domain/repositories/auth_repository.dart';

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
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // MARK: - State
  final _searchState = SearchState();
  final _filterState = FilterState();
  Timer? _debounce;
  
  @override
  bool get wantKeepAlive => true;

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
    _tabController = TabController(length: 3, vsync: this);
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    // Delayed animation start
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabAnimationController.forward();
        _searchAnimationController.forward();
      }
    });
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchState.currentQuery = _searchController.text;
          _searchState.showHistory = _searchController.text.isEmpty;
          _filterEmprendimientos();
        });
      }
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset < 100 && !_fabAnimationController.isDismissed) {
      _fabAnimationController.reverse();
    } else if (offset > 100 && !_fabAnimationController.isCompleted) {
      _fabAnimationController.forward();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() => _searchState.isLoading = true);

      // Auth check
      final isSignedIn = await widget.authRepository.isSignedIn();
      if (!isSignedIn) {
        _showErrorSnackbar('Por favor, inicia sesión para continuar.');
        return;
      }

      // Ensure token
      if (_authToken == null || _authToken!.isEmpty) {
        final tokenResult = await widget.authRepository.getAuthToken();
        _authToken = tokenResult.fold((failure) => null, (token) => token);
        
        if (_authToken == null || _authToken!.isEmpty) {
          _showErrorSnackbar('Error de autenticación. Inicia sesión nuevamente.');
          return;
        }
      }

      // Load preferences
      await _loadFilterPreferences();
      
      // Load search history
      _searchState.searchHistory = await _repository.getSearchHistory();

      // Load parroquias (all available)
      try {
        _filterState.parroquias = await _repository.getParroquias();
      } catch (e) {
        debugPrint('Error loading parroquias: $e');
        final allData = await _repository.getEmprendimientos(
          ordenarPor: _filterState.sortBy,
          token: _authToken,
          forceRefresh: false,
        );
        _filterState.parroquias = 
            _repository.getUniqueParroquias(allData).toList();
      }

      // Load emprendimientos with filters
      _searchState.allEmprendimientos = await _repository.getEmprendimientos(
        ordenarPor: _filterState.sortBy,
        token: _authToken,
        categoria: _filterState.selectedCategory != 'Todas' 
            ? _filterState.selectedCategory 
            : null,
        parroquia: _filterState.selectedParroquias.isNotEmpty 
            ? _filterState.selectedParroquias.join(',') 
            : null,
        forceRefresh: true,
      );

      _filterState.categories = 
          _repository.getUniqueCategories(_searchState.allEmprendimientos);
      
      _filterEmprendimientos();

    } catch (e) {
      String errorMessage = 'Error al cargar datos: $e';
      
      if (e.toString().contains('No autorizado') || 
          e.toString().contains('401')) {
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

    // Search filter
    if (_searchState.currentQuery.isNotEmpty) {
      filtered = _repository.searchEmprendimientos(
        filtered, 
        _searchState.currentQuery,
      );
    }

    // Category filter
    if (_filterState.selectedCategory != 'Todas') {
      filtered = _repository.filterByCategory(
        filtered, 
        _filterState.selectedCategory,
      );
    }

    // Parroquia filter
    if (_filterState.selectedParroquias.isNotEmpty) {
      filtered = filtered
          .where((e) => _filterState.selectedParroquias.contains(e.parroquia))
          .toList();
    }

    // Price filter
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
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: message.contains('inicia sesión')
            ? SnackBarAction(
                label: 'Iniciar Sesión',
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
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBarWidget(
            animation: _searchAnimationController,
            onRefresh: _loadData,
            onFilterPressed: _showFilterDialog,
            onLogoutPressed: _showLogoutDialog,
            hasActiveFilters: _filterState.hasActiveFilters,
          ),
          SearchSectionWidget(
            controller: _searchController,
            animation: _searchAnimationController,
            currentQuery: _searchState.currentQuery,
            showHistory: _searchState.showHistory,
            searchHistory: _searchState.searchHistory,
            onHistoryTap: (term) {
              _searchController.text = term;
              setState(() => _searchState.showHistory = false);
            },
            onHistoryClear: () {
              _repository.clearSearchHistory();
              setState(() => _searchState.searchHistory.clear());
            },
            onHistoryDelete: (term) {
              setState(() => _searchState.searchHistory.remove(term));
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _repository.addToSearchHistory(value);
              }
            },
          ),
          if (!_searchState.isLoading)
            FilterTabsWidget(controller: _tabController),
        ],
        body: _buildBody(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_searchState.isLoading) {
      return const LoadingStateWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildEmprendimientosList(_searchState.filteredEmprendimientos),
        _buildEmprendimientosList(_getPremiumEmprendimientos()),
        _buildFavoritesList(),
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
            _repository.clearSearchHistory();
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: emprendimientos.length,
        itemBuilder: (context, index) {
          return EmprendimientoCard(
            emprendimiento: emprendimientos[index],
            onTap: () => _navigateToDetail(emprendimientos[index]),
            onFavoriteToggle: () => _toggleFavorite(emprendimientos[index]),
          );
        },
      ),
    );
  }

  List<Emprendimiento> _getPremiumEmprendimientos() {
    return _searchState.filteredEmprendimientos
        .where((e) => e.categoryPriority == 3)
        .toList();
  }

  Widget _buildFavoritesList() {
    final favorites = _searchState.filteredEmprendimientos
        .where((e) => e.isFavoritedByUser)
        .toList();

    if (favorites.isEmpty) {
      return const Center(
        child: EmptyFavoritesWidget(),
      );
    }

    return _buildEmprendimientosList(favorites);
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.easeOut,
        ),
      ),
      child: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.keyboard_arrow_up),
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        filterState: _filterState.copy(),
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
          
          _loadData();
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await widget.authRepository.logout();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackbar('Error al cerrar sesión: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Emprendimiento emprendimiento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmprendimientoDetailPage(
          emprendimiento: emprendimiento,
          authRepository: widget.authRepository,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Emprendimiento emprendimiento) async {
    if (_authToken == null || _authToken!.isEmpty) {
      _showErrorSnackbar('Necesitas iniciar sesión para marcar favoritos');
      return;
    }

    try {
      final success = await _repository.toggleLike(
        emprendimiento.id,
        _authToken!,
      );

      if (success && mounted) {
        setState(() {
          final index = _searchState.allEmprendimientos
              .indexWhere((e) => e.id == emprendimiento.id);
          
          if (index != -1) {
            _searchState.allEmprendimientos[index] =
                _searchState.allEmprendimientos[index].copyWith(
              isFavoritedByUser: 
                  !_searchState.allEmprendimientos[index].isFavoritedByUser,
            );
          }
          _filterEmprendimientos();
        });
      } else if (!success) {
        _showErrorSnackbar('Error al actualizar favoritos');
      }
    } catch (e) {
      _showErrorSnackbar('Error al actualizar favoritos: $e');
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

*/

import 'dart:async';
import 'package:emprendegastroloja/core/constants/api_constants.dart';
import 'package:emprendegastroloja/presentation/pages/main/widgets/filter_bottom_sheet.dart';
import 'package:emprendegastroloja/presentation/pages/main/widgets/emprendimientos_widgets.dart';
import 'package:flutter/material.dart';
import '../../../data/models/emprendimiento_model.dart';
import '../../../data/datasources/remote/emprendimientos_remote_datasource.dart';
import '../../../data/datasources/local/emprendimientos_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../domain/repositories/emprendimientos_repository.dart';
import 'emprendimiento_detail_page.dart';
import 'package:emprendegastroloja/domain/repositories/auth_repository.dart';

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
  late TabController _tabController;
  late AnimationController _fabAnimationController;
  late AnimationController _searchAnimationController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // MARK: - State
  final _searchState = SearchState();
  final _filterState = FilterState();
  Timer? _debounce;
  int _currentTabIndex = 0; // Track current tab
  
  @override
  bool get wantKeepAlive => true;

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
    _tabController = TabController(length: 3, vsync: this);
    
    // Add tab change listener
    _tabController.addListener(_onTabChanged);
    
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _searchAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);

    // Delayed animation start
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fabAnimationController.forward();
        _searchAnimationController.forward();
      }
    });
  }

  // NEW: Handle tab changes
  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    
    final newIndex = _tabController.index;
    if (_currentTabIndex != newIndex) {
      _currentTabIndex = newIndex;
      
      // Reset filters when changing tabs to maintain consistency
      if (mounted) {
        setState(() {
          // Clear search
          _searchController.clear();
          _searchState.currentQuery = '';
          
          // Reset filters to show all data in the new tab
          _filterState.reset();
          
          // Recalculate filtered data for new tab
          _filterEmprendimientos();
        });
      }
    }
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchState.currentQuery = _searchController.text;
          _searchState.showHistory = _searchController.text.isEmpty;
          _filterEmprendimientos();
        });
      }
    });
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    if (offset < 100 && !_fabAnimationController.isDismissed) {
      _fabAnimationController.reverse();
    } else if (offset > 100 && !_fabAnimationController.isCompleted) {
      _fabAnimationController.forward();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    try {
      setState(() => _searchState.isLoading = true);

      // Auth check
      final isSignedIn = await widget.authRepository.isSignedIn();
      if (!isSignedIn) {
        _showErrorSnackbar('Por favor, inicia sesión para continuar.');
        return;
      }

      // Ensure token
      if (_authToken == null || _authToken!.isEmpty) {
        final tokenResult = await widget.authRepository.getAuthToken();
        _authToken = tokenResult.fold((failure) => null, (token) => token);
        
        if (_authToken == null || _authToken!.isEmpty) {
          _showErrorSnackbar('Error de autenticación. Inicia sesión nuevamente.');
          return;
        }
      }

      // Load preferences
      await _loadFilterPreferences();
      
      // Load search history
      _searchState.searchHistory = await _repository.getSearchHistory();

      // Load parroquias (all available) - ALWAYS from complete dataset
      try {
        _filterState.parroquias = await _repository.getParroquias();
      } catch (e) {
        debugPrint('Error loading parroquias: $e');
        // Fallback: load all data first
        final allData = await _repository.getEmprendimientos(
          ordenarPor: _filterState.sortBy,
          token: _authToken,
          forceRefresh: false,
        );
        _filterState.parroquias = 
            _repository.getUniqueParroquias(allData).toList();
      }

      // Load ALL emprendimientos without filters first
      // This ensures we always have the complete dataset
      final allData = await _repository.getEmprendimientos(
        ordenarPor: _filterState.sortBy,
        token: _authToken,
        forceRefresh: true,
      );

      _searchState.allEmprendimientos = allData;

      // IMPORTANT: Extract categories and parroquias from ALL data
      // not from filtered data
      _filterState.categories = 
          _repository.getUniqueCategories(_searchState.allEmprendimientos);
      
      // If parroquias weren't loaded above, get them from all data
      if (_filterState.parroquias.isEmpty) {
        _filterState.parroquias = 
            _repository.getUniqueParroquias(_searchState.allEmprendimientos)
                .toList();
      }

      // Now apply filters
      _filterEmprendimientos();

    } catch (e) {
      String errorMessage = 'Error al cargar datos: $e';
      
      if (e.toString().contains('No autorizado') || 
          e.toString().contains('401')) {
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

  // IMPROVED: Filter logic that works per tab
  void _filterEmprendimientos() {
    // Start with ALL emprendimientos
    var filtered = List<Emprendimiento>.from(_searchState.allEmprendimientos);

    // Apply search filter first
    if (_searchState.currentQuery.isNotEmpty) {
      filtered = _repository.searchEmprendimientos(
        filtered, 
        _searchState.currentQuery,
      );
    }

    // Apply category filter
    if (_filterState.selectedCategory != 'Todas') {
      filtered = _repository.filterByCategory(
        filtered, 
        _filterState.selectedCategory,
      );
    }

    // Apply parroquia filter
    if (_filterState.selectedParroquias.isNotEmpty) {
      filtered = filtered
          .where((e) => _filterState.selectedParroquias.contains(e.parroquia))
          .toList();
    }

    // Apply price filter
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
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: message.contains('inicia sesión')
            ? SnackBarAction(
                label: 'Iniciar Sesión',
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
    _tabController.removeListener(_onTabChanged); // Clean up listener
    _tabController.dispose();
    _fabAnimationController.dispose();
    _searchAnimationController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBarWidget(
            animation: _searchAnimationController,
            onRefresh: _loadData,
            onFilterPressed: _showFilterDialog,
            onLogoutPressed: _showLogoutDialog,
            hasActiveFilters: _filterState.hasActiveFilters,
          ),
          SearchSectionWidget(
            controller: _searchController,
            animation: _searchAnimationController,
            currentQuery: _searchState.currentQuery,
            showHistory: _searchState.showHistory,
            searchHistory: _searchState.searchHistory,
            onHistoryTap: (term) {
              _searchController.text = term;
              setState(() => _searchState.showHistory = false);
            },
            onHistoryClear: () {
              _repository.clearSearchHistory();
              setState(() => _searchState.searchHistory.clear());
            },
            onHistoryDelete: (term) {
              setState(() => _searchState.searchHistory.remove(term));
            },
            onSubmitted: (value) {
              if (value.isNotEmpty) {
                _repository.addToSearchHistory(value);
              }
            },
          ),
          if (!_searchState.isLoading)
            FilterTabsWidget(controller: _tabController),
        ],
        body: _buildBody(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildBody() {
    if (_searchState.isLoading) {
      return const LoadingStateWidget();
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildEmprendimientosList(_searchState.filteredEmprendimientos),
        _buildEmprendimientosList(_getPremiumEmprendimientos()),
        _buildFavoritesList(),
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
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: emprendimientos.length,
        itemBuilder: (context, index) {
          return EmprendimientoCard(
            emprendimiento: emprendimientos[index],
            onTap: () => _navigateToDetail(emprendimientos[index]),
            onFavoriteToggle: () => _toggleFavorite(emprendimientos[index]),
          );
        },
      ),
    );
  }

  // IMPROVED: Get premium from filtered results to respect current filters
  List<Emprendimiento> _getPremiumEmprendimientos() {
    return _searchState.filteredEmprendimientos
        .where((e) => e.categoryPriority == 3)
        .toList();
  }

  // IMPROVED: Get favorites from filtered results to respect current filters
  Widget _buildFavoritesList() {
    final favorites = _searchState.filteredEmprendimientos
        .where((e) => e.isFavoritedByUser)
        .toList();

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const EmptyFavoritesWidget(),
            if (_filterState.hasActiveFilters) ...[
              const SizedBox(height: 16),
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
              ),
            ],
          ],
        ),
      );
    }

    return _buildEmprendimientosList(favorites);
  }

  Widget _buildFloatingActionButton() {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _fabAnimationController,
          curve: Curves.easeOut,
        ),
      ),
      child: FloatingActionButton(
        onPressed: () {
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        },
        child: const Icon(Icons.keyboard_arrow_up),
      ),
    );
  }

  void _showFilterDialog() {
    // Create a copy with COMPLETE filter options (not from filtered data)
    final filterStateCopy = _filterState.copy();
    
    // Ensure we're passing the complete dataset for filter calculations
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        filterState: filterStateCopy,
        allEmprendimientos: _searchState.allEmprendimientos, // Complete dataset
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
          
          // Reapply filters with new state
          _filterEmprendimientos();
        },
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              try {
                await widget.authRepository.logout();
                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  _showErrorSnackbar('Error al cerrar sesión: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Emprendimiento emprendimiento) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmprendimientoDetailPage(
          emprendimiento: emprendimiento,
          authRepository: widget.authRepository,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite(Emprendimiento emprendimiento) async {
    if (_authToken == null || _authToken!.isEmpty) {
      _showErrorSnackbar('Necesitas iniciar sesión para marcar favoritos');
      return;
    }

    try {
      final success = await _repository.toggleLike(
        emprendimiento.id,
        _authToken!,
      );

      if (success && mounted) {
        setState(() {
          final index = _searchState.allEmprendimientos
              .indexWhere((e) => e.id == emprendimiento.id);
          
          if (index != -1) {
            _searchState.allEmprendimientos[index] =
                _searchState.allEmprendimientos[index].copyWith(
              isFavoritedByUser: 
                  !_searchState.allEmprendimientos[index].isFavoritedByUser,
            );
          }
          _filterEmprendimientos();
        });
      } else if (!success) {
        _showErrorSnackbar('Error al actualizar favoritos');
      }
    } catch (e) {
      _showErrorSnackbar('Error al actualizar favoritos: $e');
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
