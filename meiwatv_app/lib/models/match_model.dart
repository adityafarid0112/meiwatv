import 'package:flutter/foundation.dart';

class MatchModel {
  final String id;
  final String title;
  final String homeTeam;
  final String awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final String? homeScore;
  final String? awayScore;
  final String? scoreText;
  final String? matchMinute;
  final String league;
  final String kickoffIso;
  final String kickoffText;
  final int status; // 0 = Upcoming, 1 = Live, 2 = Finished
  final String sportCategory; // e.g. ⚽ Sepak Bola, 🏀 Bola Basket, etc.
  final String streamJalur1; // HLS / HD
  final String streamJalur2; // FLV / Fast
  final String streamJalur3; // Web / Backup

  const MatchModel({
    required this.id,
    required this.title,
    required this.homeTeam,
    required this.awayTeam,
    this.homeLogo,
    this.awayLogo,
    this.homeScore,
    this.awayScore,
    this.scoreText,
    this.matchMinute,
    required this.league,
    required this.kickoffIso,
    required this.kickoffText,
    required this.status,
    this.sportCategory = '⚽ Sepak Bola',
    required this.streamJalur1,
    required this.streamJalur2,
    required this.streamJalur3,
  });

  bool get isLive => status == 1;
  bool get isUpcoming => status == 0;
  bool get isFinished => status == 2;
  bool get hasScore =>
      (isLive || isFinished) &&
      (((homeScore != null &&
              awayScore != null &&
              homeScore!.isNotEmpty &&
              awayScore!.isNotEmpty) ||
          (scoreText != null && scoreText!.isNotEmpty)));

  factory MatchModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final title = json['title'] as String? ?? 'Pertandingan Olahraga';
    final parts = title.split(RegExp(r'\s+vs\s+|\s+-\s+', caseSensitive: false));
    final defaultHome = parts.isNotEmpty ? parts[0].trim() : 'Tim Tuan Rumah';
    final defaultAway = parts.length > 1 ? parts[1].trim() : 'Tim Tamu';

    final streams = json['streams'] is Map<String, dynamic>
        ? json['streams'] as Map<String, dynamic>
        : <String, dynamic>{};

    return MatchModel(
      id: docId ?? json['id'] as String? ?? UniqueKey().toString(),
      title: title,
      homeTeam: json['homeTeam'] as String? ?? defaultHome,
      awayTeam: json['awayTeam'] as String? ?? defaultAway,
      homeLogo: json['homeLogo'] as String?,
      awayLogo: json['awayLogo'] as String?,
      homeScore: json['homeScore']?.toString(),
      awayScore: json['awayScore']?.toString(),
      scoreText: json['scoreText'] as String?,
      matchMinute: json['matchMinute'] as String?,
      league: json['league'] as String? ?? 'Live Sports',
      kickoffIso: json['kickoffIso'] as String? ?? '',
      kickoffText: json['kickoffText'] as String? ?? 'Live Hari Ini',
      status: json['status'] is int
          ? json['status'] as int
          : (json['status'] == 'LIVE' || json['status'] == 1 ? 1 : 0),
      sportCategory: json['sportCategory'] as String? ?? '⚽ Sepak Bola',
      streamJalur1: json['streamUrl'] as String? ??
          json['streamJalur1'] as String? ??
          streams['jalur1'] as String? ??
          '',
      streamJalur2: json['server2Url'] as String? ??
          json['streamJalur2'] as String? ??
          streams['jalur2'] as String? ??
          '',
      streamJalur3: json['postUrl'] as String? ??
          json['streamJalur3'] as String? ??
          streams['jalur3'] as String? ??
          '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'homeTeam': homeTeam,
      'awayTeam': awayTeam,
      'homeLogo': homeLogo,
      'awayLogo': awayLogo,
      'homeScore': homeScore,
      'awayScore': awayScore,
      'scoreText': scoreText,
      'matchMinute': matchMinute,
      'league': league,
      'kickoffIso': kickoffIso,
      'kickoffText': kickoffText,
      'status': status,
      'sportCategory': sportCategory,
      'streamJalur1': streamJalur1,
      'streamJalur2': streamJalur2,
      'streamJalur3': streamJalur3,
      'streams': {
        'jalur1': streamJalur1,
        'jalur2': streamJalur2,
        'jalur3': streamJalur3,
      },
    };
  }
}
