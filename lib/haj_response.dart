



class HAJResponse {
  final int statusCode;
  final String message;
  dynamic body;

  HAJResponse({required this.statusCode, required this.message, this.body});
}