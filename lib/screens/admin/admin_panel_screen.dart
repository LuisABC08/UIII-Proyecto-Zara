import 'package:flutter/material.dart';
import 'admin_category_screen.dart';
import 'admin_orders_screen.dart';



class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  static const _sections = [
    {'label': 'CAMISAS', 'key': 'camisas'},
    {'label': 'PANTALONES', 'key': 'pantalones'},
    {'label': 'FALDAS', 'key': 'faldas'},
    {'label': 'SHORTS', 'key': 'shorts'},
    {'label': 'CALZADO', 'key': 'calzado'},
    {'label': 'PEDIDOS', 'key': 'pedidos'},
    {'label': 'INVENTARIO', 'key': 'inventario'},
    {'label': 'CATEGORÍAS', 'key': 'categorias'},
    {'label': 'CLIENTES', 'key': 'clientes'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
                    'ADMINISTRACIÓN',
                    style: TextStyle(
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
            const SizedBox(height: 8),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _sections.length,
                itemBuilder: (context, i) {
                  final section = _sections[i];
                  return _AdminPanelItem(
                    label: section['label']!,
                    index: i,
                    onTap: () {
                      final key = section['key']!;
                      if (key == 'pedidos') {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const AdminOrdersScreen()),
  );
}

                      if ([
                        'camisas',
                        'pantalones',
                        'faldas',
                        'shorts',
                        'calzado',
                      ].contains(key)) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AdminCategoryScreen(
                              categoria: key,
                              titulo: section['label']!,
                            ),
                          ),
                        );
                      }
                      // pedidos, inventario, etc — puedes expandir
                    },
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

class _AdminPanelItem extends StatelessWidget {
  final String label;
  final int index;
  final VoidCallback onTap;

  const _AdminPanelItem({
    required this.label,
    required this.index,
    required this.onTap,
  });

  // Acento sutil por fila alternada
  Color get _accent => index.isEven ? Colors.white : const Color(0xFFF9F9F9);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: _accent, // ← color movido DENTRO de decoration
          border: const Border(
            bottom: BorderSide(color: Colors.black, width: 1),
          ),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 3,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
