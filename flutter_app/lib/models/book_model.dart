class Book {
  final int id;
  final String imageUrl;
  final String title;
  final String summary;

  Book({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.summary,
  });

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json["id"],
        imageUrl: json["image"],
        title: json["title"],
        summary: json["summary"],
      );
}
