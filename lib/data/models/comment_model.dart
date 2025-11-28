class Comment {
  final int id;
  final int emprendimientoId;
  final int userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  int likesCount;
  bool isLikedByUser;
  List<CommentReply> replies;

  Comment({
    required this.id,
    required this.emprendimientoId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    this.likesCount = 0,
    this.isLikedByUser = false,
    this.replies = const [],
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['id'],
      emprendimientoId: json['establecimiento'],
      userId: json['user'],
      userName: json['user_name'] ?? 'Usuario',
      userAvatar: json['user_avatar'] ?? 'https://ui-avatars.com/api/?name=Usuario',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
      likesCount: json['likes_count'] ?? 0,
      isLikedByUser: json['is_liked_by_user'] ?? false,
      replies: json['replies'] != null
          ? (json['replies'] as List)
              .map((r) => CommentReply.fromJson(r))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'content': content,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return 'hace $years año${years > 1 ? 's' : ''}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return 'hace $months mes${months > 1 ? 'es' : ''}';
    } else if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'justo ahora';
    }
  }

  bool get hasReplies => replies.isNotEmpty;

  Comment copyWith({
    int? likesCount,
    bool? isLikedByUser,
    List<CommentReply>? replies,
  }) {
    return Comment(
      id: id,
      emprendimientoId: emprendimientoId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      createdAt: createdAt,
      likesCount: likesCount ?? this.likesCount,
      isLikedByUser: isLikedByUser ?? this.isLikedByUser,
      replies: replies ?? this.replies,
    );
  }
}

class CommentReply {
  final int id;
  final int commentId;
  final int userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;

  CommentReply({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
  });

  factory CommentReply.fromJson(Map<String, dynamic> json) {
    return CommentReply(
      id: json['id'],
      commentId: json['comment'],
      userId: json['user'],
      userName: json['user_name'] ?? 'Usuario',
      userAvatar: json['user_avatar'] ?? 'https://ui-avatars.com/api/?name=Usuario',
      content: json['content'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'comment': commentId,
      'content': content,
    };
  }

  String get timeAgo {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inDays > 0) {
      return 'hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'hace ${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return 'hace ${difference.inMinutes}m';
    } else {
      return 'ahora';
    }
  }
}