import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:finance_track/core/localization/localization.dart';

/// Search bar widget for filtering transactions
class SearchBarWidget extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final VoidCallback onClear;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onClear,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _clearAndUnfocus() {
    widget.controller.clear();
    widget.onClear();
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: AppLocalizations.tr('Search transactions'),
          hintStyle: TextStyle(
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.7),
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Theme.of(context).colorScheme.primary,
          ),
          filled: true,
          fillColor: Colors.white,
          suffixIcon: _isFocused || widget.controller.text.isNotEmpty
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.controller.text.isNotEmpty)
                      IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20.r,
                        ),
                        onPressed: () {
                          widget.controller.clear();
                          widget.onSearch('');
                        },
                        splashRadius: 20.r,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 32.w,
                          minHeight: 32.h,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.only(right: 8.w),
                      child: TextButton(
                        onPressed: _clearAndUnfocus,
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          minimumSize: Size(40.w, 32.h),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: LocalizedText('Cancel',
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 8.w),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color:
                  Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.r),
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
        onChanged: widget.onSearch,
        textInputAction: TextInputAction.search,
        onSubmitted: widget.onSearch,
        cursorColor: Theme.of(context).colorScheme.primary,
        style: TextStyle(
          fontSize: 16.sp,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
