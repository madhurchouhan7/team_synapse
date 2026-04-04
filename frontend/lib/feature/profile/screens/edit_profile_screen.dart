import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/profile/provider/profile_form_validators.dart';
import 'package:watt_sense/feature/profile/provider/profile_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _avatarController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _avatarController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _avatarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final operationState = ref.watch(profileOperationProvider);
    final uploadProgress = ref.watch(avatarUploadProgressProvider);
    final draft = ref.watch(profileDraftProvider);
    final notifier = ref.read(profileProvider.notifier);
    final isUploading = uploadProgress != null;

    if (_nameController.text != draft.name) {
      _nameController.text = draft.name;
    }
    if (_avatarController.text != draft.avatarUrl) {
      _avatarController.text = draft.avatarUrl;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: profileState.when(
          loading: () => _LoadingView(
            retry: notifier.retryFetch,
            showRetry: profileState.hasError,
          ),
          error: (_, __) => _ErrorView(retry: notifier.retryFetch),
          data: (_) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update your profile details',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (operationState.hasSaveError) ...[
                      _SaveErrorBanner(
                        message:
                            operationState.message ??
                            'We could not update your profile right now. Check your connection, review highlighted fields, and try again.',
                        retry: notifier.retrySave,
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (operationState.hasSaveSuccess) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Text(
                          operationState.message ??
                              'Profile updated successfully.',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: CircleAvatar(
                              radius: 34,
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundImage: draft.avatarUrl.isNotEmpty
                                  ? NetworkImage(draft.avatarUrl)
                                  : null,
                              onForegroundImageError: draft.avatarUrl.isNotEmpty
                                  ? (_, __) {}
                                  : null,
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF94A3B8),
                                size: 34,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: isUploading
                                  ? null
                                  : () async {
                                      final file = await _picker.pickImage(
                                        source: ImageSource.gallery,
                                        imageQuality: 85,
                                        maxWidth: 1200,
                                      );
                                      if (file == null) {
                                        return;
                                      }

                                      await notifier.uploadAvatarFile(
                                        file.path,
                                      );
                                      if (!mounted) return;

                                      final latestOperation = ref.read(
                                        profileOperationProvider,
                                      );
                                      if (!latestOperation.hasSaveError) {
                                        ScaffoldMessenger.of(context)
                                          ..hideCurrentSnackBar()
                                          ..showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Avatar uploaded. Tap Save Profile to apply changes.',
                                              ),
                                            ),
                                          );
                                      }
                                    },
                              icon: isUploading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    )
                                  : const Icon(Icons.photo_library_outlined),
                              label: Text(
                                isUploading
                                    ? 'Uploading ${(uploadProgress * 100).toStringAsFixed(0)}%'
                                    : 'Upload from Gallery',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Name',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            onChanged: notifier.setDraftName,
                            validator: (value) {
                              final fieldError =
                                  operationState.fieldErrors['name'];
                              return fieldError ??
                                  ProfileFormValidators.validateName(value);
                            },
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Enter your full name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Avatar URL',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _avatarController,
                            onChanged: notifier.setDraftAvatarUrl,
                            validator: (value) {
                              final fieldError =
                                  operationState.fieldErrors['avatarUrl'];
                              return fieldError ??
                                  ProfileFormValidators.validateAvatarUrl(
                                    value,
                                  );
                            },
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'https://example.com/avatar.png',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: operationState.isSaving || isUploading
                            ? null
                            : () async {
                                final isValid =
                                    _formKey.currentState?.validate() ?? false;
                                if (!isValid) {
                                  return;
                                }
                                notifier.clearOperationFeedback();
                                await notifier.saveProfile();
                                if (!mounted) return;
                                _formKey.currentState?.validate();
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: operationState.isSaving
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Save Profile',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  final Future<void> Function() retry;
  final bool showRetry;

  const _LoadingView({required this.retry, required this.showRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2563EB)),
            const SizedBox(height: 16),
            Text(
              'Loading your profile details...',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
              ),
            ),
            if (showRetry) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: retry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2563EB),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final Future<void> Function() retry;

  const _ErrorView({required this.retry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Text(
                  'Profile data not available',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pull to refresh or tap Retry to load your latest profile details.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: retry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveErrorBanner extends StatelessWidget {
  final String message;
  final Future<void> Function() retry;

  const _SaveErrorBanner({required this.message, required this.retry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w400,
              height: 1.5,
              color: const Color(0xFFB91C1C),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: retry,
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF2563EB),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(
              'Retry',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
