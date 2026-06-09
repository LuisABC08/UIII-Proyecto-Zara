import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _db = FirebaseFirestore.instance;
  bool _loading = true;
  Map<String, dynamic>? _address;

  // Edición
  final _calleCtrl    = TextEditingController();
  final _ciudadCtrl   = TextEditingController();
  final _estadoCtrl   = TextEditingController();
  final _cpCtrl       = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _calleCtrl.dispose(); _ciudadCtrl.dispose();
    _estadoCtrl.dispose(); _cpCtrl.dispose(); _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = context.read<AuthService>().currentUser!.uid;
    final doc = await _db.collection('users').doc(uid).get();
    if (!mounted) return;
    final data = doc.data();
    if (data?['direccion'] != null) {
      _address = Map<String, dynamic>.from(data!['direccion']);
      _calleCtrl.text    = _address!['calle']    ?? '';
      _ciudadCtrl.text   = _address!['ciudad']   ?? '';
      _estadoCtrl.text   = _address!['estado']   ?? '';
      _cpCtrl.text       = _address!['cp']       ?? '';
      _telefonoCtrl.text = _address!['telefono'] ?? '';
    }
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    final uid = context.read<AuthService>().currentUser!.uid;
    final newAddress = {
      'calle':    _calleCtrl.text.trim(),
      'ciudad':   _ciudadCtrl.text.trim(),
      'estado':   _estadoCtrl.text.trim(),
      'cp':       _cpCtrl.text.trim(),
      'telefono': _telefonoCtrl.text.trim(),
    };
    await _db.collection('users').doc(uid).update({'direccion': newAddress});
    if (!mounted) return;
    setState(() => _address = newAddress);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dirección actualizada', style: TextStyle(fontSize: 12, letterSpacing: 0.5)),
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
        title: const Text('ELIMINAR DIRECCIÓN',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 2)),
        content: const Text('¿Deseas eliminar esta dirección guardada?',
            style: TextStyle(fontSize: 13, color: Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.black45))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('ELIMINAR',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm != true) return;
    final uid = context.read<AuthService>().currentUser!.uid;
    await _db.collection('users').doc(uid).update({'direccion': FieldValue.delete()});
    if (!mounted) return;
    setState(() => _address = null);
  }

  void _showEditSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 20, 28, 36),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36, height: 3,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                _address == null ? 'NUEVA DIRECCIÓN' : 'EDITAR DIRECCIÓN',
                style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 24),
              _Field(ctrl: _calleCtrl, label: 'CALLE Y NÚMERO'),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _Field(ctrl: _ciudadCtrl, label: 'CIUDAD')),
                const SizedBox(width: 16),
                Expanded(child: _Field(ctrl: _estadoCtrl, label: 'ESTADO')),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _Field(ctrl: _cpCtrl, label: 'CÓDIGO POSTAL',
                    keyboard: TextInputType.number)),
                const SizedBox(width: 16),
                Expanded(child: _Field(ctrl: _telefonoCtrl, label: 'TELÉFONO',
                    keyboard: TextInputType.phone)),
              ]),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: _save,
                child: Container(
                  width: double.infinity, height: 50,
                  color: Colors.black,
                  alignment: Alignment.center,
                  child: const Text('GUARDAR DIRECCIÓN',
                      style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 3, color: Colors.white,
                      )),
                ),
              ),
            ],
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
                  const Text('MIS DIRECCIONES',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 4,
                      )),
                  const Spacer(),
                  GestureDetector(
                    onTap: _showEditSheet,
                    child: Container(
                      width: 32, height: 32,
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
              const Expanded(child: Center(
                child: CircularProgressIndicator(color: Colors.black, strokeWidth: 1.5),
              ))
            else if (_address == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off_outlined, size: 52, color: Colors.black),
                      const SizedBox(height: 16),
                      const Text('SIN DIRECCIONES GUARDADAS',
                          style: TextStyle(
                            fontSize: 11, letterSpacing: 3,
                            color: Colors.black38, fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _showEditSheet,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
                          color: Colors.black,
                          child: const Text('AGREGAR DIRECCIÓN',
                              style: TextStyle(
                                fontSize: 10, fontWeight: FontWeight.w600,
                                letterSpacing: 3, color: Colors.white,
                              )),
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
                      const Text('DIRECCIÓN GUARDADA',
                          style: TextStyle(
                            fontSize: 10, fontWeight: FontWeight.w600,
                            letterSpacing: 2, color: Colors.black45,
                          )),
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 18),
                                const SizedBox(width: 8),
                                const Text('PRINCIPAL',
                                    style: TextStyle(
                                      fontSize: 10, fontWeight: FontWeight.w700,
                                      letterSpacing: 2,
                                    )),
                                const Spacer(),
                                GestureDetector(
                                  onTap: _showEditSheet,
                                  child: const Icon(Icons.edit_outlined, size: 18),
                                ),
                                const SizedBox(width: 14),
                                GestureDetector(
                                  onTap: _delete,
                                  child: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: Colors.black),
                            const SizedBox(height: 14),
                            _AddressRow(icon: Icons.home_outlined,
                                text: _address!['calle'] ?? ''),
                            const SizedBox(height: 10),
                            _AddressRow(icon: Icons.location_city_outlined,
                                text: '${_address!['ciudad']}, ${_address!['estado']}'),
                            const SizedBox(height: 10),
                            _AddressRow(icon: Icons.markunread_mailbox_outlined,
                                text: 'CP ${_address!['cp']}'),
                            const SizedBox(height: 10),
                            _AddressRow(icon: Icons.phone_outlined,
                                text: _address!['telefono'] ?? ''),
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

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _AddressRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: Colors.black45),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final TextInputType? keyboard;
  const _Field({required this.ctrl, required this.label, this.keyboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontSize: 10, fontWeight: FontWeight.w600,
          letterSpacing: 2, color: Colors.black45,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 14),
          decoration: const InputDecoration(
            isDense: true,
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