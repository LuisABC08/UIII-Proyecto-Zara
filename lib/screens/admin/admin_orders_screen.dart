import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/cart_model.dart';

class AdminOrdersScreen extends StatelessWidget {
  const AdminOrdersScreen({super.key});

  static const _estados = ['pendiente', 'procesando', 'enviado', 'entregado'];

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'procesando': return const Color(0xFF1565C0);
      case 'enviado':    return const Color(0xFF2E7D32);
      case 'entregado':  return Colors.black;
      default:           return Colors.black45;
    }
  }

  Future<void> _updateEstado(String pedidoId, String nuevoEstado) async {
    await FirebaseFirestore.instance
        .collection('pedidos')
        .doc(pedidoId)
        .update({'estado': nuevoEstado});
  }

  void _showEstadoDialog(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 3,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'CAMBIAR ESTADO',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pedido #${order.id.substring(0, 8).toUpperCase()}',
              style: const TextStyle(
                fontSize: 11,
                color: Colors.black45,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            ..._estados.map((estado) {
              final isSelected = order.estado == estado;
              return GestureDetector(
                onTap: () async {
                  await _updateEstado(order.id, estado);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.black : Colors.white,
                    border: Border.all(
                      color: isSelected ? Colors.black : Colors.black,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        estado.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: isSelected ? Colors.white : Colors.black,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(Icons.check, size: 16, color: Colors.white),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    'PEDIDOS',
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

            // Filtro por estado
            SizedBox(
              height: 44,
              child: _EstadoFilter(),
            ),
            const Divider(height: 1, color: Colors.black),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('pedidos')
                    .orderBy('fecha', descending: true)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 1.5),
                    );
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        'SIN PEDIDOS AÚN',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: Colors.black38,
                        ),
                      ),
                    );
                  }

                  final pedidos = snap.data!.docs;
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: pedidos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, i) {
                      final data =
                          pedidos[i].data() as Map<String, dynamic>;
                      final order = OrderModel.fromMap(data, pedidos[i].id);
                      return _AdminOrderCard(
                        order: order,
                        estadoColor: _estadoColor(order.estado),
                        onEditEstado: () =>
                            _showEstadoDialog(context, order),
                      );
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

// Widget interno de filtro por estado
class _EstadoFilter extends StatefulWidget {
  @override
  State<_EstadoFilter> createState() => _EstadoFilterState();
}

class _EstadoFilterState extends State<_EstadoFilter> {
  int _selected = 0;
  final _tabs = ['TODOS', 'PENDIENTE', 'PROCESANDO', 'ENVIADO', 'ENTREGADO'];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      itemCount: _tabs.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => setState(() => _selected = i),
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: _selected == i ? Colors.black : Colors.white,
            border: Border.all(
              color: _selected == i ? Colors.black : Colors.black,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            _tabs[i],
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: _selected == i ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final Color estadoColor;
  final VoidCallback onEditEstado;

  const _AdminOrderCard({
    required this.order,
    required this.estadoColor,
    required this.onEditEstado,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
                      '#${order.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.fecha.day}/${order.fecha.month}/${order.fecha.year}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Estado editable
                GestureDetector(
                  onTap: onEditEstado,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: estadoColor),
                    ),
                    child: Row(
                      children: [
                        Text(
                          order.estado.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: estadoColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.edit_outlined,
                            size: 10, color: estadoColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Cliente ID
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Text(
              'CLIENTE: ${order.userId.substring(0, 12)}...',
              style: const TextStyle(
                fontSize: 10,
                color: Colors.black38,
                letterSpacing: 0.5,
              ),
            ),
          ),

          // Items
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item['nombre']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      'x${item['cantidad']}  \$${(item['precio'] as num).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              )),

          // Total
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            margin: const EdgeInsets.only(top: 4),
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
}