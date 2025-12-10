import 'dart:convert';
import 'package:emprendegastroloja/data/datasources/local/auth_local_datasource.dart';
import 'package:http/http.dart' as http;
import '../../data/models/comment_model.dart';

class CommentRepository {
  final String baseUrl;
  final AuthLocalDataSourceImpl localDataSource;

  CommentRepository({required this.baseUrl, required this.localDataSource});

  Future<Map<String, String>> _getHeaders() async {
    final token = await localDataSource.getToken();
    //print("🔑 Using token: $token");
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Comment>> getComments(int emprendimientoId) async {
    try {
      final headers = await _getHeaders();
      //print("📡 Fetching comments for emprendimiento: $emprendimientoId");

      final response = await http.get(
        Uri.parse('$baseUrl/comments/$emprendimientoId/'),
        headers: headers,
      );

      //print("📥 Response status: ${response.statusCode}");

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Comment.fromJson(json)).toList();
      } else if (response.statusCode == 401) {
        // If unauthorized, try without auth (for public comments)
        final publicResponse = await http.get(
          Uri.parse('$baseUrl/comments/$emprendimientoId/'),
          headers: {'Content-Type': 'application/json'},
        );

        if (publicResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(publicResponse.body);
          return data.map((json) => Comment.fromJson(json)).toList();
        }

        throw Exception('Authentication required to view comments');
      } else {
        throw Exception(
          'Failed to load comments: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      //print("❌ Error loading comments: $e");
      throw Exception('Error loading comments: $e');
    }
  }

  /// Create a new comment
  Future<Comment> createComment(int emprendimientoId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/$emprendimientoId/'),
        headers: await _getHeaders(),
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 201) {
        return Comment.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create comment: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating comment: $e');
    }
  }

  /// Delete a comment
/// Delete a comment
Future<void> deleteComment(int emprendimientoId, int commentId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/comments/$emprendimientoId/$commentId/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete comment: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Error deleting comment: $e');
  }
}

/// Delete a reply - uses the proper nested endpoint
Future<void> deleteReply(int commentId, int replyId) async {
  try {
    final response = await http.delete(
      Uri.parse('$baseUrl/comments/$commentId/replies/$replyId/'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception('Failed to delete reply: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    throw Exception('Error deleting reply: $e');
  }
}

  /// Create a reply to a comment (you'll need to add this endpoint to Django)
  Future<CommentReply> createReply(int commentId, String content) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/comments/$commentId/replies/'),
        headers: await _getHeaders(),
        body: json.encode({'content': content}),
      );

      if (response.statusCode == 201) {
        return CommentReply.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create reply: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating reply: $e');
    }
  }

  /// Like/unlike a comment (you'll need to add this endpoint to Django)
  Future<void> toggleCommentLike(int commentId) async {
    try {
      // First check if already liked
      final checkResponse = await http.get(
        Uri.parse('$baseUrl/comments/$commentId/like/'),
        headers: await _getHeaders(),
      );

      if (checkResponse.statusCode == 200) {
        final data = json.decode(checkResponse.body);

        final isLiked = data['is_liked'] ?? false;

        // Toggle like
        if (isLiked) {
          // Unlike
          await http.delete(
            Uri.parse('$baseUrl/comments/$commentId/like/'),
            headers: await _getHeaders(),
          );
        } else {
          // Like
          await http.post(
            Uri.parse('$baseUrl/comments/$commentId/like/'),
            headers: await _getHeaders(),
          );
        }
      }
    } catch (e) {
      throw Exception('Error toggling comment like: $e');
    }
  }

  
}
