class Product {
  final int id;
  final String nameProduct;
  final String? description;  // 👈 NUEVO CAMPO
  final double unitPrice;
  final int stock;
  final String status;
  final int categoryId;
  final String? imagen;
  final Category? category;

  Product({
    required this.id,
    required this.nameProduct,
    this.description,  // 👈 NUEVO CAMPO
    required this.unitPrice,
    required this.stock,
    required this.status,
    required this.categoryId,
    this.imagen,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      nameProduct: json['nameProduct'],
      description: json['description'],  // 👈 NUEVO CAMPO
      unitPrice: (json['unitPrice'] as num).toDouble(),
      stock: json['stock'],
      status: json['status'],
      categoryId: json['categoryId'],
      imagen: json['imagen'],
      category: json['Category'] != null
          ? Category.fromJson(json['Category'])
          : null,
    );
  }
}

class Category {
  final int categoryId;
  final String categoryName;

  Category({
    required this.categoryId,
    required this.categoryName,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['category_id'],
      categoryName: json['category_name'],
    );
  }
}

class ProductsPaginatedResponse {
  final int totalItems;
  final int totalPages;
  final int currentPage;
  final List<Product> data;

  ProductsPaginatedResponse({
    required this.totalItems,
    required this.totalPages,
    required this.currentPage,
    required this.data,
  });

  factory ProductsPaginatedResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> dataList = json['data'];
    return ProductsPaginatedResponse(
      totalItems: json['totalItems'],
      totalPages: json['totalPages'],
      currentPage: json['currentPage'],
      data: dataList.map((item) => Product.fromJson(item)).toList(),
    );
  }
}