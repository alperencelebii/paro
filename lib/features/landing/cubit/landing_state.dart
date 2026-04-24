import 'package:equatable/equatable.dart';

/// State for the landing pages
class LandingState extends Equatable {
  /// Current page index
  final int currentPage;

  /// Whether an animation is in progress
  final bool isAnimating;

  /// Create a new landing state
  const LandingState({
    this.currentPage = 0,
    this.isAnimating = false,
  });

  /// Create a copy of this state with modified properties
  LandingState copyWith({
    int? currentPage,
    bool? isAnimating,
  }) {
    return LandingState(
      currentPage: currentPage ?? this.currentPage,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }

  @override
  List<Object?> get props => [currentPage, isAnimating];
}
