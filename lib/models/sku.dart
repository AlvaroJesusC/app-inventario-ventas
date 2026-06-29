class Sku {
  final String valor;

  const Sku(this.valor);

  /// Genera un SKU legible y estructurado a partir del nombre del producto y su categoría.
  /// Ejemplo: Categoría "Bebidas", Nombre "Agua Loa" -> "BEB-AGUA-01"
  factory Sku.generar({
    required String nombre,
    required String categoria,
    int indice = 1,
  }) {
    // Función auxiliar para normalizar texto (sin tildes, sin caracteres raros, en mayúsculas)
    String normalizar(String texto) {
      final mapaAcentos = {
        'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u',
        'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U',
        'ñ': 'n', 'Ñ': 'N',
      };
      
      String textoLimpio = texto;
      mapaAcentos.forEach((acento, sinAcento) {
        textoLimpio = textoLimpio.replaceAll(acento, sinAcento);
      });

      return textoLimpio
          .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '') // Solo alfanuméricos y espacios
          .toUpperCase()
          .trim();
    }

    final catLimpia = normalizar(categoria);
    final nomLimpio = normalizar(nombre);

    // Código de categoría (primeras 3 letras o 'GEN' por defecto)
    final codigoCat = catLimpia.isNotEmpty
        ? (catLimpia.length >= 3 ? catLimpia.substring(0, 3) : catLimpia.padRight(3, 'X'))
        : 'GEN';

    // Código de nombre (primeras 3 o 4 letras significativas de la primera palabra, o palabras combinadas)
    final palabras = nomLimpio.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    String codigoNom;
    if (palabras.length >= 2) {
      final p1 = palabras[0];
      final p2 = palabras[1];
      final frag1 = p1.substring(0, p1.length >= 3 ? 3 : p1.length);
      final frag2 = p2.substring(0, p2.length >= 3 ? 3 : p2.length);
      codigoNom = '$frag1$frag2';
    } else if (palabras.isNotEmpty) {
      final p = palabras[0];
      codigoNom = p.substring(0, p.length >= 5 ? 5 : p.length);
    } else {
      codigoNom = 'PROD';
    }

    // Sufijo secuencial de 2 dígitos (ej. 01, 02)
    final sufijo = indice.toString().padLeft(2, '0');

    return Sku('$codigoCat-$codigoNom-$sufijo');
  }

  /// Verifica si el formato del SKU es válido (ej. tiene longitud mínima)
  bool get esValido => valor.isNotEmpty && valor.length >= 3;

  @override
  String toString() => valor;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sku && runtimeType == other.runtimeType && valor == other.valor;

  @override
  int get hashCode => valor.hashCode;
}
