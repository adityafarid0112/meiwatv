class Movie {
  final String title;
  final String slug;
  final String url;
  final String posterUrl;
  final String rating;
  final String quality;
  final String year;
  final String duration;
  final String synopsis;
  final List<String> genres;
  final String director;
  final List<String> cast;
  final String embedUrl;
  final bool isSeries;

  Movie({
    required this.title,
    required this.slug,
    required this.url,
    required this.posterUrl,
    this.rating = "",
    this.quality = "HD",
    this.year = "",
    this.duration = "",
    this.synopsis = "",
    this.genres = const [],
    this.director = "",
    this.cast = const [],
    this.embedUrl = "",
    this.isSeries = false,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      url: json['url'] ?? '',
      posterUrl: json['posterUrl'] ?? '',
      rating: json['rating'] ?? '',
      quality: json['quality'] ?? 'HD',
      year: json['year'] ?? '',
      duration: json['duration'] ?? '',
      synopsis: json['synopsis'] ?? '',
      genres: List<String>.from(json['genres'] ?? []),
      director: json['director'] ?? '',
      cast: List<String>.from(json['cast'] ?? []),
      embedUrl: json['embedUrl'] ?? '',
      isSeries: json['isSeries'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'slug': slug,
      'url': url,
      'posterUrl': posterUrl,
      'rating': rating,
      'quality': quality,
      'year': year,
      'duration': duration,
      'synopsis': synopsis,
      'genres': genres,
      'director': director,
      'cast': cast,
      'embedUrl': embedUrl,
      'isSeries': isSeries,
    };
  }

  Movie copyWith({
    String? title,
    String? slug,
    String? url,
    String? posterUrl,
    String? rating,
    String? quality,
    String? year,
    String? duration,
    String? synopsis,
    List<String>? genres,
    String? director,
    List<String>? cast,
    String? embedUrl,
    bool? isSeries,
  }) {
    return Movie(
      title: title ?? this.title,
      slug: slug ?? this.slug,
      url: url ?? this.url,
      posterUrl: posterUrl ?? this.posterUrl,
      rating: rating ?? this.rating,
      quality: quality ?? this.quality,
      year: year ?? this.year,
      duration: duration ?? this.duration,
      synopsis: synopsis ?? this.synopsis,
      genres: genres ?? this.genres,
      director: director ?? this.director,
      cast: cast ?? this.cast,
      embedUrl: embedUrl ?? this.embedUrl,
      isSeries: isSeries ?? this.isSeries,
    );
  }
}

class GenreCategory {
  final String title;
  final String slug;

  const GenreCategory({required this.title, required this.slug});

  factory GenreCategory.fromJson(Map<String, dynamic> json) {
    return GenreCategory(
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
    );
  }
}

class StudioSource {
  final String name;
  final String baseUrl;
  final int priority;
  final bool isActive;

  StudioSource({
    required this.name,
    required this.baseUrl,
    required this.priority,
    required this.isActive,
  });

  factory StudioSource.fromJson(Map<String, dynamic> json) {
    return StudioSource(
      name: json['name'] ?? '',
      baseUrl: json['baseUrl'] ?? '',
      priority: json['priority'] ?? 1,
      isActive: json['isActive'] ?? true,
    );
  }
}
