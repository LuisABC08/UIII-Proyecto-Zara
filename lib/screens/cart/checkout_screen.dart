
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _db = FirebaseFirestore.instance;

  // Pasos: 0 = dirección, 1 = tarjeta, 2 = confirmación
  int _step = 0;
  bool _loading = false;
  bool _loadingSaved = true;

  // Dirección
  final _calleCtrl     = TextEditingController();
  final _ciudadCtrl    = TextEditingController();
  final _estadoCtrl    = TextEditingController();
  final _cpCtrl        = TextEditingController();
  final _telefonoCtrl  = TextEditingController();

  // Tarjeta
  final _nombreTCtrl   = TextEditingController();
  final _numeroCtrl    = TextEditingController();
  final _vencCtrl      = TextEditingController();
  final _cvvCtrl       = TextEditingController();

  bool _guardarDireccion = true;
  bool _guardarTarjeta   = true;

  // Datos guardados previos
  Map<String, dynamic>? _savedAddress;
  Map<String, dynamic>? _savedCard;
  bool _usingSavedAddress = false;
  bool _usingSavedCard    = false;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final uid = context.read<AuthService>().currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!mounted) return;
    final data = doc.data();
    if (data != null) {
      if (data['direccion'] != null) {
        _savedAddress = Map<String, dynamic>.from(data['direccion']);
        _fillAddress(_savedAddress!);
        setState(() => _usingSavedAddress = true);
      }
      if (data['tarjeta'] != null) {
        _savedCard = Map<String, dynamic>.from(data['tarjeta']);
        _fillCard(_savedCard!);
        setState(() => _usingSavedCard = true);
      }
    }
    setState(() => _loadingSaved = false);
  }

  void _fillAddress(Map<String, dynamic> d) {
    _calleCtrl.text    = d['calle']    ?? '';
    _ciudadCtrl.text   = d['ciudad']   ?? '';
    _estadoCtrl.text   = d['estado']   ?? '';
    _cpCtrl.text       = d['cp']       ?? '';
    _telefonoCtrl.text = d['telefono'] ?? '';
  }

  void _fillCard(Map<String, dynamic> d) {
    _nombreTCtrl.text = d['nombre']  ?? '';
    _numeroCtrl.text  = d['numero']  ?? '';
    _vencCtrl.text    = d['venc']    ?? '';
    // CVV nunca se rellena por seguridad
  }

  void _clearAddress() {
    _calleCtrl.clear(); _ciudadCtrl.clear();
    _estadoCtrl.clear(); _cpCtrl.clear(); _telefonoCtrl.clear();
  }

  void _clearCard() {
    _nombreTCtrl.clear(); _numeroCtrl.clear();
    _vencCtrl.clear(); _cvvCtrl.clear();
  }

  String get _cardDisplay {
    final n = _numeroCtrl.text.replaceAll(' ', '');
    if (n.length < 4) return '**** **** **** ****';
    return '**** **** **** ${n.substring(n.length - 4)}';
  }

  bool get _addressValid =>
      _calleCtrl.text.isNotEmpty &&
      _ciudadCtrl.text.isNotEmpty &&
      _estadoCtrl.text.isNotEmpty &&
      _cpCtrl.text.isNotEmpty &&
      _telefonoCtrl.text.isNotEmpty;

  bool get _cardValid =>
      _nombreTCtrl.text.isNotEmpty &&
      _numeroCtrl.text.replaceAll(' ', '').length == 16 &&
      _vencCtrl.text.length == 5 &&
      _cvvCtrl.text.length >= 3;

  Future<void> _placeOrder() async {
    setState(() => _loading = true);
    final auth = context.read<AuthService>();
    final cart = context.read<CartService>();
    final uid  = auth.currentUser!.uid;

    final direccion = {
      'calle':    _calleCtrl.text.trim(),
      'ciudad':   _ciudadCtrl.text.trim(),
      'estado':   _estadoCtrl.text.trim(),
      'cp':       _cpCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
    };

    final tarjeta = {
      'nombre': _nombreTCtrl.text.trim(),
      'numero': _numeroCtrl.text.trim(),
      'venc':   _vencCtrl.text.trim(),
    };

    // Guardar datos si el usuario lo pidió
    final Map<String, dynamic> updates = {};
    if (_guardarDireccion) updates['direccion'] = direccion;
    if (_guardarTarjeta)   updates['tarjeta']   = tarjeta;
    if (updates.isNotEmpty) {
      await _db.collection('users').doc(uid).update(updates);
    }

    // Crear pedido
    await _db.collection('pedidos').add({
      'userId':    uid,
      'items':     cart.items.map((i) => i.toMap()).toList(),
      'subtotal':  cart.subtotal,
      'total':     cart.total,
      'estado':    'pendiente',
      'direccion': direccion,
      'tarjeta':   '**** **** **** ${_numeroCtrl.text.replaceAll(' ', '').substring(12)}',
      'fecha':     FieldValue.serverTimestamp(),
    });

    // Vaciar carrito
    await cart.checkout(uid);

    if (mounted) {
      setState(() => _loading = false);
      _showSuccess();
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: const BoxDecoration(
                  color: Colors.black, shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 20),
              const Text(
                'PEDIDO CONFIRMADO',
                style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Te notificaremos cuando\ntu pedido sea enviado.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13, color: Colors.black45, height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity, height: 48,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text(
                    'SEGUIR COMPRANDO',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600,
                      letterSpacing: 3, color: Colors.white,
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

  @override
  void dispose() {
    _calleCtrl.dispose(); _ciudadCtrl.dispose(); _estadoCtrl.dispose();
    _cpCtrl.dispose(); _telefonoCtrl.dispose(); _nombreTCtrl.dispose();
    _numeroCtrl.dispose(); _vencCtrl.dispose(); _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartService>();

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
                    onTap: () => _step > 0
                        ? setState(() => _step--)
                        : Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 22),
                  ),
                  const Spacer(),
                  const Text(
                    'CHECKOUT',
                    style: TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 22),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            // Indicador de pasos
            _StepIndicator(currentStep: _step),

            const Divider(height: 1, color: Colors.black),

            if (_loadingSaved)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                      color: Colors.black, strokeWidth: 1.5),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_step == 0) _buildAddressStep(),
                      if (_step == 1) _buildCardStep(),
                      if (_step == 2) _buildConfirmStep(cart),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

            // Botón inferior
            _buildBottomButton(cart),
          ],
        ),
      ),
    );
  }

  // ── PASO 0: DIRECCIÓN ──────────────────────────────────────────
  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'DIRECCIÓN DE ENTREGA'),
        const SizedBox(height: 4),

        // Usar guardada
        if (_savedAddress != null)
          _SavedDataBanner(
            icon: Icons.location_on_outlined,
            label: '${_savedAddress!['calle']}, ${_savedAddress!['ciudad']}',
            using: _usingSavedAddress,
            onToggle: () {
              setState(() {
                _usingSavedAddress = !_usingSavedAddress;
                if (_usingSavedAddress) {
                  _fillAddress(_savedAddress!);
                } else {
                  _clearAddress();
                }
              });
            },
          ),

        const SizedBox(height: 20),
        _Field(ctrl: _calleCtrl,    label: 'CALLE Y NÚMERO'),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _Field(ctrl: _ciudadCtrl, label: 'CIUDAD')),
            const SizedBox(width: 16),
            Expanded(child: _Field(ctrl: _estadoCtrl, label: 'ESTADO')),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(child: _Field(ctrl: _cpCtrl, label: 'CÓDIGO POSTAL',
                keyboard: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: _Field(ctrl: _telefonoCtrl, label: 'TELÉFONO',
                keyboard: TextInputType.phone)),
          ],
        ),
        const SizedBox(height: 24),
        _CheckOption(
          value: _guardarDireccion,
          label: 'Guardar dirección para futuras compras',
          onChanged: (v) => setState(() => _guardarDireccion = v),
        ),
      ],
    );
  }

  // ── PASO 1: TARJETA ────────────────────────────────────────────
  Widget _buildCardStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'MÉTODO DE PAGO'),
        const SizedBox(height: 4),

        if (_savedCard != null)
          _SavedDataBanner(
            icon: Icons.credit_card_outlined,
            label: '**** **** **** ${(_savedCard!['numero'] ?? '').toString().replaceAll(' ', '').substring(12)}',
            using: _usingSavedCard,
            onToggle: () {
              setState(() {
                _usingSavedCard = !_usingSavedCard;
                if (_usingSavedCard) {
                  _fillCard(_savedCard!);
                } else {
                  _clearCard();
                }
              });
            },
          ),

        const SizedBox(height: 20),

        // Vista previa de tarjeta
        _CardPreview(
          numero: _numeroCtrl.text,
          nombre: _nombreTCtrl.text,
          venc: _vencCtrl.text,
        ),

        const SizedBox(height: 24),
        _Field(ctrl: _nombreTCtrl, label: 'NOMBRE EN LA TARJETA',
            onChanged: (_) => setState(() {})),
        const SizedBox(height: 18),
        _Field(
          ctrl: _numeroCtrl,
          label: 'NÚMERO DE TARJETA',
          keyboard: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            _CardNumberFormatter(),
          ],
          maxLength: 19,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _Field(
                ctrl: _vencCtrl,
                label: 'MM/AA',
                keyboard: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _ExpiryFormatter(),
                ],
                maxLength: 5,
                onChanged: (_) => setState(() {}),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _Field(
                ctrl: _cvvCtrl,
                label: 'CVV',
                keyboard: TextInputType.number,
                obscure: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 4,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _CheckOption(
          value: _guardarTarjeta,
          label: 'Guardar tarjeta para futuras compras',
          onChanged: (v) => setState(() => _guardarTarjeta = v),
        ),
      ],
    );
  }

  // ── PASO 2: CONFIRMACIÓN ───────────────────────────────────────
  Widget _buildConfirmStep(CartService cart) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(title: 'RESUMEN DEL PEDIDO'),
        const SizedBox(height: 20),

        // Dirección
        _ConfirmBlock(
          icon: Icons.location_on_outlined,
          title: 'ENTREGA',
          content:
              '${_calleCtrl.text}\n${_ciudadCtrl.text}, ${_estadoCtrl.text} ${_cpCtrl.text}\nTel: ${_telefonoCtrl.text}',
          onEdit: () => setState(() => _step = 0),
        ),
        const SizedBox(height: 16),

        // Tarjeta
        _ConfirmBlock(
          icon: Icons.credit_card_outlined,
          title: 'PAGO',
          content: '${_nombreTCtrl.text}\n$_cardDisplay  ·  ${_vencCtrl.text}',
          onEdit: () => setState(() => _step = 1),
        ),
        const SizedBox(height: 24),

        // Productos
        const Text(
          'PRODUCTOS',
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            letterSpacing: 2, color: Colors.black45,
          ),
        ),
        const SizedBox(height: 12),
        ...cart.items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.nombre,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                        Text('${item.talla} · ${item.color}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.black45)),
                      ],
                    ),
                  ),
                  Text(
                    'x${item.cantidad}  \$${item.subtotal.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            )),

        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(color: Colors.black12),
        ),

        // Totales
        _TotalRow(label: 'SUBTOTAL',
            value: '\$${cart.subtotal.toStringAsFixed(0)}'),
        const SizedBox(height: 8),
        const _TotalRow(label: 'ENVÍO', value: 'GRATIS'),
        const SizedBox(height: 12),
        _TotalRow(
          label: 'TOTAL',
          value: '\$${cart.total.toStringAsFixed(0)}',
          bold: true,
        ),
      ],
    );
  }

  // ── BOTÓN INFERIOR ─────────────────────────────────────────────
  Widget _buildBottomButton(CartService cart) {
    String label;
    VoidCallback? action;

    if (_step == 0) {
      label = 'CONTINUAR AL PAGO';
      action = _addressValid ? () => setState(() => _step = 1) : null;
    } else if (_step == 1) {
      label = 'REVISAR PEDIDO';
      action = _cardValid ? () => setState(() => _step = 2) : null;
    } else {
      label = 'CONFIRMAR COMPRA  ·  \$${cart.total.toStringAsFixed(0)}';
      action = _loading ? null : _placeOrder;
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.black12)),
        color: Colors.white,
      ),
      child: GestureDetector(
        onTap: action,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 52,
          color: action != null ? Colors.black : Colors.black26,
          alignment: Alignment.center,
          child: _loading
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 1.5),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    letterSpacing: 2.5, color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

// ── WIDGETS AUXILIARES ─────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['DIRECCIÓN', 'PAGO', 'CONFIRMAR'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            return Container(
              width: 32, height: 1,
              color: i ~/ 2 < currentStep ? Colors.black : Colors.black,
            );
          }
          final step = i ~/ 2;
          final done = step < currentStep;
          final active = step == currentStep;
          return Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? Colors.black : Colors.transparent,
                  border: Border.all(
                    color: done || active ? Colors.black : Colors.black26,
                  ),
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w700,
                            color: active ? Colors.white : Colors.black38,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[step],
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 1.5,
                  color: active ? Colors.black : Colors.black38,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  final String numero;
  final String nombre;
  final String venc;
  const _CardPreview({required this.numero, required this.nombre, required this.venc});

  @override
  Widget build(BuildContext context) {
    final n = numero.replaceAll(' ', '');
    final display = n.isEmpty
        ? '**** **** **** ****'
        : numero.padRight(19, '*').substring(0, 19);

    return Container(
      width: double.infinity,
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.black),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('ZARA',
                  style: TextStyle(color: Colors.white, fontSize: 16,
                      fontWeight: FontWeight.w900, letterSpacing: 4)),
              const Spacer(),
              Container(
                width: 32, height: 20,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white38),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Icon(Icons.credit_card,
                    size: 14, color: Colors.white54),
              ),
            ],
          ),
          const Spacer(),
          Text(
            display,
            style: const TextStyle(
              color: Colors.white, fontSize: 18,
              letterSpacing: 2, fontWeight: FontWeight.w300,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TITULAR',
                      style: TextStyle(color: Colors.white38,
                          fontSize: 8, letterSpacing: 1.5)),
                  Text(
                    nombre.isEmpty ? '— — —' : nombre.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white, fontSize: 12, letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('VENCE',
                      style: TextStyle(color: Colors.white38,
                          fontSize: 8, letterSpacing: 1.5)),
                  Text(
                    venc.isEmpty ? 'MM/AA' : venc,
                    style: const TextStyle(
                      color: Colors.white, fontSize: 12, letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SavedDataBanner extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool using;
  final VoidCallback onToggle;
  const _SavedDataBanner({
    required this.icon, required this.label,
    required this.using, required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: using ? Colors.black : Colors.black),
          color: using ? Colors.black : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 16,
                color: using ? Colors.white : Colors.black54),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12, letterSpacing: 0.3,
                  color: using ? Colors.white : Colors.black54,
                ),
              ),
            ),
            Text(
              using ? 'USANDO GUARDADO' : 'USAR GUARDADO',
              style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: using ? Colors.white70 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final VoidCallback onEdit;
  const _ConfirmBlock({
    required this.icon, required this.title,
    required this.content, required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(border: Border.all(color: Colors.black12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      letterSpacing: 2, color: Colors.black45,
                    )),
                const SizedBox(height: 6),
                Text(content,
                    style: const TextStyle(
                      fontSize: 13, height: 1.5, color: Colors.black87,
                    )),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            child: const Text(
              'EDITAR',
              style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w700,
                letterSpacing: 1.5, decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 3,
            )),
        const SizedBox(height: 6),
        Container(width: 30, height: 1.5, color: Colors.black),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _TotalRow({required this.label, required this.value, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
              fontSize: bold ? 13 : 12, letterSpacing: 1.5,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
              color: bold ? Colors.black : Colors.black54,
            )),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontSize: bold ? 16 : 12,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
            )),
      ],
    );
  }
}

class _CheckOption extends StatelessWidget {
  final bool value;
  final String label;
  final ValueChanged<bool> onChanged;
  const _CheckOption({required this.value, required this.label, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          Container(
            width: 18, height: 18,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black45),
              color: value ? Colors.black : Colors.white,
            ),
            child: value
                ? const Icon(Icons.check, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboard;
  final bool obscure;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const _Field({
    required this.ctrl,
    required this.label,
    this.keyboard,
    this.obscure = false,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              letterSpacing: 2, color: Colors.black45,
            )),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          obscureText: obscure,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          decoration: const InputDecoration(
            isDense: true,
            counterText: '',
            contentPadding: EdgeInsets.symmetric(vertical: 10),
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

// Formatters
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    final digits = newVal.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    final str = buffer.toString();
    return newVal.copyWith(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue newVal) {
    var text = newVal.text.replaceAll('/', '');
    if (text.length > 2) text = '${text.substring(0, 2)}/${text.substring(2)}';
    return newVal.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}