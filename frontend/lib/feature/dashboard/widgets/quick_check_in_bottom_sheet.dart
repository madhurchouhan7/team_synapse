import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/feature/dashboard/providers/streak_provider.dart';

void showQuickCheckInBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const QuickCheckInBottomSheet(),
  );
}

class QuickCheckInBottomSheet extends ConsumerStatefulWidget {
  const QuickCheckInBottomSheet({super.key});

  @override
  ConsumerState<QuickCheckInBottomSheet> createState() =>
      _QuickCheckInBottomSheetState();
}

class _QuickCheckInBottomSheetState
    extends ConsumerState<QuickCheckInBottomSheet> {
  String selectedMood = 'Good';
  List<String> selectedTags = ['Guests'];
  bool _isSubmitting = false;

  final List<String> tags = [
    'Guests',
    'Too hot',
    'Travel',
    'AC Heavy',
    'Working from home',
  ];

  @override
  Widget build(BuildContext context) {
    final streakState = ref.watch(streakStateProvider);
    final streak = streakState.streak;
    final alreadyCheckedIn = streakState.checkedInToday;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Streak Banner
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: alreadyCheckedIn
                          ? const Color(0xFFECFDF5) // green tint
                          : const Color(0xFFFFF9EE), // orange tint
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: alreadyCheckedIn
                            ? const Color(0xFFBBF7D0)
                            : const Color(0xFFFFEDD5),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              alreadyCheckedIn ? "✅ " : "🔥 ",
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(
                              alreadyCheckedIn
                                  ? "Already checked in today!"
                                  : "$streak day streak!",
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: alreadyCheckedIn
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFEA580C),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          alreadyCheckedIn
                              ? "Come back tomorrow to keep your streak!"
                              : streak > 0
                              ? "Keep it up! You're doing great."
                              : "Start your efficiency streak today!",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: alreadyCheckedIn
                                ? const Color(0xFF22C55E)
                                : const Color(0xFFF97316),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    alreadyCheckedIn
                        ? "You're all set for today!"
                        : "How did you do today?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    alreadyCheckedIn
                        ? "Your check-in was logged. See you tomorrow!"
                        : "Log your energy adherence for brighter insights.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 32),

                  if (!alreadyCheckedIn) ...[
                    // Mood Selection
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildMoodCard('Good', '😊')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMoodCard('Okay', '😐')),
                        const SizedBox(width: 16),
                        Expanded(child: _buildMoodCard('Bad', '😓')),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Tags Label
                    Text(
                      "QUICK TAGS",
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tags Wrap
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: tags.map((tag) => _buildTag(tag)).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Note input
                    Container(
                      height: 120,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          TextField(
                            maxLines: null,
                            decoration: InputDecoration(
                              hintText: "Optional: Add a note...",
                              hintStyle: GoogleFonts.inter(
                                color: const Color(0xFF94A3B8),
                                fontSize: 14,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontSize: 14,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Icon(
                              Icons.edit,
                              size: 14,
                              color: const Color(0xFFCBD5E1),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E60F2),
                          disabledBackgroundColor: const Color(
                            0xFF1E60F2,
                          ).withValues(alpha: 0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                "Submit Check-in",
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Close / Skip Button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                    ),
                    child: Text(
                      alreadyCheckedIn ? "Close" : "Skip for now",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final checked = await ref.read(streakNotifierProvider.notifier).checkIn();

    if (!mounted) return;

    // Close the sheet first for a snappy feel
    Navigator.pop(context);

    if (checked) {
      // Show success toast on the parent screen
      final scaffoldCtx = context;
      if (scaffoldCtx.mounted) {
        ScaffoldMessenger.of(scaffoldCtx).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Text("🔥", style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                Text(
                  "Check-in recorded! Streak updated.",
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1E60F2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildMoodCard(String label, String emoji) {
    bool isSelected = selectedMood == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E60F2)
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 32)),
                const SizedBox(height: 12),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFF1E60F2)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            if (isSelected)
              Positioned(
                top: -16,
                right: -10,
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E60F2),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String label) {
    bool isSelected = selectedTags.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            selectedTags.remove(label);
          } else {
            selectedTags.add(label);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E60F2) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF1E60F2)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            color: isSelected ? Colors.white : const Color(0xFF475569),
          ),
        ),
      ),
    );
  }
}
