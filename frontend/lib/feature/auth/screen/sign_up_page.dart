import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/auth/models/user_model.dart';
import 'package:watt_sense/feature/auth/providers/auth_provider.dart';
import 'package:watt_sense/feature/auth/widgets/cta_button.dart';
import 'package:watt_sense/feature/auth/widgets/sign_in_with_google.dart';
import 'package:watt_sense/utils/svg_assets.dart';

class SignUpPage extends ConsumerStatefulWidget {
  const SignUpPage({super.key});

  @override
  ConsumerState<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends ConsumerState<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ─── Navigation helper ─────────────────────────────────────────────────────

  void _navigateAfterAuth(UserModel user) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  // ─── Auth actions ───────────────────────────────────────────────────────────

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreedToTerms) {
      _showSnackBar(
        'Please agree to the Terms of Service and Privacy Policy.',
        isError: true,
      );
      return;
    }
    FocusScope.of(context).unfocus();
    await ref
        .read(authNotifierProvider.notifier)
        .signUpWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );
    // Navigation is handled by ref.listen in build().
  }

  Future<void> _handleGoogleSignIn() async {
    FocusScope.of(context).unfocus();
    await ref.read(authNotifierProvider.notifier).signInWithGoogle();
    // Navigation handled by ref.listen.
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

  InputDecoration _fieldDecoration({
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      prefixIcon: prefixIcon,
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

  @override
  Widget build(BuildContext context) {
    // ── Reactive navigation ──────────────────────────────────────────────────
    ref.listen<AsyncValue<UserModel?>>(authStateProvider, (_, next) {
      next.whenData((user) {
        if (user != null) _navigateAfterAuth(user);
      });
    });

    // ── Show errors via snackbar ─────────────────────────────────────────────
    ref.listen<AuthState>(authNotifierProvider, (_, curr) {
      if (curr.status == AuthStatus.error &&
          curr.errorMessage != null &&
          mounted) {
        _showSnackBar(curr.errorMessage!, isError: true);
      }
    });

    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.status == AuthStatus.loading;
    final screenWidth = MediaQuery.of(context).size.width;
    final fontSize = screenWidth * 0.05;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Create Account',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Google Sign-Up ────────────────────────────────
                SignInWithGoogle(
                  svgAssets: SvgAssets.google_svg,
                  onPressed: isLoading ? null : _handleGoogleSignIn,
                ),

                // ── OR Divider ────────────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(vertical: fontSize * 0.6),
                  child: Row(
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
                ),

                // ── Full Name ─────────────────────────────────────
                _SectionLabel(label: 'Full Name', fontSize: fontSize),
                SizedBox(height: fontSize * 0.4),
                TextFormField(
                  controller: _nameController,
                  style: GoogleFonts.nunito(color: Colors.black),
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                  decoration: _fieldDecoration(
                    hint: 'Enter your full name',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 15, right: 5),
                      child: Icon(Icons.person_outline, color: Colors.grey),
                    ),
                  ),
                ),

                SizedBox(height: fontSize * 1.2),

                // ── Email ─────────────────────────────────────────
                _SectionLabel(label: 'Email Address', fontSize: fontSize),
                SizedBox(height: fontSize * 0.4),
                TextFormField(
                  controller: _emailController,
                  style: GoogleFonts.nunito(color: Colors.black),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Email is required';
                    }
                    if (!val.contains('@') || !val.contains('.')) {
                      return 'Enter a valid email address';
                    }
                    return null;
                  },
                  decoration: _fieldDecoration(
                    hint: 'Enter your email address',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 15, right: 5),
                      child: Icon(Icons.email_outlined, color: Colors.grey),
                    ),
                  ),
                ),

                SizedBox(height: fontSize * 1.2),

                // ── Password ──────────────────────────────────────
                _SectionLabel(label: 'Password', fontSize: fontSize),
                SizedBox(height: fontSize * 0.4),
                TextFormField(
                  controller: _passwordController,
                  style: GoogleFonts.nunito(color: Colors.black),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Password is required';
                    }
                    if (val.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                  decoration: _fieldDecoration(
                    hint: 'Create a password',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 15, right: 5),
                      child: Icon(Icons.lock_outline, color: Colors.grey),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                ),

                SizedBox(height: fontSize * 1.2),

                // ── Confirm Password ──────────────────────────────
                _SectionLabel(label: 'Confirm Password', fontSize: fontSize),
                SizedBox(height: fontSize * 0.4),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: GoogleFonts.nunito(color: Colors.black),
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleSignUp(),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (val != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  decoration: _fieldDecoration(
                    hint: 'Confirm your password',
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 15, right: 5),
                      child: Icon(Icons.lock_outline, color: Colors.grey),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(
                        () =>
                            _obscureConfirmPassword = !_obscureConfirmPassword,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: fontSize * 1.2),

                // ── Terms & Conditions ────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: const Color(0xFF2563EB),
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                    ),
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'I agree to the ',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.75,
                              color: Colors.black,
                            ),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Text(
                              'Terms of Service',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize * 0.75,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Text(
                            ' and ',
                            style: GoogleFonts.poppins(
                              fontSize: fontSize * 0.75,
                              color: Colors.black,
                            ),
                          ),
                          InkWell(
                            onTap: () {},
                            child: Text(
                              'Privacy Policy',
                              style: GoogleFonts.poppins(
                                fontSize: fontSize * 0.75,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: fontSize * 1.2),

                // ── Create Account Button ─────────────────────────
                CtaButton(
                  text: 'Create Account',
                  isLoading: isLoading,
                  loadingText: 'Creating account...',
                  onPressed: _handleSignUp,
                ),

                SizedBox(height: fontSize),

                // ── Already have an account? ──────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: GoogleFonts.poppins(
                        fontSize: fontSize * 0.75,
                        color: Colors.grey[500],
                      ),
                    ),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.pop(context),
                      child: Text(
                        'Sign In',
                        style: GoogleFonts.poppins(
                          fontSize: fontSize * 0.75,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Helper widget ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.fontSize});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: fontSize * 0.75,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }
}
