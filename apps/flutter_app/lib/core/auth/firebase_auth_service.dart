import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/app_constants.dart';

class FirebaseIdentity {
  FirebaseIdentity({
    required this.email,
    required this.displayName,
    required this.providerUserId,
    this.idToken,
  });

  final String email;
  final String displayName;
  final String providerUserId;
  final String? idToken;
}

class FirebaseAuthService {
  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ??
            GoogleSignIn(
              clientId: AppConstants.firebaseGoogleWebClientId.isEmpty
                  ? null
                  : AppConstants.firebaseGoogleWebClientId,
            );

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  bool get isEnabled => AppConstants.firebaseAuthEnabled;

  Future<FirebaseIdentity> signInWithGoogle() async {
    _assertEnabled();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign in was cancelled.');
    }

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await _firebaseAuth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user?.email == null) {
      throw Exception('Firebase did not return an email address.');
    }

    return FirebaseIdentity(
      email: user!.email!,
      displayName: user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : user.email!.split('@').first,
      providerUserId: user.uid,
      idToken: googleAuth.idToken,
    );
  }

  Future<void> signOutIfNeeded() async {
    if (!isEnabled) {
      return;
    }

    await Future.wait<void>([
      _firebaseAuth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  void _assertEnabled() {
    if (!isEnabled) {
      throw Exception(
        'Firebase auth is not enabled for this build.',
      );
    }
  }
}
