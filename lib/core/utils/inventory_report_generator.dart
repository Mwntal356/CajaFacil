import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../../data/models/product.dart';

class InventoryReportGenerator {
  static Future<void> generateAndPrintReport(List<Product> products) async {
    final pdf = pw.Document();
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);

    // Cálculos financieros
    double totalInversion = 0;
    double totalValorVenta = 0;
    
    for (var p in products) {
      totalInversion += (p.precioCosto * p.existencias);
      totalValorVenta += (p.precioVenta * p.existencias);
    }
    double utilidadPotencial = totalValorVenta - totalInversion;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Reporte de Inventario', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Inversión', fmt.format(totalInversion)),
                  _buildStatCard('Valor Venta', fmt.format(totalValorVenta)),
                  _buildStatCard('Utilidad Est.', fmt.format(utilidadPotencial)),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                context: context,
                headers: ['Producto', 'Categ.', 'Costo', 'Precio', 'Stock', 'Valor Inv.', 'Valor Venta'],
                data: products.map((p) => [
                  p.nombre,
                  p.categoria,
                  fmt.format(p.precioCosto),
                  fmt.format(p.precioVenta),
                  '${p.existencias.toStringAsFixed(0)} ${p.unidadMedida}',
                  fmt.format(p.precioCosto * p.existencias),
                  fmt.format(p.precioVenta * p.existencias),
                ]).toList(),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  static pw.Widget _buildStatCard(String title, String value) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(border: pw.Border.all()),
      child: pw.Column(children: [pw.Text(title), pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))]),
    );
  }
}
