



class HAJResponse {
  final int statusCode;
  final String message;
  dynamic body;

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  HAJResponse({required this.statusCode, required this.message, this.body});
}