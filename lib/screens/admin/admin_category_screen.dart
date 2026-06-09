import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';

class AdminCategoryScreen extends StatelessWidget {
  final String categoria;
  final String titulo;

  const AdminCategoryScreen(
      {super.key, required this.categoria, required this.titulo});

  @override
  Widget build(BuildContext context) {
    final service = ProductService();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
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
                  // Botón agregar
                  GestureDetector(
                    onTap: () => _showProductDialog(context, service, null),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                      child: const Icon(Icons.add, size: 18),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: service.getByCategory(categoria),
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
                          const SizedBox(height: 12),
                          const Text(
                            'Sin productos. Toca + para agregar.',
                            style: TextStyle(
                                color: Colors.black45,
                                fontSize: 13,
                                letterSpacing: 0.3),
                          ),
                        ],
                      ),
                    );
                  }
                  final productos = snap.data!;
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: productos.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: Colors.black),
                    itemBuilder: (context, i) => _AdminProductItem(
                      product: productos[i],
                      onEdit: () =>
                          _showProductDialog(context, service, productos[i]),
                      onDelete: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: Colors.white,
                            title: const Text(
                              'ELIMINAR PRODUCTO',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 2,
                              ),
                            ),
                            content: const Text(
                              '¿Estás segura de eliminar este producto?',
                              style: TextStyle(fontSize: 13),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, false),
                                child: const Text('CANCELAR',
                                    style: TextStyle(color: Colors.black54)),
                              ),
                              TextButton(
                                onPressed: () =>
                                    Navigator.pop(context, true),
                                child: const Text('ELIMINAR',
                                    style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await service.deleteProduct(productos[i].id);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDialog(
      BuildContext context, ProductService service, ProductModel? product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _ProductFormSheet(
        service: service,
        product: product,
        categoria: categoria,
      ),
    );
  }
}

class _AdminProductItem extends StatelessWidget {
  final ProductModel product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminProductItem(
      {required this.product,
      required this.onEdit,
      required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          // Imagen
          Container(
            width: 64,
            height: 80,
            color: const Color(0xFFF5F5F5),
            child: product.imageUrl.isNotEmpty
                ? Image.network(
                    product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.image_not_supported_outlined,
                            size: 22, color: Colors.black26),
                  )
                : const Icon(Icons.checkroom_outlined,
                    size: 24, color: Colors.black26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.talla} · ${product.color}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black45,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${product.precio.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          // Acciones
          Column(
            children: [
              GestureDetector(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.edit_outlined, size: 20),
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.delete_outline,
                      size: 20, color: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductFormSheet extends StatefulWidget {
  final ProductService service;
  final ProductModel? product;
  final String categoria;

  const _ProductFormSheet(
      {required this.service,
      required this.product,
      required this.categoria});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late final TextEditingController _nombreCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _precioCtrl;
  late final TextEditingController _tallaCtrl;
  late final TextEditingController _colorCtrl;
  late final TextEditingController _imageCtrl;
  late final TextEditingController _stockCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCtrl =
        TextEditingController(text: p != null ? '${p.precio.toInt()}' : '');
    _tallaCtrl = TextEditingController(text: p?.talla ?? '');
    _colorCtrl = TextEditingController(text: p?.color ?? '');
    _imageCtrl = TextEditingController(text: p?.imageUrl ?? '');
    _stockCtrl =
        TextEditingController(text: p != null ? '${p.stock}' : '');
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descCtrl.dispose();
    _precioCtrl.dispose();
    _tallaCtrl.dispose();
    _colorCtrl.dispose();
    _imageCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final p = ProductModel(
      id: widget.product?.id ?? '',
      nombre: _nombreCtrl.text.trim(),
      descripcion: _descCtrl.text.trim(),
      precio: double.tryParse(_precioCtrl.text) ?? 0,
      categoria: widget.categoria,
      talla: _tallaCtrl.text.trim(),
      color: _colorCtrl.text.trim(),
      imageUrl: _imageCtrl.text.trim(),
      stock: int.tryParse(_stockCtrl.text) ?? 0,
    );

    if (widget.product == null) {
      await widget.service.addProduct(p);
    } else {
      await widget.service.updateProduct(p);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 28, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Text(
              isEdit ? 'EDITAR PRODUCTO' : 'NUEVO PRODUCTO',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 24),

            _FormField(ctrl: _nombreCtrl, label: 'NOMBRE'),
            const SizedBox(height: 18),
            _FormField(ctrl: _descCtrl, label: 'DESCRIPCIÓN'),
            const SizedBox(height: 18),
            _FormField(
                ctrl: _precioCtrl,
                label: 'PRECIO',
                keyboard: TextInputType.number),
            const SizedBox(height: 18),
            _FormField(ctrl: _tallaCtrl, label: 'TALLA'),
            const SizedBox(height: 18),
            _FormField(ctrl: _colorCtrl, label: 'COLOR'),
            const SizedBox(height: 18),
            _FormField(
                ctrl: _stockCtrl,
                label: 'STOCK',
                keyboard: TextInputType.number),
            const SizedBox(height: 18),
            _FormField(ctrl: _imageCtrl, label: 'URL DE IMAGEN'),
            const SizedBox(height: 32),

            GestureDetector(
              onTap: _loading ? null : _save,
              child: Container(
                width: double.infinity,
                height: 50,
                color: Colors.black,
                alignment: Alignment.center,
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 1.5),
                      )
                    : Text(
                        isEdit ? 'GUARDAR CAMBIOS' : 'AGREGAR PRODUCTO',
                        style: const TextStyle(
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
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboard;

  const _FormField(
      {required this.ctrl, required this.label, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
            color: Colors.black45,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26, width: 1),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }
}