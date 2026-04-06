import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../utils/constants.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              child: product.imagen != null && product.imagen!.isNotEmpty
                  ? Image.network(
                      '${Constants.baseUrlImages}${product.imagen!}',
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildImagePlaceholder(),
                    )
                  : _buildImagePlaceholder(),
            ),
            // Contenido
            Padding(
              padding: const EdgeInsets.all(6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  Text(
                    product.nameProduct,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // Descripción
                  if (product.description != null &&
                      product.description!.isNotEmpty)
                    Text(
                      product.description!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 2),
                  // Estrellas
                  const Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      Icon(Icons.star, size: 12, color: Colors.amber),
                      Icon(Icons.star_half, size: 12, color: Colors.amber),
                    ],
                  ),
                  const SizedBox(height: 2),
                  // Precio
                  Text(
                    '\$${product.unitPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  // Stock
                  Text(
                    'Stock: ${product.stock}',
                    style: const TextStyle(fontSize: 9, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  // Botón Agregar — ahora agrega al CartProvider
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: product.stock > 0
                          ? () {
                              // Agregar al carrito global
                              Provider.of<CartProvider>(context, listen: false)
                                  .addProduct(product);
                              // Callback original para el snackbar
                              onAddToCart();
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        backgroundColor: const Color(0xFF0964AF),
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontSize: 10),
                        minimumSize: const Size(0, 28),
                      ),
                      child: const Text('Agregar'),
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

  Widget _buildImagePlaceholder() {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
    );
  }
}