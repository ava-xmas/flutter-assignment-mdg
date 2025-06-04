import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// book widget
import '../widgets/book_widget.dart';
// bloc
import '../bloc/books_bloc.dart';

class BooksPage extends StatefulWidget {
  final String username;

  const BooksPage({super.key, required this.username});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: Icon(Icons.search_rounded),
              background: Center(child: Text("Welcome, ${widget.username}")),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            sliver: BlocBuilder<BooksBloc, BooksState>(
              builder: (context, state) {
                if (state is BooksLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(child: CircularProgressIndicator()),
                  );
                } else if (state is BooksLoaded) {
                  final books = state.books;

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final book = books[index];
                        return BookWidget(
                          id: book.id,
                          imageUrl: book.imageUrl,
                          bookTitle: book.title,
                          bookSummary: book.summary,
                        );
                      },
                      childCount: books.length,
                    ),
                  );
                } else if (state is BooksError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Text(
                        state.message,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }
                return const SliverToBoxAdapter(child: SizedBox());
              },
            ),
          )
        ],
      ),
    );
  }
}
