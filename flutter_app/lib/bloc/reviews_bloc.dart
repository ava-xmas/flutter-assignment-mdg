import '../models/review_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../env.dart';

// events

abstract class ReviewsEvent {}

class FetchReviews extends ReviewsEvent {
  final int bookId;

  FetchReviews(this.bookId);
}

// states

abstract class ReviewsState {}

class ReviewsInitial extends ReviewsState {}

class ReviewsLoading extends ReviewsState {}

class ReviewsLoaded extends ReviewsState {
  final List<Review> reviews;

  ReviewsLoaded(this.reviews);
}

class ReviewsError extends ReviewsState {
  final String message;

  ReviewsError(this.message);
}

// bloc

class ReviewsBloc extends Bloc<ReviewsEvent, ReviewsState> {
  final Dio _dio = Dio();

  ReviewsBloc() : super(ReviewsInitial()) {
    on<FetchReviews>((event, emit) async {
      emit(ReviewsLoading());

      try {
        final response =
            await _dio.get('$baseUrl/books/${event.bookId}/reviews');

        final List<dynamic> data = response.data;

        final reviews = data.map((json) => Review.fromJson(json)).toList();

        emit(ReviewsLoaded(reviews));
      } catch (e) {
        print(e);
        emit(ReviewsError("Failed to fetch reviews: $e"));
      }
    });
  }
}
