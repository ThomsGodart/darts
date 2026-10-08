/// A three-dart average as shown everywhere: "45.2", or "–" before any dart.
String averageLabel(double? average) => average?.toStringAsFixed(1) ?? '–';

/// An MPR as shown everywhere: "3.00", or "–" before any dart.
String mprLabel(double? mpr) => mpr?.toStringAsFixed(2) ?? '–';
