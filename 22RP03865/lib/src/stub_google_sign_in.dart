// Stub for GoogleSignIn on web
// This file is only used on web to satisfy conditional imports.

class GoogleSignIn {
  GoogleSignIn();
  Future<GoogleSignInAccount?> signIn() async => null;
}

class GoogleSignInAccount {
  Future<GoogleSignInAuthentication> get authentication async => GoogleSignInAuthentication();
}

class GoogleSignInAuthentication {
  String? get idToken => null;
  String? get accessToken => null;
} 