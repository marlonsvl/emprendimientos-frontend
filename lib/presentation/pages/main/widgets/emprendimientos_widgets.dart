import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../data/models/emprendimiento_model.dart';

// MARK: - Sliver AppBar Widget
class SliverAppBarWidget extends StatelessWidget {
  final AnimationController animation;
  final VoidCallback onRefresh;
  final VoidCallback onFilterPressed;
  final VoidCallback onLogoutPressed;
  final VoidCallback onDeleteAccountPressed;
  final bool hasActiveFilters;
  final bool isGuest;

  const SliverAppBarWidget({super.key, 
    required this.animation,
    required this.onRefresh,
    required this.onFilterPressed,
    required this.onLogoutPressed,
    required this.onDeleteAccountPressed,
    required this.hasActiveFilters,
    required this.isGuest,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: true,
      pinned: true,
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.surface,

      title: null,
      
      flexibleSpace: FlexibleSpaceBar(
          background: Container(
            decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withValues(alpha: 0.3),
                Theme.of(context).colorScheme.surface,
              ],
            ),
          ),
            child: Align(
            // Align to the bottom-left for a clean expanded header look
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                'Emprendimientos Gastronómicos',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                maxLines: 2,
                overflow:  TextOverflow.ellipsis,
              ),
            ),
        
        ),
          ),
      ),
        
      actions: [
        
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: onRefresh,
          tooltip: 'Actualizar',
        ),
        IconButton(
          icon: Badge(
            isLabelVisible: hasActiveFilters,
            child: const Icon(Icons.filter_list),
          ),
          onPressed: onFilterPressed,
          tooltip: 'Filtros',
        ),
        if (isGuest)
          IconButton(
            onPressed: onLogoutPressed,
            icon: const Icon(Icons.exit_to_app),
            tooltip: 'Salir',
          )
        else
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') onLogoutPressed();
              if (value == 'delete') onDeleteAccountPressed();
            },
            icon: const Icon(Icons.more_vert), // The "three dots" menu
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Cerrar sesión'),
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_forever, color: Colors.red),
                  title: Text('Eliminar cuenta', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        
      ],
    );
  }
}

// MARK: - Search Section Widget
class SearchSectionWidget extends StatelessWidget {
  final TextEditingController controller;
  final AnimationController animation;
  final String currentQuery;
  final bool showHistory;
  final List<String> searchHistory;
  final ValueChanged<String> onHistoryTap;
  final VoidCallback onHistoryClear;
  final ValueChanged<String> onHistoryDelete;
  final ValueChanged<String> onSubmitted;

  const SearchSectionWidget({super.key, 
    required this.controller,
    required this.animation,
    required this.currentQuery,
    required this.showHistory,
    required this.searchHistory,
    required this.onHistoryTap,
    required this.onHistoryClear,
    required this.onHistoryDelete,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.5),
          end: Offset.zero,
        ).animate(animation),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Semantics(
                label: 'Campo de búsqueda de emprendimientos',
                child: Container(
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
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Buscar emprendimientos...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: currentQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                              },
                              tooltip: 'Limpiar búsqueda',
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                    ),
                    onSubmitted: onSubmitted,
                  ),
                ),
              ),
              if (showHistory && searchHistory.isNotEmpty)
                _SearchHistoryWidget(
                  searchHistory: searchHistory,
                  onTap: onHistoryTap,
                  onClear: onHistoryClear,
                  onDelete: onHistoryDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// MARK: - Search History Widget
class _SearchHistoryWidget extends StatelessWidget {
  final List<String> searchHistory;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;
  final ValueChanged<String> onDelete;

  const _SearchHistoryWidget({
    required this.searchHistory,
    required this.onTap,
    required this.onClear,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
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
                onPressed: onClear,
                child: const Text('Limpiar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: searchHistory.take(5).map((term) {
              return GestureDetector(
                onTap: () => onTap(term),
                child: Chip(
                  label: Text(term),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () => onDelete(term),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// MARK: - Filter Tabs Widget
class FilterTabsWidget extends StatelessWidget {
  final TabController controller;

  const FilterTabsWidget({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: TabBar(
          controller: controller,
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
}

// MARK: - Loading State Widget
class LoadingStateWidget extends StatelessWidget {
  const LoadingStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
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
}

// MARK: - Empty State Widget
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback onClearFilters;

  const EmptyStateWidget({
    super.key,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda o ajusta los filtros',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all),
              label: const Text('Limpiar filtros'),
            ),
          ],
        ),
      ),
    );
  }
}

// MARK: - Empty Favorites Widget
class EmptyFavoritesWidget extends StatelessWidget {
  const EmptyFavoritesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
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
    );
  }
}

// MARK: - Emprendimiento Card Widget
class EmprendimientoCard extends StatelessWidget {
  final Emprendimiento emprendimiento;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;

  const EmprendimientoCard({
    super.key,
    required this.emprendimiento,
    required this.onTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildImage(context),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      child: Stack(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CachedNetworkImage(
              imageUrl: emprendimiento.photoUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.grey[300],
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey[300],
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
              ),
            ),
          ),
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: CategoryHelper.getColor(emprendimiento.categoria)
                    .withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                CategoryHelper.formatDisplay(
                  emprendimiento.categoryDisplayName,
                ),
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
                  emprendimiento.isFavoritedByUser
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: emprendimiento.isFavoritedByUser
                      ? Colors.red
                      : Colors.white,
                ),
                onPressed: onFavoriteToggle,
                tooltip: emprendimiento.isFavoritedByUser
                    ? 'Quitar de favoritos'
                    : 'Agregar a favoritos',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          _buildLocation(context),
          const SizedBox(height: 12),
          _buildDescription(context),
          const SizedBox(height: 12),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
        /*Column(
          children: [
            RatingStarsWidget(rating: emprendimiento.averageRating),
            Text(
              '${emprendimiento.averageRating.toStringAsFixed(1)} (${emprendimiento.ratingCount})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),*/
      ],
    );
  }

  Widget _buildLocation(BuildContext context) {
    return Row(
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
            emprendimiento.tipo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      emprendimiento.oferta,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
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
        ] else
          const Spacer(),
        SocialStatWidget(icon: Icons.favorite, count: emprendimiento.likesCount),
        const SizedBox(width: 16),
        SocialStatWidget(icon: Icons.comment, count: emprendimiento.commentsCount),
      ],
    );
  }
}

// MARK: - Rating Stars Widget
class RatingStarsWidget extends StatelessWidget {
  final double rating;

  const RatingStarsWidget({super.key, required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor()
              ? Icons.star
              : index < rating
                  ? Icons.star_half
                  : Icons.star_border,
          size: 16,
          color: Colors.amber,
        );
      }),
    );
  }
}

// MARK: - Social Stat Widget
class SocialStatWidget extends StatelessWidget {
  final IconData icon;
  final int count;

  const SocialStatWidget({
    super.key,
    required this.icon,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
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
}

// MARK: - Category Helper
class CategoryHelper {
  static String formatDisplay(String categoria) {
    const starRatings = {
      '3 estrellas': '⭐⭐⭐',
      '2 estrellas': '⭐⭐',
      '1 estrella': '⭐',
    };

    final lowerCategoria = categoria.toLowerCase();
    return starRatings[lowerCategoria] ?? categoria;
  }

  static Color getColor(String categoria) {
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
      default:
        return Colors.grey;
    }
  }
}