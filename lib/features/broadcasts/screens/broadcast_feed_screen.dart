import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_typography.dart';
import '../../auth/models/user_model.dart';
import '../models/broadcast_model.dart';
import '../services/broadcast_service.dart';
import 'broadcast_detail_screen.dart';

class BroadcastFeedScreen extends StatefulWidget {
  final UserModel currentUser;

  const BroadcastFeedScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<BroadcastFeedScreen> createState() => _BroadcastFeedScreenState();
}

class _BroadcastFeedScreenState extends State<BroadcastFeedScreen> {
  List<BroadcastModel> _broadcasts = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // 'all', 'unread', 'urgent'

  @override
  void initState() {
    super.initState();
    _fetchBroadcasts();
  }

  Future<void> _fetchBroadcasts() async {
    setState(() => _isLoading = true);
    final list = await BroadcastService.getBroadcastsForUser(
      userId: widget.currentUser.id ?? '',
      lksdmScope: widget.currentUser.effectiveLksdm,
    );
    if (mounted) {
      setState(() {
        _broadcasts = list;
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    final dt = DateTime.tryParse(dateStr);
    if (dt == null) return dateStr;
    final local = dt.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year;
    return '$day/$month/$year';
  }

  @override
  Widget build(BuildContext context) {
    final lksdmName = widget.currentUser.effectiveLksdm;

    final filteredList = _broadcasts.where((b) {
      if (_selectedFilter == 'unread') return !b.isReadByMe;
      if (_selectedFilter == 'urgent') return b.isUrgent;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Pengumuman $lksdmName'),
        backgroundColor: AppColors.colorPrimary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Filter Chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade50,
            child: Row(
              children: [
                _buildFilterChip('all', 'Semua (${_broadcasts.length})'),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'unread',
                  'Belum Dibaca (${_broadcasts.where((b) => !b.isReadByMe).length})',
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  'urgent',
                  'Penting (${_broadcasts.where((b) => b.isUrgent).length})',
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Daftar Broadcast Feed
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchBroadcasts,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredList.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.campaign_outlined,
                                    size: 64, color: Colors.grey.shade400),
                                const SizedBox(height: 12),
                                Text(
                                  'Belum Ada Pengumuman',
                                  style: AppTypography.heading3.copyWith(
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Pengumuman resmi dari $lksdmName akan tampil di halaman ini.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredList.length,
                          itemBuilder: (ctx, idx) {
                            final b = filteredList[idx];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: b.isReadByMe ? 1 : 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: !b.isReadByMe
                                      ? AppColors.colorPrimary.withOpacity(0.4)
                                      : Colors.grey.shade200,
                                  width: !b.isReadByMe ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BroadcastDetailScreen(
                                        broadcast: b,
                                        currentUser: widget.currentUser,
                                      ),
                                    ),
                                  );
                                  _fetchBroadcasts();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
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
                                            b.senderName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade700,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            _formatDate(b.createdAt),
                                            style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey),
                                          ),
                                          if (!b.isReadByMe) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Colors.blue,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        b.title,
                                        style:
                                            AppTypography.heading4.copyWith(
                                          fontWeight: !b.isReadByMe
                                              ? FontWeight.bold
                                              : FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        b.content,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTypography.bodySmall,
                                      ),
                                      if (b.hasAttachment) ...[
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            const Icon(Icons.attach_file,
                                                size: 14,
                                                color: Colors.blueGrey),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                b.attachmentName ??
                                                    'Berkas Lampiran',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.blueGrey,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return FilterChip(
      selected: isSelected,
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: Colors.white,
      selectedColor: AppColors.colorPrimary,
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }
}
