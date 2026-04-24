import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../bloc/faq_bloc.dart';

/// FAQ screen with categorized questions and answers about app features
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FaqBloc()..add(const InitializeFaqData()),
      child: const FaqView(),
    );
  }
}

class FaqView extends StatefulWidget {
  const FaqView({super.key});

  @override
  State<FaqView> createState() => _FaqViewState();
}

class _FaqViewState extends State<FaqView> with SingleTickerProviderStateMixin {
  // For search functionality
  final TextEditingController _searchController = TextEditingController();

  // Animation controller for smooth transitions
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Scroll controller for handling scroll events
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double expandedHeight = 180.h;

    return BlocListener<FaqBloc, FaqState>(
      listenWhen: (previous, current) =>
          current.error != null && previous.error != current.error,
      listener: (context, state) {
        if (state.error != null) {
          // Using a SelectableText.rich for error display rather than a SnackBar
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: SelectableText.rich(
                TextSpan(
                  text: state.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: BlocBuilder<FaqBloc, FaqState>(
            builder: (context, state) {
              if (state.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return NestedScrollView(
                controller: _scrollController,
                headerSliverBuilder: (context, innerBoxIsScrolled) => [
                  SliverAppBar(
                    expandedHeight: expandedHeight,
                    floating: false,
                    pinned: true,
                    backgroundColor: const Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    flexibleSpace: FlexibleSpaceBar(
                      title: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
                        child: const Text(
                          'Frequently Asked Questions',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6C63FF), Color(0xFF5A52CC)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF6C63FF)
                                  .withValues(alpha: 0.3),
                              offset: const Offset(0, 4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20.w),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'How can we help you?',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                Text(
                                  'Find answers to common questions about using the app.',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    delegate: _SliverSearchBarDelegate(
                      minHeight: 80.h,
                      maxHeight: 80.h,
                      child: _buildSearchBar(theme),
                    ),
                    pinned: true,
                  ),
                ],
                body: state.isSearching
                    ? _buildSearchResults(theme, state)
                    : _buildFaqList(theme, state),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return BlocBuilder<FaqBloc, FaqState>(
      buildWhen: (previous, current) =>
          previous.searchQuery != current.searchQuery,
      builder: (context, state) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                offset: const Offset(0, 3),
                blurRadius: 6,
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search FAQs...',
              filled: true,
              fillColor: Colors.grey[50],
              prefixIcon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF6C63FF)),
                      onPressed: () {
                        _searchController.clear();
                        context.read<FaqBloc>().add(const ClearSearch());
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide:
                    const BorderSide(color: Color(0xFF6C63FF), width: 1.5),
              ),
              contentPadding:
                  EdgeInsets.symmetric(vertical: 14.h, horizontal: 16.w),
              hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
            ),
            style: TextStyle(fontSize: 14.sp),
            onChanged: (value) {
              context.read<FaqBloc>().add(SearchFaqs(query: value));
            },
          ),
        );
      },
    );
  }

  Widget _buildSearchResults(ThemeData theme, FaqState state) {
    if (state.searchResults.isEmpty) {
      return Center(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 32.h),
              Icon(
                Icons.search_off,
                size: 64.r,
                color: Colors.grey[300],
              ),
              SizedBox(height: 24.h),
              Text(
                'No results found for "${state.searchQuery}"',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              SizedBox(height: 12.h),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 32.w),
                child: Text(
                  'Try using different keywords or check for spelling errors',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32.h),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                  context.read<FaqBloc>().add(const ClearSearch());
                },
                icon: const Icon(Icons.refresh, color: Color(0xFF6C63FF)),
                label: Text(
                  'Clear Search',
                  style: TextStyle(
                    color: const Color(0xFF6C63FF),
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding:
                      EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _SearchResultsListView(
      theme: theme,
      results: state.searchResults,
    );
  }

  Widget _buildFaqList(ThemeData theme, FaqState state) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 16.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final category = state.faqCategories[index];
                final isExpanded =
                    state.expandedCategories[category.title] ?? false;

                return _FaqCategoryItem(
                  category: category,
                  isExpanded: isExpanded,
                  theme: theme,
                  onToggle: () {
                    context.read<FaqBloc>().add(
                        ToggleCategoryExpansion(categoryTitle: category.title));
                  },
                );
              },
              childCount: state.faqCategories.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SearchResultsListView extends StatelessWidget {
  final ThemeData theme;
  final List<FaqSearchResult> results;

  const _SearchResultsListView({
    required this.theme,
    required this.results,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final result = results[index];
                return _buildSearchResultItem(result, theme, index);
              },
              childCount: results.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResultItem(
      FaqSearchResult result, ThemeData theme, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          colorScheme: theme.colorScheme.copyWith(
            surface: Colors.white,
          ),
        ),
        child: ExpansionTile(
          maintainState: true,
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          leading: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              result.categoryIcon,
              color: const Color(0xFF6C63FF),
              size: 20.r,
            ),
          ),
          subtitle: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                margin: EdgeInsets.only(top: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF6C63FF).withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(4.r),
                ),
                child: Text(
                  result.category,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          childrenPadding: const EdgeInsets.all(0),
          title: Text(
            result.question,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          iconColor: const Color(0xFF6C63FF),
          collapsedIconColor: const Color(0xFF6C63FF),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
              decoration: BoxDecoration(
                color: Colors.grey[50],
              ),
              child: SelectableText(
                result.answer,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqCategoryItem extends StatelessWidget {
  final FaqCategory category;
  final bool isExpanded;
  final ThemeData theme;
  final VoidCallback onToggle;

  const _FaqCategoryItem({
    required this.category,
    required this.isExpanded,
    required this.theme,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // Check if this is an expense-related category

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: theme.copyWith(
          dividerColor: Colors.transparent,
          colorScheme: theme.colorScheme.copyWith(
            surface: Colors.white,
          ),
        ),
        child: ExpansionTile(
          initiallyExpanded: isExpanded,
          maintainState: true,
          onExpansionChanged: (expanded) => onToggle(),
          backgroundColor: Colors.white,
          collapsedBackgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          leading: Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              category.icon,
              color: const Color(0xFF6C63FF),
              size: 22.r,
            ),
          ),
          title: Text(
            category.title,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          iconColor: const Color(0xFF6C63FF),
          collapsedIconColor: const Color(0xFF6C63FF),
          tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          childrenPadding: EdgeInsets.only(bottom: 8.h, left: 8.w, right: 8.w),
          children: [
            if (isExpanded) _buildFaqItems(),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqItems() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 8.h),
      itemCount: category.questions.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.grey[200],
        height: 1,
        thickness: 1,
      ),
      itemBuilder: (context, index) {
        return _buildQuestionItem(category.questions[index]);
      },
    );
  }

  Widget _buildQuestionItem(FaqItem faqItem) {
    return Theme(
      data: theme.copyWith(
        dividerColor: Colors.transparent,
        colorScheme: theme.colorScheme.copyWith(
          surface: Colors.white,
        ),
      ),
      child: ExpansionTile(
        maintainState: true,
        tilePadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        childrenPadding: const EdgeInsets.all(0),
        title: Text(
          faqItem.question,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        iconColor: const Color(0xFF6C63FF),
        collapsedIconColor: const Color(0xFF6C63FF),
        backgroundColor: Colors.white,
        collapsedBackgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        collapsedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: Colors.grey[50],
            ),
            child: SelectableText(
              faqItem.answer,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SliverPersistentHeaderDelegate for the search bar
class _SliverSearchBarDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverSearchBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverSearchBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
