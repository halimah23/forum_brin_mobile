import 'package:flutter/material.dart';
import '../data/tusi_catalog_data.dart';
import '../models/category_model.dart';

/// Modal Bottom Sheet interaktif dan ringkas untuk melihat Tugas & Fungsi (Tupoksi) 14 Tim BOSDM
class TupoksiBottomSheet extends StatefulWidget {
  final void Function(String teamName)? onSelectTeam;

  const TupoksiBottomSheet({
    super.key,
    this.onSelectTeam,
  });

  /// Menampilkan TupoksiBottomSheet
  static Future<String?> show(
    BuildContext context, {
    void Function(String teamName)? onSelectTeam,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TupoksiBottomSheet(onSelectTeam: onSelectTeam),
    );
  }

  @override
  State<TupoksiBottomSheet> createState() => _TupoksiBottomSheetState();
}

class _TupoksiBottomSheetState extends State<TupoksiBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;

    // Filter tim & tusi berdasarkan kata kunci pencarian
    final List<Map<String, dynamic>> filteredTeams = [];

    for (final team in TusiCatalogData.centralTeams) {
      final tusiList = TusiCatalogData.getTugasFungsiByTeam(team);
      if (_searchQuery.isEmpty) {
        filteredTeams.add({
          'team': team,
          'tusi': tusiList,
          'matched': false,
        });
      } else {
        final teamMatches = team.toLowerCase().contains(_searchQuery);
        final matchingTusi = tusiList.where((t) {
          final kodeMatches = t.kode?.toLowerCase().contains(_searchQuery) ?? false;
          return t.nama.toLowerCase().contains(_searchQuery) || kodeMatches;
        }).toList();

        if (teamMatches || matchingTusi.isNotEmpty) {
          filteredTeams.add({
            'team': team,
            'tusi': teamMatches ? tusiList : matchingTusi,
            'matched': true,
          });
        }
      }
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle drag bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 16, 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.menu_book_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Tugas & Fungsi 14 Tim BOSDM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF212121),
                            ),
                          ),
                          Text(
                            'Cari bidang layanan atau tugas fungsi terkait',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Tutup',
                    ),
                  ],
                ),
              ),

              // Search Box
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari tim, mutasi, talenta, disiplin, KGB...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Hasil pencarian / daftar tim
              Expanded(
                child: filteredTeams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded,
                                size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada tim atau tupoksi yang cocok',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Coba gunakan kata kunci umum lainnya',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                        itemCount: filteredTeams.length,
                        itemBuilder: (context, index) {
                          final item = filteredTeams[index];
                          final String teamName = item['team'] as String;
                          final List<CategoryModel> tusiList =
                              item['tusi'] as List<CategoryModel>;
                          final bool isSearching = _searchQuery.isNotEmpty;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSearching && item['matched'] == true
                                    ? primaryColor.withValues(alpha: 0.3)
                                    : Colors.grey[200]!,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Theme(
                              data: theme.copyWith(dividerColor: Colors.transparent),
                              child: ExpansionTile(
                                initiallyExpanded: isSearching,
                                tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                leading: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: primaryColor.withValues(alpha: 0.1),
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  teamName,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                subtitle: Text(
                                  '${tusiList.length} Lingkup Tugas & Fungsi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                children: [
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Divider(height: 1),
                                        const SizedBox(height: 8),
                                        ...tusiList.map((tusi) {
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 4),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  margin:
                                                      const EdgeInsets.only(top: 2),
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[100],
                                                    borderRadius:
                                                        BorderRadius.circular(4),
                                                    border: Border.all(
                                                        color: Colors.grey[300]!),
                                                  ),
                                                  child: Text(
                                                    tusi.kode ?? '-',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    tusi.nama,
                                                    style: const TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xFF424242),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                        if (widget.onSelectTeam != null) ...[
                                          const SizedBox(height: 10),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: primaryColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 8,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              icon: const Icon(
                                                Icons.check_circle_outline,
                                                size: 16,
                                              ),
                                              label: const Text(
                                                'Pilih Tim Ini',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              onPressed: () {
                                                widget.onSelectTeam!(teamName);
                                                Navigator.pop(context, teamName);
                                              },
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
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
  }
}
