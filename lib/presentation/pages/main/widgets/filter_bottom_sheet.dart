import 'package:flutter/material.dart';
import '../../../../data/models/emprendimiento_model.dart';
import '../emprendimientos_search_page.dart'; // For FilterState

class FilterBottomSheet extends StatefulWidget {
  final FilterState filterState;
  final List<Emprendimiento> allEmprendimientos;
  final ValueChanged<FilterState> onApply;

  const FilterBottomSheet({
    super.key,
    required this.filterState,
    required this.allEmprendimientos,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterState _tempState;

  @override
  void initState() {
    super.initState();
    _tempState = widget.filterState.copy();
  }

  @override
  Widget build(BuildContext context) {
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
                  _buildHandle(context),
                  const SizedBox(height: 24),
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildCategorySection(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildParroquiaSection(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildPriceSection(),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 24),
                  _buildSortSection(),
                  const SizedBox(height: 32),
                  _buildActionButtons(context),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHandle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outline,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
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
            setState(() {
              _tempState.reset();
            });
          },
          icon: const Icon(Icons.clear_all),
          label: const Text('Limpiar todo'),
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
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
          children: ['Todas', ..._tempState.categories.toList()].map((option) {
            final isSelected = option == _tempState.selectedCategory;
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _tempState.selectedCategory = option;
                });
              },
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
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

  Widget _buildParroquiaSection() {
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
            if (_tempState.selectedParroquias.isNotEmpty)
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempState.selectedParroquias.clear();
                  });
                },
                child: Text(
                    'Limpiar (${_tempState.selectedParroquias.length})'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _tempState.parroquias.map((parroquia) {
            final isSelected = _tempState.selectedParroquias.contains(parroquia);
            return FilterChip(
              label: Text(parroquia),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (isSelected) {
                    _tempState.selectedParroquias.remove(parroquia);
                  } else {
                    _tempState.selectedParroquias.add(parroquia);
                  }
                });
              },
              backgroundColor:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
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
        if (_tempState.selectedParroquias.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .secondaryContainer
                  .withValues(alpha: 0.3),
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
                    '${_tempState.selectedParroquias.length} parroquia${_tempState.selectedParroquias.length > 1 ? 's' : ''} seleccionada${_tempState.selectedParroquias.length > 1 ? 's' : ''}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSecondaryContainer,
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

  Widget _buildPriceSection() {
    final prices = widget.allEmprendimientos
        .where((e) => e.precioPromedio > 0)
        .map((e) => e.precioPromedio)
        .toList();

    if (prices.isEmpty) {
      return const SizedBox.shrink();
    }

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPriceValue = prices.reduce((a, b) => a > b ? a : b);
    final currentMaxPrice = _tempState.maxPrice ?? maxPriceValue;

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
              '\$${currentMaxPrice.toStringAsFixed(2)}',
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
          label: '\$${currentMaxPrice.toStringAsFixed(2)}',
          onChanged: (value) {
            setState(() {
              _tempState.maxPrice = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${minPrice.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            Text(
              '\$${maxPriceValue.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        if (_tempState.maxPrice != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _tempState.maxPrice = null;
              });
            },
            icon: const Icon(Icons.clear, size: 16),
            label: const Text('Quitar filtro de precio'),
          ),
        ],
      ],
    );
  }

  Widget _buildSortSection() {
    const sortOptions = {
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
            groupValue: _tempState.sortBy,
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _tempState.sortBy = value;
                });
              }
            },
            contentPadding: EdgeInsets.zero,
            dense: true,
          );
        }),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
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
              widget.onApply(_tempState);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Aplicar Filtros'),
          ),
        ),
      ],
    );
  }
}