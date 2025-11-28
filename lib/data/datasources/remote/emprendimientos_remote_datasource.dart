import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../models/emprendimiento_model.dart';

class EmprendimientosRemoteDataSource {
  final String baseUrl;
  final http.Client client;

  EmprendimientosRemoteDataSource({
    required this.baseUrl,
    http.Client? client,
  }) : client = client ?? http.Client();

  static const Duration _timeout = Duration(seconds: 30);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Map<String, String> _headersWithAuth(String? token) {
    final headers = Map<String, String>.from(_headers);
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<List<Emprendimiento>> getEmprendimientos({
    String? search,
    String? categoria,
    String? parroquia,
    String? sector,
    String? ordenarPor,
    double? precio, 
    int? page,
    int? pageSize,
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/establecimientos/').replace(
        queryParameters: _buildQueryParameters(
          search: search,
          categoria: categoria,
          parroquia: parroquia,
          sector: sector,
          ordenarPor: ordenarPor,
          precio: precio,
          page: page,
          pageSize: pageSize,
        ),
      );

      final response = await client
          .get(uri, headers: _headersWithAuth(token))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? data;
        
        return results
            .map((json) => Emprendimiento.fromJson(json as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticación inválido');
      } else if (response.statusCode == 404) {
        throw NotFoundException('No se encontraron emprendimientos');
      } else {
        throw ServerException(
          'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } on FormatException {
      throw DataException('Error al procesar los datos');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Error inesperado: $e');
    }
  }

  Future<Emprendimiento> getEmprendimientoById(
    int id, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/establecimientos/$id/');

      final response = await client
          .get(uri, headers: _headersWithAuth(token))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Emprendimiento.fromJson(data);
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticación inválido');
      } else if (response.statusCode == 404) {
        throw NotFoundException('Emprendimiento no encontrado');
      } else {
        throw ServerException(
          'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } on FormatException {
      throw DataException('Error al procesar los datos');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Error inesperado: $e');
    }
  }

  Future<bool> likeEmprendimiento(int id, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/likes/$id');

      final response = await client
          .post(uri, headers: _headersWithAuth(token))
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticación inválido');
      } else if (response.statusCode == 400) {
        throw ValidationException('Ya has dado like a este emprendimiento');
      } else {
        throw ServerException(
          'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Error inesperado: $e');
    }
  }

  Future<bool> unlikeEmprendimiento(int id, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/likes/$id');

      final response = await client
          .delete(uri, headers: _headersWithAuth(token))
          .timeout(_timeout);

      if (response.statusCode == 204 || response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticación inválido');
      } else if (response.statusCode == 404) {
        throw NotFoundException('Like no encontrado');
      } else {
        throw ServerException(
          'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Error inesperado: $e');
    }
  }

  Future<bool> rateEmprendimiento(int id, int rating, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/ratings/$id');
      final body = json.encode({'rating': rating});

      final response = await client
          .post(uri, headers: _headersWithAuth(token), body: body)
          .timeout(_timeout);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticación inválido');
      } else if (response.statusCode == 400) {
        throw ValidationException('Calificación inválida');
      } else {
        throw ServerException(
          'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } on FormatException {
      throw DataException('Error al procesar los datos');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Error inesperado: $e');
    }
  }

  Future<bool> addComment(int id, String comment, String token) async {
    try {
      final uri = Uri.parse('$baseUrl/api/establecimientos/$id/comments/');
      final body = json.encode({'content': comment});

      final response = await client
          .post(uri, headers: _headersWithAuth(token), body: body)
          .timeout(_timeout);

      if (response.statusCode == 201) {
        return true;
      } else if (response.statusCode == 401) {
        throw UnauthorizedException('Token de autenticación inválido');
      } else if (response.statusCode == 400) {
        throw ValidationException('Comentario inválido');
      } else {
        throw ServerException(
          'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } on FormatException {
      throw DataException('Error al procesar los datos');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Error inesperado: $e');
    }
  }

  Future<List<String>> getParroquias() async {
    try {
      final uri = Uri.parse('$baseUrl/parroquias');

      final response = await client
          .get(uri, headers: _headers)
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      } else {
        throw ServerException(
          'Error del servidor: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on SocketException {
      throw NetworkException('Sin conexión a internet');
    } on http.ClientException {
      throw NetworkException('Error de conexión');
    } on FormatException {
      throw DataException('Error al procesar los datos');
    } catch (e) {
      if (e is AppException) rethrow;
      throw UnknownException('Error inesperado: $e');
    }
  }

  Map<String, String> _buildQueryParameters({
    String? search,
    String? categoria,
    String? parroquia,
    String? sector,
    String? ordenarPor,
    double? precio, 
    int? page,
    int? pageSize,
  }) {
    final params = <String, String>{};

    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (categoria != null && categoria.isNotEmpty) {
      params['categoria'] = categoria;
    }
    if (parroquia != null && parroquia.isNotEmpty) {
      params['parroquia'] = parroquia;
    }
    if (sector != null && sector.isNotEmpty) {
      params['sector'] = sector;
    }
    if (ordenarPor != null && ordenarPor.isNotEmpty) {
      params['ordering'] = ordenarPor;
    }
    if (precio != null) {
      params['precio'] = precio.toString();
    }
    if (page != null) {
      params['page'] = page.toString();
    }
    if (pageSize != null) {
      params['page_size'] = pageSize.toString();
    }

    return params;
  }
}

// Custom exceptions
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(String message) : super(message);
}

class ServerException extends AppException {
  final int? statusCode;
  const ServerException(String message, {this.statusCode}) : super(message);
}

class UnauthorizedException extends AppException {
  const UnauthorizedException(String message) : super(message);
}

class NotFoundException extends AppException {
  const NotFoundException(String message) : super(message);
}

class ValidationException extends AppException {
  const ValidationException(String message) : super(message);
}

class DataException extends AppException {
  const DataException(String message) : super(message);
}

class UnknownException extends AppException {
  const UnknownException(String message) : super(message);
}