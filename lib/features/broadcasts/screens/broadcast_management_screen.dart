import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../models/broadcast_model.dart';
import '../models/broadcast_recipient_model.dart';
import '../services/broadcast_service.dart';
import 'create_broadcast_screen.dart';

class BroadcastManagementScreen extends StatefulWidget {
  final UserModel currentUser;

  const BroadcastManagementScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<BroadcastManagementScreen> createState() =>
      _BroadcastManagementScreenState();
}

class _BroadcastManagementScreenState extends State<BroadcastManagementScreen> {
  late String _lksdmScope;
  List<BroadcastModel> _broadcasts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _lksdmScope = widget.currentUser.isSuperAdmin
        ? 'ALL'
        : widget.currentUser.effectiveLksdm;
    _fetchBroadcasts();
  }

  Future<void> _fetchBroadcasts() async {
    setState(() => _isLoading = true);
    final list = await BroadcastService.getBroadcastsCreatedBy(
      senderId: widget.currentUser.id ?? '',
      lksdmScope: _lksdmScope,
    );
    if (mounted) {
      setState(() {
        _broadcasts = list;
        _isLoading = false;
      });
    }
  }

  void _showRecipientsSheet(BroadcastModel broadcast) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<List<BroadcastRecipientModel>>(
          future: BroadcastService.getBroadcastRecipients(broadcast.id),
          builder: (context, snapshot) {
            final recipients = snapshot.data ?? [];
            final readList = recipients.where((r) => r.isRead).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Keterbacaan Siaran',
                          style: AppTypography.heading3,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  Text(
                    broadcast.title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.colorPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Ringkasan Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(
                          'Total Target',
                          '${recipients.length}',
                          Colors.black87,
                        ),
                        _buildSummaryItem(
                          'Sudah Dibaca',
                          '${readList.length}',
                          Colors.green.shade700,
                        ),
                        _buildSummaryItem(
                          'Belum Dibaca',
                          '${recipients.length - readList.length}',
                          Colors.orange.shade800,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Daftar Pegawai Target', style: AppTypography.heading4),
                  const SizedBox(height: 8),
                  Expanded(
                    child: snapshot.connectionState == ConnectionState.waiting
                        ? const Center(child: CircularProgressIndicator())
                        : recipients.isEmpty
                            ? const Center(
                                child: Text('Belum ada data penerima terekam'),
                              )
                            : ListView.separated(
                                itemCount: recipients.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (ctx, idx) {
                                  final r = recipients[idx];
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: CircleAvatar(
                                      backgroundColor: r.isRead
                                          ? Colors.green.shade100
                                          : Colors.grey.shade200,
                                      child: Icon(
                                        r.isRead
                                            ? Icons.check_circle
                                            : Icons.access_time_rounded,
                                        color: r.isRead
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                    title: Text(
                                      r.userName ?? 'Pegawai (${r.userId})',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    subtitle: Text(
                                      r.userUnit ?? 'Unit tidak diketahui',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: r.isRead
                                            ? Colors.green.shade50
                                            : Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: r.isRead
                                              ? Colors.green.shade300
                                              : Colors.amber.shade300,
                                        ),
                                      ),
                                      child: Text(
                                        r.isRead ? 'Dibaca' : 'Terkirim',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: r.isRead
                                              ? Colors.green.shade800
                                              : Colors.amber.shade900,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
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
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  void _confirmDelete(BroadcastModel broadcast) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Siaran?'),
        content: Text(
          'Apakah Anda yakin ingin menghapus siaran "${broadcast.title}"? Riwayat siaran dan notifikasi terkait akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await BroadcastService.deleteBroadcast(broadcast.id);
              _fetchBroadcasts();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Siaran berhasil dihapus')),
                );
              }
            },
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manajemen Broadcast $_lksdmScope'),
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: Colors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBroadcasts,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _broadcasts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign_outlined,
                              size: 72, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'Belum Ada Broadcast Terkirim',
                            style: AppTypography.heading3.copyWith(
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Buat pengumuman satu arah dengan berkas lampiran untuk pegawai di wilayah $_lksdmScope sekarang.',
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.colorPrimary,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                            ),
                            icon: const Icon(Icons.add, color: Colors.white),
                            label: const Text(
                              'Buat Siaran Perdana',
                              style: TextStyle(color: Colors.white),
                            ),
                            onPressed: () async {
                              final res = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CreateBroadcastScreen(
                                    currentUser: widget.currentUser,
                                  ),
                                ),
                              );
                              if (res == true) _fetchBroadcasts();
                            },
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _broadcasts.length,
                    itemBuilder: (ctx, idx) {
                      final b = _broadcasts[idx];
                      final total = b.totalRecipients ?? 0;
                      final read = b.readCount ?? 0;
                      final percent =
                          total > 0 ? ((read / total) * 100).round() : 0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: b.isUrgent
                                ? Colors.red.shade300
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Icon Badge
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: b.isUrgent
                                          ? Colors.red.shade50
                                          : AppColors.colorPrimary.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      b.isUrgent
                                          ? Icons.warning_rounded
                                          : Icons.campaign_rounded,
                                      color: b.isUrgent
                                          ? Colors.red
                                          : AppColors.colorPrimary,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            if (b.isUrgent)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 2),
                                                margin: const EdgeInsets.only(
                                                    right: 6),
                                                decoration: BoxDecoration(
                                                  color: Colors.red.shade100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'URGENT',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            Text(
                                              b.targetType == 'all_lksdm'
                                                  ? 'Semua Pegawai'
                                                  : b.targetType == 'unit_filter'
                                                      ? 'Unit: ${b.targetFilterValue}'
                                                      : 'Target Khusus',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          b.title,
                                          style: AppTypography.heading4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (val) {
                                      if (val == 'recipients') {
                                        _showRecipientsSheet(b);
                                      } else if (val == 'delete') {
                                        _confirmDelete(b);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(
                                        value: 'recipients',
                                        child: Row(
                                          children: [
                                            Icon(Icons.people_outline,
                                                size: 18),
                                            SizedBox(width: 8),
                                            Text('Daftar Penerima'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline,
                                                size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Hapus Siaran',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                b.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall,
                              ),
                              if (b.hasAttachment) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Icon(Icons.attach_file,
                                        size: 14, color: Colors.blueGrey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        b.attachmentName ?? 'Lampiran Berkas',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const Divider(height: 20),
                              // Baris Keterbacaan & Tanggal
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Keterbacaan: $read / $total Pegawai ($percent%)',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.grey.shade800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: total > 0
                                                ? (read / total)
                                                : 0.0,
                                            backgroundColor:
                                                Colors.grey.shade200,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                              percent >= 70
                                                  ? Colors.green
                                                  : percent >= 30
                                                      ? Colors.orange
                                                      : AppColors.colorPrimary,
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  TextButton(
                                    onPressed: () => _showRecipientsSheet(b),
                                    child: const Text(
                                      'Rincian',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.colorPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Buat Siaran Baru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateBroadcastScreen(
                currentUser: widget.currentUser,
              ),
            ),
          );
          if (res == true) _fetchBroadcasts();
        },
      ),
    );
  }
}
