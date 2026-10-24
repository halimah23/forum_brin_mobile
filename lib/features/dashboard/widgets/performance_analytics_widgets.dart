import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_typography.dart';
import '../services/performance_analytics_service.dart';

/// Kartu Ringkasan Indeks Kepuasan Layanan (CSAT) & Aspek Penilaian
class CsatScoreCardWidget extends StatelessWidget {
  final CsatOverview overview;
  final String title;
  final String subtitle;

  const CsatScoreCardWidget({
    super.key,
    required this.overview,
    this.title = 'Indeks Kepuasan Layanan (CSAT)',
    this.subtitle = 'Evaluasi layanan, staf penanganan, dan kemudahan aplikasi',
  });

  @override
  Widget build(BuildContext context) {
    final avg = overview.averageRating;
    final totalRated = overview.totalRated;
    final satRate = overview.satisfactionRate;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFFD97706),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.heading3),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Rating Hero Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          avg > 0 ? avg.toStringAsFixed(1) : '-',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 28),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$totalRated Ulasan Masuk',
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF92400E)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Tingkat Kepuasan',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${satRate.toStringAsFixed(1)}%',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: totalRated > 0 ? (satRate / 100).clamp(0.0, 1.0) : 0.0,
                        backgroundColor: AppColors.slate200,
                        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      totalRated > 0
                          ? '${overview.starBreakdown[5] ?? 0} Sangat Puas, ${overview.starBreakdown[4] ?? 0} Puas dari total penanganan tiket.'
                          : 'Belum ada penilaian kepuasan layanan yang diberikan.',
                      style: const TextStyle(fontSize: 10.5, color: AppColors.slate600),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 12),

          // 4 Aspek Layanan Tag Indicators
          const Text(
            'Sorotan Aspek Layanan:',
            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.slate800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: overview.tagCounts.entries.map((entry) {
              final count = entry.value;
              final isHigh = count > 0;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isHigh ? const Color(0xFFF0FDF4) : AppColors.slate100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isHigh ? const Color(0xFFBBF7D0) : AppColors.slate300,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHigh ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                      size: 13,
                      color: isHigh ? const Color(0xFF16A34A) : AppColors.slate400,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isHigh ? const Color(0xFF166534) : AppColors.slate600,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: isHigh ? const Color(0xFFDCFCE7) : AppColors.slate200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isHigh ? const Color(0xFF15803D) : AppColors.slate700,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Kartu Leaderboard Staf & Ketua Tim (Rutin & Gercep Menjawab)
class StaffLeaderboardCardWidget extends StatelessWidget {
  final List<StaffPerformanceStat> staffList;
  final String title;
  final String subtitle;
  final VoidCallback? onViewAll;

  const StaffLeaderboardCardWidget({
    super.key,
    required this.staffList,
    this.title = 'Kinerja Staf & Tim Penanganan (Gercep)',
    this.subtitle = 'Staf dan Ketua Tim yang rutin, cepat, dan ber-rating tinggi',
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.military_tech_rounded,
                  color: Color(0xFF0284C7),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.heading3),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (staffList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada aktivitas respons staf pada tiket.',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: staffList.length,
              separatorBuilder: (_, __) => const Divider(height: 12, color: AppColors.slate200),
              itemBuilder: (context, index) {
                final staff = staffList[index];
                final rank = index + 1;

                Color rankColor = AppColors.slate500;
                if (rank == 1) rankColor = const Color(0xFFD97706);
                if (rank == 2) rankColor = const Color(0xFF475569);
                if (rank == 3) rankColor = const Color(0xFFB45309);

                return Row(
                  children: [
                    // Rank Badge
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: rank <= 3 ? rankColor.withAlpha(30) : AppColors.slate100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: rank <= 3 ? rankColor : AppColors.slate300,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '$rank',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: rankColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Staff Name & Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.name,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.slate900,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.slate100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  staff.role,
                                  style: const TextStyle(fontSize: 9.5, color: AppColors.slate700, fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  staff.teamOrLksdm,
                                  style: const TextStyle(fontSize: 9.5, color: AppColors.slate500),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Performance Stats Pills
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 2),
                            Text(
                              staff.averageRating > 0 ? staff.averageRating.toStringAsFixed(1) : '-',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '⚡ ${staff.gercepCount} Gercep',
                                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${staff.ticketsHandledCount} tiket',
                              style: const TextStyle(fontSize: 10, color: AppColors.slate600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Kartu Anggota Paling Sering Bertanya (Top Frequent Askers)
class TopMembersCardWidget extends StatelessWidget {
  final List<MemberActivityStat> memberList;
  final String title;
  final String subtitle;

  const TopMembersCardWidget({
    super.key,
    required this.memberList,
    this.title = 'Pegawai Paling Aktif Berkonsultasi',
    this.subtitle = 'Pegawai yang rutin menyampaikan kendala & pertanyaan kepegawaian',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E8FF),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.record_voice_over_rounded,
                  color: Color(0xFF9333EA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.heading3),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (memberList.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada data pertanyaan pegawai.',
                style: TextStyle(fontSize: 12, color: AppColors.slate500),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: memberList.length,
              separatorBuilder: (_, __) => const Divider(height: 12, color: AppColors.slate200),
              itemBuilder: (context, index) {
                final member = memberList[index];
                final rank = index + 1;

                return Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F3FF),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFDDD6FE), width: 1),
                      ),
                      child: Text(
                        '$rank',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            member.name,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.slate900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${member.kawasan} • ${member.satuanKerja}',
                            style: const TextStyle(fontSize: 10, color: AppColors.slate500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${member.questionCount} Pertanyaan',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF7E22CE)),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${member.resolvedCount} tuntas terjawab',
                          style: const TextStyle(fontSize: 9.5, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}

/// Kartu Kinerja Personal Staf Admin / Petugas
class PersonalPerformanceCardWidget extends StatelessWidget {
  final StaffPerformanceStat personalStat;

  const PersonalPerformanceCardWidget({
    super.key,
    required this.personalStat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFF16A34A),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rapor Kinerja & CSAT Anda', style: AppTypography.heading3),
                    Text('Penilaian pegawai atas responsivitas dan kualitas jawaban Anda', style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Row(
            children: [
              // Rating Anda
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            personalStat.averageRating > 0
                                ? personalStat.averageRating.toStringAsFixed(1)
                                : '-',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 20),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${personalStat.ratingCount} Ulasan Masuk',
                        style: const TextStyle(fontSize: 10, color: Color(0xFF166534)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Tiket Ditangani
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.slate100,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: AppColors.slate200),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${personalStat.ticketsHandledCount}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.slate800),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Tiket Ditangani',
                        style: TextStyle(fontSize: 10, color: AppColors.slate600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Respons Gercep
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '${personalStat.gercepCount}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Respon Gercep ⚡',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          if (personalStat.tagCounts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Apresiasi dari Pegawai:',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.slate700),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: personalStat.tagCounts.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Text(
                    '${e.key} (${e.value})',
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D)),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
