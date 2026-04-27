import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/product.dart';
import '../../../core/theme/app_theme.dart';

class ReportScreen extends StatelessWidget {
  final List<Product> products;

  const ReportScreen({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    // Suma de base de simulación (Mes actual)
    final double baseMes = 60000.0;
    final double totalVentasReales = products.fold(0, (sum, p) => sum + (p.existencias * p.precioVenta)); // Ajustar según lógica real si es necesario
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reporte de Inventario'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () => _printPdf(context, fmt),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Ventas Totales Simulación: ${fmt.format(baseMes)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Producto')),
                    DataColumn(label: Text('Stock')),
                    DataColumn(label: Text('Costo')),
                    DataColumn(label: Text('Precio')),
                    DataColumn(label: Text('Valor Inv.')),
                  ],
                  rows: products.map((p) => DataRow(
                    color: p.esStockBajo ? WidgetStateProperty.all(Colors.red.withOpacity(0.2)) : null,
                    cells: [
                      DataCell(Text(p.nombre, style: TextStyle(color: p.esStockBajo ? Colors.red : null))),
                      DataCell(Text('${p.existencias.toStringAsFixed(0)} ${p.unidadMedida}', style: TextStyle(color: p.esStockBajo ? Colors.red : null))),
                      DataCell(Text(fmt.format(p.precioCosto), style: TextStyle(color: p.esStockBajo ? Colors.red : null))),
                      DataCell(Text(fmt.format(p.precioVenta), style: TextStyle(color: p.esStockBajo ? Colors.red : null))),
                      DataCell(Text(fmt.format(p.valorTotalInventario), style: TextStyle(color: p.esStockBajo ? Colors.red : null))),
                    ]
                  )).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printPdf(BuildContext context, NumberFormat fmt) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            headers: ['Producto', 'Stock', 'Costo', 'Precio', 'Valor Inv.'],
            data: products.map((p) => [
              p.nombre,
              '${p.existencias.toStringAsFixed(0)} ${p.unidadMedida}',
              fmt.format(p.precioCosto),
              fmt.format(p.precioVenta),
              fmt.format(p.valorTotalInventario),
            ]).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
