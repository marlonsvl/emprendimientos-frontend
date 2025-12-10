import 'package:emprendegastroloja/data/models/comment_model.dart';
import 'package:emprendegastroloja/domain/repositories/comment_repository.dart';
import 'package:flutter/material.dart';

class CommentsSection extends StatefulWidget {
  final int emprendimientoId;
  final CommentRepository commentRepository;
  final int? currentUserId;

  const CommentsSection({
    super.key,
    required this.emprendimientoId,
    required this.commentRepository,
    this.currentUserId,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  List<Comment> _comments = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final comments = await widget.commentRepository.getComments(
        widget.emprendimientoId,
      );
      
      if (!mounted) return;
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const PageStorageKey<String>('comments_tab'),
      slivers: [
        _buildHeader(),
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_error != null)
          _buildError()
        else if (_comments.isEmpty)
          _buildEmptyState()
        else
          _buildCommentsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Column(
          children: [
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showWriteReviewDialog,
                icon: const Icon(Icons.rate_review, size: 16),
                label: const Text('Escribir reseña'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.comment, size: 64, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text('No hay comentarios aún', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Sé el primero en dejar una reseña',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommentsList() {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => CommentCard(
            comment: _comments[index],
            currentUserId: widget.currentUserId,
            onDelete: () => _deleteComment(_comments[index]),
            onLike: () => _toggleLike(_comments[index]),
            onReply: (text) => _addReply(_comments[index], text),
          ),
          childCount: _comments.length,
        ),
      ),
    );
  }

  Widget _buildError() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadComments,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showWriteReviewDialog() {
    // Implementation...
  }

  Future<void> _deleteComment(Comment comment) async {
    // Implementation...
  }

  Future<void> _toggleLike(Comment comment) async {
    // Implementation...
  }

  Future<void> _addReply(Comment comment, String text) async {
    // Implementation...
  }
}

class CommentCard extends StatelessWidget {
  final Comment comment;
  final int? currentUserId;
  final VoidCallback onDelete;
  final VoidCallback onLike;
  final Function(String) onReply;

  const CommentCard({
    Key? key,
    required this.comment,
    required this.currentUserId,
    required this.onDelete,
    required this.onLike,
    required this.onReply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isOwner = currentUserId != null && comment.userId == currentUserId;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Comment content...
          ],
        ),
      ),
    );
  }
}