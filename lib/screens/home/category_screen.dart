import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import '../../models/product_model.dart';

class CategoryScreen extends StatelessWidget {
  final String categoria;
  final String titulo;

  const CategoryScreen(
      {super.key, required this.categoria, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final productService = ProductService();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                  const Spacer(),
                  Text(
                    titulo,
                    style: const TextStyle(
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
              child: StreamBuilder<List<ProductModel>>(
                stream: productService.getByCategory(categoria),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Colors.black, strokeWidth: 1.5),
                    );
                  }
                  if (!snap.hasData || snap.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inventory_2_outlined,
                              size: 48, color: Colors.black26),
                          const SizedBox(height: 16),
                          Text(
                            'Sin productos en $titulo',
                            style: const TextStyle(
                              color: Colors.black45,
                              letterSpacing: 1,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final productos = snap.data!;
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: productos.length,
                    itemBuilder: (context, i) =>
                        _ProductCard(product: productos[i]),
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

class _ProductCard extends StatefulWidget {
  final ProductModel product;
  const _ProductCard({required this.product});

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _adding = false;

  Future<void> _addToCart() async {
    setState(() => _adding = true);
    final auth = context.read<AuthService>();
    final cart = context.read<CartService>();
    if (auth.currentUser != null) {
      await cart.addToCart(auth.currentUser!.uid, widget.product);
    }
    if (mounted) setState(() => _adding = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.product.nombre} añadido al carrito',
            style: const TextStyle(letterSpacing: 0.5, fontSize: 12),
          ),
          backgroundColor: Colors.black,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen
          Expanded(
            child: Container(
              color: const Color(0xFFF8F8F8),
              child: widget.product.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                              strokeWidth: 1, color: Colors.black26),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                        child: Icon(Icons.image_not_supported_outlined,
                            color: Colors.black26),
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.checkroom_outlined,
                          size: 40, color: Colors.black26),
                    ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.product.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${widget.product.precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),

          // Botón añadir
          GestureDetector(
            onTap: _adding ? null : _addToCart,
            child: Container(
              margin: const EdgeInsets.all(10),
              height: 36,
              color: Colors.black,
              alignment: Alignment.center,
              child: _adding
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 1.5),
                    )
                  : const Text(
                      'AÑADIR',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                        color: Colors.white,
                      ),
                    ),
          ),
          ),
        ],
      ),
    );
  }
}