import 'package:flutter_test/flutter_test.dart';

import 'package:app_inventario_ventas/main.dart';

void main() {
  testWidgets('StockApp renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const StockApp());

    // Verifica que la pantalla de login se muestra
    expect(find.text('StockApp'), findsOneWidget);
    expect(find.text('Gestión para tu negocio'), findsOneWidget);
    expect(find.text('Ingresar'), findsOneWidget);
  });
}
