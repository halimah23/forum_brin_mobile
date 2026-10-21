import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../../notifications/widgets/notification_bell_widget.dart';
import '../../questions/models/question_model.dart';
import '../../questions/models/ticket_status.dart';
import '../../questions/screens/question_detail_screen.dart';
import '../../questions/services/question_service.dart';
import '../../questions/widgets/question_card.dart';
import '../widgets/trending_chart_widget.dart';

class AdminDashboardScreen extends StatefulWidget {
  final UserModel user;

  const AdminDashboardScreen({
    super.key,
    required this.user,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<QuestionModel> teamQuestions = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final filter = widget.user.isAdminLksdm
        ? widget.user.effectiveLksdm
        : (widget.user.tim ?? 'Tim Layanan SDM BOSDM');
    final list = await QuestionService.getQuestions(teamFilter: filter);
    if (mounted) {
      setState(() {
        teamQuestions = list;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdminLksdm = widget.user.isAdminLksdm;
    final lksdmName = widget.user.effectiveLksdm;
    final teamName = widget.user.tim ?? (isAdminLksdm ? lksdmName : 'Fungsi Pengelolaan data dan informasi SDM');
    final primaryColor = isAdminLksdm ? Colors.teal.shade800 : AppColors.primaryBlue;

    final totalCount = teamQuestions.length;
    final waitingQuestions = teamQuestions.where((q) => q.ticketStatus == TicketStatus.open).toList();
    final inProgressQuestions = teamQuestions.where((q) => q.isActive && q.ticketStatus != TicketStatus.open).toList();
    final closedQuestions = teamQuestions.where((q) => q.isClosed).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Image.asset(
              AppConstants.logoAssetPath,
              height: 32,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: primaryColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.slate300, width: 1),
                    ),
                    child: Text(
                      isAdminLksdm ? 'STAF ADMIN LKSDM ($lksdmName)' : 'STAF ADMIN PUSAT ($teamName)',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.slate800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          NotificationBellWidget(user: widget.user, iconColor: primaryColor),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: primaryColor,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 480,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Greeting
                    Text(
                      isAdminLksdm ? 'Selamat datang Staf Admin Kawasan,' : 'Selamat datang Staf Admin Pusat,',
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Active Queue Banner Alert (Jika ada antrean tiket aktif)
                    if (waitingQuestions.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: const Color(0xFFFCD34D), width: 1.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFFD97706), size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${waitingQuestions.length} Antrean Tiket Aktif Memerlukan Respons',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Ada tiket baru dari pegawai yang masuk ke wilayah $lksdmName dan siap ditindaklanjuti atau dijawab langsung.',
                              style: const TextStyle(fontSize: 11.5, color: Color(0xFF92400E), height: 1.3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Metric Counters Row
                    Row(
                      children: [
                        _buildStatBox(
                          label: 'Antrean Baru',
                          value: '${waitingQuestions.length}',
                          color: const Color(0xFFD97706),
                          icon: Icons.hourglass_top_rounded,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          label: 'Diproses',
                          value: '${inProgressQuestions.length}',
                          color: const Color(0xFF0D9488),
                          icon: Icons.support_agent_rounded,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          label: 'Selesai',
                          value: '${closedQuestions.length}',
                          color: const Color(0xFF16A34A),
                          icon: Icons.task_alt_rounded,
                        ),
                        const SizedBox(width: 10),
                        _buildStatBox(
                          label: 'Total',
                          value: '$totalCount',
                          color: AppColors.slate700,
                          icon: Icons.inbox_rounded,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // DAFTAR TIKET AKTIF KAWASAN
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isAdminLksdm ? 'Antrean Tiket $lksdmName' : 'Antrean Tiket $teamName',
                          style: AppTypography.heading3,
                        ),
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (!isLoading && teamQuestions.isEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inbox_outlined, size: 36, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text(
                              'Belum ada tiket antrean untuk wilayah $lksdmName',
                              style: const TextStyle(fontSize: 12, color: AppColors.slate600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: teamQuestions.take(5).length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final q = teamQuestions[index];
                          return QuestionCard(
                            question: q,
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuestionDetailScreen(
                                    question: q,
                                    currentUser: widget.user,
                                  ),
                                ),
                              );
                              _loadData();
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 20),

                    // JOBDESK SCOPE CARD DARI CSV
                    Container(
                      padding: const EdgeInsets.all(14),
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
                              Icon(isAdminLksdm ? Icons.location_city : Icons.account_tree, color: primaryColor, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  isAdminLksdm ? 'Cakupan Tugas & Fungsi $lksdmName' : 'Cakupan Tugas & Fungsi $teamName',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAdminLksdm
                                ? '• Penegakan hukuman disiplin ringan-sedang\n• Fasilitasi Kenaikan Gaji Berkala (KGB)\n• Monitoring Tugas Belajar & Kehadiran Pegawai Kawasan\n• Layanan kepegawaian kawasan & verifikasi layanan pusat'
                                : '• Penanganan eskalasi sesuai tupoksi $teamName\n• Penilaian & penetapan kebijakan tingkat pusat\n• Pendampingan percakapan tripartit (Pegawai + LKSDM + Tim Pusat)',
                            style: const TextStyle(fontSize: 11, height: 1.4, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CHART TOPIK PERTANYAAN PALING BANYAK DITANYAKAN
                    const TrendingChartWidget(),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: AppColors.slate600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
