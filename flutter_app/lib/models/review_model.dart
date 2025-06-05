class Review {
  final int rating;
  final String username;
  final String comment;

  Review({
    required this.rating,
    required this.username,
    required this.comment,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      rating: json["rating"],
      username: json["username"],
      comment: json["comment"],
    );
  }
}
