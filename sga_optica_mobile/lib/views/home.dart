import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import 'main_screen.dart';

// ─────────────────────────────────────────────
//  Colores
// ─────────────────────────────────────────────
const Color _kPrimary      = Color(0xFF0964AF);
const Color _kPrimaryLight = Color(0xFF2196F3);
const Color _kPrimaryDark  = Color(0xFF054A82);
const Color _kBg           = Color(0xFFF4F8FB);
const Color _kTextDark     = Color(0xFF0D1B2A);
const Color _kTextGrey     = Color(0xFF7A8A99);

// ─────────────────────────────────────────────
//  Datos del carrusel
// ─────────────────────────────────────────────
class _BannerData {
  final String title;
  final String price;
  final String imageUrl;
  const _BannerData(this.title, this.price, this.imageUrl);
}

const List<_BannerData> _banners = [
  _BannerData(
    'Lentes de Moda',
    '\$120.000',
    'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=700&q=80',
  ),
  _BannerData(
    'Monturas Premium',
    '\$89.000',
    'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=700&q=80',
  ),
  _BannerData(
    'Los Mejores Lentes Del País',
    '\$65.000',
    'https://images.unsplash.com/photo-1591076482161-42ce6da69f67?w=700&q=80',
  ),
];

// ─────────────────────────────────────────────
//  HomeScreen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentBanner = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<ProductProvider>(context, listen: false);
      if (prov.products.isEmpty) prov.fetchProducts();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ── Navegar al tab de Productos dentro de MainScreen ──
  // Corrige el bug: antes hacía Navigator.push independiente
  // y perdía el BottomNavigationBar
  void _goToProductos() {
    final mainState = context.findAncestorStateOfType<MainScreenState>();
    if (mainState != null) {
      mainState.onItemTapped(1); // índice 1 = Productos
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ══════════════════════════════════════
            //  BLOQUE AZUL: header + buscador + banner
            // ══════════════════════════════════════
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPrimaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                children: [
                  // ── Header ──────────────────────────
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 32,
                            height: 18,
                            child: CustomPaint(
                              painter: _GlassesPainter(Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'S.G.A ÓPTICA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () => _snack('Notificaciones - Próximamente'),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.18),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.notifications_none_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Subtítulo ────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 16),
                    child: Text(
                      '¡Cuida tu salud visual!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.93),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  // ── Buscador blanco ──────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: GestureDetector(
                      onTap: () => _snack('Búsqueda - Próximamente'),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 16),
                            Icon(Icons.search_rounded,
                                color: _kTextGrey, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Buscar Productos',
                              style: TextStyle(
                                  color: _kTextGrey, fontSize: 14.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Carrusel ─────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      height: 215,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: _banners.length,
                        onPageChanged: (i) =>
                            setState(() => _currentBanner = i),
                        itemBuilder: (ctx, i) => _BannerCard(
                          data: _banners[i],
                          // ✅ FIX: navega al tab interno, no hace push
                          onTap: _goToProductos,
                        ),
                      ),
                    ),
                  ),

                  // ── Indicadores ──────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_banners.length, (i) {
                        final active = i == _currentBanner;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: active ? 22 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: active
                                ? Colors.white
                                : Colors.white.withOpacity(0.40),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // ══════════════════════════════════════
            //  DESTACADOS — 3 categorías
            // ══════════════════════════════════════
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 18),
              child: Text(
                'Destacados',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark,
                  letterSpacing: 0.1,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: _CatCard(
                      label: 'Lentes',
                      imageUrl:
                          'https://images.unsplash.com/photo-1574258495973-f010dfbb5371?w=300&q=80',
                      onTap: _goToProductos,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CatCard(
                      label: 'Monturas',
                      imageUrl:
                          'https://images.unsplash.com/photo-1511499767150-a48a237f0083?w=300&q=80',
                      onTap: _goToProductos,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CatCard(
                      label: 'Accesorios',
                      imageUrl:
                          'https://images.unsplash.com/photo-1508296695146-257a814070b4?w=300&q=80',
                      onTap: _goToProductos,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  BannerCard
// ─────────────────────────────────────────────
class _BannerCard extends StatelessWidget {
  final _BannerData data;
  final VoidCallback onTap;
  const _BannerCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: _kPrimaryDark,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              data.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF1565C0),
                child: const Center(
                  child: Icon(Icons.remove_red_eye_rounded,
                      size: 64, color: Colors.white24),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.20),
                      Colors.black.withOpacity(0.68),
                    ],
                    stops: const [0.30, 0.55, 1.0],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          data.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            shadows: [
                              Shadow(color: Colors.black54, blurRadius: 6)
                            ],
                          ),
                        ),
                        const SizedBox(height: 9),
                        GestureDetector(
                          onTap: onTap,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A80D9),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.shopping_bag_rounded,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 5),
                                Text(
                                  'Comprar Ahora',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D47A1).withOpacity(0.88),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1),
                    ),
                    child: Text(
                      data.price,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  CatCard — ahora tiene onTap para navegar
// ─────────────────────────────────────────────
class _CatCard extends StatelessWidget {
  final String label;
  final String imageUrl;
  final VoidCallback onTap;
  const _CatCard(
      {required this.label, required this.imageUrl, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 72,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE3F0FB),
                  child: const Center(
                    child: Icon(Icons.remove_red_eye_rounded,
                        size: 30, color: _kPrimary),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Painter: ícono gafas
// ─────────────────────────────────────────────
class _GlassesPainter extends CustomPainter {
  final Color color;
  const _GlassesPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round;
    final r  = size.height * 0.40;
    final cy = size.height * 0.54;
    final lx = size.width * 0.27;
    final rx = size.width * 0.73;
    canvas.drawCircle(Offset(lx, cy), r, p);
    canvas.drawCircle(Offset(rx, cy), r, p);
    canvas.drawLine(Offset(lx + r, cy), Offset(rx - r, cy), p);
    canvas.drawLine(Offset(lx - r, cy), Offset(0, cy - r * 0.5), p);
    canvas.drawLine(Offset(rx + r, cy), Offset(size.width, cy - r * 0.5), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}