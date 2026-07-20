import 'dart:convert';

class PdfFieldOptions {
  final bool cliente;
  final bool version;
  final bool talla;
  final bool nombreNumero;
  final bool cantidad;
  final bool estado;
  final bool imagenPrincipal;
  final bool parches;

  const PdfFieldOptions({
    required this.cliente,
    required this.version,
    required this.talla,
    required this.nombreNumero,
    required this.cantidad,
    required this.estado,
    required this.imagenPrincipal,
    required this.parches,
  });

  factory PdfFieldOptions.defaults() {
    return const PdfFieldOptions(
      cliente: true,
      version: true,
      talla: true,
      nombreNumero: true,
      cantidad: true,
      estado: true,
      imagenPrincipal: true,
      parches: true,
    );
  }

  PdfFieldOptions copyWith({
    bool? cliente,
    bool? version,
    bool? talla,
    bool? nombreNumero,
    bool? cantidad,
    bool? estado,
    bool? imagenPrincipal,
    bool? parches,
  }) {
    return PdfFieldOptions(
      cliente: cliente ?? this.cliente,
      version: version ?? this.version,
      talla: talla ?? this.talla,
      nombreNumero: nombreNumero ?? this.nombreNumero,
      cantidad: cantidad ?? this.cantidad,
      estado: estado ?? this.estado,
      imagenPrincipal: imagenPrincipal ?? this.imagenPrincipal,
      parches: parches ?? this.parches,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cliente': cliente,
      'version': version,
      'talla': talla,
      'nombreNumero': nombreNumero,
      'cantidad': cantidad,
      'estado': estado,
      'imagenPrincipal': imagenPrincipal,
      'parches': parches,
    };
  }

  factory PdfFieldOptions.fromMap(Map<String, dynamic> map) {
    final d = PdfFieldOptions.defaults();

    bool flag(String key, bool fallback) {
      final v = map[key];
      return v is bool ? v : fallback;
    }

    return PdfFieldOptions(
      cliente: flag('cliente', d.cliente),
      version: flag('version', d.version),
      talla: flag('talla', d.talla),
      nombreNumero: flag('nombreNumero', d.nombreNumero),
      cantidad: flag('cantidad', d.cantidad),
      estado: flag('estado', d.estado),
      imagenPrincipal: flag('imagenPrincipal', d.imagenPrincipal),
      parches: flag('parches', d.parches),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory PdfFieldOptions.fromJson(String source) {
    try {
      return PdfFieldOptions.fromMap(jsonDecode(source) as Map<String, dynamic>);
    } catch (_) {
      return PdfFieldOptions.defaults();
    }
  }
}
