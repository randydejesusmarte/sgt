import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import '../models.dart';
import '../repositories.dart';

class ReportesPage extends StatefulWidget {
  const ReportesPage({super.key});

  @override
  State<ReportesPage> createState() => _ReportesPageState();
}

class _ReportesPageState extends State<ReportesPage> {
  final ClienteRepository _clienteRepo = inject<ClienteRepository>();
  final FacturaRepository _facturaRepo = inject<FacturaRepository>();
  final CompraRepository _compraRepo = inject<CompraRepository>();
  final EmpleadoRepository _empleadoRepo = inject<EmpleadoRepository>();
  final ServicioRepository _servicioRepo = inject<ServicioRepository>();

  // Datos base
  List<Empleado> _empleados = [];
  List<Map<String, dynamic>> _serviciosConDetalles = [];
  List<Factura> _facturas = [];
  List<Compra> _compras = [];
  int _totalClientesCount = 0;
  bool _isLoading = true;

  // Estado del Workflow de Filtros
  int? _selectedEmpleadoId; // null = Todos
  String? _selectedEstado; // null = Todos
  String _presetPeriod = 'mes'; // 'hoy', 'ayer', 'semana', 'mes', 'personalizado', 'todo'
  DateTimeRange? _customDateRange;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase().trim();
      });
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    try {
      final clientes = await _clienteRepo.getAll();
      final facturas = await _facturaRepo.getAll();
      final compras = await _compraRepo.getAll();
      final empleados = await _empleadoRepo.getAll();
      final servicios = await _servicioRepo.getServiciosConDetalles();

      setState(() {
        _totalClientesCount = clientes.length;
        _facturas = facturas;
        _compras = compras;
        _empleados = empleados;
        _serviciosConDetalles = servicios;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar datos de reportes: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // Rango de fecha efectivo según preset o rango personalizado
  DateTimeRange? _getEffectiveDateRange() {
    final now = DateTime.now();
    switch (_presetPeriod) {
      case 'hoy':
        final start = DateTime(now.year, now.month, now.day);
        final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'ayer':
        final yesterday = now.subtract(const Duration(days: 1));
        final start = DateTime(yesterday.year, yesterday.month, yesterday.day);
        final end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        return DateTimeRange(start: start, end: end);
      case 'semana':
        // Inicio de semana (Lunes)
        final start = now.subtract(Duration(days: now.weekday - 1));
        final startDate = DateTime(start.year, start.month, start.day);
        final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        return DateTimeRange(start: startDate, end: endDate);
      case 'mes':
        final start = DateTime(now.year, now.month, 1);
        final nextMonth = DateTime(now.year, now.month + 1, 1);
        final end = nextMonth.subtract(const Duration(seconds: 1));
        return DateTimeRange(start: start, end: end);
      case 'personalizado':
        return _customDateRange;
      case 'todo':
      default:
        return null;
    }
  }

  bool _isDateInRange(DateTime date, DateTimeRange? range) {
    if (range == null) return true;
    final dateOnly = DateTime(date.year, date.month, date.day);
    final startOnly = DateTime(range.start.year, range.start.month, range.start.day);
    final endOnly = DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59);
    return !dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly);
  }

  // Filtrado de servicios
  List<Map<String, dynamic>> _getFilteredServicios() {
    final range = _getEffectiveDateRange();

    return _serviciosConDetalles.where((s) {
      // 1. Filtro por Empleado
      if (_selectedEmpleadoId != null) {
        final empId = s['s_empleado_id'] as int?;
        if (empId != _selectedEmpleadoId) return false;
      }

      // 2. Filtro por Estado
      if (_selectedEstado != null && _selectedEstado!.isNotEmpty) {
        final estado = (s['s_estado'] as String? ?? '').toLowerCase();
        if (estado != _selectedEstado!.toLowerCase()) return false;
      }

      // 3. Filtro por Fecha
      final fechaStr = s['s_fecha'] as String?;
      if (fechaStr != null) {
        try {
          final fecha = DateTime.parse(fechaStr);
          if (!_isDateInRange(fecha, range)) return false;
        } catch (_) {}
      }

      // 4. Búsqueda por texto (Cliente, Vehículo, Descripción, Empleado)
      if (_searchQuery.isNotEmpty) {
        final cNombre = (s['c_nombre'] as String? ?? '').toLowerCase();
        final vMarca = (s['v_marca'] as String? ?? '').toLowerCase();
        final vModelo = (s['v_modelo'] as String? ?? '').toLowerCase();
        final vPlaca = (s['v_placa'] as String? ?? '').toLowerCase();
        final eNombre = (s['e_nombre'] as String? ?? '').toLowerCase();
        final desc = (s['s_descripcion'] as String? ?? '').toLowerCase();

        final matches = cNombre.contains(_searchQuery) ||
            vMarca.contains(_searchQuery) ||
            vModelo.contains(_searchQuery) ||
            vPlaca.contains(_searchQuery) ||
            eNombre.contains(_searchQuery) ||
            desc.contains(_searchQuery);

        if (!matches) return false;
      }

      return true;
    }).toList();
  }

  // Filtrado de Facturas
  List<Factura> _getFilteredFacturas(List<Map<String, dynamic>> filteredServices) {
    final range = _getEffectiveDateRange();

    return _facturas.where((f) {
      // Fecha
      if (!_isDateInRange(f.fecha, range)) return false;

      // Si hay filtro de empleado, validar si la factura concuerda con los servicios filtrados
      if (_selectedEmpleadoId != null) {
        // Verificar si la factura pertenece a algún cliente de los servicios filtrados
        final clienteIdsWithEmp = filteredServices
            .map((s) => s['v_cliente_id'] as int?)
            .whereType<int>()
            .toSet();
        if (!clienteIdsWithEmp.contains(f.clienteId)) return false;
      }

      return true;
    }).toList();
  }

  // Filtrado de Compras
  List<Compra> _getFilteredCompras(List<Map<String, dynamic>> filteredServices) {
    final range = _getEffectiveDateRange();
    final serviceIds = filteredServices.map((s) => s['s_id'] as int?).whereType<int>().toSet();

    return _compras.where((c) {
      if (!_isDateInRange(c.fecha, range)) return false;
      if (_selectedEmpleadoId != null) {
        if (!serviceIds.contains(c.servicioId)) return false;
      }
      return true;
    }).toList();
  }

  void _limpiarFiltros() {
    setState(() {
      _selectedEmpleadoId = null;
      _selectedEstado = null;
      _presetPeriod = 'todo';
      _customDateRange = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  Future<void> _seleccionarRangoPersonalizado() async {
    final now = DateTime.now();
    final initialRange = _customDateRange ??
        DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initialRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange.shade700,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _presetPeriod = 'personalizado';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Reportes y Estadísticas'),
          backgroundColor: Colors.orange.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final filteredServicios = _getFilteredServicios();
    final filteredFacturas = _getFilteredFacturas(filteredServicios);
    final filteredCompras = _getFilteredCompras(filteredServicios);

    // Cálculos de Métricas sobre datos filtrados
    final totalServiciosCount = filteredServicios.length;

    final totalFacturado = filteredFacturas
        .where((f) => f.estado == 'pagada')
        .fold(0.0, (sum, f) => sum + f.total);

    final totalPendiente = filteredFacturas
        .where((f) => f.estado == 'pendiente')
        .fold(0.0, (sum, f) => sum + f.total);

    final totalCompras = filteredCompras.fold(0.0, (sum, c) => sum + c.total);

    final gananciaNeta = totalFacturado - totalCompras;

    final totalCostoServicios = filteredServicios.fold(
        0.0, (sum, s) => sum + (s['s_costo'] as double? ?? 0.0));

    final promedioPorServicio = totalServiciosCount > 0
        ? totalCostoServicios / totalServiciosCount
        : 0.0;

    final hayFiltrosActivos = _selectedEmpleadoId != null ||
        _selectedEstado != null ||
        _presetPeriod != 'todo' ||
        _searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.navigate('/'),
        ),
        title: const Text('Reportes y Estadísticas'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar Datos',
            onPressed: _loadAllData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // WORKFLOW DE FILTRADO
            _buildWorkflowFilterCard(hayFiltrosActivos),

            const SizedBox(height: 16),

            // INDICADOR DE FILTROS ACTIVOS (Resumen)
            if (hayFiltrosActivos) _buildActiveFiltersBadge(),

            const SizedBox(height: 12),

            // KPI CARDS DINÁMICAS
            _buildMetricsGrid(
              totalServiciosCount: totalServiciosCount,
              totalFacturado: totalFacturado,
              totalPendiente: totalPendiente,
              totalCompras: totalCompras,
              gananciaNeta: gananciaNeta,
              promedioPorServicio: promedioPorServicio,
            ),

            const SizedBox(height: 24),

            // MODULO DE RENDIMIENTO POR EMPLEADO
            _buildEmpleadoPerformanceSection(filteredServicios),

            const SizedBox(height: 24),

            // MONITOR DETALLADO DE OPERACIONES Y SERVICIOS FILTRADOS
            _buildFilteredOperationsSection(filteredServicios),

            const SizedBox(height: 24),

            // FOOTER CON FECHA DE REPORTE
            Card(
              color: Colors.orange.shade50,
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline, size: 30, color: Colors.orange),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reporte actualizado en tiempo real:',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  // WIDGET: PANEL DE FILTRADO INTERACTIVO
  Widget _buildWorkflowFilterCard(bool hayFiltrosActivos) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Workflow de Filtrado & Monitoreo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$_totalClientesCount Clientes Registrados',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                if (hayFiltrosActivos) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _limpiarFiltros,
                    icon: const Icon(Icons.clear_all, size: 18, color: Colors.red),
                    label: const Text(
                      'Limpiar Filtros',
                      style: TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ],
            ),
            const Divider(height: 20),

            // CHIPS DE PERÍODOS RÁPIDOS
            const Text(
              'Período de Tiempo:',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPeriodChip('Hoy', 'hoy'),
                  _buildPeriodChip('Ayer', 'ayer'),
                  _buildPeriodChip('Esta Semana', 'semana'),
                  _buildPeriodChip('Este Mes', 'mes'),
                  _buildCustomRangeChip(),
                  _buildPeriodChip('Todo', 'todo'),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // SELECTOR DE EMPLEADO Y ESTADO
            Row(
              children: [
                // DROPDOWN EMPLEADO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Empleado:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<int?>(
                        initialValue: _selectedEmpleadoId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('Todos los Empleados'),
                          ),
                          ..._empleados.map((e) => DropdownMenuItem<int?>(
                                value: e.id,
                                child: Text(
                                  e.nombre,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                        ],
                        onChanged: (val) => setState(() => _selectedEmpleadoId = val),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // DROPDOWN ESTADO
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estado Operativo:',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedEstado,
                        isExpanded: true,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        items: const [
                          DropdownMenuItem<String?>(
                            value: null,
                            child: Text('Todos los Estados'),
                          ),
                          DropdownMenuItem(
                            value: 'Recepcionado',
                            child: Text('Recepcionado'),
                          ),
                          DropdownMenuItem(
                            value: 'En Diagnóstico',
                            child: Text('En Diagnóstico'),
                          ),
                          DropdownMenuItem(
                            value: 'En Reparación',
                            child: Text('En Reparación'),
                          ),
                          DropdownMenuItem(
                            value: 'Espera de Repuestos',
                            child: Text('Espera Repuestos'),
                          ),
                          DropdownMenuItem(
                            value: 'Listo para Entrega',
                            child: Text('Listo para Entrega'),
                          ),
                          DropdownMenuItem(
                            value: 'Entregado / Facturado',
                            child: Text('Entregado / Facturado'),
                          ),
                          DropdownMenuItem(
                            value: 'Cancelado',
                            child: Text('Cancelado'),
                          ),
                        ],
                        onChanged: (val) => setState(() => _selectedEstado = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // BÚSQUEDA RÁPIDA DE TEXTO
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por cliente, vehículo, técnico o servicio...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = _presetPeriod == value;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.orange.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _presetPeriod = value;
              _customDateRange = null;
            });
          }
        },
      ),
    );
  }

  Widget _buildCustomRangeChip() {
    final isSelected = _presetPeriod == 'personalizado';
    String label = 'Rango...';
    if (isSelected && _customDateRange != null) {
      final f = DateFormat('dd/MM/yy');
      label = '${f.format(_customDateRange!.start)} - ${f.format(_customDateRange!.end)}';
    }

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        avatar: Icon(
          Icons.date_range,
          size: 16,
          color: isSelected ? Colors.white : Colors.orange.shade700,
        ),
        label: Text(label),
        selected: isSelected,
        selectedColor: Colors.orange.shade700,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        onSelected: (_) => _seleccionarRangoPersonalizado(),
      ),
    );
  }

  Widget _buildActiveFiltersBadge() {
    final range = _getEffectiveDateRange();
    final parts = <String>[];

    if (_presetPeriod != 'todo') {
      if (_presetPeriod == 'personalizado' && range != null) {
        final f = DateFormat('dd/MM/yyyy');
        parts.add('Período: ${f.format(range.start)} al ${f.format(range.end)}');
      } else {
        parts.add('Período: ${_presetPeriod.toUpperCase()}');
      }
    }

    if (_selectedEmpleadoId != null) {
      final emp = _empleados.firstWhere(
        (e) => e.id == _selectedEmpleadoId,
        orElse: () => Empleado(nombre: 'ID #$_selectedEmpleadoId', telefono: '', createdAt: DateTime.now()),
      );
      parts.add('Empleado: ${emp.nombre}');
    }

    if (_selectedEstado != null) {
      parts.add('Estado: $_selectedEstado');
    }

    if (_searchQuery.isNotEmpty) {
      parts.add('Búsqueda: "$_searchQuery"');
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt, size: 18, color: Colors.blue.shade800),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Filtros Activos: ${parts.join(' | ')}',
              style: TextStyle(
                color: Colors.blue.shade900,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // WIDGET: TARJETAS KPI DINÁMICAS
  Widget _buildMetricsGrid({
    required int totalServiciosCount,
    required double totalFacturado,
    required double totalPendiente,
    required double totalCompras,
    required double gananciaNeta,
    required double promedioPorServicio,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Servicios en Filtro',
                totalServiciosCount.toString(),
                Icons.build,
                Colors.blue.shade700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Facturado (Pagado)',
                '\$${totalFacturado.toStringAsFixed(2)}',
                Icons.attach_money,
                Colors.green.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Pendiente de Pago',
                '\$${totalPendiente.toStringAsFixed(2)}',
                Icons.pending_actions,
                Colors.orange.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Compras/Gastos',
                '\$${totalCompras.toStringAsFixed(2)}',
                Icons.shopping_cart,
                Colors.red.shade700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Ganancia Neta Filtro',
                '\$${gananciaNeta.toStringAsFixed(2)}',
                Icons.trending_up,
                gananciaNeta >= 0 ? Colors.teal.shade700 : Colors.red.shade900,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Promedio por Servicio',
                '\$${promedioPorServicio.toStringAsFixed(2)}',
                Icons.analytics,
                Colors.purple.shade700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            colors: [color, color.withAlpha(200)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22, color: Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: DESEMPEÑO POR EMPLEADO
  Widget _buildEmpleadoPerformanceSection(List<Map<String, dynamic>> filteredServicios) {
    if (_empleados.isEmpty) {
      return const SizedBox.shrink();
    }

    // Agrupar métricas por empleado
    final Map<int?, List<Map<String, dynamic>>> grouped = {};
    for (var s in filteredServicios) {
      final empId = s['s_empleado_id'] as int?;
      grouped.putIfAbsent(empId, () => []).add(s);
    }

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.badge, color: Colors.indigo.shade700, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Rendimiento por Empleado (Filtro Activo)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _empleados.length,
              separatorBuilder: (context, index) => const Divider(height: 16),
              itemBuilder: (context, index) {
                final emp = _empleados[index];
                final serviciosEmp = grouped[emp.id] ?? [];
                final totalTrabajos = serviciosEmp.length;
                final totalGenerado = serviciosEmp.fold(
                  0.0,
                  (sum, s) => sum + (s['s_costo'] as double? ?? 0.0),
                );
                final completados = serviciosEmp.where((s) {
                  final estado = (s['s_estado'] as String? ?? '').toLowerCase();
                  return estado.contains('entregado') || estado.contains('listo');
                }).length;

                return Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.indigo.shade100,
                      child: Text(
                        emp.nombre.isNotEmpty ? emp.nombre[0].toUpperCase() : 'E',
                        style: TextStyle(
                          color: Colors.indigo.shade900,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            emp.nombre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            emp.especialidad ?? 'Técnico General',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '$totalTrabajos trabajos ($completados listos)',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '\$${totalGenerado.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // WIDGET: MONITOR DETALLADO DE OPERACIONES Y SERVICIOS FILTRADOS
  Widget _buildFilteredOperationsSection(List<Map<String, dynamic>> filteredServicios) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: Colors.orange.shade800, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Operaciones y Servicios Monitoreados (${filteredServicios.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (filteredServicios.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      const Text(
                        'No se encontraron servicios con los filtros seleccionados.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredServicios.length > 15 ? 15 : filteredServicios.length,
                separatorBuilder: (context, index) => const Divider(height: 12),
                itemBuilder: (context, index) {
                  final s = filteredServicios[index];
                  final cNombre = s['c_nombre'] as String? ?? 'Cliente Desconocido';
                  final vMarca = s['v_marca'] as String? ?? '';
                  final vModelo = s['v_modelo'] as String? ?? '';
                  final vPlaca = s['v_placa'] as String? ?? '';
                  final eNombre = s['e_nombre'] as String? ?? 'Sin Asignar';
                  final estado = s['s_estado'] as String? ?? 'Recepcionado';
                  final costo = s['s_costo'] as double? ?? 0.0;
                  final fechaStr = s['s_fecha'] as String?;

                  String fechaFormatted = '';
                  if (fechaStr != null) {
                    try {
                      final dt = DateTime.parse(fechaStr);
                      fechaFormatted = DateFormat('dd/MM/yyyy HH:mm').format(dt);
                    } catch (_) {
                      fechaFormatted = fechaStr;
                    }
                  }

                  final statusColor = _getBadgeColorForEstado(estado);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$cNombre ($vMarca $vModelo - $vPlaca)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: statusColor),
                          ),
                          child: Text(
                            estado,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s['s_descripcion'] as String? ?? 'Sin descripción',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.person, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Técnico: $eNombre',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              const Spacer(),
                              Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                fechaFormatted,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    trailing: Text(
                      '\$${costo.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.blueAccent,
                      ),
                    ),
                    onTap: () => context.navigate('/servicios'),
                  );
                },
              ),
            if (filteredServicios.length > 15)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: TextButton.icon(
                    onPressed: () => context.navigate('/servicios'),
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(
                      'Ver todos los ${filteredServicios.length} registros en Servicios',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getBadgeColorForEstado(String estado) {
    switch (estado.toLowerCase()) {
      case 'entregado / facturado':
      case 'entregado':
      case 'completado':
        return Colors.green.shade800;
      case 'listo para entrega':
      case 'listo':
        return Colors.teal.shade700;
      case 'en reparación':
      case 'en reparacion':
        return Colors.blue.shade800;
      case 'en diagnóstico':
      case 'en diagnostico':
        return Colors.purple.shade700;
      case 'espera de repuestos':
      case 'espera repuestos':
        return Colors.orange.shade800;
      case 'cancelado':
        return Colors.red.shade800;
      case 'recepcionado':
      default:
        return Colors.grey.shade800;
    }
  }
}