import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../env.dart';

// events

abstract class ReviewEvent {}

class AddReview extends ReviewEvent {
  final int bookId;
  final int rating;
  final String comment;
  final String username;

  AddReview({
    required this.bookId,
    required this.rating,
    required this.comment,
    required this.username,
  });
}

class UpdateReview extends ReviewEvent {
  final int reviewId;
  final String username;
  final String newComment;
  final int newRating;

  UpdateReview({
    required this.reviewId,
    required this.username,
    required this.newComment,
    required this.newRating,
  });
}

class DeleteReview extends ReviewEvent {
  final int reviewId;
  final String username;

  DeleteReview({required this.reviewId, required this.username});
}

// states

abstract class ReviewState {}

class ReviewInitial extends ReviewState {}

class ReviewLoading extends ReviewState {}

class ReviewSuccess extends ReviewState {}

class ReviewError extends ReviewState {
  final String message;

  ReviewError(this.message);
}

// bloc

class ReviewBloc extends Bloc<ReviewEvent, ReviewState> {
  final _dio = Dio();

  ReviewBloc() : super(ReviewInitial()) {
    on<AddReview>((event, emit) async {
      emit(ReviewLoading());

      try {
        final response = await _dio.post(
          "$baseUrl/books/${event.bookId}/review",
          data: {
            "username": event.username,
            "rating": event.rating,
            "comment": event.comment,
          },
        );

        emit(ReviewSuccess());
      } catch (e) {
        emit(ReviewError("Failed to add review: $e"));
      }
    });

    on<UpdateReview>((event, emit) async {
      emit(ReviewLoading());

      try {
        final response = await _dio.put(
          "$baseUrl/reviews/${event.reviewId}/edit",
          data: {
            "username": event.username,
            "rating": event.newRating,
            "comment": event.newComment,
          },
        );

        emit(ReviewSuccess());
      } catch (e) {
        emit(ReviewError("Failed to update review: $e"));
      }
    });

    on<DeleteReview>((event, emit) async {
      emit(ReviewLoading());

      try {
        final response = await _dio.delete(
          "$baseUrl/reviews/${event.reviewId}/delete",
          data: {
            "username": event.username,
          },
        );

        emit(ReviewSuccess());
      } catch (e) {
        print("Failed to delete review: $e");
        emit(ReviewError("Failed to delete review: $e"));
      }
    });
  }
}
