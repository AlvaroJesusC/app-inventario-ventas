import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/sale_model.dart';

class ShareUtils {
  /// Formatea la venta en un formato de texto amigable para enviar por WhatsApp o correo.
  static String formatSaleAsText(SaleModel sale) {
    final buffer = StringBuffer();
    final localFecha = sale.fecha.toLocal();
    final String dateStr =
        "${localFecha.day.toString().padLeft(2, '0')}/${localFecha.month.toString().padLeft(2, '0')}/${localFecha.year} ${localFecha.hour.toString().padLeft(2, '0')}:${localFecha.minute.toString().padLeft(2, '0')}";

    final String shortId = sale.id.length > 5 
        ? sale.id.substring(sale.id.length - 5).toUpperCase() 
        : sale.id.toUpperCase();
    final String transId = '#VTA-$shortId';

    buffer.writeln("🧾 *TICKET DE VENTA*");
    buffer.writeln("══════════════════════════════");
    buffer.writeln("*Transacción:* $transId");
    buffer.writeln("*Fecha/Hora:*  $dateStr");
    buffer.writeln("*Cajero:*      ${sale.cajero}");
    
    if (sale.cliente != null && sale.cliente!.trim().isNotEmpty) {
      buffer.writeln("*Cliente:*     ${sale.cliente}");
    }
    
    buffer.writeln("*Método Pago:* ${sale.metodoPago ?? 'Efectivo'}");
    buffer.writeln("══════════════════════════════");
    
    // Tabla de productos en bloque de código monospaciado
    buffer.writeln("```");
    buffer.writeln("Cant Detalle             Total");
    buffer.writeln("──────────────────────────────");

    for (var item in sale.articulos) {
      final String qtyStr = "${item.cantidad}x ".padRight(5);
      final String totalStr = "S/. ${(item.precio * item.cantidad).toStringAsFixed(2)}".padLeft(10);
      
      String desc = item.nombre;
      if (desc.length > 15) {
        desc = "${desc.substring(0, 12)}...";
      }
      desc = desc.padRight(15);
      
      buffer.writeln("$qtyStr$desc$totalStr");
    }

    buffer.writeln("──────────────────────────────");
    buffer.writeln("```");

    final subtotal = sale.articulos.fold(0.0, (sum, item) => sum + (item.precio * item.cantidad));
    final taxes = subtotal * 0.18; // 18% IGV
    
    buffer.writeln("══════════════════════════════");
    buffer.writeln("*Subtotal:*        S/. ${subtotal.toStringAsFixed(2)}");
    buffer.writeln("*Impuestos (18%):*  S/. ${taxes.toStringAsFixed(2)}");
    buffer.writeln("*TOTAL:*           *S/. ${sale.total.toStringAsFixed(2)}*");
    buffer.writeln("══════════════════════════════");
    buffer.writeln("¡Gracias por su compra!");

    return buffer.toString();
  }

  /// Comparte el ticket utilizando el menú nativo del dispositivo (WhatsApp, Correo, etc.)
  static Future<void> shareViaSystem(SaleModel sale) async {
    final text = formatSaleAsText(sale);
    await SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Ticket de Venta S/. ${sale.total.toStringAsFixed(2)}',
      ),
    );
  }

  /// Envía el ticket directamente por WhatsApp a un número específico o abre el selector de WhatsApp si no se especifica.
  static Future<void> shareViaWhatsApp(SaleModel sale, {String? phoneNumber}) async {
    final text = formatSaleAsText(sale);
    
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      // Limpiar caracteres no numéricos
      var cleanPhone = phoneNumber.replaceAll(RegExp(r'\D'), '');
      
      // Si el número tiene 9 dígitos y empieza con 9 (número celular estándar en Perú), agregamos código de país 51
      if (cleanPhone.length == 9 && cleanPhone.startsWith('9')) {
        cleanPhone = '51$cleanPhone';
      }
      
      final whatsappUrl = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(text)}");
      
      try {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } catch (e) {
        // Si falla por alguna razón (por ejemplo, sin conexión o error de app), abrir el share nativo
        await SharePlus.instance.share(
          ShareParams(text: text),
        );
      }
    } else {
      // Si no se proporcionó número, abrir el share nativo del sistema
      await SharePlus.instance.share(
        ShareParams(text: text),
      );
    }
  }
}
