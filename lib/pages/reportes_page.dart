import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../repositories.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  final ClienteRepository _clienteRepo = Modular.get<ClienteRepository>();
  final FacturaRepository _facturaRepo = Modular.get<FacturaRepository>();
  final CompraRepository _compraRepo = Modular.get<CompraRepository>();

  int _totalClientes = 0;
  int _totalFacturas = 0;
  double _totalFacturado = 0;
  double _totalPendiente = 0;
  double _totalCompras = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReportes();
  }

  Future<void> _loadReportes() async {
    final clientes = await _clienteRepo.getAll();
    final facturas = await _facturaRepo.getAll();
    final compras = await _compraRepo.getAll();

    _totalClientes = clientes.length;
    _totalFacturas = facturas.length;
    _totalFacturado = facturas
        .where((f) => f.estado == 'pagada')
        .fold(0, (sum, f) => sum + f.total);
    _totalPendiente = facturas
        .where((f) => f.estado == 'pendiente')
        .fold(0, (sum, f) => sum + f.total);
    _totalCompras = compras.fold(0, (sum, c) => sum + c.total);

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reportes'),
          backgroundColor: Colors.orange.shade700,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Modular.to.navigate('/'),
        ),
        title: const Text('Reportes y Estadísticas'),
        backgroundColor: Colors.orange.shade700,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isLoading = true);
          await _loadReportes();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatCard(
              'Total Clientes',
              _totalClientes.toString(),
              Icons.people,
              Colors.blue,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total Facturas',
              _totalFacturas.toString(),
              Icons.receipt_long,
              Colors.purple,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total Facturado (Pagado)',
              '\$${_totalFacturado.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total Pendiente de Pago',
              '\$${_totalPendiente.toStringAsFixed(2)}',
              Icons.pending,
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Total en Compras',
              '\$${_totalCompras.toStringAsFixed(2)}',
              Icons.shopping_cart,
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildStatCard(
              'Ganancia Neta Estimada',
              '\$${(_totalFacturado - _totalCompras).toStringAsFixed(2)}',
              Icons.trending_up,
              _totalFacturado > _totalCompras ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Acciones Rápidas',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.search, color: Colors.blue),
                      title: const Text('Buscar Cliente'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Modular.to.navigate('/clientes'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.add_circle, color: Colors.purple),
                      title: const Text('Nueva Factura'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Modular.to.navigate('/facturas/nueva'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.receipt, color: Colors.green),
                      title: const Text('Ver Todas las Facturas'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => Modular.to.navigate('/facturas'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.info_outline, size: 40, color: Colors.orange),
                    const SizedBox(height: 8),
                    const Text(
                      'Reporte generado el:',
                      style: TextStyle(fontSize: 12),
                    ),
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, Color.fromRGBO(255, 255, 255, 0.627)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(icon, size: 48, color: Colors.white),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}