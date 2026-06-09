import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  UserModel? _userModel;
  UserModel? get userModel => _userModel;

  Future<String?> register({
    required String nombre,
    required String apellidos,
    required String correo,
    required String edad,
    required String username,
    required String password,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: correo,
        password: password,
      );
      final user = UserModel(
        uid: cred.user!.uid,
        nombre: nombre,
        apellidos: apellidos,
        correo: correo,
        edad: edad,
        username: username,
        rol: 'user',
      );
      await _db.collection('users').doc(cred.user!.uid).set(user.toMap());
      _userModel = user;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<String?> login(String correo, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: correo,
        password: password,
      );
      await _loadUser(cred.user!.uid);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    }
  }

  Future<void> _loadUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      _userModel = UserModel.fromMap(doc.data()!, uid);
    }
  }

  Future<void> loadCurrentUser() async {
    if (_auth.currentUser != null) {
      await _loadUser(_auth.currentUser!.uid);
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userModel = null;
    notifyListeners();
  }

  bool get isAdmin => _userModel?.rol == 'admin';

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Este correo ya está registrado';
      case 'invalid-email':
        return 'Correo inválido';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres';
      case 'user-not-found':
        return 'Usuario no encontrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Error al autenticar. Intenta de nuevo';
    }
  }
}
