import 'package:flutter/material.dart';

class BookPage extends StatefulWidget {
  final int? bookId;

  const BookPage({super.key, this.bookId});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Book ID: ${widget.bookId}'),
    );
  }
}
