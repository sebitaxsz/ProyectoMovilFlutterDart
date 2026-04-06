import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import 'product_detail.dart';

// ─────────────────────────────────────────────
//  Colores (consistentes con el resto de la app)
// ─────────────────────────────────────────────
const Color _kPrimary     = Color(0xFF0964AF);
const Color _kPrimaryLight= Color(0xFF2196F3);
const Color _kBg          = Color(0xFFF4F8FB);
const Color _kTextDark    = Color(0xFF0D1B2A);
const Color _kTextGrey    = Color(0xFF7A8A99);

// ─────────────────────────────────────────────
//  Categorías de filtro
// ─────────────────────────────────────────────
const List<String> _filterLabels = ['Todos', 'Lentes', 'Monturas', 'Accesorios'];

// Palabras clave para filtrar por nombre de categoría de la API
const Map<String, List<String>> _filterKeywords = {
  'Lentes':    ['lente', 'lens', 'lentes', 'oftálmico', 'oftalmico', 'solar', 'sol'],
  'Monturas':  ['montura', 'armazón', 'armazon', 'frame', 'armadura'],
  'Accesorios':['accesorio', 'paño', 'liquido', 'líquido', 'estuche', 'case',
                'limpia', 'microf', 'cleaning', 'mry', 'mx2', 'ray-ban', 'rayban'],
};

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'Todos';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ProductProvider>(context, listen: false).fetchProducts();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMoreProducts();
      }
    }
  }

  void _showAddToCartMessage(String productName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$productName agregado al carrito'),
        duration: const Duration(seconds: 1),
        backgroundColor: _kPrimary,
      ),
    );
  }

  // Filtra los productos según el filtro activo.
  // Busca en el nombre del producto Y en el nombre de la categoría.
  bool _matchesFilter(dynamic product) {
    if (_selectedFilter == 'Todos') return true;
    final keywords = _filterKeywords[_selectedFilter] ?? [];
    final name = product.nameProduct.toLowerCase();
    final catName = (product.category?.categoryName ?? '').toLowerCase();
    return keywords.any((kw) => name.contains(kw) || catName.contains(kw));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, provider, child) {
        // ── Estado de carga inicial ──────────────────────────────
        if (provider.isLoading && provider.products.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: _kPrimary),
          );
        }

        // ── Estado de error ──────────────────────────────────────
        if (provider.errorMessage.isNotEmpty && provider.products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 52, color: Colors.red[300]),
                const SizedBox(height: 12),
                const Text(
                  'Error al cargar productos',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _kTextDark,
                      fontSize: 15),
                ),
                const SizedBox(height: 6),
                Text(provider.errorMessage,
                    style: const TextStyle(color: _kTextGrey, fontSize: 13),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    provider.clearError();
                    provider.fetchProducts();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          );
        }

        // ── Lista filtrada ───────────────────────────────────────
        final filtered = provider.products
            .where((p) => _matchesFilter(p))
            .toList();

        return Column(
          children: [
            // ══════════════════════════════════════
            //  BARRA DE FILTROS — Todos / Lentes /
            //  Monturas / Accesorios
            // ══════════════════════════════════════
            Container(
              color: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: _filterLabels.map((label) {
                  final isActive = _selectedFilter == label;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedFilter = label),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive ? _kPrimary : const Color(0xFFF0F6FC),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? _kPrimary
                                : const Color(0xFFD0DFF0),
                            width: 1,
                          ),
                          boxShadow: isActive
                              ? [
                                  BoxShadow(
                                    color: _kPrimary.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : [],
                        ),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isActive ? Colors.white : _kTextGrey,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Divisor sutil bajo los filtros
            Container(height: 1, color: const Color(0xFFE8F0F8)),

            // ══════════════════════════════════════
            //  GRID DE PRODUCTOS
            // ══════════════════════════════════════
            Expanded(
              child: filtered.isEmpty && !provider.isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off_rounded,
                              size: 52,
                              color: _kTextGrey.withOpacity(0.5)),
                          const SizedBox(height: 12),
                          const Text(
                            'No hay productos en esta categoría',
                            style: TextStyle(
                                color: _kTextGrey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(10),
                      child: GridView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.55,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemCount: filtered.length +
                            (provider.isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Spinner al final al cargar más
                          if (index == filtered.length &&
                              provider.isLoadingMore) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(
                                    color: _kPrimary),
                              ),
                            );
                          }
                          final product = filtered[index];
                          return ProductCard(
                            product: product,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ProductDetailScreen(
                                          productId: product.id),
                                ),
                              );
                            },
                            onAddToCart: () {
                              _showAddToCartMessage(product.nameProduct);
                            },
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}