class VideoServer {
  final String name;
  final String serverKey;
  final String url;
  final String qualityLabel;

  const VideoServer({
    required this.name,
    required this.serverKey,
    required this.url,
    required this.qualityLabel,
  });

  factory VideoServer.fromJson(Map<String, dynamic> json) {
    return VideoServer(
      name: json['name'] ?? '',
      serverKey: json['serverKey'] ?? '',
      url: json['url'] ?? '',
      qualityLabel: json['qualityLabel'] ?? 'HD',
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'serverKey': serverKey,
    'url': url,
    'qualityLabel': qualityLabel,
  };
}

class SeriesEpisode {
  final int season;
  final int episodeNo;
  final String title;
  final String slug;
  final String url;
  final String embedUrl;
  final List<VideoServer> servers;

  SeriesEpisode({
    required this.season,
    required this.episodeNo,
    required this.title,
    required this.slug,
    required this.url,
    this.embedUrl = '',
    this.servers = const [],
  });

  factory SeriesEpisode.fromJson(Map<String, dynamic> json, {String baseUrl = ''}) {
    final slug = json['slug'] ?? '';
    String fullUrl = slug;
    if (!fullUrl.startsWith('http') && baseUrl.isNotEmpty) {
      final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
      final cleanSlug = slug.startsWith('/') ? slug : '/$slug';
      fullUrl = '$cleanBase$cleanSlug';
    }
    return SeriesEpisode(
      season: json['s'] is int ? json['s'] : int.tryParse(json['s']?.toString() ?? '1') ?? 1,
      episodeNo: json['episode_no'] is int
          ? json['episode_no']
          : int.tryParse(json['episode_no']?.toString() ?? '1') ?? 1,
      title: json['title'] ?? 'Episode ${json['episode_no'] ?? 1}',
      slug: slug,
      url: fullUrl,
      embedUrl: json['embedUrl'] ?? '',
      servers: json['servers'] != null && json['servers'] is List
          ? (json['servers'] as List).map((s) => VideoServer.fromJson(s)).toList()
          : const [],
    );
  }

  SeriesEpisode copyWith({
    int? season,
    int? episodeNo,
    String? title,
    String? slug,
    String? url,
    String? embedUrl,
    List<VideoServer>? servers,
  }) {
    return SeriesEpisode(
      season: season ?? this.season,
      episodeNo: episodeNo ?? this.episodeNo,
      title: title ?? this.title,
      slug: slug ?? this.slug,
      url: url ?? this.url,
      embedUrl: embedUrl ?? this.embedUrl,
      servers: servers ?? this.servers,
    );
  }
}

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
  final List<SeriesEpisode> episodes;
  final List<VideoServer> servers;

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
    this.episodes = const [],
    this.servers = const [],
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
      servers: json['servers'] != null && json['servers'] is List
          ? (json['servers'] as List).map((s) => VideoServer.fromJson(s)).toList()
          : const [],
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
      'servers': servers.map((s) => s.toJson()).toList(),
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
    List<SeriesEpisode>? episodes,
    List<VideoServer>? servers,
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
      episodes: episodes ?? this.episodes,
      servers: servers ?? this.servers,
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
