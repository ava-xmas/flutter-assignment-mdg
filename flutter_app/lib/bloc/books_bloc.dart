import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/book_model.dart';
import 'package:dio/dio.dart';
import '../env.dart';

// events

abstract class BooksEvent {}

class FetchBooks extends BooksEvent {}

// states

abstract class BooksState {}

class BooksInitial extends BooksState {}

class BooksLoading extends BooksState {}

class BooksLoaded extends BooksState {
  final List<Book> books;

  BooksLoaded(this.books);
}

class BooksError extends BooksState {
  final String message;

  BooksError(this.message);
}

// bloc

class BooksBloc extends Bloc<BooksEvent, BooksState> {
  final Dio _dio = Dio();

  BooksBloc() : super(BooksInitial()) {
    on<FetchBooks>((event, emit) async {
      emit(BooksLoading());

      try {
        final response = await _dio.get('$baseUrl/books');

        final List<dynamic> data = response.data;

        final books = data.map((json) => Book.fromJson(json)).toList();
        emit(BooksLoaded(books));
      } catch (e) {
        print(e);
        emit(BooksError("Failed to fetch books: $e"));
      }
    });
  }
}
