class CartItemModel {
  final String id;
  final String productoId;
  final String nombre;
  final double precio;
  int cantidad;
  final String imageUrl;
  final String talla;
  final String color;
  final String categoria;

  CartItemModel({
    required this.id,
    required this.productoId,
    required this.nombre,
    required this.precio,
    required this.cantidad,
    required this.imageUrl,
    required this.talla,
    required this.color,
    required this.categoria,
  });

  factory CartItemModel.fromMap(Map<String, dynamic> map, String id) {
    return CartItemModel(
      id: id,
      productoId: map['productoId'] ?? '',
      nombre: map['nombre'] ?? '',
      precio: (map['precio'] ?? 0).toDouble(),
      cantidad: map['cantidad'] ?? 1,
      imageUrl: map['imageUrl'] ?? '',
      talla: map['talla'] ?? '',
      color: map['color'] ?? '',
      categoria: map['categoria'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'nombre': nombre,
        'precio': precio,
        'cantidad': cantidad,
        'imageUrl': imageUrl,
        'talla': talla,
        'color': color,
        'categoria': categoria,
      };

  double get subtotal => precio * cantidad;
}

class OrderModel {
  final String id;
  final String userId;
  final List<Map<String, dynamic>> items;
  final double subtotal;
  final double total;
  final String estado; // pendiente, procesando, enviado, entregado
  final DateTime fecha;

  OrderModel({
    required this.id,
    required this.userId,
    required this.items,
    required this.subtotal,
    required this.total,
    required this.estado,
    required this.fecha,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    return OrderModel(
      id: id,
      userId: map['userId'] ?? '',
      items: List<Map<String, dynamic>>.from(map['items'] ?? []),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      total: (map['total'] ?? 0).toDouble(),
      estado: map['estado'] ?? 'pendiente',
      fecha: (map['fecha'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'items': items,
        'subtotal': subtotal,
        'total': total,
        'estado': estado,
        'fecha': fecha,
      };
}
