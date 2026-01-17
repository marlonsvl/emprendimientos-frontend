import 'package:flutter/material.dart';
import '../../../../data/models/emprendimiento_model.dart';
import '../emprendimientos_search_page.dart'; // For FilterState

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
        color: Colors.white, 
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
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        gradient: BrandColors.gradient,
        borderRadius: BorderRadius.circular(2),
      ),
    ),
  );
}

  Widget _buildHeader(BuildContext context) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: BrandColors.gradient,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: BrandColors.goldenYellow.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.tune,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Filtros',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _tempState.reset();
            });
          },
          icon: const Icon(Icons.clear_all, color: Colors.white, size: 20),
          label: const Text(
            'Limpiar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          style: TextButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha:0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildSectionHeader(IconData icon, String title, {Widget? trailing}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16),
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
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
        ),
        if (trailing != null) trailing,
      ],
    ),
  );
}

  Widget _buildCategorySection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(Icons.category, 'Categoría'),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: ['Todas', ..._tempState.categories.toList()].map((option) {
          final isSelected = option == _tempState.selectedCategory;
          return InkWell(
            onTap: () {
              setState(() {
                _tempState.selectedCategory = option;
              });
            },
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? BrandColors.gradient : null,
                color: isSelected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey.shade300,
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: BrandColors.goldenYellow.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ] : null,
              ),
              child: Text(
                option,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
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
      _buildSectionHeader(
        Icons.location_on,
        'Parroquias',
        trailing: _tempState.selectedParroquias.isNotEmpty
          ? TextButton(
              onPressed: () {
                setState(() {
                  _tempState.selectedParroquias.clear();
                });
              },
              style: TextButton.styleFrom(
                foregroundColor: BrandColors.deepGold,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              ),
              child: Text(
                'Limpiar (${_tempState.selectedParroquias.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : null,
      ),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _tempState.parroquias.map((parroquia) {
          final isSelected = _tempState.selectedParroquias.contains(parroquia);
          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _tempState.selectedParroquias.remove(parroquia);
                } else {
                  _tempState.selectedParroquias.add(parroquia);
                }
              });
            },
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                  ? BrandColors.lightYellow.withValues(alpha:0.3)
                  : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: isSelected ? BrandColors.goldenYellow : Colors.grey.shade300,
                  width: isSelected ? 2 : 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: BrandColors.deepGold,
                      ),
                    ),
                  Text(
                    parroquia,
                    style: TextStyle(
                      color: isSelected ? BrandColors.deepGold : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
      if (_tempState.selectedParroquias.isNotEmpty) ...[
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                BrandColors.lightYellow.withValues(alpha:0.2),
                BrandColors.brightYellow.withValues(alpha:0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: BrandColors.goldenYellow.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: BrandColors.goldenYellow.withValues(alpha:0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 18,
                  color: BrandColors.deepGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_tempState.selectedParroquias.length} parroquia${_tempState.selectedParroquias.length > 1 ? 's' : ''} seleccionada${_tempState.selectedParroquias.length > 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: BrandColors.deepGold,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
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
      _buildSectionHeader(Icons.attach_money, 'Precio máximo'),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Hasta:',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: BrandColors.gradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${currentMaxPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: BrandColors.goldenYellow,
                inactiveTrackColor: Colors.grey.shade300,
                thumbColor: BrandColors.deepGold,
                overlayColor: BrandColors.goldenYellow.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
              ),
              child: Slider(
                value: currentMaxPrice,
                min: minPrice,
                max: maxPriceValue,
                divisions: 20,
                onChanged: (value) {
                  setState(() {
                    _tempState.maxPrice = value;
                  });
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '\$${minPrice.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '\$${maxPriceValue.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      if (_tempState.maxPrice != null) ...[
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () {
            setState(() {
              _tempState.maxPrice = null;
            });
          },
          icon: const Icon(Icons.clear, size: 18, color: BrandColors.deepGold),
          label: const Text(
            'Quitar filtro de precio',
            style: TextStyle(
              color: BrandColors.deepGold,
              fontWeight: FontWeight.w600,
            ),
          ),
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
    'precio_promedio': 'Precio (menor primero)',
    '-precio_promedio': 'Precio (mayor primero)',
    'nombre': 'Nombre (A-Z)',
  };

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _buildSectionHeader(Icons.sort, 'Ordenar por'),
      Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: sortOptions.entries.map((entry) {
            final isSelected = _tempState.sortBy == entry.key;
            return InkWell(
              onTap: () {
                setState(() {
                  _tempState.sortBy = entry.key;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  gradient: isSelected ? BrandColors.gradient : null,
                  borderRadius: entry.key == sortOptions.keys.first
                    ? const BorderRadius.vertical(top: Radius.circular(16))
                    : entry.key == sortOptions.keys.last
                      ? const BorderRadius.vertical(bottom: Radius.circular(16))
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey.shade400,
                          width: 2,
                        ),
                        color: isSelected ? Colors.white : Colors.transparent,
                      ),
                      child: isSelected
                        ? const Center(
                            child: Icon(
                              Icons.circle,
                              size: 10,
                              color: BrandColors.deepGold,
                            ),
                          )
                        : null,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      entry.value,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
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
            side: const BorderSide(color: BrandColors.goldenYellow, width: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Cancelar',
            style: TextStyle(
              color: BrandColors.goldenYellow,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Container(
          decoration: BoxDecoration(
            gradient: BrandColors.gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: BrandColors.goldenYellow.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () {
              widget.onApply(_tempState);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Aplicar Filtros',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
}