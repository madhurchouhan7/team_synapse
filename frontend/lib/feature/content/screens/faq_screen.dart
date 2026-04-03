import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/content/models/content_models.dart';
import 'package:watt_sense/feature/content/provider/content_provider.dart';

class FaqScreen extends ConsumerStatefulWidget {
  const FaqScreen({super.key});

  @override
  ConsumerState<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends ConsumerState<FaqScreen> {
  final TextEditingController _searchController = TextEditingController();

  static const List<_StaticFaq> _curatedFaqs = [
    _StaticFaq(
      topic: 'billing',
      question: 'Why is my electricity bill higher this month?',
      answer:
          'Seasonal appliance usage (especially cooling), higher slab rates, and longer peak-hour usage are common reasons for sudden bill jumps.',
    ),
    _StaticFaq(
      topic: 'billing',
      question: 'What does "units consumed" mean?',
      answer:
          'Units are measured in kWh (kilowatt-hour). One unit means using a 1000W appliance for one hour.',
    ),
    _StaticFaq(
      topic: 'savings',
      question: 'Which appliances usually consume the most power?',
      answer:
          'Air conditioners, water heaters, refrigerators, and old motors typically contribute the largest share of monthly consumption.',
    ),
    _StaticFaq(
      topic: 'savings',
      question: 'How can I reduce AC cost without losing comfort?',
      answer:
          'Set AC around 24-26C, use fan circulation, close leaks, and clean filters regularly to reduce compressor runtime.',
    ),
    _StaticFaq(
      topic: 'payments',
      question: 'What happens if I miss my due date?',
      answer:
          'Most providers add late fees and may apply additional penalties over time. Paying before due date avoids these charges.',
    ),
    _StaticFaq(
      topic: 'solar',
      question: 'Can rooftop solar fully replace my grid bill?',
      answer:
          'It depends on roof area, location, sanctioned load, and usage pattern. Many homes reduce bills significantly but still keep grid support.',
    ),
    _StaticFaq(
      topic: 'meter',
      question: 'Why does my meter keep running even at night?',
      answer:
          'Always-on loads like refrigerator, standby electronics, router, and security devices continue drawing energy overnight.',
    ),
    _StaticFaq(
      topic: 'support',
      question: 'How do I raise a bill correction request?',
      answer:
          'Use Contact Support with bill details, meter photo, and period information. You will get a ticket reference for tracking.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final faqAsync = ref.watch(faqContentProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'FAQs',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.read(faqContentProvider.notifier).refreshContent(),
          ),
        ],
      ),
      body: faqAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
        error: (error, stackTrace) {
          return _ErrorState(
            message: 'Unable to load FAQs right now.',
            onRetry: () => ref.read(faqContentProvider.notifier).retry(),
          );
        },
        data: (state) {
          final mergedTopics = <String>{
            ...state.topics,
            ..._curatedFaqs.map((item) => item.topic),
          }.toList(growable: false);

          final normalizedQuery = state.query.trim().toLowerCase();
          final normalizedTopic = state.selectedTopic.trim().toLowerCase();
          final filteredCurated = _curatedFaqs
              .where((item) {
                if (normalizedTopic.isEmpty || normalizedTopic == 'all') {
                  return true;
                }
                return item.topic.toLowerCase() == normalizedTopic;
              })
              .where((item) {
                if (normalizedQuery.isEmpty) {
                  return true;
                }
                return item.question.toLowerCase().contains(normalizedQuery) ||
                    item.answer.toLowerCase().contains(normalizedQuery);
              })
              .toList(growable: false);

          if (_searchController.text != state.query) {
            _searchController.value = TextEditingValue(
              text: state.query,
              selection: TextSelection.collapsed(offset: state.query.length),
            );
          }

          return RefreshIndicator(
            onRefresh: () =>
                ref.read(faqContentProvider.notifier).refreshContent(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                const _FaqHeroCard(),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchController,
                  onChanged: (value) =>
                      ref.read(faqContentProvider.notifier).setQuery(value),
                  decoration: InputDecoration(
                    hintText: 'Search FAQ',
                    prefixIcon: const Icon(Icons.search_rounded),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: mergedTopics.contains(state.selectedTopic)
                      ? state.selectedTopic
                      : 'all',
                  decoration: InputDecoration(
                    labelText: 'Topic',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  items: mergedTopics
                      .map(
                        (topic) => DropdownMenuItem<String>(
                          value: topic,
                          child: Text(_topicLabel(topic)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    ref.read(faqContentProvider.notifier).setTopic(value);
                  },
                ),
                if (state.feedback.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _FeedbackBanner(text: state.feedback),
                ],
                const SizedBox(height: 12),
                if (state.filteredItems.isNotEmpty) ...[
                  _SectionTitle(
                    title: 'From Support Center',
                    icon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 10),
                  ...state.filteredItems.map(
                    (item) => _FaqTile(
                      question: item.question,
                      answer: item.answer,
                      topic: item.topic,
                    ),
                  ),
                ],
                if (filteredCurated.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  _SectionTitle(
                    title: 'Popular Questions',
                    icon: Icons.local_fire_department_outlined,
                  ),
                  const SizedBox(height: 10),
                  ...filteredCurated.map(
                    (item) => _FaqTile(
                      question: item.question,
                      answer: item.answer,
                      topic: item.topic,
                      isCurated: true,
                    ),
                  ),
                ],
                if (state.filteredItems.isEmpty && filteredCurated.isEmpty)
                  _EmptyState(message: state.emptyGuidance),
              ],
            ),
          );
        },
      ),
    );
  }

  String _topicLabel(String raw) {
    if (raw == 'all') {
      return 'All Topics';
    }
    if (raw.isEmpty) {
      return raw;
    }
    return raw[0].toUpperCase() + raw.substring(1).toLowerCase();
  }
}

class _FaqHeroCard extends StatelessWidget {
  const _FaqHeroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x330EA5E9),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.forum_outlined, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Answers for billing, savings, meter readings, and support in one place.',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.question,
    required this.answer,
    required this.topic,
    this.isCurated = false,
  });

  final String question;
  final String answer;
  final String topic;
  final bool isCurated;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isCurated
                ? const Color(0xFFFFF7ED)
                : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isCurated ? Icons.lightbulb_outline : Icons.help_outline_rounded,
            size: 16,
            color: isCurated ? const Color(0xFFEA580C) : AppColors.primaryBlue,
          ),
        ),
        title: Text(
          question,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            height: 1.35,
          ),
        ),
        subtitle: Text(
          topic,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          Text(
            answer,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackBanner extends StatelessWidget {
  const _FeedbackBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryBlue,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        message,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.forum_outlined,
                color: Color(0xFFB42318),
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaticFaq {
  const _StaticFaq({
    required this.topic,
    required this.question,
    required this.answer,
  });

  final String topic;
  final String question;
  final String answer;

  FaqItem toFaqItem() {
    return FaqItem(
      id: question,
      topic: topic,
      question: question,
      answer: answer,
    );
  }
}
