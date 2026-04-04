import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';

class ProductProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Product> _products = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String _errorMessage = '';
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMore = true;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;

  // Cargar primera página (resetear lista)
  Future<void> fetchProducts({bool refresh = false}) async {
    if (refresh) {
      _products = [];
      _currentPage = 1;
      _hasMore = true;
    }

    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final response = await _apiService.getProducts(page: _currentPage);
      _products = response.data;
      _totalPages = response.totalPages;
      _hasMore = _currentPage < _totalPages;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cargar siguiente página (scroll infinito)
  Future<void> loadMoreProducts() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = _currentPage + 1;
      final response = await _apiService.getProducts(page: nextPage);
      
      _products.addAll(response.data);
      _currentPage = response.currentPage;
      _totalPages = response.totalPages;
      _hasMore = _currentPage < _totalPages;
    } catch (e) {
      // No mostrar error en scroll infinito para no molestar
      print('Error loading more products: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Limpiar errores
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Obtener producto por ID (de la lista cacheada)
  Product? getProductById(int id) {
    try {
      return _products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
}