class MovieInteraction {
  final int? id;
  final int userId;
  final int movieId;
  bool isWatched;
  bool isFavorite;
  bool isWantToWatch;
  int? rating;
  String? review;
  DateTime? watchedDate;

  MovieInteraction({
    this.id,
    required this.userId,
    required this.movieId,
    this.isWatched = false,
    this.isFavorite = false,
    this.isWantToWatch = false,
    this.rating,
    this.review,
    this.watchedDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'movieId': movieId,
      'isWatched': isWatched ? 1 : 0,
      'isFavorite': isFavorite ? 1 : 0,
      'isWantToWatch': isWantToWatch ? 1 : 0,
      'rating': rating,
      'review': review,
      'watchedDate': watchedDate?.toIso8601String(),
    };
  }

  factory MovieInteraction.fromMap(Map<String, dynamic> map) {
    return MovieInteraction(
      id: map['id'],
      userId: map['userId'],
      movieId: map['movieId'],
      isWatched: map['isWatched'] == 1,
      isFavorite: map['isFavorite'] == 1,
      isWantToWatch: map['isWantToWatch'] == 1,
      rating: map['rating'],
      review: map['review'],
      watchedDate: map['watchedDate'] != null ? DateTime.parse(map['watchedDate']) : null,
    );
  }
}