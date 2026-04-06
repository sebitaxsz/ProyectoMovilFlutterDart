import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({Key? key, required this.productId})
      : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late Future<Product> _productFuture;

  // ── Animación del botón "Agregar al carrito" ────────
  late final AnimationController _btnController;
  late final Animation<double> _scaleAnim;
  bool _added = false; // controla si mostrar checkmark o carrito

  @override
  void initState() {
    super.initState();

    // Intenta usar caché primero
    final cached = Provider.of<ProductProvider>(context, listen: false)
        .getProductById(widget.productId);
    _productFuture = cached != null
        ? Future.value(cached)
        : ApiService().getProductById(widget.productId);

    // Animación escala: crece y vuelve (efecto "pop")
    _btnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 1.12)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 1),
      TweenSequenceItem(
          tween: Tween(begin: 1.12, end: 1.0)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 1),
    ]).animate(_btnController);
  }

  @override
  void dispose() {
    _btnController.dispose();
    super.dispose();
  }

  // ── Agregar al carrito con animación ────────────────
  void _addToCart(Product product) {
    Provider.of<CartProvider>(context, listen: false).addProduct(product);

    // Animación del botón
    _btnController.forward(from: 0);
    setState(() => _added = true);

    // Volver al ícono de carrito después de 1.5s
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _added = false);
    });

    // Snackbar con acción "Ver carrito"
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${product.nameProduct} agregado',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF0964AF),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        action: SnackBarAction(
          label: 'Ver carrito',
          textColor: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle del Producto'),
        backgroundColor: const Color(0xFF0964AF),
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        // Badge del carrito en el AppBar
        actions: [
          Consumer<CartProvider>(
            builder: (_, cart, __) => Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
                if (cart.itemCount > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${cart.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(
                    color: Color(0xFF0964AF)));
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => setState(() {
                      _productFuture =
                          ApiService().getProductById(widget.productId);
                    }),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final product = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Imagen grande ──────────────────────────
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: product.imagen != null &&
                            product.imagen!.isNotEmpty
                        ? Image.network(
                            '${Constants.baseUrlImages}${product.imagen!}',
                            height: 250,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _placeholder(250),
                          )
                        : _placeholder(250),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Nombre ────────────────────────────────
                Text(
                  product.nameProduct,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // ── Descripción ───────────────────────────
                if (product.description != null &&
                    product.description!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Descripción:',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(product.description!,
                            style: const TextStyle(
                                fontSize: 14, height: 1.5)),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),

                // ── Categoría ─────────────────────────────
                if (product.category != null)
                  Text(
                    'Categoría: ${product.category!.categoryName}',
                    style: const TextStyle(
                        fontSize: 16, color: Colors.grey),
                  ),
                const SizedBox(height: 8),

                // ── Estrellas ─────────────────────────────
                const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star, color: Colors.amber),
                    Icon(Icons.star_half, color: Colors.amber),
                    SizedBox(width: 8),
                    Text('(4.5)',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Precio ────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Precio:',
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      Text(
                        '\$${product.unitPrice.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Stock ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: product.stock > 0
                        ? Colors.blue[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: product.stock > 0
                          ? Colors.blue[200]!
                          : Colors.red[200]!,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Stock disponible:',
                          style: TextStyle(fontSize: 16)),
                      Text(
                        '${product.stock} unidades',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: product.stock > 0
                              ? Colors.blue
                              : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // ── Botón Agregar al carrito con animación ─
                ScaleTransition(
                  scale: _scaleAnim,
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      decoration: BoxDecoration(
                        gradient: product.stock > 0
                            ? LinearGradient(
                                colors: _added
                                    ? [
                                        const Color(0xFF2E7D32),
                                        const Color(0xFF43A047)
                                      ]
                                    : [
                                        const Color(0xFF0964AF),
                                        const Color(0xFF2196F3)
                                      ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              )
                            : null,
                        color: product.stock <= 0 ? Colors.grey[300] : null,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: product.stock > 0
                            ? [
                                BoxShadow(
                                  color: (_added
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFF0964AF))
                                      .withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                )
                              ]
                            : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(30),
                          onTap: product.stock > 0
                              ? () => _addToCart(product)
                              : null,
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              transitionBuilder: (child, anim) =>
                                  ScaleTransition(scale: anim, child: child),
                              child: _added
                                  ? const Row(
                                      key: ValueKey('added'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: Colors.white, size: 22),
                                        SizedBox(width: 8),
                                        Text(
                                          '¡Agregado al carrito!',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      key: const ValueKey('add'),
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                            Icons.shopping_cart_rounded,
                                            color: Colors.white,
                                            size: 22),
                                        const SizedBox(width: 8),
                                        Text(
                                          product.stock > 0
                                              ? 'Agregar al carrito'
                                              : 'Sin stock',
                                          style: TextStyle(
                                            color: product.stock > 0
                                                ? Colors.white
                                                : Colors.grey[600],
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _placeholder(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported,
          size: 80, color: Colors.grey),
    );
  }
}