/// Integers show with no decimal point, halves show one decimal place —
/// matches the prototype's `fmt(n)` exactly.
String fmtNum(double n) => n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(1);
