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
  })  : ticketIdsHandled = ticketIdsHandled ?? {},
        ratings = ratings ?? [],
        tagCounts = tagCounts ?? {};

  int get ticketsHandledCount => ticketIdsHandled.length;
  int get ratingCount => ratings.length;
  double get averageRating => ratings.isEmpty
      ? 0.0
      : ratings.reduce((a, b) => a + b) / ratings.length;

  double get gercepRate => ticketsHandledCount == 0
      ? 0.0
      : (gercepCount / ticketsHandledCount).clamp(0.0, 1.0);
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
  /// Ringkasan Makro CSAT & Kepuasan Layanan dari sekumpulan pertanyaan
  static CsatOverview calculateCsatOverview(List<QuestionModel> questions) {
    if (questions.isEmpty) return CsatOverview.empty();

    int totalRated = 0;
    int sumRating = 0;
    int satisfiedCount = 0; // >= 4

    final Map<int, int> starBreakdown = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    final Map<String, int> tagCounts = {
      'Staf Ramah & Solutif': 0,
      'Jawaban Jelas & Akurat': 0,
      'Respon Cepat (Gercep)': 0,
      'Aplikasi Mudah Digunakan': 0,
    };
    final List<Map<String, dynamic>> recentFeedbacks = [];

    for (var q in questions) {
      if (q.rating != null && q.rating! > 0) {
        final r = q.rating!.clamp(1, 5);
        totalRated++;
        sumRating += r;
        starBreakdown[r] = (starBreakdown[r] ?? 0) + 1;
        if (r >= 4) satisfiedCount++;

        for (var tag in q.ratingTagsList) {
          tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
        }

        if (q.ratingFeedback != null && q.ratingFeedback!.trim().isNotEmpty) {
          recentFeedbacks.add({
            'ticketNumber': q.ticketNumber ?? '#${q.id}',
            'authorName': q.displayAuthorName,
            'rating': r,
            'feedback': q.ratingFeedback!.trim(),
            'tags': q.ratingTagsList,
            'date': q.ratingSubmittedAt ?? q.resolvedAt ?? q.createdAt ?? '',
          });
        }
      }
    }

    final double avg = totalRated > 0 ? (sumRating / totalRated) : 0.0;
    final double satRate = totalRated > 0 ? ((satisfiedCount / totalRated) * 100) : 0.0;

    return CsatOverview(
      totalTickets: questions.length,
      totalRated: totalRated,
      averageRating: avg,
      satisfactionRate: satRate,
      starBreakdown: starBreakdown,
      tagCounts: tagCounts,
      recentFeedbacks: recentFeedbacks,
    );
  }

  /// Daftar Pegawai/Member yang paling sering mengajukan pertanyaan (Top Frequent Askers)
  static List<MemberActivityStat> getTopActiveMembers(
    List<QuestionModel> questions, {
    int limit = 5,
  }) {
    final Map<String, MemberActivityStat> membersMap = {};

    for (var q in questions) {
      final name = q.user?.name ?? (q.isPublic ? 'Pegawai' : q.auditAuthorName);
      final userId = q.user?.id ?? q.user?.email ?? name;
      final kawasan = q.user?.kawasan ?? q.lksdmKawasan ?? '-';
      final satker = q.user?.satuanKerja ?? '-';

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
