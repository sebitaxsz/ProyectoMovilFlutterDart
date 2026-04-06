import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../providers/cart_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/constants.dart';
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

// ─────────────────────────────────────────────
//  Tipos de pago disponibles en la API
//  GET /api/v1/paymentType  (público, sin token)
// ─────────────────────────────────────────────
class _PaymentType {
  final int id;
  final String name;
  const _PaymentType({required this.id, required this.name});

  factory _PaymentType.fromJson(Map<String, dynamic> j) =>
      _PaymentType(id: j['id'], name: j['name'] ?? 'Desconocido');
}

// ─────────────────────────────────────────────
//  CartScreen
// ─────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // ── Código de descuento (UI, sin lógica real aún) ────
  final _discountController = TextEditingController();
  double _discount = 0;

  // ── Tipos de pago cargados desde la API ──────────────
  List<_PaymentType> _paymentTypes = [];
  int? _selectedPaymentTypeId;
  bool _loadingPayments = false;

  // ── Estado del checkout ──────────────────────────────
  bool _processingOrder = false;

  // ── Campos de entrega ────────────────────────────────
  final _nameController    = TextEditingController();
  final _phoneController   = TextEditingController();
  final _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPaymentTypes();
  }

  @override
  void dispose() {
    _discountController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // ── Cargar tipos de pago desde GET /paymentType ──────
  Future<void> _loadPaymentTypes() async {
    setState(() => _loadingPayments = true);
    try {
      final res = await http
          .get(Uri.parse('${Constants.baseUrl}/paymentType'),
              headers: {'Content-Type': 'application/json'})
          .timeout(Constants.connectionTimeout);

      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _paymentTypes = data.map((e) => _PaymentType.fromJson(e)).toList();
          if (_paymentTypes.isNotEmpty) {
            _selectedPaymentTypeId = _paymentTypes.first.id;
          }
        });
      }
    } catch (e) {
      // Si falla, dejamos lista vacía — el usuario verá el mensaje
    } finally {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  // ── Aplicar código de descuento (lógica local de demo) ─
  void _applyDiscount() {
    final code = _discountController.text.trim().toUpperCase();
    setState(() {
      if (code == 'SGA10') {
        _discount = 0.10; // 10 %
        _snack('Descuento del 10% aplicado 🎉', success: true);
      } else if (code == 'SGA20') {
        _discount = 0.20;
        _snack('Descuento del 20% aplicado 🎉', success: true);
      } else if (code.isNotEmpty) {
        _discount = 0;
        _snack('Código de descuento inválido');
      }
    });
  }

  double _discountAmount(double subtotal) => subtotal * _discount;

  // ── Realizar pedido → POST /sales ────────────────────
  Future<void> _checkout() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (cart.isEmpty) return;

    if (_selectedPaymentTypeId == null) {
      _snack('Selecciona un método de pago');
      return;
    }

    // Validar campos básicos
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty) {
      _snack('Completa todos los campos de entrega');
      return;
    }

    // ── La API de ventas requiere customerId.
    //    El cliente logueado puede no tener un customerId propio
    //    (eso lo gestiona el backend).  Por ahora usamos un ID
    //    de prueba (1) con aviso.  Cuando el back exponga
    //    GET /customers/me se puede conectar aquí.
    //
    //    NOTA TÉCNICA: La ruta POST /sales requiere rol
    //    Administrador o Empleado.  Si el usuario logueado es
    //    cliente, la API devolverá 403.  En ese caso mostramos
    //    un mensaje claro al usuario.
    // ─────────────────────────────────────────────────────

    final token = auth.token;
    if (token == null) {
      _snack('Debes iniciar sesión para continuar');
      return;
    }

    setState(() => _processingOrder = true);

    try {
      // Intentar obtener customerId del usuario actual
      // (si el back lo expone en el futuro desde /customers/me)
      // Por ahora usamos el userId del token como customerId demo
      final body = cart.buildSaleBody(
        customerId: 1, // placeholder — conectar con endpoint real cuando esté disponible
        paymentTypeId: _selectedPaymentTypeId!,
      );

      final res = await http
          .post(
            Uri.parse('${Constants.baseUrl}/sales'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode(body),
          )
          .timeout(Constants.connectionTimeout);

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        cart.clear();
        if (mounted) _showSuccessDialog(data['numberBill'] ?? '');
      } else {
        final err = jsonDecode(res.body);
        _snack(err['message'] ?? 'Error al procesar el pedido');
      }
    } catch (e) {
      _snack('Error de conexión. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _processingOrder = false);
    }
  }

  void _snack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: success ? _kGreen : _kRed,
      duration: const Duration(seconds: 2),
    ));
  }

  void _showSuccessDialog(String numberBill) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _kGreen, size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              '¡Pedido realizado!',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _kTextDark),
            ),
            const SizedBox(height: 8),
            Text(
              numberBill.isNotEmpty
                  ? 'Factura: $numberBill'
                  : 'Tu pedido fue procesado correctamente.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextGrey, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Volver al home usando el estado de MainScreen
              final mainState =
                  context.findAncestorStateOfType<MainScreenState>();
              mainState?.onItemTapped(0);
            },
            child: const Text('Ir al Inicio',
                style: TextStyle(color: _kPrimary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        if (cart.isEmpty) return _buildEmptyCart(context);
        return _buildCartContent(context, cart);
      },
    );
  }

  // ── Carrito vacío ─────────────────────────────────────
  Widget _buildEmptyCart(BuildContext context) {
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
            child: const Icon(Icons.shopping_cart_outlined,
                size: 56, color: _kPrimary),
          ),
          const SizedBox(height: 20),
          const Text(
            'Tu carrito está vacío',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kTextDark),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega productos desde la sección Productos',
            style: TextStyle(color: _kTextGrey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              final mainState =
                  context.findAncestorStateOfType<MainScreenState>();
              mainState?.onItemTapped(1);
            },
            icon: const Icon(Icons.shopping_bag_rounded),
            label: const Text('Ver Productos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: Colors.white,
              padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Carrito con productos ─────────────────────────────
  Widget _buildCartContent(BuildContext context, CartProvider cart) {
    final subtotalBase = cart.subtotal;
    final discountAmt  = _discountAmount(subtotalBase);
    final finalTotal   = (subtotalBase - discountAmt) + cart.shipping;

    return Scaffold(
      backgroundColor: _kBg,
      body: Column(
        children: [
          // ── Lista de items ────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(14),
              physics: const BouncingScrollPhysics(),
              children: [
                // Items del carrito
                ...cart.items.map((item) => _CartItemTile(
                      item: item,
                      onIncrement: () => Provider.of<CartProvider>(context,
                              listen: false)
                          .increment(item.product.id),
                      onDecrement: () => Provider.of<CartProvider>(context,
                              listen: false)
                          .decrement(item.product.id),
                      onRemove: () => Provider.of<CartProvider>(context,
                              listen: false)
                          .removeProduct(item.product.id),
                    )),

                const SizedBox(height: 16),

                // ── Código de descuento ───────────────────
                _SectionCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _discountController,
                          textCapitalization:
                              TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'Código de Descuento',
                            hintStyle:
                                const TextStyle(color: _kTextGrey, fontSize: 14),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFD0DFF0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                  color: Color(0xFFD0DFF0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide:
                                  const BorderSide(color: _kPrimary),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _applyDiscount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 11),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: const Text('Aplicar',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Resumen de precios ────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Resumen',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _kTextDark)),
                      const SizedBox(height: 12),
                      _SummaryRow('Subtotal',
                          '\$${_fmt(subtotalBase)}'),
                      if (_discount > 0)
                        _SummaryRow(
                            'Descuento (${(_discount * 100).toInt()}%)',
                            '-\$${_fmt(discountAmt)}',
                            valueColor: _kGreen),
                      _SummaryRow('Envío', '\$${_fmt(cart.shipping)}'),
                      const Divider(height: 20, color: Color(0xFFE8F0F8)),
                      _SummaryRow(
                        'Total',
                        '\$${_fmt(finalTotal)}',
                        isBold: true,
                        valueColor: _kPrimary,
                        fontSize: 16,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Método de pago ────────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Método de Pago',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _kTextDark)),
                      const SizedBox(height: 10),
                      _loadingPayments
                          ? const Center(
                              child: SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _kPrimary),
                              ),
                            )
                          : _paymentTypes.isEmpty
                              ? const Text('No disponible',
                                  style: TextStyle(color: _kTextGrey))
                              : DropdownButtonFormField<int>(
                                  initialValue: _selectedPaymentTypeId,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFD0DFF0)),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: Color(0xFFD0DFF0)),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius:
                                          BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: _kPrimary),
                                    ),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 10),
                                    isDense: true,
                                  ),
                                  items: _paymentTypes
                                      .map((pt) => DropdownMenuItem(
                                            value: pt.id,
                                            child: Text(pt.name,
                                                style: const TextStyle(
                                                    fontSize: 14)),
                                          ))
                                      .toList(),
                                  onChanged: (v) => setState(
                                      () => _selectedPaymentTypeId = v),
                                ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ── Datos de entrega ──────────────────────
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Datos de Entrega',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: _kTextDark)),
                      const SizedBox(height: 12),
                      _DeliveryField(
                        controller: _nameController,
                        icon: Icons.person_outline_rounded,
                        hint: 'Nombre completo',
                      ),
                      const SizedBox(height: 8),
                      _DeliveryField(
                        controller: _phoneController,
                        icon: Icons.phone_outlined,
                        hint: 'Teléfono',
                        inputType: TextInputType.phone,
                      ),
                      const SizedBox(height: 8),
                      _DeliveryField(
                        controller: _addressController,
                        icon: Icons.location_on_outlined,
                        hint: 'Dirección',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Botón Realizar Pago ───────────────────────
          Container(
            padding:
                const EdgeInsets.fromLTRB(16, 10, 16, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _kPrimary.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _processingOrder ? null : _checkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  elevation: 0,
                ),
                child: _processingOrder
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation(Colors.white)),
                      )
                    : Text(
                        'Realizar Pago  •  \$${_fmt(finalTotal)}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
}

// ─────────────────────────────────────────────
//  Widget: ítem individual del carrito
// ─────────────────────────────────────────────
class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemTile({
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0964AF).withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: item.product.imagen != null &&
                    item.product.imagen!.isNotEmpty
                ? Image.network(
                    '${Constants.baseUrlImages}${item.product.imagen!}',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder(),
                  )
                : _placeholder(),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.nameProduct,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0D1B2A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Estrellas estáticas como en el mockup
                Row(
                  children: List.generate(
                      5,
                      (i) => Icon(
                            i < 4 ? Icons.star : Icons.star_half,
                            size: 11,
                            color: Colors.amber,
                          )),
                ),
                const SizedBox(height: 4),
                // Precio unitario
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0964AF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '\$${_fmt(item.product.unitPrice)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Controles cantidad + eliminar
          Column(
            children: [
              // Botón eliminar
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.delete_outline_rounded,
                      size: 16, color: Color(0xFFD32F2F)),
                ),
              ),
              const SizedBox(height: 10),
              // Controles +/-
              Row(
                children: [
                  _QtyButton(
                      icon: Icons.remove,
                      onTap: onDecrement),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '${item.quantity}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0D1B2A)),
                    ),
                  ),
                  _QtyButton(
                      icon: Icons.add,
                      onTap: onIncrement),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: const Color(0xFFE3F0FB),
      child: const Icon(Icons.remove_red_eye_rounded,
          size: 28, color: Color(0xFF0964AF)),
    );
  }

  String _fmt(double v) => v
      .toStringAsFixed(0)
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
}

// ─────────────────────────────────────────────
//  Botón de cantidad (+/-)
// ─────────────────────────────────────────────
class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F0FB),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFD0DFF0)),
        ),
        child: Icon(icon, size: 14, color: const Color(0xFF0964AF)),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Card de sección (padding + sombra suave)
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0964AF).withOpacity(0.07),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────
//  Fila de resumen (label + valor)
// ─────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isBold;
  final Color? valueColor;
  final double fontSize;

  const _SummaryRow(
    this.label,
    this.value, {
    this.isBold = false,
    this.valueColor,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: fontSize,
                  color: const Color(0xFF7A8A99),
                  fontWeight:
                      isBold ? FontWeight.w700 : FontWeight.w400)),
          Text(value,
              style: TextStyle(
                  fontSize: fontSize,
                  color: valueColor ?? const Color(0xFF0D1B2A),
                  fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Campo de entrega con ícono
// ─────────────────────────────────────────────
class _DeliveryField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType inputType;

  const _DeliveryField({
    required this.controller,
    required this.icon,
    required this.hint,
    this.inputType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: inputType,
      style: const TextStyle(fontSize: 14, color: Color(0xFF0D1B2A)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF7A8A99), fontSize: 14),
        prefixIcon: Icon(icon, size: 18, color: const Color(0xFF0964AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD0DFF0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFD0DFF0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF0964AF)),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        filled: true,
        fillColor: const Color(0xFFF8FBFF),
      ),
    );
  }
}