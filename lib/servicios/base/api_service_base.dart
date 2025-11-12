import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../configuracion/app_config.dart';

abstract class ApiServiceBase {
  final String baseUrl;
  final Map<String, String> defaultHeaders;

  ApiServiceBase({
    String? baseUrl,
    Map<String, String>? headers,
  })  : baseUrl = baseUrl ?? AppConfig.baseApiUrl,
        defaultHeaders = {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          ...?headers,
        };

  // Método GET genérico
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParameters,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint, queryParameters);
      final response = await _makeRequest(
        () => http.get(uri, headers: _mergeHeaders(headers)),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Método POST genérico
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _makeRequest(
        () => http.post(
          uri,
          headers: _mergeHeaders(headers),
          body: body != null ? json.encode(body) : null,
        ),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Método PUT genérico
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _makeRequest(
        () => http.put(
          uri,
          headers: _mergeHeaders(headers),
          body: body != null ? json.encode(body) : null,
        ),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Método DELETE genérico
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _makeRequest(
        () => http.delete(uri, headers: _mergeHeaders(headers)),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Método PATCH genérico
  Future<ApiResponse<T>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final uri = _buildUri(endpoint);
      final response = await _makeRequest(
        () => http.patch(
          uri,
          headers: _mergeHeaders(headers),
          body: body != null ? json.encode(body) : null,
        ),
      );

      return _handleResponse<T>(response, fromJson);
    } catch (e) {
      return ApiResponse.error(_handleError(e));
    }
  }

  // Construir URI con parámetros de consulta
  Uri _buildUri(String endpoint, [Map<String, String>? queryParameters]) {
    final url = baseUrl.endsWith('/') && endpoint.startsWith('/')
        ? '$baseUrl${endpoint.substring(1)}'
        : baseUrl.endsWith('/') || endpoint.startsWith('/')
            ? '$baseUrl$endpoint'
            : '$baseUrl/$endpoint';

    return Uri.parse(url).replace(queryParameters: queryParameters);
  }

  // Combinar headers por defecto con headers personalizados
  Map<String, String> _mergeHeaders(Map<String, String>? customHeaders) {
    return {
      ...defaultHeaders,
      ...?customHeaders,
    };
  }

  // Ejecutar request con timeout y reintentos
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFunction,
  ) async {
    int attempts = 0;
    late http.Response response;

    while (attempts < AppConfig.maxRetryAttempts) {
      try {
        response = await requestFunction().timeout(
          Duration(seconds: AppConfig.apiTimeoutSeconds),
        );

        if (_shouldRetry(response.statusCode) && attempts < AppConfig.maxRetryAttempts - 1) {
          attempts++;
          await Future.delayed(Duration(milliseconds: _getDelayMs(attempts)));
          continue;
        }

        return response;
      } on SocketException {
        if (attempts < AppConfig.maxRetryAttempts - 1) {
          attempts++;
          await Future.delayed(Duration(milliseconds: _getDelayMs(attempts)));
          continue;
        }
        throw ApiException('Sin conexión a internet', ApiErrorType.network);
      } on HttpException {
        throw ApiException('Error de HTTP', ApiErrorType.http);
      } on FormatException {
        throw ApiException('Formato de respuesta inválido', ApiErrorType.parse);
      } catch (e) {
        if (attempts < AppConfig.maxRetryAttempts - 1) {
          attempts++;
          await Future.delayed(Duration(milliseconds: _getDelayMs(attempts)));
          continue;
        }
        throw ApiException('Error desconocido: $e', ApiErrorType.unknown);
      }
    }

    return response;
  }

  // Determinar si se debe reintentar basado en el código de estado
  bool _shouldRetry(int statusCode) {
    return statusCode >= 500 || statusCode == 429; // Server error o rate limit
  }

  // Calcular delay exponencial para reintentos
  int _getDelayMs(int attempt) {
    return (1000 * (attempt * 2)).clamp(1000, 10000);
  }

  // Manejar respuesta HTTP
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(Map<String, dynamic>)? fromJson,
  ) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      // Respuesta exitosa
      if (response.body.isEmpty) {
        return ApiResponse.success(null);
      }

      try {
        final jsonData = json.decode(response.body);

        if (fromJson != null && jsonData is Map<String, dynamic>) {
          final data = fromJson(jsonData);
          return ApiResponse.success(data);
        } else if (fromJson != null && jsonData is List) {
          final data = jsonData.map((item) => fromJson(item)).toList();
          return ApiResponse.success(data as T);
        } else {
          return ApiResponse.success(jsonData);
        }
      } catch (e) {
        return ApiResponse.error(
          ApiException('Error al parsear respuesta', ApiErrorType.parse),
        );
      }
    } else {
      // Respuesta de error
      return ApiResponse.error(_handleHttpError(statusCode, response.body));
    }
  }

  // Manejar errores HTTP
  ApiException _handleHttpError(int statusCode, String responseBody) {
    String message;
    ApiErrorType type;

    try {
      final jsonBody = json.decode(responseBody);
      message = jsonBody['message'] ?? jsonBody['error'] ?? 'Error desconocido';
    } catch (e) {
      message = 'Error de servidor';
    }

    switch (statusCode) {
      case 400:
        type = ApiErrorType.badRequest;
        message = message.isNotEmpty ? message : 'Solicitud inválida';
        break;
      case 401:
        type = ApiErrorType.unauthorized;
        message = 'No autorizado';
        break;
      case 403:
        type = ApiErrorType.forbidden;
        message = 'Acceso denegado';
        break;
      case 404:
        type = ApiErrorType.notFound;
        message = 'Recurso no encontrado';
        break;
      case 429:
        type = ApiErrorType.rateLimit;
        message = 'Demasiadas solicitudes';
        break;
      case 500:
        type = ApiErrorType.serverError;
        message = 'Error interno del servidor';
        break;
      default:
        type = ApiErrorType.unknown;
        message = message.isNotEmpty ? message : 'Error desconocido';
    }

    return ApiException(message, type, statusCode);
  }

  // Manejar errores generales
  ApiException _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    } else if (error is SocketException) {
      return ApiException('Sin conexión a internet', ApiErrorType.network);
    } else if (error is HttpException) {
      return ApiException('Error de HTTP', ApiErrorType.http);
    } else if (error is FormatException) {
      return ApiException('Formato de respuesta inválido', ApiErrorType.parse);
    } else {
      return ApiException('Error desconocido: $error', ApiErrorType.unknown);
    }
  }
}

// Clase para respuestas de API
class ApiResponse<T> {
  final T? data;
  final ApiException? error;
  final bool isSuccess;

  ApiResponse._({this.data, this.error, required this.isSuccess});

  factory ApiResponse.success(T? data) {
    return ApiResponse._(data: data, isSuccess: true);
  }

  factory ApiResponse.error(ApiException error) {
    return ApiResponse._(error: error, isSuccess: false);
  }

  bool get hasData => data != null;
  bool get hasError => error != null;
}

// Clase para excepciones de API
class ApiException implements Exception {
  final String message;
  final ApiErrorType type;
  final int? statusCode;

  ApiException(this.message, this.type, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message (${type.name})';
}

// Enum para tipos de errores
enum ApiErrorType {
  network,
  http,
  parse,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  rateLimit,
  serverError,
  unknown,
}

// Clase para configuración de autenticación
class AuthConfig {
  final String? token;
  final String? refreshToken;
  final String tokenType;

  AuthConfig({
    this.token,
    this.refreshToken,
    this.tokenType = 'Bearer',
  });

  Map<String, String> get authHeaders {
    if (token != null) {
      return {'Authorization': '$tokenType $token'};
    }
    return {};
  }
}

// Extensión para servicios con autenticación
mixin AuthenticatedApiMixin on ApiServiceBase {
  AuthConfig? _authConfig;

  void setAuthConfig(AuthConfig config) {
    _authConfig = config;
  }

  void clearAuth() {
    _authConfig = null;
  }

  @override
  Map<String, String> _mergeHeaders(Map<String, String>? customHeaders) {
    final headers = {
      ...defaultHeaders,
      ...?_authConfig?.authHeaders,
      ...?customHeaders,
    };
    return headers;
  }

  bool get isAuthenticated => _authConfig?.token != null;
}