import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SavedCardsScreen extends StatefulWidget {
  const SavedCardsScreen({super.key});

  @override
  State<SavedCardsScreen> createState() => _SavedCardsScreenState();
}

class _SavedCardsScreenState extends State<SavedCardsScreen> {
  final _db = FirebaseFirestore.instance;
  bool _loading = true;
  Map<String, dynamic>? _card;

  final _nombreCtrl = TextEditingController();
  final _numeroCtrl = TextEditingController();
  final _vencCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _numeroCtrl.dispose();
    _vencCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = context.read<AuthService>().currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!mounted) return;
    final data = doc.data();
    if (data?['tarjeta'] != null) {
      _card = Map<String, dynamic>.from(data!['tarjeta']);
      _nombreCtrl.text = _card!['nombre'] ?? '';
      _numeroCtrl.text = _card!['numero'] ?? '';
      _vencCtrl.text = _card!['venc'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = context.read<AuthService>().currentUser!.uid;
    final newCard = {
      'nombre': _nombreCtrl.text.trim(),
      'numero': _numeroCtrl.text.trim(),
      'venc': _vencCtrl.text.trim(),
    };
    await _db.collection('users').doc(uid).update({'tarjeta': newCard});
    if (!mounted) return;
    setState(() => _card = newCard);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Tarjeta actualizada',
          style: TextStyle(fontSize: 12, letterSpacing: 0.5),
        ),
        backgroundColor: Colors.black,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'ELIMINAR TARJETA',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        content: const Text(
          '¿Deseas eliminar esta tarjeta guardada?',
          style: TextStyle(fontSize: 13, color: Colors.black54),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'CANCELAR',
              style: TextStyle(color: Colors.black45),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ELIMINAR',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = context.read<AuthService>().currentUser!.uid;
    await _db.collection('users').doc(uid).update({
      'tarjeta': FieldValue.delete(),
    });
    if (!mounted) return;
    setState(() {
      _card = null;
      _nombreCtrl.clear();
      _numeroCtrl.clear();
      _vencCtrl.clear();
    });
  }

  String get _maskedNumber {
    final n = (_card?['numero'] ?? '').toString().replaceAll(' ', '');
    if (n.length < 4) return '**** **** **** ****';
    return '**** **** **** ${n.substring(n.length - 4)}';
  }

  String get _previewNumber {
    final n = _numeroCtrl.text.replaceAll(' ', '');
    if (n.isEmpty) return '**** **** **** ****';
    return _numeroCtrl.text.padRight(19, ' ');
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
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
                  _card == null ? 'NUEVA TARJETA' : 'EDITAR TARJETA',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 24),

                // Preview animado
                _CardVisual(
                  numero: _numeroCtrl.text,
                  nombre: _nombreCtrl.text,
                  venc: _vencCtrl.text,
                ),
                const SizedBox(height: 24),

                _SheetField(
                  ctrl: _nombreCtrl,
                  label: 'NOMBRE EN LA TARJETA',
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 18),
                _SheetField(
                  ctrl: _numeroCtrl,
                  label: 'NÚMERO DE TARJETA',
                  keyboard: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _CardNumberFormatter(),
                  ],
                  maxLength: 19,
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _SheetField(
                        ctrl: _vencCtrl,
                        label: 'MM/AA',
                        keyboard: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          _ExpiryFormatter(),
                        ],
                        maxLength: 5,
                        onChanged: (_) => setSheetState(() {}),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // CVV no se guarda — solo informativo
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CVV',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: Colors.black45,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No guardado\npor seguridad',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.black38,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _save,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    color: Colors.black,
                    alignment: Alignment.center,
                    child: const Text(
                      'GUARDAR TARJETA',
                      style: TextStyle(
                        fontSize: 11,
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
                    'MIS TARJETAS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showEditSheet,
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

            if (_loading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    color: Colors.black,
                    strokeWidth: 1.5,
                  ),
                ),
              )
            else if (_card == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.credit_card_off_outlined,
                        size: 52,
                        color: Colors.black,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'SIN TARJETAS GUARDADAS',
                        style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 3,
                          color: Colors.black38,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _showEditSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 13,
                          ),
                          color: Colors.black,
                          child: const Text(
                            'AGREGAR TARJETA',
                            style: TextStyle(
                              fontSize: 10,
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
              )
            else
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TARJETA GUARDADA',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                          color: Colors.black45,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tarjeta visual
                      _CardVisual(
                        numero: _card!['numero'] ?? '',
                        nombre: _card!['nombre'] ?? '',
                        venc: _card!['venc'] ?? '',
                        masked: true,
                      ),
                      const SizedBox(height: 20),

                      // Acciones
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: _showEditSheet,
                              child: Container(
                                height: 46,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1.5,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'EDITAR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: _delete,
                              child: Container(
                                height: 46,
                                color: Colors.red.shade50,
                                alignment: Alignment.center,
                                child: const Text(
                                  'ELIMINAR',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Detalle
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Column(
                          children: [
                            _DetailRow(
                              label: 'TITULAR',
                              value: _card!['nombre'] ?? '',
                            ),
                            const Divider(height: 24, color: Colors.black),
                            _DetailRow(label: 'NÚMERO', value: _maskedNumber),
                            const Divider(height: 24, color: Colors.black),
                            _DetailRow(
                              label: 'VENCE',
                              value: _card!['venc'] ?? '',
                            ),
                            const Divider(height: 24, color: Colors.black),
                            const _DetailRow(label: 'CVV', value: '•••'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CardVisual extends StatelessWidget {
  final String numero;
  final String nombre;
  final String venc;
  final bool masked;
  const _CardVisual({
    required this.numero,
    required this.nombre,
    required this.venc,
    this.masked = false,
  });

  String get _displayNumber {
    final n = numero.replaceAll(' ', '');
    if (masked) {
      if (n.length < 4) return '**** **** **** ****';
      return '**** **** **** ${n.substring(n.length - 4)}';
    }
    return numero.isEmpty ? '**** **** **** ****' : numero;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 185,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.black),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'ZARA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 22,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white24),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(
                  Icons.credit_card,
                  size: 14,
                  color: Colors.white38,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            _displayNumber,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              letterSpacing: 2,
              fontWeight: FontWeight.w300,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TITULAR',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    nombre.isEmpty ? '— — —' : nombre.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'VENCE',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 8,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    venc.isEmpty ? 'MM/AA' : venc,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      letterSpacing: 0.8,
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  const _SheetField({
    required this.ctrl,
    required this.label,
    this.keyboard,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
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
          controller: ctrl,
          keyboardType: keyboard,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 14),
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

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old,
    TextEditingValue newVal,
  ) {
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
    TextEditingValue old,
    TextEditingValue newVal,
  ) {
    var text = newVal.text.replaceAll('/', '');
    if (text.length > 2) text = '${text.substring(0, 2)}/${text.substring(2)}';
    return newVal.copyWith(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
