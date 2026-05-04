abstract class ApiConsumer {
  Future<dynamic> get(String path, {Map<String, dynamic>? queryParameters});
  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData,
  });
  Future<dynamic> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData,
  });
  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
  });

  Future<dynamic> request(
    String path, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    bool? isFormData = false,
    dynamic options,
  });
}
