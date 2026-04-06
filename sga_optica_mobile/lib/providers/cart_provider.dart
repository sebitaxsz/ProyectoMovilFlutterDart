import 'package:flutter/material.dart';
import '../models/product_model.dart';

// ─────────────────────────────────────────────
//  Ítem del carrito: producto + cantidad
// ─────────────────────────────────────────────
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get subtotal => product.unitPrice * quantity;
}

// ─────────────────────────────────────────────
//  CartProvider — estado global del carrito
// ─────────────────────────────────────────────
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get subtotal => _items.fold(0, (sum, i) => sum + i.subtotal);

  // Envío fijo de $2.000
  double get shipping => _items.isEmpty ? 0 : 2000;

  double get total => subtotal + shipping;

  bool get isEmpty => _items.isEmpty;

  // ── Agregar producto (o sumar cantidad si ya existe) ──
  void addProduct(Product product) {
    final idx = _items.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      _items[idx].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    notifyListeners();
  }

  // ── Incrementar cantidad ──────────────────────────────
  void increment(int productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      // No superar el stock disponible
      if (_items[idx].quantity < _items[idx].product.stock) {
        _items[idx].quantity++;
        notifyListeners();
      }
    }
  }

  // ── Decrementar cantidad (eliminar si llega a 0) ──────
  void decrement(int productId) {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx >= 0) {
      if (_items[idx].quantity > 1) {
        _items[idx].quantity--;
      } else {
        _items.removeAt(idx);
      }
      notifyListeners();
    }
  }

  // ── Eliminar producto del carrito ─────────────────────
  void removeProduct(int productId) {
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  // ── Vaciar carrito ────────────────────────────────────
  void clear() {
    _items.clear();
    notifyListeners();
  }

  // ── Construir body para POST /sales ──────────────────
  // Requiere customerId y paymentTypeId desde fuera
  Map<String, dynamic> buildSaleBody({
    required int customerId,
    required int paymentTypeId,
  }) {
    return {
      'customerId': customerId,
      'paymentTypeId': paymentTypeId,
      'products': _items
          .map((i) => {
                'productId': i.product.id,
                'quantity': i.quantity,
              })
          .toList(),
    };
  }
}