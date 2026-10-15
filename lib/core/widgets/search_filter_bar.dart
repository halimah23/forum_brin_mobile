import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_radius.dart';

class SearchFilterBar extends StatefulWidget {
  final String hintText;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilter;
  final TextEditingController? controller;

  const SearchFilterBar({
    super.key,
    this.hintText = 'Cari no tiket, judul, atau kata kunci...',
    required this.onSearchChanged,
    this.onFilterTap,
    this.hasActiveFilter = false,
    this.controller,
  });

  @override
  State<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends State<SearchFilterBar> {
  late final TextEditingController _controller;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onTextChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      widget.onSearchChanged(value.trim());
    });
    setState(() {});
  }

  void _clearSearch() {
    _controller.clear();
    _debounceTimer?.cancel();
    widget.onSearchChanged('');
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.slate400, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onTextChanged,
              style: const TextStyle(fontSize: 13, color: AppColors.slate900),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle:
                    const TextStyle(fontSize: 13, color: AppColors.slate400),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (_controller.text.isNotEmpty)
            GestureDetector(
              onTap: _clearSearch,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.cancel, color: AppColors.slate400, size: 18),
              ),
            ),
          if (widget.onFilterTap != null) ...[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1,
              height: 20,
              color: AppColors.border,
            ),
            InkWell(
              onTap: widget.onFilterTap,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Stack(
                  children: [
                    Icon(
                      Icons.tune_rounded,
                      color: widget.hasActiveFilter
                          ? AppColors.primaryRed
                          : AppColors.slate600,
                      size: 20,
                    ),
                    if (widget.hasActiveFilter)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
