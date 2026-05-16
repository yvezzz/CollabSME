/// Exception personnalisée pour transporter les erreurs structurées de l'API.
class ApiException implements Exception {
  final String message;
  final Map<String, dynamic>? errors;
  final int? statusCode;

  ApiException(this.message, {this.errors, this.statusCode});

  @override
  String toString() => message;
}
