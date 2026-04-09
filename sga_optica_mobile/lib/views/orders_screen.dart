import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

// ─────────────────────────────────────────────
//  Colores (consistentes con toda la app)
// ─────────────────────────────────────────────
const Color _kPrimary      = Color(0xFF0964AF);
const Color _kPrimaryLight = Color(0xFF2196F3);
const Color _kBg           = Color(0xFFF4F8FB);
const Color _kCard         = Colors.white;
const Color _kTextDark     = Color(0xFF0D1B2A);
const Color _kTextGrey     = Color(0xFF7A8A99);
const Color _kGreen        = Color(0xFF2E7D32);
const Color _kRed          = Color(0xFFD32F2F);
const Color _kWarning      = Color(0xFFFF9800);

// ─────────────────────────────────────────────
//  Modelo de Pedido
// ─────────────────────────────────────────────
class Order {
  final int id;
  final String fecha;
  final double total;
  final String estado;
  final List<OrderProduct> productos;
  final Map<String, dynamic> cliente;
  final String metodoPago;

  Order({
    required this.id,
    required this.fecha,
    required this.total,
    required this.estado,
    required this.productos,
    required this.cliente,
    required this.metodoPago,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      fecha: json['fecha'],
      total: (json['total'] as num).toDouble(),
      estado: json['estado'],
      productos: (json['productos'] as List)
          .map((p) => OrderProduct.fromJson(p))
          .toList(),
      cliente: json['cliente'] ?? {},
      metodoPago: json['metodoPago'] ?? 'No especificado',
    );
  }
}

class OrderProduct {
  final String nombre;
  final int cantidad;
  final double precio;

  OrderProduct({
    required this.nombre,
    required this.cantidad,
    required this.precio,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      nombre: json['nombre'],
      cantidad: json['cantidad'],
      precio: (json['precio'] as num).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────
//  OrdersScreen
// ─────────────────────────────────────────────
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _isLoading = true;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _checkAuthAndLoadOrders();
  }

  Future<void> _checkAuthAndLoadOrders() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    
    if (!auth.isAuthenticated) {
      setState(() {
        _isAuthenticated = false;
        _isLoading = false;
      });
      return;
    }
    
    setState(() {
      _isAuthenticated = true;
    });
    
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      
      if (user == null) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
        return;
      }
      
      final userEmail = user.username;
      final prefs = await SharedPreferences.getInstance();
      final storageKey = 'pedidos_$userEmail';
      final pedidosStr = prefs.getString(storageKey);
      
      if (pedidosStr != null) {
        final List<dynamic> pedidosData = jsonDecode(pedidosStr);
        setState(() {
          _orders = pedidosData.map((data) => Order.fromJson(data)).toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading orders: $e');
      setState(() {
        _orders = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshOrders() async {
    await _loadOrders();
  }

  Color _getEstadoColor(String estado) {
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('entregado')) {
      return _kGreen;
    } else if (estadoLower.contains('camino') || estadoLower.contains('enviado')) {
      return _kPrimary;
    } else if (estadoLower.contains('pendiente')) {
      return _kWarning;
    } else {
      return _kTextGrey;
    }
  }

  String _getEstadoIcon(String estado) {
    final estadoLower = estado.toLowerCase();
    if (estadoLower.contains('entregado')) {
      return '📦';
    } else if (estadoLower.contains('camino') || estadoLower.contains('enviado')) {
      return '🚚';
    } else if (estadoLower.contains('pendiente')) {
      return '⏳';
    } else {
      return '❓';
    }
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _kTextGrey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Título
              Row(
                children: [
                  Text(
                    _getEstadoIcon(order.estado),
                    style: const TextStyle(fontSize: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pedido #${order.id}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _kTextDark,
                          ),
                        ),
                        Text(
                          order.fecha,
                          style: const TextStyle(
                            fontSize: 13,
                            color: _kTextGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getEstadoColor(order.estado).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      order.estado,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getEstadoColor(order.estado),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Productos
              const Text(
                'Productos',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kTextDark,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: order.productos.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final product = order.productos[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.nombre,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: _kTextDark,
                                  ),
                                ),
                                Text(
                                  'Cantidad: ${product.cantidad}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: _kTextGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '\$${_fmt(product.precio * product.cantidad)}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              
              const Divider(height: 24),
              
              // Datos del cliente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos de Entrega',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.person_outline,
                      label: 'Nombre',
                      value: order.cliente['nombre'] ?? 'No especificado',
                    ),
                    _InfoRow(
                      icon: Icons.phone_outlined,
                      label: 'Teléfono',
                      value: order.cliente['telefono'] ?? 'No especificado',
                    ),
                    _InfoRow(
                      icon: Icons.location_on_outlined,
                      label: 'Dirección',
                      value: order.cliente['direccion'] ?? 'No especificado',
                    ),
                    _InfoRow(
                      icon: Icons.credit_card,
                      label: 'Método de Pago',
                      value: order.metodoPago,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Total
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kPrimary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kPrimary.withOpacity(0.2)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total del Pedido',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                    Text(
                      '\$${_fmt(order.total)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _kPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text(
          'Mis Pedidos',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _kTextDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: _kPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: _kPrimary),
            onPressed: _refreshOrders,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (!_isAuthenticated) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F0FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline,
                size: 56,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Debes iniciar sesión',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Inicia sesión para ver tus pedidos',
              style: TextStyle(
                fontSize: 13,
                color: _kTextGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Iniciar Sesión'),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _kPrimary,
            ),
            SizedBox(height: 16),
            Text(
              'Cargando tus pedidos...',
              style: TextStyle(
                fontSize: 13,
                color: _kTextGrey,
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFE3F0FB),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 56,
                color: _kPrimary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'No tienes pedidos aún',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Realiza tu primera compra',
              style: TextStyle(
                fontSize: 13,
                color: _kTextGrey,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Volver al home y navegar a productos
                Navigator.pop(context);
                final mainState = context.findAncestorStateOfType<MainScreenState>();
                mainState?.onItemTapped(1);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Ver Productos'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshOrders,
      color: _kPrimary,
      child: ListView.separated(
        padding: const EdgeInsets.all(14),
        physics: const BouncingScrollPhysics(),
        itemCount: _orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _OrderCard(
            order: order,
            onTap: () => _showOrderDetails(order),
            fmt: _fmt,
            getEstadoColor: _getEstadoColor,
            getEstadoIcon: _getEstadoIcon,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Order Card Widget
// ─────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onTap;
  final String Function(double) fmt;
  final Color Function(String) getEstadoColor;
  final String Function(String) getEstadoIcon;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.fmt,
    required this.getEstadoColor,
    required this.getEstadoIcon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _kPrimary.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: ID y fecha
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      getEstadoIcon(order.estado),
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pedido #${order.id}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _kTextDark,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getEstadoColor(order.estado).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.estado,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: getEstadoColor(order.estado),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Fecha
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: _kTextGrey,
                ),
                const SizedBox(width: 6),
                Text(
                  order.fecha,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _kTextGrey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Productos (primeros 2)
            ...order.productos.take(2).map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    size: 12,
                    color: _kTextGrey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      product.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _kTextGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'x${product.cantidad}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kPrimary,
                    ),
                  ),
                ],
              ),
            )),
            
            if (order.productos.length > 2)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '+${order.productos.length - 2} producto(s) más',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kTextGrey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            
            const Divider(height: 20),
            
            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _kTextGrey,
                  ),
                ),
                Text(
                  '\$${fmt(order.total)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _kPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Info Row Widget
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: _kPrimary),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: _kTextGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _kTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}