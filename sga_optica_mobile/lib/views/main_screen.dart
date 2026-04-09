import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'home.dart';
import 'productos.dart';
import 'cart.dart';
import 'profile.dart';

const Color _kPrimary     = Color(0xFF0964AF);
const Color _kPrimaryDark = Color(0xFF054A82);

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;

  // Controlador para el shake del ícono del carrito cuando se agrega un item
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  // Guarda el count anterior para detectar cuando sube
  int _prevCartCount = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    ProductosScreen(),
    CartScreen(),
    ProfileScreen(),
  ];

  final List<String> _titles = [
    '',
    'Productos',
    'Carrito',
    'Perfil',
  ];

  @override
  void initState() {
    super.initState();

    // Animación de shake: oscila de -0.05 a 0.05 radianes (≈3°)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.12, end: 0.12), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: -0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.08, end: 0.08), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void onItemTapped(int index) => setState(() => _selectedIndex = index);

  // Llamado desde ProductCard / ProductDetail cuando se agrega un ítem
  void triggerCartShake() {
    _shakeController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isHome = _selectedIndex == 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isHome ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Consumer<CartProvider>(
        builder: (context, cart, _) {
          // Detectar cuando el carrito sube → shake automático
          if (cart.itemCount > _prevCartCount) {
            _prevCartCount = cart.itemCount;
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _shakeController.forward(from: 0));
          } else {
            _prevCartCount = cart.itemCount;
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF4F8FB),
            appBar: isHome
                ? null
                : AppBar(
                    title: Text(
                      _titles[_selectedIndex],
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        letterSpacing: 0.3,
                      ),
                    ),
                    centerTitle: true,
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    automaticallyImplyLeading: false,
                  ),
            body: _screens[_selectedIndex],
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_kPrimaryDark, _kPrimary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.30),
                    blurRadius: 16,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Inicio',
                        index: 0,
                        selected: _selectedIndex,
                        onTap: onItemTapped,
                      ),
                      _NavItem(
                        icon: Icons.shopping_bag_rounded,
                        label: 'Productos',
                        index: 1,
                        selected: _selectedIndex,
                        onTap: onItemTapped,
                      ),
                      // ── Carrito con badge animado ────────────
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onItemTapped(2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _shakeAnimation,
                                builder: (_, child) => Transform.rotate(
                                  angle: _shakeAnimation.value,
                                  child: child,
                                ),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 200),
                                      padding: _selectedIndex == 2
                                          ? const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 4)
                                          : const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _selectedIndex == 2
                                            ? Colors.white.withOpacity(0.22)
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Icon(
                                        Icons.shopping_cart_rounded,
                                        color: _selectedIndex == 2
                                            ? Colors.white
                                            : Colors.white.withOpacity(0.55),
                                        size: 22,
                                      ),
                                    ),
                                    // Badge con contador
                                    if (cart.itemCount > 0)
                                      Positioned(
                                        top: -4,
                                        right: _selectedIndex == 2 ? -2 : -4,
                                        child: AnimatedScale(
                                          scale: cart.itemCount > 0 ? 1 : 0,
                                          duration: const Duration(
                                              milliseconds: 250),
                                          curve: Curves.elasticOut,
                                          child: Container(
                                            width: 18,
                                            height: 18,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFF3B30),
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                  color: _kPrimary, width: 1.5),
                                            ),
                                            child: Center(
                                              child: Text(
                                                cart.itemCount > 99
                                                    ? '99+'
                                                    : '${cart.itemCount}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Carrito',
                                style: TextStyle(
                                  color: _selectedIndex == 2
                                      ? Colors.white
                                      : Colors.white.withOpacity(0.55),
                                  fontSize: 10.5,
                                  fontWeight: _selectedIndex == 2
                                      ? FontWeight.w700
                                      : FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _NavItem(
                        icon: Icons.person_rounded,
                        label: 'Perfil',
                        index: 3,
                        selected: _selectedIndex,
                        onTap: onItemTapped,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Item nav normal (sin badge)
// ─────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = index == selected;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 14, vertical: 4)
                  : const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withOpacity(0.22)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.55),
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color:
                    isActive ? Colors.white : Colors.white.withOpacity(0.55),
                fontSize: 10.5,
                fontWeight:
                    isActive ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}