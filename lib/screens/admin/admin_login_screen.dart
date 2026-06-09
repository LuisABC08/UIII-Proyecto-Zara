import 'package:flutter/material.dart';
import 'admin_panel_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscure1 = true;
  bool _obscure2 = true;
  String? _error;

  // Credenciales hardcoded de admin (puedes moverlas a Firestore)
  static const _adminUser = 'admin';
  static const _adminPass = 'zara2024';

  void _login() {
    if (_passCtrl.text != _confirmCtrl.text) {
      setState(() => _error = 'Las contraseñas no coinciden');
      return;
    }
    if (_userCtrl.text == _adminUser && _passCtrl.text == _adminPass) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminPanelScreen()),
      );
    } else {
      setState(() => _error = 'Credenciales incorrectas');
    }
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.arrow_back, size: 22),
              ),
              const SizedBox(height: 56),

              const Text(
                'SISTEMA DE',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  height: 1,
                ),
              ),
              const Text(
                'ADMINISTRACIÓN',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 4,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(width: 40, height: 1.5, color: Colors.black),
              const SizedBox(height: 48),

              _AdminField(
                controller: _userCtrl,
                label: 'USUARIO',
              ),
              const SizedBox(height: 24),
              _AdminField(
                controller: _passCtrl,
                label: 'CONTRASEÑA',
                obscure: _obscure1,
                onToggle: () => setState(() => _obscure1 = !_obscure1),
              ),
              const SizedBox(height: 24),
              _AdminField(
                controller: _confirmCtrl,
                label: 'CONFIRMAR CONTRASEÑA',
                obscure: _obscure2,
                onToggle: () => setState(() => _obscure2 = !_obscure2),
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style:
                      const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],

              const SizedBox(height: 48),

              GestureDetector(
                onTap: _login,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text(
                    'INGRESAR',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback? onToggle;

  const _AdminField({
    required this.controller,
    required this.label,
    this.obscure = false,
    this.onToggle,
  });

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
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
            suffixIcon: onToggle != null
                ? GestureDetector(
                    onTap: onToggle,
                    child: Icon(
                      obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                      color: Colors.black38,
                    ),
                  )
                : null,
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black26, width: 1),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black, width: 1.5),
            ),
            border: InputBorder.none,
          ),
        ),
      ],
    );
  }
}
