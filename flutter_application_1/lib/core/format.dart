/// "Hace 5 min", "Hace 3 h", "Hace 2 d" o la fecha si ya pasó una semana.
String tiempoRelativo(DateTime? fecha) {
  if (fecha == null) return '';
  final diff = DateTime.now().difference(fecha);
  if (diff.isNegative || diff.inMinutes < 1) return 'Hace un momento';
  if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
  return fechaCorta(fecha);
}

/// dd/MM/yyyy
String fechaCorta(DateTime? fecha) {
  if (fecha == null) return '';
  final d = fecha.day.toString().padLeft(2, '0');
  final m = fecha.month.toString().padLeft(2, '0');
  return '$d/$m/${fecha.year}';
}

/// Primera letra en mayúscula para los avatares.
String inicial(String? texto) {
  final t = (texto ?? '').trim();
  return t.isEmpty ? '?' : t.substring(0, 1).toUpperCase();
}
