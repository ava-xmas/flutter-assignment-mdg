import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// CONSTRAINT RELATIONS B/W PARENT AND CHILD WIDGET

// each parent gives its child widget a set of constraints to adhere to
// constrains go down -> sizes go up -> parent sets position
// firstly, a widget asks its parent about the constraints it must adhere to -> min and max width and height
// the widget iteratively passes these constraints to its children, potentially modifying them if necessary
// upon receiving the constraints, each child widget decides its own size
// the parent widget then places its children one by one on the screen, and while doing so,
// it respects the size preferences of the children and positions them both horizontally and vertically

// FN REFERENCES VS FN CALLS

// () => context.go("...") is a close or an anonymous fn, it creates a fn that will call context.go when the user taps
// context.go("...") calls it immediately and assigns its result to ontap which expects a fn not void -> error

BoxDecoration boxDecor = BoxDecoration(
  borderRadius: BorderRadius.circular(6.0),
  border: Border.all(
    color: Colors.grey.shade300,
    width: 1.0,
  ),
);

class BookWidget extends StatelessWidget {
  final int id;
  final String? imageUrl;
  final String bookTitle;
  final String bookSummary;

  const BookWidget({
    super.key,
    required this.id,
    this.imageUrl,
    required this.bookTitle,
    required this.bookSummary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/book/$id'),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Container(
          constraints: BoxConstraints(
            minWidth: double.infinity,
          ),
          alignment: Alignment.center,
          decoration: boxDecor,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // cover page of the book
              SizedBox(
                height: 120,
                child: Image.network(
                  imageUrl ?? "",
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image),
                ),
              ),

              SizedBox(width: 6),

              // title + summary ( w ellipsis for overflow )
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookTitle,
                      style: TextStyle(fontSize: 20),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Text(
                        bookSummary,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
