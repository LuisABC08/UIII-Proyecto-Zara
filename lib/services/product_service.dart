import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'productos';

  Stream<List<ProductModel>> getByCategory(String categoria) {
    return _db
        .collection(_col)
        .where('categoria', isEqualTo: categoria)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());
  }

  Stream<List<ProductModel>> getAll() {
    return _db.collection(_col).snapshots().map(
        (s) => s.docs.map((d) => ProductModel.fromMap(d.data(), d.id)).toList());
  }

  Future<void> addProduct(ProductModel p) async {
    await _db.collection(_col).add(p.toMap());
  }

  Future<void> updateProduct(ProductModel p) async {
    await _db.collection(_col).doc(p.id).update(p.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _db.collection(_col).doc(id).delete();
  }
}
