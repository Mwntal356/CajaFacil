import '../../../data/models/sale.dart';
import 'package:intl/intl.dart';

class TicketService {
  // Generar formato para impresora térmica (ESC/POS) - Simulación en Texto
  static String generateThermalTicket(Sale sale, String businessName) {
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    
    StringBuffer ticket = StringBuffer();
    ticket.writeln('================================');
    ticket.writeln(businessName.toUpperCase());
    ticket.writeln('================================');
    ticket.writeln('Fecha: ${dateFmt.format(sale.date)}');
    ticket.writeln('--------------------------------');
    ticket.writeln('Producto       Cant      Total');
    ticket.writeln('--------------------------------');
    
    for (var p in sale.products) {
      String name = p.productName.length > 14 
          ? p.productName.substring(0, 11) + '...' 
          : p.productName.padRight(14);
      String qty = p.quantity.toString().padRight(9);
      String price = fmt.format(p.priceAtSale * p.quantity);
      ticket.writeln('$name $qty $price');
    }
    
    ticket.writeln('--------------------------------');
    ticket.writeln('TOTAL:         ${fmt.format(sale.total).padLeft(17)}');
    ticket.writeln('Método:        ${sale.paymentMethod.padLeft(17)}');
    ticket.writeln('================================');
    ticket.writeln('  ¡Gracias por su compra!  ');
    ticket.writeln('================================');
    
    return ticket.toString();
  }

  // Generar mensaje para WhatsApp
  static String generateWhatsAppMessage(Sale sale, String businessName) {
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 2);
    
    StringBuffer msg = StringBuffer();
    msg.writeln('✅ *¡Gracias por tu compra en $businessName!*');
    msg.writeln('');
    msg.writeln('📋 *Resumen de tu pedido:*');
    
    for (var p in sale.products) {
      msg.writeln('• ${p.quantity}x ${p.productName} - ${fmt.format(p.priceAtSale * p.quantity)}');
    }
    
    msg.writeln('');
    msg.writeln('*Total a pagar:* ${fmt.format(sale.total)}');
    msg.writeln('*Método de pago:* ${sale.paymentMethod}');
    msg.writeln('');
    msg.writeln('¡Esperamos verte pronto! 🚀');
    
    return msg.toString();
  }
}
