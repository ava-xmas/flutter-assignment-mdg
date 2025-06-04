import 'package:flutter/material.dart';

class BookPage extends StatefulWidget {
  String? bookId;

  BookPage({super.key, required this.bookId});

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
