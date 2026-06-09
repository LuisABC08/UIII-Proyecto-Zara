import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_model.dart';
import '../models/product_model.dart';

class CartService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<CartItemModel> _items = [];
  List<CartItemModel> get items => _items;

  double get subtotal =>
      _items.fold(0, (sum, item) => sum + item.subtotal);
  double get total => subtotal; // envío gratis
  int get itemCount => _items.fold(0, (sum, item) => sum + item.cantidad);

  Future<void> loadCart(String uid) async {
    final snap =
        await _db.collection('carrito').doc(uid).collection('items').get();
    _items =
        snap.docs.map((d) => CartItemModel.fromMap(d.data(), d.id)).toList();
    notifyListeners();
  }

  Future<void> addToCart(String uid, ProductModel product) async {
    final existing = _items.firstWhere(
      (i) => i.productoId == product.id,
      orElse: () => CartItemModel(
        id: '',
        productoId: '',
        nombre: '',
        precio: 0,
        cantidad: 0,
        imageUrl: '',
        talla: '',
        color: '',
        categoria: '',
      ),
    );

    if (existing.productoId == product.id) {
      existing.cantidad++;
      await _db
          .collection('carrito')
          .doc(uid)
          .collection('items')
          .doc(existing.id)
          .update({'cantidad': existing.cantidad});
    } else {
      final item = CartItemModel(
        id: '',
        productoId: product.id,
        nombre: product.nombre,
        precio: product.precio,
        cantidad: 1,
        imageUrl: product.imageUrl,
        talla: product.talla,
        color: product.color,
        categoria: product.categoria,
      );
      final doc = await _db
          .collection('carrito')
          .doc(uid)
          .collection('items')
          .add(item.toMap());
      _items.add(CartItemModel(
        id: doc.id,
        productoId: item.productoId,
        nombre: item.nombre,
        precio: item.precio,
        cantidad: item.cantidad,
        imageUrl: item.imageUrl,
        talla: item.talla,
        color: item.color,
        categoria: item.categoria,
      ));
    }
    notifyListeners();
  }

  Future<void> updateQuantity(String uid, CartItemModel item, int qty) async {
    if (qty <= 0) {
      await removeItem(uid, item);
      return;
    }
    item.cantidad = qty;
    await _db
        .collection('carrito')
        .doc(uid)
        .collection('items')
        .doc(item.id)
        .update({'cantidad': qty});
    notifyListeners();
  }

  Future<void> removeItem(String uid, CartItemModel item) async {
    _items.remove(item);
    await _db
        .collection('carrito')
        .doc(uid)
        .collection('items')
        .doc(item.id)
        .delete();
    notifyListeners();
  }

  Future<void> checkout(String uid) async {
    final order = {
      'userId': uid,
      'items': _items.map((i) => i.toMap()).toList(),
      'subtotal': subtotal,
      'total': total,
      'estado': 'pendiente',
      'fecha': FieldValue.serverTimestamp(),
    };
    await _db.collection('pedidos').add(order);
    // Limpiar carrito
    final snap = await _db
        .collection('carrito')
        .doc(uid)
        .collection('items')
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
    _items = [];
    notifyListeners();
  }

  void clearLocal() {
    _items = [];
    notifyListeners();
  }
}
