import 'package:flutter/foundation.dart';
import '../utils/league_translator.dart';

class MatchModel {
  final String id;
  final String _title;
  final String _homeTeam;
  final String _awayTeam;
  final String? homeLogo;
  final String? awayLogo;
  final String? homeScore;
  final String? awayScore;
  final String? scoreText;
  final String? matchMinute;
  final String _league;
  final String kickoffIso;
  final String kickoffText;
  final int status; // 0 = Upcoming, 1 = Live, 2 = Finished
  final String sportCategory; // e.g. ⚽ Sepak Bola, 🏀 Bola Basket, etc.
  final String streamJalur1; // HLS / HD
  final String streamJalur2; // FLV / Fast
  final String streamJalur3; // Web / Backup
  final String streamJalur4; // Fallback / Additional

  const MatchModel({
    required this.id,
    required String title,
    required String homeTeam,
    required String awayTeam,
    this.homeLogo,
    this.awayLogo,
    this.homeScore,
    this.awayScore,
    this.scoreText,
    this.matchMinute,
    required String league,
    required this.kickoffIso,
    required this.kickoffText,
    required this.status,
    this.sportCategory = '⚽ Sepak Bola',
    required this.streamJalur1,
    required this.streamJalur2,
    required this.streamJalur3,
    this.streamJalur4 = '',
  })  : _title = title,
        _homeTeam = homeTeam,
        _awayTeam = awayTeam,
        _league = league;

  String get homeTeam => LeagueTranslator.cleanTeamName(_homeTeam);
  String get awayTeam => LeagueTranslator.cleanTeamName(_awayTeam);
  String get title {
    final h = homeTeam;
    final a = awayTeam;
    if (h.isNotEmpty && a.isNotEmpty) {
      return '$h vs $a';
    }
    return LeagueTranslator.cleanTeamName(_title);
  }
  String get league => LeagueTranslator.translate(_league);

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

  List<String> get availableStreams {
    final list = <String>[];
    if (streamJalur1.isNotEmpty) list.add(streamJalur1);
    if (streamJalur2.isNotEmpty && !list.contains(streamJalur2)) list.add(streamJalur2);
    if (streamJalur3.isNotEmpty && !list.contains(streamJalur3)) list.add(streamJalur3);
    if (streamJalur4.isNotEmpty && !list.contains(streamJalur4)) list.add(streamJalur4);
    return list;
  }

  factory MatchModel.fromJson(Map<String, dynamic> json, {String? docId}) {
    final rawLeague = json['league'] as String? ?? 'Live Sports';
    final translatedLeague = LeagueTranslator.translate(rawLeague);

    final rawTitle = json['title'] as String? ?? 'Pertandingan Olahraga';
    final parts = rawTitle.split(RegExp(r'\s+vs\s+|\s+-\s+', caseSensitive: false));
    final defaultHome = parts.isNotEmpty ? parts[0].trim() : 'Tim Tuan Rumah';
    final defaultAway = parts.length > 1 ? parts[1].trim() : 'Tim Tamu';

    final rawHome = json['homeTeam'] as String? ?? defaultHome;
    final rawAway = json['awayTeam'] as String? ?? defaultAway;

    final home = LeagueTranslator.cleanTeamName(rawHome);
    final away = LeagueTranslator.cleanTeamName(rawAway);
    final title = '$home vs $away';

    final streams = json['streams'] is Map<String, dynamic>
        ? json['streams'] as Map<String, dynamic>
        : <String, dynamic>{};

    return MatchModel(
      id: docId ?? json['id'] as String? ?? UniqueKey().toString(),
      title: title,
      homeTeam: home,
      awayTeam: away,
      homeLogo: json['homeLogo'] as String?,
      awayLogo: json['awayLogo'] as String?,
      homeScore: json['homeScore']?.toString(),
      awayScore: json['awayScore']?.toString(),
      scoreText: json['scoreText'] as String?,
      matchMinute: json['matchMinute'] as String?,
      league: translatedLeague,
      kickoffIso: json['kickoffIso'] as String? ?? '',
      kickoffText: json['kickoffText'] as String? ?? 'Live Hari Ini',
      status: json['status'] is int
          ? json['status'] as int
          : (json['status'] == 'LIVE' || json['status'] == 1 ? 1 : 0),
      sportCategory: json['sportCategory'] as String? ?? '⚽ Sepak Bola',
      streamJalur1: json['streamJalur1'] as String? ??
          streams['jalur1'] as String? ??
          json['streamUrl'] as String? ??
          json['daddyliveUrl'] as String? ??
          '',
      streamJalur2: json['streamJalur2'] as String? ??
          streams['jalur2'] as String? ??
          json['server2Url'] as String? ??
          '',
      streamJalur3: json['streamJalur3'] as String? ??
          streams['jalur3'] as String? ??
          json['postUrl'] as String? ??
          '',
      streamJalur4: json['streamJalur4'] as String? ??
          streams['jalur4'] as String? ??
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
      'streamJalur4': streamJalur4,
      'streams': {
        'jalur1': streamJalur1,
        'jalur2': streamJalur2,
        'jalur3': streamJalur3,
        'jalur4': streamJalur4,
      },
    };
  }
}
