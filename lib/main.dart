import 'package:carpool_app/auth_wrapper.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import the package

// --- STATE MANAGEMENT (Riverpod) ---
final isLoginViewProvider = StateProvider<bool>((ref) => true);
final authControllerProvider = Provider((ref) => AuthController(ref));
final isLoadingProvider = StateProvider<bool>((ref) => false);

// --- FIREBASE INITIALIZATION ---
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load the environment variables from the .env file
  await dotenv.load(fileName: ".env");

  await Firebase.initializeApp(
    // Use the variables from the .env file
    options: FirebaseOptions(
      apiKey: dotenv.env['FIREBASE_API_KEY']!,
      authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN']!,
      projectId: dotenv.env['FIREBASE_PROJECT_ID']!,
      storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET']!,
      messagingSenderId: dotenv.env['FIREBASE_MESSAGING_SENDER_ID']!,
      appId: dotenv.env['FIREBASE_APP_ID']!,
      measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID']!,
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

  Future<void> signUp(BuildContext context, String email, String password) async {
    _ref.read(isLoadingProvider.notifier).state = true;
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': email.trim(),
          'createdAt': Timestamp.now(),
          'name': null,
        });
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
}

// --- APP'S ROOT WIDGET ---
class CarpoolAuthApp extends StatelessWidget {
  const CarpoolAuthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carpool App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme).apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black,
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0D6EFD),
          secondary: Color(0xFF6C757D),
        ),
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
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            return const Row(
              children: [
                Expanded(child: AppIntroPanel()),
                Expanded(child: AuthFormPanel()),
              ],
            );
          } else {
            return const SingleChildScrollView(
              child: Column(
                children: [
                  AppIntroPanel(),
                  AuthFormPanel(),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}

// --- WIDGET FOR THE LEFT-SIDE INTRO PANEL ---
class AppIntroPanel extends StatelessWidget {
  const AppIntroPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8F9FA),
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'CARPOOL',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 16),
              Text(
                'The easiest way to organize carpools with your friends.',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Log your trips, track costs automatically, and make settling up simple and stress-free.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- WIDGET FOR THE RIGHT-SIDE FORM PANEL ---
class AuthFormPanel extends ConsumerWidget {
  const AuthFormPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoginView = ref.watch(isLoginViewProvider);

    return Container(
      padding: const EdgeInsets.all(32.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: isLoginView
                ? const LoginForm(key: ValueKey('login'))
                : const SignUpForm(key: ValueKey('signup')),
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
    FocusScope.of(context).unfocus();
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Welcome Back!', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black)),
          const SizedBox(height: 24),
          _AuthTextField(
            label: 'Email',
            hint: 'your@email.com',
            controller: _emailController,
            autofillHints: const [AutofillHints.email],
          ),
          const SizedBox(height: 16),
          _AuthTextField(
            label: 'Password',
            hint: '********',
            obscureText: true,
            controller: _passwordController,
            autofillHints: const [AutofillHints.password],
            onEditingComplete: _submit,
          ),
          const SizedBox(height: 24),
          _SubmitButton(
            text: 'LOGIN',
            isLoading: isLoading,
            onPressed: _submit,
          ),
          const SizedBox(height: 16),
          const _GoogleButton(),
          const SizedBox(height: 16),
          _AuthSwitchLink(
            text: 'New here? ',
            linkText: 'Sign up',
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Create Account', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black)),
        const SizedBox(height: 24),
        _AuthTextField(label: 'Email', hint: 'your@email.com', controller: _emailController),
        const SizedBox(height: 16),
        _AuthTextField(label: 'Password', hint: '********', obscureText: true, controller: _passwordController),
        const SizedBox(height: 24),
        _SubmitButton(
          text: 'SIGN UP',
          isLoading: isLoading,
          onPressed: _submit,
        ),
        const SizedBox(height: 16),
        const _GoogleButton(),
        const SizedBox(height: 16),
        _AuthSwitchLink(
          text: 'Have an account? ',
          linkText: 'Log in',
          onTap: () => ref.read(isLoginViewProvider.notifier).state = true,
        ),
      ],
    );
  }
}

// --- SHARED WIDGETS (used by both forms) ---

class _AuthTextField extends StatelessWidget {
  final String label;
  final String hint;
  final bool obscureText;
  final TextEditingController controller;
  final Iterable<String>? autofillHints;
  final VoidCallback? onEditingComplete;

  const _AuthTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.obscureText = false,
    this.autofillHints,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          autofillHints: autofillHints,
          onEditingComplete: onEditingComplete,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: const Color(0xFFF1F3F5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitButton extends StatelessWidget {
  final String text;
  final bool isLoading;
  final VoidCallback onPressed;

  const _SubmitButton({
    required this.text,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _GoogleButton extends StatelessWidget {
  const _GoogleButton();

  @override
  Widget build(BuildContext context) {
    final String googleLogoSvg = '''
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
      <path fill="#4285F4" d="M24 9.5c3.9 0 6.9 1.6 9 3.6l6.9-6.9C35.4 2.1 30.1 0 24 0 14.9 0 7.3 5.4 4.1 12.9l7.8 6C13.8 13.3 18.5 9.5 24 9.5z"/>
      <path fill="#34A853" d="M46.2 25.4c0-1.7-.2-3.4-.5-5H24v9.5h12.5c-.5 3.1-2.1 5.7-4.6 7.5l7.3 5.7c4.3-4 6.9-9.9 6.9-17.7z"/>
      <path fill="#FBBC05" d="M11.9 28.8c-.5-1.5-.8-3.1-.8-4.8s.3-3.3.8-4.8l-7.8-6C1.5 16.5 0 20.1 0 24s1.5 7.5 4.1 10.8l7.8-6z"/>
      <path fill="#EA4335" d="M24 48c6.1 0 11.4-2 15.1-5.4l-7.3-5.7c-2 1.4-4.6 2.2-7.8 2.2-5.5 0-10.2-3.8-11.9-9l-7.8 6C7.3 42.6 14.9 48 24 48z"/>
      <path fill="none" d="M0 0h48v48H0z"/>
    </svg>
    ''';

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () { /* TODO: Handle Google Sign-In */ },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
            side: const BorderSide(color: Color(0xFFDEE2E6)),
          ),
        ),
        icon: SvgPicture.string(googleLogoSvg, height: 24, width: 24),
        label: const Text('Continue with Google', style: TextStyle(fontWeight: FontWeight.bold)),
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
        style: Theme.of(context).textTheme.bodyMedium,
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
