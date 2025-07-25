import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserProvider extends ChangeNotifier {
  UserModel? _user;

  UserModel? get user => _user;

  void setUser(UserModel user) {
    _user = user;
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    notifyListeners();
  }

  List<String> get flaggedQuestions => _user?.flaggedQuestions ?? [];

  void updateFlaggedQuestions(List<String> flagged) {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        userType: _user!.userType,
        flaggedQuestions: flagged,
        hasShared: _user!.hasShared,
        displayName: _user!.displayName,
        avatarUrl: _user!.avatarUrl,
        sharedPlatforms: _user!.sharedPlatforms,
      );
      notifyListeners();
    }
  }

  Map<String, bool> get sharedPlatforms => _user?.sharedPlatforms ?? {};

  void updateSharedPlatforms(Map<String, bool> platforms) {
    if (_user != null) {
      _user = UserModel(
        uid: _user!.uid,
        email: _user!.email,
        userType: _user!.userType,
        flaggedQuestions: _user!.flaggedQuestions,
        hasShared: _user!.hasShared,
        displayName: _user!.displayName,
        avatarUrl: _user!.avatarUrl,
        sharedPlatforms: platforms,
      );
      notifyListeners();
    }
  }
} 