import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/models/user_model.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/auth/screen/sign_up_page.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/auth/widgets/sign_in_with_google.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class SignInPage extends ConsumerStatefulWidget {
  const SignInPage({super.key});

  @override
  ConsumerState<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends ConsumerState<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ─── Navigation helper ─────────────────────────────────────────────────────

  void _navigateAfterAuth(UserModel user) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ─── Auth actions ───────────────────────────────────────────────────────────

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref
        .read(authNotifierProvider.notifier)
        .signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
    // Navigation is handled by ref.listen below — no manual push here.
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    // Navigation handled by ref.listen.
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar('Enter your email above first.', isError: false);
      return;
    }
    await ref
        .read(authNotifierProvider.notifier)
        .sendPasswordReset(email: email);
    if (mounted) {
      _showSnackBar(
        'Password reset email sent! Check your inbox.',
        isError: false,
      );
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.white),
        ),
        backgroundColor: isError
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ── Reactive navigation: fires whenever authStateProvider changes ──────────
    // This is the KEY fix — it runs even while SignInPage is on the nav stack.
    ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user != null) _navigateAfterAuth(user);
      });
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;

    // Show errors via snackbar (only when status just became error)
    ref.listen<AuthState>(authNotifierProvider, (prev, curr) {
      if (curr.status == AuthStatus.error &&
          curr.errorMessage != null &&
          mounted) {
        _showSnackBar(curr.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final fontSize = screenWidth * 0.05;

          return SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(fontSize * 0.75),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Header ────────────────────────────────────────────
                    Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome Back!',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize * 1.45,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: fontSize * 0.4),
                            Text(
                              'Sign in to continue',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize * 0.8,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ── Hero image ────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: fontSize * 1.2),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/svg/sign_in_overlay.png',
                          width: screenWidth * 0.5,
                          height: screenWidth * 0.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),

                    // ── Email ─────────────────────────────────────────────
                    TextFormField(
                      controller: _emailController,
                      style: GoogleFonts.nunito(color: Colors.black),
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      enabled: !isLoading,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!val.contains('@') || !val.contains('.')) {
                          return 'Enter a valid email address';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Enter email address',
                        prefixIcon: Icons.email_outlined,
                      ),
                    ),

                    SizedBox(height: fontSize * 0.7),

                    // ── Password ──────────────────────────────────────────
                    TextFormField(
                      controller: _passwordController,
                      style: GoogleFonts.nunito(color: Colors.black),
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      enabled: !isLoading,
                      onFieldSubmitted: (_) => _handleSignIn(),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Password is required';
                        }
                        if (val.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                      decoration: _inputDecoration(
                        hint: 'Password',
                        prefixIcon: Icons.lock_outline,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.grey,
                          ),
                          onPressed: isLoading
                              ? null
                              : () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                        ),
                      ),
                    ),

                    // ── Forgot password ────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: isLoading ? null : _handleForgotPassword,
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.75,
                              fontWeight: FontWeight.w600,
                              color: isLoading
                                  ? Colors.grey[400]
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // ── OR divider ─────────────────────────────────────────
                    Row(
                      children: [
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: fontSize * 0.5,
                          ),
                          child: Text(
                            'OR',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.8,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(color: Colors.grey[300], thickness: 1),
                        ),
                      ],
                    ),

                    SizedBox(height: fontSize * 0.8),

                    // ── Google sign-in ─────────────────────────────────────
                    SignInWithGoogle(
                      svgAssets: SvgAssets.google_svg,
                      onPressed: isLoading ? null : _handleGoogleSignIn,
                    ),

                    SizedBox(height: fontSize * 1.5),

                    // ── CTA: Sign In (stays in place, just turns muted) ────
                    CtaButton(
                      text: 'Sign In',
                      isLoading: isLoading,
                      loadingText: 'Signing in...',
                      onPressed: _handleSignIn,
                    ),

                    SizedBox(height: fontSize),

                    // ── Sign Up link ───────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don't have an account?",
                          style: GoogleFonts.poppins(
                            fontSize: fontSize * 0.75,
                            color: Colors.grey[600],
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SignUpPage(),
                                  ),
                                ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.75,
                              fontWeight: FontWeight.w600,
                              color: isLoading
                                  ? Colors.grey[400]
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 15, right: 5),
        child: Icon(prefixIcon, color: Colors.grey),
      ),
      suffixIcon: suffixIcon,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[400]!),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
        borderRadius: BorderRadius.circular(12),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
