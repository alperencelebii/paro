import 'package:flutter/foundation.dart';

/// Provider to manage initial animations across the app
class AnimationProvider extends ChangeNotifier {
  bool _hasPlayedInitialAnimations = false;

  /// Whether the initial animations have been played
  bool get hasPlayedInitialAnimations => _hasPlayedInitialAnimations;

  /// Mark initial animations as played
  void markInitialAnimationsAsPlayed() {
    _hasPlayedInitialAnimations = true;
    notifyListeners();
  }
}
