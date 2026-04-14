// Representasi kondisi autentikasi
enum AuthStatus {
  initial,          // Belum ada action
  loading,          // Proses berlangsung
  authenticated,    // Login berhasil + token backend ada
  unauthenticated,  // Belum login / logout
  emailNotVerified, // Login tapi email belum dikonfirmasi
  error,            // Ada error
}

class AuthProvider extends ChangeNotifier { 
  final FirebaseAuth _auth = FirebaseAuth.instance; 
  final GoogleSignIn _googleSignIn = GoogleSignIn(); 
 
  // ─── State ─────────────────────────────────────────────── 
  AuthStatus _status = AuthStatus.initial; 
  User?     _firebaseUser; 
  String?   _backendToken;   // Token dari backend (bukan Firebase token) 
  String?   _errorMessage; 
 
  AuthStatus get status       => _status; 
  User?      get firebaseUser  => _firebaseUser; 
  String?    get backendToken  => _backendToken; 
  String?    get errorMessage  => _errorMessage; 
  bool       get isLoading     => _status == AuthStatus.loading;  
  
} 
