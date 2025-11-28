import '../../data/models/emprendimiento_model.dart';
import '../../data/datasources/remote/emprendimientos_remote_datasource.dart';
import '../../data/datasources/local/emprendimientos_local_datasource.dart';

class EmprendimientosRepository {
  final EmprendimientosRemoteDataSource remoteDataSource;
  final EmprendimientosLocalDataSource localDataSource;

  EmprendimientosRepository({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  Future<List<Emprendimiento>> getEmprendimientos({
    String? search,
    String? categoria,
    String? parroquia,
    String? sector,
    String? ordenarPor,
    double? precio, 
    int? page,
    int? pageSize,
    String? token, // Make sure this is being used
    bool forceRefresh = false,
  }) async {
    try {
      // If no token provided, try to get it from local storage
      String? authToken = token;
      if (authToken == null || authToken.isEmpty) {
        // You might want to get it from local datasource
        //authToken = await localDataSource.getAuthToken();
      }

      // Try to get from cache first if no specific search/filter and not forcing refresh
      if (!forceRefresh && 
          (search == null || search.isEmpty) && 
          categoria == null && 
          parroquia == null && 
          sector == null && 
          precio == null) {
        final cachedEmprendimientos = await localDataSource.getCachedEmprendimientos();
        if (cachedEmprendimientos != null) {
          return _sortEmprendimientos(cachedEmprendimientos, ordenarPor);
        }
      }

      // Get from remote - ALWAYS pass the token
      final emprendimientos = await remoteDataSource.getEmprendimientos(
        search: search,
        categoria: categoria,
        parroquia: parroquia,
        sector: sector,
        ordenarPor: ordenarPor,
        precio: precio,
        page: page,
        pageSize: pageSize,
        token: authToken, // Ensure this is passed
      );

      // Cache the results if it's a general request (no specific filters)
      if ((search == null || search.isEmpty) && 
          categoria == null && 
          parroquia == null && 
          sector == null) {
        await localDataSource.cacheEmprendimientos(emprendimientos);
      }

      return emprendimientos;
    } catch (e) {
      // If remote fails and we have cache, return cache
      if (e is NetworkException) {
        final cachedEmprendimientos = await localDataSource.getCachedEmprendimientos();
        if (cachedEmprendimientos != null) {
          return _sortEmprendimientos(cachedEmprendimientos, ordenarPor);
        }
      }
      rethrow;
    }
  }

  Future<Emprendimiento> getEmprendimientoById(int id, {String? token}) async {
    try {
      // Try cache first
      final cached = await localDataSource.getCachedEmprendimiento(id);
      
      try {
        // Always try to get fresh data with token
        final emprendimiento = await remoteDataSource.getEmprendimientoById(id, token: token);
        // Cache the fresh data
        await localDataSource.cacheEmprendimiento(emprendimiento);
        return emprendimiento;
      } catch (e) {
        // If remote fails but we have cache, return cache
        if (e is NetworkException && cached != null) {
          return cached;
        }
        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> toggleLike(int id, String token) async {
    try {
      // Get current emprendimiento to check like status
      final emprendimiento = await getEmprendimientoById(id, token: token);
      
      bool success;
      if (emprendimiento.isFavoritedByUser) {
        success = await remoteDataSource.unlikeEmprendimiento(id, token);
        if (success) {
          await localDataSource.removeFromFavorites(id);
        }
      } else {
        success = await remoteDataSource.likeEmprendimiento(id, token);
        if (success) {
          await localDataSource.addToFavorites(id);
        }
      }
      
      return success;
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> rateEmprendimiento(int id, int rating, String token) async {
    try {
      return await remoteDataSource.rateEmprendimiento(id, rating, token);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> addComment(int id, String comment, String token) async {
    try {
      return await remoteDataSource.addComment(id, comment, token);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> getParroquias() async {
    try {
      return await remoteDataSource.getParroquias();
    } catch (e) {
      rethrow;
    }
  }

  // Local operations
  Future<List<int>> getFavorites() async {
    return await localDataSource.getFavorites();
  }

  Future<bool> isFavorite(int id) async {
    return await localDataSource.isFavorite(id);
  }

  Future<List<String>> getSearchHistory() async {
    return await localDataSource.getSearchHistory();
  }

  Future<bool> addToSearchHistory(String searchTerm) async {
    return await localDataSource.addToSearchHistory(searchTerm);
  }

  Future<bool> clearSearchHistory() async {
    return await localDataSource.clearSearchHistory();
  }

  Future<bool> saveFilterPreferences({
    String? categoria,
    String? parroquia,
    String? ordenarPor,
  }) async {
    return await localDataSource.saveFilterPreferences(
      categoria: categoria,
      parroquia: parroquia,
      ordenarPor: ordenarPor,
    );
  }

  Future<Map<String, String?>> getFilterPreferences() async {
    return await localDataSource.getFilterPreferences();
  }

  Future<bool> clearCache() async {
    return await localDataSource.clearCache();
  }

  // Helper method to sort emprendimientos
  List<Emprendimiento> _sortEmprendimientos(
    List<Emprendimiento> emprendimientos,
    String? ordenarPor,
  ) {
    final sortedList = List<Emprendimiento>.from(emprendimientos);

    switch (ordenarPor) {
      case 'rating':
      case '-average_rating':
        sortedList.sort((a, b) => b.averageRating.compareTo(a.averageRating));
        break;
      case 'likes':
      case '-likes_count':
        sortedList.sort((a, b) => b.likesCount.compareTo(a.likesCount));
        break;
      case 'categoria':
      case '-categoria':
        sortedList.sort((a, b) => b.categoryPriority.compareTo(a.categoryPriority));
        break;
      case 'precio':
      case 'precio_promedio':
        sortedList.sort((a, b) => a.precioPromedio.compareTo(b.precioPromedio));
        break;
      case '-precio':
      case '-precio_promedio':
        sortedList.sort((a, b) => b.precioPromedio.compareTo(a.precioPromedio));
        break;
      case 'nombre':
        sortedList.sort((a, b) => a.nombre.compareTo(b.nombre));
        break;
      case '-nombre':
        sortedList.sort((a, b) => b.nombre.compareTo(a.nombre));
        break;
      default:
        // Default sorting: by category priority first, then by rating
        sortedList.sort((a, b) {
          final categoryComparison = b.categoryPriority.compareTo(a.categoryPriority);
          if (categoryComparison != 0) return categoryComparison;
          return b.averageRating.compareTo(a.averageRating);
        });
    }

    return sortedList;
  }

  // Search emprendimientos with intelligent filtering
  List<Emprendimiento> searchEmprendimientos(
    List<Emprendimiento> emprendimientos,
    String query,
  ) {
    if (query.isEmpty) return emprendimientos;

    final queryLower = query.toLowerCase();
    
    return emprendimientos.where((emprendimiento) {
      return emprendimiento.nombre.toLowerCase().contains(queryLower) ||
             emprendimiento.propietario.toLowerCase().contains(queryLower) ||
             emprendimiento.parroquia.toLowerCase().contains(queryLower) ||
             emprendimiento.sector.toLowerCase().contains(queryLower) ||
             emprendimiento.tipoTurismo.toLowerCase().contains(queryLower) ||
             emprendimiento.oferta.toLowerCase().contains(queryLower) ||
             emprendimiento.categoria.toLowerCase().contains(queryLower) ||
             emprendimiento.tipoServicio.toLowerCase().contains(queryLower);
    }).toList();
  }

  // Filter emprendimientos by category
  List<Emprendimiento> filterByCategory(
    List<Emprendimiento> emprendimientos,
    String categoria,
  ) {
    if (categoria.isEmpty || categoria == 'Todas') return emprendimientos;
    
    return emprendimientos.where((emprendimiento) {
      return emprendimiento.categoria.toLowerCase() == categoria.toLowerCase();
    }).toList();
  }

  // Filter emprendimientos by parroquia
  List<Emprendimiento> filterByParroquia(
    List<Emprendimiento> emprendimientos,
    String parroquia,
  ) {
    if (parroquia.isEmpty || parroquia == 'Todas') return emprendimientos;
    
    return emprendimientos.where((emprendimiento) {
      return emprendimiento.parroquia.toLowerCase() == parroquia.toLowerCase();
    }).toList();
  }

  // Get emprendimientos by category priority (like Michelin stars)
  List<Emprendimiento> getEmprendimientosByCategory() {
    return []; // This will be populated from the main list
  }

  // Get unique categories from emprendimientos
  Set<String> getUniqueCategories(List<Emprendimiento> emprendimientos) {
    return emprendimientos.map((e) => e.categoria).where((c) => c.isNotEmpty).toSet();
  }

  // Get unique parroquias from emprendimientos
  Set<String> getUniqueParroquias(List<Emprendimiento> emprendimientos) {
    return emprendimientos.map((e) => e.parroquia).where((p) => p.isNotEmpty).toSet();
  }
}