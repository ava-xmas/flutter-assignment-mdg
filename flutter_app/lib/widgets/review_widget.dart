import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/reviews_bloc.dart';
import '../bloc/review_bloc.dart';
import '../models/review_model.dart';
import '../screens/auth/auth_cubit.dart';

class ReviewWidget extends StatefulWidget {
  final int bookId;
  final Review review;
  const ReviewWidget({
    super.key,
    required this.bookId,
    required this.review,
  });

  @override
  State<ReviewWidget> createState() => _ReviewWidgetState();
}

class _ReviewWidgetState extends State<ReviewWidget> {
  bool isEditing = false;
  late TextEditingController _commentController;
  late TextEditingController _ratingController;
  late int _rating;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController(text: widget.review.comment);
    _ratingController =
        TextEditingController(text: widget.review.rating.toString());
    _rating = widget.review.rating;
  }

  @override
  void dispose() {
    _commentController.dispose();
    _ratingController.dispose();
    super.dispose();
  }

  void _editReview() {
    // call review bloc
    final myUsername = context.read<AuthCubit>().state.username;

    context.read<ReviewBloc>().add(UpdateReview(
          reviewId: widget.review.id,
          newRating: _rating,
          newComment: _commentController.text,
          username: myUsername!,
        ));

    setState(() {
      isEditing = false;
    });
  }

  void _deleteReview() async {
    final confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text("Delete review"),
            content: Text("Are you sure you want to delete this review?"),
            actions: [
              IconButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: Icon(Icons.check)),
              IconButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  icon: Icon(Icons.close)),
            ],
          );
        });

    if (confirm != true) return;

    // call review bloc
    if (!mounted) return;

    final myUsername = context.read<AuthCubit>().state.username;

    context.read<ReviewBloc>().add(DeleteReview(
          reviewId: widget.review.id,
          username: myUsername!,
        ));

    context.read<ReviewsBloc>().add(FetchReviews(widget.bookId));

    setState(() {
      isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final myUsername = context.watch<AuthCubit>().state.username;
    final isOwner = widget.review.username == myUsername;

    return Column(
      children: [
        // top row : username and edit / delete for owner
        Row(
          mainAxisAlignment: isOwner
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.start,
          children: [
            Text(widget.review.username),
            if (isOwner)
              Row(
                children: [
                  IconButton(
                    icon: Icon(isEditing ? Icons.close : Icons.edit, size: 16),
                    onPressed: () {
                      setState(() {
                        isEditing = !isEditing;
                      });
                    },
                  ),
                  if (!isEditing)
                    IconButton(
                      icon: Icon(Icons.delete, size: 16),
                      onPressed: _deleteReview,
                    ),
                ],
              ),
          ],
        ),

        const SizedBox(height: 10),

        // edit mode
        if (isEditing) ...[
          Column(
            children: [
              Slider(
                value: _rating.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: _rating.toString(),
                onChanged: (value) {
                  setState(() {
                    _rating = value.round();
                  });
                },
              ),
              TextField(
                controller: _commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Edit your comment',
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: _editReview,
                  icon: Icon(Icons.save),
                ),
              )
            ],
          ),
        ] else ...[
          // view mode
          Row(
            children: [
              Text(widget.review.rating.toString()), // large
              Text(
                widget.review.comment,
                maxLines: 5,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          )
        ]
      ],
    );
  }
}
