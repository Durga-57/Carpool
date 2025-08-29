import 'package:carpool_app/auth_wrapper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// --- STATE MANAGEMENT (Riverpod) ---
final isLoginViewProvider = StateProvider<bool>((ref) => true);

final authControllerProvider = Provider((ref) {
  return AuthController(ref);
});

final isLoadingProvider = StateProvider<bool>((ref) => false);

// --- FIREBASE INITIALIZATION ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // SECURE DEPLOYMENT: Read keys from the build environment.
  // These are passed in via the --dart-define flag.
  const firebaseApiKey = String.fromEnvironment('FIREBASE_API_KEY');
  const firebaseAuthDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  const firebaseProjectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  const firebaseStorageBucket =
      String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  const firebaseMessagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  const firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');

  if (firebaseApiKey.isEmpty) {
    print("Firebase environment variables are not set. App cannot start.");
    return;
  }

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: firebaseApiKey,
      authDomain: firebaseAuthDomain,
      projectId: firebaseProjectId,
      storageBucket: firebaseStorageBucket,
      messagingSenderId: firebaseMessagingSenderId,
      appId: firebaseAppId,
    ),
  );

  runApp(
    const ProviderScope(
      child: CarpoolAuthApp(),
    ),
  );
}

// --- AUTHENTICATION LOGIC CONTROLLER ---
class AuthController {
  final Ref _ref;
  AuthController(this._ref);

  Future<void> _createUserData(User user) async {
    final userDocRef =
        FirebaseFirestore.instance.collection('users').doc(user.uid);
    await userDocRef.set({
      'uid': user.uid,
      'email': user.email,
      'name': null, // Initially null until onboarding is complete
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> signUp(BuildContext context, String email, String password) async {
    _ref.read(isLoadingProvider.notifier).state = true;
    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      if (userCredential.user != null) {
        await _createUserData(userCredential.user!);
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An error occurred.')),
        );
      }
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> login(BuildContext context, String email, String password) async {
    _ref.read(isLoadingProvider.notifier).state = true;
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'An error occurred.')),
        );
      }
    } finally {
      _ref.read(isLoadingProvider.notifier).state = false;
    }
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }
}

// --- APP'S ROOT WIDGET ---
class CarpoolAuthApp extends StatelessWidget {
  const CarpoolAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpool App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7F8FC),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthWrapper(),
    );
  }
}

// --- MAIN AUTHENTICATION SCREEN ---
class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Consumer(builder: (context, ref, child) {
              final isLogin = ref.watch(isLoginViewProvider);
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: isLogin
                    ? const LoginForm(key: ValueKey('login'))
                    : const SignUpForm(key: ValueKey('signup')),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// --- WIDGET FOR THE LOGIN FORM ---
class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authControllerProvider).login(
          context,
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);

    return AutofillGroup(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Welcome Back!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Log in to continue your carpool journey.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          _AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'your@email.com',
            icon: Icons.alternate_email,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '********',
            icon: Icons.lock_outline,
            obscureText: true,
            autofillHints: const [AutofillHints.password],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('LOGIN'),
          ),
          const SizedBox(height: 24),
          _AuthSwitchLink(
            text: 'Don\'t have an account? ',
            linkText: 'Sign Up',
            onTap: () => ref.read(isLoginViewProvider.notifier).state = false,
          ),
        ],
      ),
    );
  }
}
// --- WIDGET FOR THE SIGN-UP FORM ---
class SignUpForm extends ConsumerStatefulWidget {
  const SignUpForm({super.key});

  @override
  ConsumerState<SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends ConsumerState<SignUpForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    ref.read(authControllerProvider).signUp(
          context,
          _emailController.text,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLoadingProvider);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text('Create Account',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('Start organizing your carpools today.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center),
        const SizedBox(height: 40),
        _AuthTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'your@email.com',
            icon: Icons.alternate_email),
        const SizedBox(height: 16),
        _AuthTextField(
            controller: _passwordController,
            label: 'Password',
            hint: '********',
            icon: Icons.lock_outline,
            obscureText: true),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('SIGN UP'),
        ),
        const SizedBox(height: 24),
        _AuthSwitchLink(
          text: 'Already have an account? ',
          linkText: 'Log In',
          onTap: () => ref.read(isLoginViewProvider.notifier).state = true,
        ),
      ],
    );
  }
}

// --- SHARED WIDGETS ---

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Iterable<String>? autofillHints;

  const _AuthTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.autofillHints,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      autofillHints: autofillHints,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
    );
  }
}

class _AuthSwitchLink extends StatelessWidget {
  final String text;
  final String linkText;
  final VoidCallback onTap;

  const _AuthSwitchLink({
    required this.text,
    required this.linkText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: const TextStyle(color: Colors.black, fontFamily: 'Poppins'),
        children: [
          TextSpan(text: text),
          TextSpan(
            text: linkText,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
            recognizer: TapGestureRecognizer()..onTap = onTap,
          ),
        ],
      ),
    );
  }
}

