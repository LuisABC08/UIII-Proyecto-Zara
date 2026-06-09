class ProductModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final String categoria; // camisas, pantalones, faldas, shorts, calzado
  final String talla;
  final String color;
  final String imageUrl;
  final int stock;

  ProductModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    required this.talla,
    required this.color,
    required this.imageUrl,
    required this.stock,
  });

  factory ProductModel.fromMap(Map<String, dynamic> map, String id) {
    return ProductModel(
      id: id,
      nombre: map['nombre'] ?? '',
      descripcion: map['descripcion'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      categoria: map['categoria'] ?? '',
      talla: map['talla'] ?? '',
      color: map['color'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      stock: map['stock'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'categoria': categoria,
        'talla': talla,
        'color': color,
        'imageUrl': imageUrl,
        'stock': stock,
      };
}
