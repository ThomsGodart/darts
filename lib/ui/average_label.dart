/// A three-dart average as shown everywhere: "45.2", or "–" before any dart.
String averageLabel(double? average) => average?.toStringAsFixed(1) ?? '–';
