import 'package:equatable/equatable.dart';

class AboutState extends Equatable {
  final bool isLoading;
  final String? errorMessage;
  final List<FeatureInfo> appFeatures;
  final List<FeatureInfo> filteredFeatures;
  final String searchQuery;

  const AboutState({
    this.isLoading = false,
    this.errorMessage,
    this.appFeatures = const [],
    this.filteredFeatures = const [],
    this.searchQuery = '',
  });

  @override
  List<Object?> get props => [
        isLoading,
        errorMessage,
        appFeatures,
        filteredFeatures,
        searchQuery,
      ];

  AboutState copyWith({
    bool? isLoading,
    String? Function()? errorMessage,
    List<FeatureInfo>? appFeatures,
    List<FeatureInfo>? filteredFeatures,
    String? searchQuery,
  }) {
    return AboutState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      appFeatures: appFeatures ?? this.appFeatures,
      filteredFeatures: filteredFeatures ?? this.filteredFeatures,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class FeatureInfo {
  final String title;
  final String description;
  final String icon;
  final String route;
  final List<String> tags;
  final bool isPreview;

  const FeatureInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.route,
    this.tags = const [],
    this.isPreview = false,
  });
}
