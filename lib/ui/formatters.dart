/// Formats [value] as currency with thousands separators and two decimals,
/// e.g. `$1,234.56`. Values too large for fixed notation use exponents.
String formatCash(double value) {
  if (!value.isFinite || value.abs() >= 1e21) {
    return '\$${value.toStringAsExponential(3)}';
  }
  final fixed = value.abs().toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = fixed.substring(0, dot);
  final grouped = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) grouped.write(',');
    grouped.write(whole[i]);
  }
  final sign = value < 0 && fixed != '0.00' ? '-' : '';
  return '$sign\$$grouped${fixed.substring(dot)}';
}

/// Formats [duration] compactly, e.g. `2h 5m 9s`.
String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
  if (minutes > 0) return '${minutes}m ${seconds}s';
  return '${seconds}s';
}
