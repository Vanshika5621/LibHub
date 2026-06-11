class Book {
  final String id;
  final String title;
  final String author;
  final String? publisher;
  final String? description;
  final String? coverImage;
  final String genre;
  final String language;
  final int? pages;
  final int? publishedYear;
  final String? isbn;
  final int totalCopies;
  final int availableCopies;
  final double rating;
  final int ratingCount;
  final bool isTrending;
  final bool isNewArrival;
  final DateTime createdAt;

  Book({
    required this.id,
    required this.title,
    required this.author,
    this.publisher,
    this.description,
    this.coverImage,
    required this.genre,
    required this.language,
    this.pages,
    this.publishedYear,
    this.isbn,
    required this.totalCopies,
    required this.availableCopies,
    required this.rating,
    required this.ratingCount,
    required this.isTrending,
    required this.isNewArrival,
    required this.createdAt,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      publisher: json['publisher'] as String?,
      description: json['description'] as String?,
      coverImage: json['cover_image'] as String?,
      genre: json['genre'] as String,
      language: json['language'] as String? ?? 'English',
      pages: json['pages'] as int?,
      publishedYear: json['published_year'] as int?,
      isbn: json['isbn'] as String?,
      totalCopies: json['total_copies'] as int? ?? 1,
      availableCopies: json['available_copies'] as int? ?? 1,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      isTrending: json['is_trending'] as bool? ?? false,
      isNewArrival: json['is_new_arrival'] as bool? ?? false,
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'author': author,
      'publisher': publisher,
      'description': description,
      'cover_image': coverImage,
      'genre': genre,
      'language': language,
      'pages': pages,
      'published_year': publishedYear,
      'isbn': isbn,
      'total_copies': totalCopies,
      'available_copies': availableCopies,
      'rating': rating,
      'rating_count': ratingCount,
      'is_trending': isTrending,
      'is_new_arrival': isNewArrival,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
