import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/cart_model.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key});

  Color _estadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'procesando':
        return const Color(0xFF1565C0);
      case 'enviado':
        return const Color(0xFF2E7D32);
      case 'entregado':
        return Colors.black;
      default:
        return Colors.black45;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthService>().currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Text(
            'INICIA SESIÓN PARA VER TUS PEDIDOS',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 3,
              color: Colors.black38,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    final uid = user.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                  const Spacer(),
                  const Text(
                    'MIS PEDIDOS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pedidos')
                    .where('userId', isEqualTo: uid)
                    .snapshots(),

                builder: (context, snap) {
                  // Manejar errores del stream
                  if (snap.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.black26,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snap.error}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Si el error persiste, verifica\nque el índice de Firestore esté creado',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 1.5,
                      ),
                    );
                  }

                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_bag_outlined,
                            size: 52,
                            color: Colors.black,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'AÚN NO TIENES PEDIDOS',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 3,
                              color: Colors.black38,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final pedidos = snap.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: pedidos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      try {
                        final data = pedidos[i].data() as Map<String, dynamic>;
                        final order = OrderModel.fromMap(data, pedidos[i].id);
                        return _OrderCard(
                          order: order,
                          estadoColor: _estadoColor(order.estado),
                        );
                      } catch (e) {
                        // Si un pedido tiene datos corruptos, no rompe toda la lista
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Text(
                            'Error al cargar pedido: $e',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final Color estadoColor;
  const _OrderCard({required this.order, required this.estadoColor});

  @override
  Widget build(BuildContext context) {
    // Seguridad para el ID
    final orderId = order.id.length >= 8
        ? order.id.substring(0, 8).toUpperCase()
        : order.id.toUpperCase();

    // Seguridad para items - manejar tanto List<Map> como List<<CartItemModel>
    final items = _parseItems(order.items);

    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header del pedido
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black)),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PEDIDO #$orderId',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${order.fecha.day}/${order.fecha.month}/${order.fecha.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: estadoColor),
                  ),
                  child: Text(
                    order.estado.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                      color: estadoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items del pedido
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['nombre'] ?? 'Producto',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${item['talla'] ?? 'N/A'} · ${item['color'] ?? 'N/A'}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'x${item['cantidad'] ?? 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.black45,
                        ),
                      ),
                      Text(
                        '\$${_parsePrecio(item['precio'])}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: Color(0xFFF9F9F9),
              border: Border(top: BorderSide(color: Colors.black)),
            ),
            child: Row(
              children: [
                const Text(
                  'TOTAL',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${order.total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper para parsear items de forma segura
  List<Map<String, dynamic>> _parseItems(dynamic items) {
    if (items == null) return [];
    if (items is List<Map<String, dynamic>>) return items;
    if (items is List) {
      return items.map((e) {
        if (e is Map<String, dynamic>) return e;
        // Si es CartItemModel, convertir a Map
        if (e is CartItemModel) {
          return {
            'nombre': e.nombre,
            'talla': e.talla,
            'color': e.color,
            'cantidad': e.cantidad,
            'precio': e.precio,
            'imageUrl': e.imageUrl,
          };
        }
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  // Helper para parsear precio de forma segura
  String _parsePrecio(dynamic precio) {
    if (precio == null) return '0';
    if (precio is num) return precio.toStringAsFixed(0);
    if (precio is String) {
      final parsed = double.tryParse(precio);
      return parsed?.toStringAsFixed(0) ?? '0';
    }
    return '0';
  }
}
