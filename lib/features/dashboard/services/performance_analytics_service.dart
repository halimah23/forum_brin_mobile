import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../questions/models/question_model.dart';

class StaffPerformanceStat {
  final String key;
  final String name;
  final String role;
  final String teamOrLksdm;
  int answerCount;
  final Set<int> ticketIdsHandled;
  final List<int> ratings;
  int gercepCount;
  final Map<String, int> tagCounts;

  final int? _ticketsHandledOverride;
  final double? _averageRatingOverride;
  final int? _ratingCountOverride;

  StaffPerformanceStat({
    required this.key,
    required this.name,
    required this.role,
    required this.teamOrLksdm,
    this.answerCount = 0,
    Set<int>? ticketIdsHandled,
    List<int>? ratings,
    this.gercepCount = 0,
    Map<String, int>? tagCounts,
    int? ticketsHandledOverride,
    double? averageRatingOverride,
    int? ratingCountOverride,
  })  : ticketIdsHandled = ticketIdsHandled ?? {},
        ratings = ratings ?? [],
        tagCounts = tagCounts ?? {},
        _ticketsHandledOverride = ticketsHandledOverride,
        _averageRatingOverride = averageRatingOverride,
        _ratingCountOverride = ratingCountOverride;

  int get ticketsHandledCount =>
      _ticketsHandledOverride ?? ticketIdsHandled.length;
  int get ratingCount => _ratingCountOverride ?? ratings.length;
  double get averageRating =>
      _averageRatingOverride ??
      (ratings.isEmpty
          ? 0.0
          : ratings.reduce((a, b) => a + b) / ratings.length);

  double get gercepRate => ticketsHandledCount == 0
      ? 0.0
      : (gercepCount / ticketsHandledCount).clamp(0.0, 1.0);

  factory StaffPerformanceStat.fromSupabase(Map<String, dynamic> json) {
    final name = json['staff_name']?.toString() ?? 'Petugas';
    final rawRole = json['role']?.toString() ?? 'Staf Layanan SDM';
    final team = json['team_or_lksdm']?.toString() ?? 'Layanan SDM BRIN';
    final totalTickets =
        int.tryParse(json['total_tickets_handled']?.toString() ?? '0') ?? 0;
    final totalAnswers =
        int.tryParse(json['total_answers']?.toString() ?? '0') ?? 0;
    final avgRating =
        double.tryParse(json['avg_rating']?.toString() ?? '0') ?? 0.0;
    final ratingCount =
        int.tryParse(json['rating_count']?.toString() ?? '0') ?? 0;
    final gercepCount =
        int.tryParse(json['gercep_count']?.toString() ?? '0') ?? 0;

    return StaffPerformanceStat(
      key: json['staff_id']?.toString() ?? name,
      name: name,
      role: rawRole,
      teamOrLksdm: team,
      answerCount: totalAnswers,
      gercepCount: gercepCount,
      ticketsHandledOverride: totalTickets,
      averageRatingOverride: avgRating,
      ratingCountOverride: ratingCount,
    );
  }
}

class MemberActivityStat {
  final String userId;
  final String name;
  final String kawasan;
  final String satuanKerja;
  int questionCount;
  int resolvedCount;
  final List<int> ratingsGiven;

  MemberActivityStat({
    required this.userId,
    required this.name,
    required this.kawasan,
    required this.satuanKerja,
    this.questionCount = 0,
    this.resolvedCount = 0,
    List<int>? ratingsGiven,
  }) : ratingsGiven = ratingsGiven ?? [];

  double get averageRatingGiven => ratingsGiven.isEmpty
      ? 0.0
      : ratingsGiven.reduce((a, b) => a + b) / ratingsGiven.length;
}

class CsatOverview {
  final int totalTickets;
  final int totalRated;
  final double averageRating;
  final double satisfactionRate; // Persentase bintang >= 4
  final Map<int, int> starBreakdown; // 1 to 5
  final Map<String, int> tagCounts;
  final List<Map<String, dynamic>> recentFeedbacks;

  const CsatOverview({
    required this.totalTickets,
    required this.totalRated,
    required this.averageRating,
    required this.satisfactionRate,
    required this.starBreakdown,
    required this.tagCounts,
    required this.recentFeedbacks,
  });

  static CsatOverview empty() {
    return const CsatOverview(
      totalTickets: 0,
      totalRated: 0,
      averageRating: 0.0,
      satisfactionRate: 0.0,
      starBreakdown: {5: 0, 4: 0, 3: 0, 2: 0, 1: 0},
      tagCounts: {
        'Staf Ramah & Solutif': 0,
        'Jawaban Jelas & Akurat': 0,
        'Respon Cepat (Gercep)': 0,
        'Aplikasi Mudah Digunakan': 0,
      },
      recentFeedbacks: [],
    );
  }
}

class PerformanceAnalyticsService {
  static SupabaseClient get _client => Supabase.instance.client;

  /// Ambil data Leaderboard Kinerja Petugas langsung dari Supabase View `view_staff_performance_leaderboard`
  /// Dengan fallback dinamis ke kalkulasi in-memory jika koneksi offline / view belum dieksekusi
  static Future<List<StaffPerformanceStat>> fetchStaffLeaderboardFromSupabase({
    List<QuestionModel>? fallbackQuestions,
    String? teamFilter,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('view_staff_performance_leaderboard').select();
      if (teamFilter != null && teamFilter.isNotEmpty && teamFilter != 'Semua Tim') {
        query = query.ilike('team_or_lksdm', '%$teamFilter%');
      }
      final response = await query.limit(limit);
      final rawList = List<Map<String, dynamic>>.from(response);
      if (rawList.isNotEmpty) {
        return rawList.map((item) => StaffPerformanceStat.fromSupabase(item)).toList();
      }
    } catch (e) {
      debugPrint('Notice: fetchStaffLeaderboardFromSupabase fallback to local memory: $e');
    }

    if (fallbackQuestions != null && fallbackQuestions.isNotEmpty) {
      return getStaffPerformanceLeaderboard(
        fallbackQuestions,
        teamFilter: teamFilter,
        limit: limit,
      );
    }
    return [];
  }

  /// Menghitung ringkasan survei kepuasan layanan (CSAT Overview)
  static CsatOverview calculateCsatOverview(List<QuestionModel> questions) {
    int totalTickets = questions.length;
    int totalRated = 0;
    int sumRating = 0;
    int satisfiedCount = 0;

    final starMap = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final tagCounts = <String, int>{
      'Staf Ramah & Solutif': 0,
      'Jawaban Jelas & Akurat': 0,
      'Respon Cepat (Gercep)': 0,
      'Aplikasi Mudah Digunakan': 0,
    };
    final List<Map<String, dynamic>> feedbacks = [];

    for (var q in questions) {
      if (q.rating != null && q.rating! >= 1 && q.rating! <= 5) {
        totalRated++;
        final r = q.rating!;
        sumRating += r;
        starMap[r] = (starMap[r] ?? 0) + 1;
        if (r >= 4) satisfiedCount++;

        for (var tag in q.ratingTagsList) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }

        if (q.ratingFeedback != null && q.ratingFeedback!.trim().isNotEmpty) {
          feedbacks.add({
            'ticket_id': q.id,
            'ticket_number': q.ticketNumber,
            'user_name': q.displayAuthorName,
            'user_kawasan': q.lksdmKawasan ?? q.authorAsalLksdm,
            'rating': r,
            'feedback': q.ratingFeedback!.trim(),
            'tags': q.ratingTagsList,
            'submitted_at': q.ratingSubmittedAt ?? q.resolvedAt ?? q.createdAt,
          });
        }
      }
    }

    feedbacks.sort((a, b) => (b['submitted_at'] ?? '').compareTo(a['submitted_at'] ?? ''));

    final avgRating = totalRated == 0 ? 0.0 : (sumRating / totalRated);
    final satRate = totalRated == 0 ? 0.0 : ((satisfiedCount / totalRated) * 100);

    return CsatOverview(
      totalTickets: totalTickets,
      totalRated: totalRated,
      averageRating: avgRating,
      satisfactionRate: satRate,
      starBreakdown: starMap,
      tagCounts: tagCounts,
      recentFeedbacks: feedbacks.take(10).toList(),
    );
  }

  /// Leaderboard pegawai yang paling aktif mengajukan pertanyaan
  static List<MemberActivityStat> getTopActiveMembers(
    List<QuestionModel> questions, {
    int limit = 5,
  }) {
    final Map<String, MemberActivityStat> membersMap = {};

    for (var q in questions) {
      final user = q.user;
      final userId = user?.id ?? q.displayAuthorName;
      final name = user?.name ?? q.displayAuthorName;
      final kawasan = q.lksdmKawasan ?? user?.effectiveLksdm ?? 'Layanan Kawasan SDM';
      final satker = user?.unit ?? 'Unit Kerja BRIN';

      final stat = membersMap.putIfAbsent(
        userId,
        () => MemberActivityStat(
          userId: userId,
          name: name,
          kawasan: kawasan,
          satuanKerja: satker,
        ),
      );

      stat.questionCount++;
      if (q.isClosed) stat.resolvedCount++;
      if (q.rating != null && q.rating! > 0) {
        stat.ratingsGiven.add(q.rating!);
      }
    }

    final list = membersMap.values.toList();
    list.sort((a, b) => b.questionCount.compareTo(a.questionCount));
    if (list.length > limit) return list.sublist(0, limit);
    return list;
  }

  /// Leaderboard kinerja staf / admin / ketua tim yang menangani tiket
  static List<StaffPerformanceStat> getStaffPerformanceLeaderboard(
    List<QuestionModel> questions, {
    String? teamFilter,
    int limit = 10,
  }) {
    final Map<String, StaffPerformanceStat> staffMap = {};

    for (var q in questions) {
      final answers = q.answers ?? [];
      final hasGercepTag = q.ratingTagsList.any((t) => t.toLowerCase().contains('gercep'));

      for (var ans in answers) {
        if (!ans.isOfficial || ans.isSystemEvent) continue;

        final name = ans.penjawabNama.trim();
        if (name.isEmpty || name.toLowerCase() == 'sistem' || name.toLowerCase() == 'pengguna') continue;

        final role = ans.penjawabRole;
        final teamOrLksdm = ans.senderLksdm ?? ans.senderUnit ?? q.lksdmKawasan ?? q.targetTimPusat ?? 'BOSDM BRIN';

        if (teamFilter != null && teamFilter.isNotEmpty && teamFilter != 'Semua Tim') {
          final filterClean = teamFilter.toLowerCase();
          final matches = teamOrLksdm.toLowerCase().contains(filterClean) ||
              (ans.penjawabRole.toLowerCase().contains(filterClean));
          if (!matches) continue;
        }

        final stat = staffMap.putIfAbsent(
          name,
          () => StaffPerformanceStat(
            key: name,
            name: name,
            role: role,
            teamOrLksdm: teamOrLksdm,
          ),
        );

        stat.answerCount++;
        if (q.id != null) {
          stat.ticketIdsHandled.add(q.id!);
        }

        // Hitung Kecepatan Respons (Gercep)
        bool isFast = hasGercepTag;
        if (!isFast && ans.createdAt != null && q.createdAt != null) {
          try {
            final qTime = DateTime.parse(q.createdAt!);
            final aTime = DateTime.parse(ans.createdAt!);
            if (aTime.difference(qTime).inHours <= 2) {
              isFast = true;
            }
          } catch (_) {}
        }
        if (isFast) {
          stat.gercepCount++;
        }

        // Catat Rating tiket yang ditangani
        if (q.rating != null && q.rating! > 0) {
          stat.ratings.add(q.rating!);
          for (var tag in q.ratingTagsList) {
            stat.tagCounts[tag] = (stat.tagCounts[tag] ?? 0) + 1;
          }
        }
      }
    }

    final list = staffMap.values.toList();
    // Urutkan berdasarkan: 1. Tiket ditangani (banyak), 2. Rata-rata rating (tinggi), 3. Gercep
    list.sort((a, b) {
      final compTickets = b.ticketsHandledCount.compareTo(a.ticketsHandledCount);
      if (compTickets != 0) return compTickets;
      return b.averageRating.compareTo(a.averageRating);
    });

    if (list.length > limit) return list.sublist(0, limit);
    return list;
  }

  /// Statistik kinerja personal staf/admin tertentu
  static StaffPerformanceStat getStaffPersonalPerformance(
    List<QuestionModel> questions, {
    required String userId,
    required String userName,
    String? role,
    String? team,
  }) {
    final cleanName = userName.trim().toLowerCase();
    final stat = StaffPerformanceStat(
      key: userName,
      name: userName,
      role: role ?? 'Staf Admin',
      teamOrLksdm: team ?? 'Layanan SDM',
    );

    for (var q in questions) {
      final answers = q.answers ?? [];
      final hasGercepTag = q.ratingTagsList.any((t) => t.toLowerCase().contains('gercep'));
      bool handledThisTicket = false;

      for (var ans in answers) {
        if (ans.isSystemEvent) continue;

        final matchUserId = ans.userId != null && ans.userId == userId;
        final matchName = ans.penjawabNama.trim().toLowerCase() == cleanName;

        if (matchUserId || matchName) {
          stat.answerCount++;
          handledThisTicket = true;

          bool isFast = hasGercepTag;
          if (!isFast && ans.createdAt != null && q.createdAt != null) {
            try {
              final qTime = DateTime.parse(q.createdAt!);
              final aTime = DateTime.parse(ans.createdAt!);
              if (aTime.difference(qTime).inHours <= 2) isFast = true;
            } catch (_) {}
          }
          if (isFast) stat.gercepCount++;
        }
      }

      if (handledThisTicket && q.id != null) {
        stat.ticketIdsHandled.add(q.id!);
        if (q.rating != null && q.rating! > 0) {
          stat.ratings.add(q.rating!);
          for (var tag in q.ratingTagsList) {
            stat.tagCounts[tag] = (stat.tagCounts[tag] ?? 0) + 1;
          }
        }
      }
    }

    return stat;
  }
}
