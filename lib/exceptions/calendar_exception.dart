class CalendarException implements Exception {
  final String code;
  final String message;
  final String? details;

  CalendarException(this.code, this.message, [this.details]);

  @override
  String toString() => 'CalendarException($code): $message${details != null ? '\n$details' : ''}';
} 