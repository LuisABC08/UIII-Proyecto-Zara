import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _contentController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  bool _showButtons = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );
    _logoScale = Tween<double>(begin: 0.85, end: 1).animate(
      CurvedAnimation(
          parent: _logoController,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut)),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeIn),
    );
    _contentSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    _runAnimation();
  }

  Future<void> _runAnimation() async {
    await _logoController.forward();
    await Future.delayed(const Duration(milliseconds: 400));

    // Check if user already logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && mounted) {
      await context.read<AuthService>().loadCurrentUser();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        return;
      }
    }

    if (mounted) {
      setState(() => _showButtons = true);
      _contentController.forward();
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // Logo central
              FadeTransition(
                opacity: _logoFade,
                child: ScaleTransition(
                  scale: _logoScale,
                  child: Column(
                    children: [
                      // Línea decorativa superior
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.black,
                        margin: const EdgeInsets.only(bottom: 32),
                      ),
                      const Text(
                        'ZARA',
                        style: TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 18,
                          color: Colors.black,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'FASHION STORE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 6,
                          color: Colors.black45,
                        ),
                      ),
                      // Línea decorativa inferior
                      Container(
                        width: 40,
                        height: 1,
                        color: Colors.black,
                        margin: const EdgeInsets.only(top: 32),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 3),

              // Botones
              if (_showButtons)
                SlideTransition(
                  position: _contentSlide,
                  child: FadeTransition(
                    opacity: _contentFade,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Iniciar sesión — botón negro sólido
                        _ZaraButton(
                          label: 'INICIAR SESIÓN',
                          filled: true,
                          onTap: () => Navigator.push(
                            context,
                            _fade(const LoginScreen()),
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Registrarse — botón outline
                        _ZaraButton(
                          label: 'CREAR CUENTA',
                          filled: false,
                          onTap: () => Navigator.push(
                            context,
                            _fade(const RegisterScreen()),
                          ),
                        ),
                        const SizedBox(height: 48),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  PageRouteBuilder _fade(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      );
}

class _ZaraButton extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ZaraButton({
    required this.label,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 52,
        decoration: BoxDecoration(
          color: filled ? Colors.black : Colors.transparent,
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 3,
            color: filled ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
