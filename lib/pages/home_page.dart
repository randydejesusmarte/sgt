import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Determinar número de columnas según el ancho
    int crossAxisCount;
    if (screenWidth < 600) {
      crossAxisCount = 2; // Móvil
    } else if (screenWidth < 900) {
      crossAxisCount = 3; // Tablet
    } else {
      crossAxisCount = 4; // Desktop
    }
    
    // Calcular tamaño de iconos y texto responsivamente
    final iconSize = screenWidth < 600 ? 36.0 : (screenWidth < 900 ? 48.0 : 56.0);
    final fontSize = screenWidth < 600 ? 13.0 : (screenWidth < 900 ? 15.0 : 16.0);
    final cardPadding = screenWidth < 600 ? 8.0 : 12.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taller de Autos'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade700.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.all(constraints.maxWidth * 0.03),
                child: GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: constraints.maxWidth * 0.02,
                  mainAxisSpacing: constraints.maxWidth * 0.02,
                  childAspectRatio: 1.1,
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildMenuCard(
                      context,
                      title: 'Clientes',
                      icon: Icons.people,
                      color: Colors.blue,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      cardPadding: cardPadding,
                      onTap: () => Modular.to.navigate('/clientes'),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Servicios',
                      icon: Icons.build,
                      color: Colors.indigo,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      cardPadding: cardPadding,
                      onTap: () => Modular.to.navigate('/servicios'),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Empleados',
                      icon: Icons.engineering,
                      color: Colors.teal,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      cardPadding: cardPadding,
                      onTap: () => Modular.to.navigate('/empleados'),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Facturas',
                      icon: Icons.receipt_long,
                      color: Colors.purple,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      cardPadding: cardPadding,
                      onTap: () => Modular.to.navigate('/facturas'),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Historial de Compras',
                      icon: Icons.shopping_cart,
                      color: Colors.green,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      cardPadding: cardPadding,
                      onTap: () => Modular.to.navigate('/compras'),
                    ),
                    _buildMenuCard(
                      context,
                      title: 'Reportes',
                      icon: Icons.bar_chart,
                      color: Colors.orange,
                      iconSize: iconSize,
                      fontSize: fontSize,
                      cardPadding: cardPadding,
                      onTap: () => Modular.to.navigate('/reportes'),
                    ),
                    _buildMenuCard(
                       context,
                       title: 'Inventario',
                       icon: Icons.inventory_2,
                       color: Colors.teal,
                       iconSize: iconSize,
                       fontSize: fontSize,
                       cardPadding: cardPadding,
                       onTap: () => Modular.to.navigate('/inventario'),
)                     ,
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required double iconSize,
    required double fontSize,
    required double cardPadding,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      shadowColor: color.withOpacity(0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: color.withOpacity(0.3),
        highlightColor: color.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                color.withOpacity(0.05),
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(cardPadding),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: iconSize,
                    color: color,
                  ),
                ),
                SizedBox(height: cardPadding),
                Flexible(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
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
}