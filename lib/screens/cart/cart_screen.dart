import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../models/cart_model.dart';
import '../cart/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();
    final auth = context.read<AuthService>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
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
                    'CARRITO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.shopping_bag_outlined, size: 22),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            if (cart.items.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        size: 56,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'TU CARRITO ESTÁ VACÍO',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 14,
                          ),
                          color: Colors.black,
                          child: const Text(
                            'EXPLORAR',
                            style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 3,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cart.items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Colors.black),
                  itemBuilder: (context, i) => _CartItem(
                    item: cart.items[i],
                    uid: auth.currentUser!.uid,
                  ),
                ),
              ),

              // Resumen pedido
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: Colors.black12, width: 1),
                  ),
                ),
                child: Column(
                  children: [
                    _SummaryRow(
                      label: 'SUBTOTAL',
                      value: '\$${cart.subtotal.toStringAsFixed(0)}',
                    ),
                    const SizedBox(height: 8),
                    const _SummaryRow(label: 'ENVÍO', value: 'GRATIS'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.black26),
                    ),
                    _SummaryRow(
                      label: 'TOTAL',
                      value: '\$${cart.total.toStringAsFixed(0)}',
                      bold: true,
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CheckoutScreen(),
                        ),
                      ),
                      child: Container(
                        width: double.infinity,
                        height: 52,
                        color: Colors.black,
                        alignment: Alignment.center,
                        child: const Text(
                          'FINALIZAR COMPRA',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 3,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  final CartItemModel item;
  final String uid;
  const _CartItem({required this.item, required this.uid});

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartService>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Container(
            width: 80,
            height: 100,
            color: const Color(0xFFF5F5F5),
            child: item.imageUrl.isNotEmpty
                ? Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1,
                          color: Colors.black26,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.checkroom_outlined,
                      color: Colors.black26,
                      size: 30,
                    ),
                  )
                : const Icon(
                    Icons.checkroom_outlined,
                    color: Colors.black26,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.talla} · ${item.color}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${item.precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                // Cantidad
                Row(
                  children: [
                    _QtyButton(
                      icon: Icons.remove,
                      onTap: () =>
                          cart.updateQuantity(uid, item, item.cantidad - 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${item.cantidad}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    _QtyButton(
                      icon: Icons.add,
                      onTap: () =>
                          cart.updateQuantity(uid, item, item.cantidad + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Eliminar
          GestureDetector(
            onTap: () => cart.removeItem(uid, item),
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.delete_outline,
                size: 20,
                color: Colors.black38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(border: Border.all(color: Colors.black26)),
        child: Icon(icon, size: 14),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: bold ? 13 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 1.5,
            color: bold ? Colors.black : Colors.black54,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 14 : 12,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
