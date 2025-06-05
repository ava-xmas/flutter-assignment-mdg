import 'package:flutter/material.dart';
import 'package:flutter_app/bloc/books_bloc.dart';
import 'package:flutter_app/bloc/reviews_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/book_model.dart';
import '../widgets/review_widget.dart';

class BookPage extends StatefulWidget {
  final int id;

  const BookPage({super.key, required this.id});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<BooksBloc, BooksState>(
        builder: (context, state) {
          if (state is BooksLoaded) {
            // get the book
            List<Book> books = state.books;
            Book book = books.firstWhere((book) => book.id == widget.id);

            return CustomScrollView(
              slivers: <Widget>[
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  shadowColor: Colors.grey,
                  pinned: false,
                  floating: false,
                  elevation: 0,
                  toolbarHeight: MediaQuery.of(context).size.height * 0.70,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Image.network(
                      book.imageUrl,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                SliverAppBar(
                  automaticallyImplyLeading: false,
                  shadowColor: Colors.grey,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  pinned: true,
                  floating: true,
                  backgroundColor: Colors.white,
                  elevation: 0,
                  // toolbarHeight: MediaQuery.of(context).size.height * 0.10,
                  flexibleSpace: FlexibleSpaceBar(
                    centerTitle: true,
                    titlePadding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12.0),
                    title: Text(
                      book.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 20,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          child: Text(
                            book.summary,
                            maxLines: 255,
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                        ),

                        SizedBox(height: 20),

                        // reviews area

                        BlocBuilder<ReviewsBloc, ReviewsState>(
                          builder: (context, state) {
                            if (state is ReviewsLoading) {
                              return Center(child: CircularProgressIndicator());
                            } else if (state is ReviewsLoaded) {
                              final reviews = state.reviews;

                              if (reviews.isEmpty) {
                                return Center(
                                  child: Text("No reviews yet."),
                                );
                              }
                              // calculate average rating
                              double avgRating = reviews
                                      .map((r) => r.rating)
                                      .reduce((a, b) => a + b) /
                                  reviews.length;

                              // count ratings per star level
                              final ratingCounts = List<int>.filled(5, 0);
                              for (var r in reviews) {
                                final index = r.rating.floor().clamp(1, 5) - 1;
                                ratingCounts[index]++;
                              }

                              return Column(
                                children: [
                                  Text(
                                    "Average Rating: ${avgRating.toStringAsFixed(1)} / 5.0",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),

                                  Text("Ratings summary"), // llm

                                  Text("All reviews"),

                                  ListView.builder(
                                      shrinkWrap: true,
                                      physics: NeverScrollableScrollPhysics(),
                                      itemCount: reviews.length,
                                      itemBuilder: (context, index) {
                                        final review = reviews[index];
                                        return Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: ReviewWidget(
                                            review: review,
                                          ),
                                        );
                                      }),
                                ],
                              );
                            } else if (state is ReviewsError) {
                              return Text(
                                  "Failed to load reviews: ${state.message}");
                            } else {
                              return SizedBox();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else if (state is BooksLoading) {
            return Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return SizedBox();
          }
        },
      ),
    );
  }
}
