import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:watt_sense/core/colors.dart';
import 'package:watt_sense/feature/solar/models/solar_models.dart';
import 'package:watt_sense/feature/solar/provider/solar_provider.dart';

class SolarCalculatorScreen extends ConsumerStatefulWidget {
  const SolarCalculatorScreen({super.key});

  @override
  ConsumerState<SolarCalculatorScreen> createState() =>
      _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends ConsumerState<SolarCalculatorScreen> {
  final _monthlyUnitsController = TextEditingController();
  final _roofAreaController = TextEditingController();
  final _stateController = TextEditingController();
  final _discomController = TextEditingController();
  final _sanctionedLoadController = TextEditingController();

  @override
  void dispose() {
    _monthlyUnitsController.dispose();
    _roofAreaController.dispose();
    _stateController.dispose();
    _discomController.dispose();
    _sanctionedLoadController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(solarProvider);
    final notifier = ref.read(solarProvider.notifier);

    _syncControllers(state.draft);

    final result = state.result;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        title: Text(
          'Solar Calculator',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFF6F8FC),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _SolarHeroCard(),
            const SizedBox(height: 14),
            _InputSection(
              title: 'Consumption Inputs',
              icon: Icons.bolt_outlined,
              child: Column(
                children: [
                  TextField(
                    key: const Key('solarMonthlyUnitsField'),
                    controller: _monthlyUnitsController,
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updateMonthlyUnits,
                    decoration: _inputDecoration(
                      label: 'Monthly units (kWh)',
                      error: state.fieldErrors['monthlyUnits'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('solarRoofAreaField'),
                    controller: _roofAreaController,
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updateRoofArea,
                    decoration: _inputDecoration(
                      label: 'Roof area (sq ft)',
                      error: state.fieldErrors['roofArea'],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InputSection(
              title: 'Location and Grid',
              icon: Icons.map_outlined,
              child: Column(
                children: [
                  TextField(
                    key: const Key('solarStateField'),
                    controller: _stateController,
                    onChanged: notifier.updateStateName,
                    decoration: _inputDecoration(
                      label: 'State',
                      error: state.fieldErrors['state'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('solarDiscomField'),
                    controller: _discomController,
                    onChanged: notifier.updateDiscom,
                    decoration: _inputDecoration(
                      label: 'DISCOM',
                      error: state.fieldErrors['discom'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: const Key('solarShadingField'),
                    initialValue: state.draft.shadingLevel,
                    decoration: _inputDecoration(label: 'Shading level'),
                    items: const [
                      DropdownMenuItem(value: 'low', child: Text('Low')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'high', child: Text('High')),
                    ],
                    onChanged: (value) =>
                        notifier.updateShadingLevel(value ?? 'medium'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('solarSanctionedLoadField'),
                    controller: _sanctionedLoadController,
                    keyboardType: TextInputType.number,
                    onChanged: notifier.updateSanctionedLoad,
                    decoration: _inputDecoration(
                      label: 'Sanctioned load (kW) - optional',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              key: const Key('solarCalculateButton'),
              onPressed: state.status == SolarStatus.loading
                  ? null
                  : notifier.calculate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                state.status == SolarStatus.loading
                    ? 'Calculating...'
                    : 'Calculate Estimate',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
            if (state.status == SolarStatus.retryableError) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: notifier.calculate,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry calculation'),
              ),
            ],
            if ((state.message ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              _InlineMessage(
                text: state.message!,
                isSuccess: state.status == SolarStatus.success,
              ),
            ],
            if (result != null) ...[
              const SizedBox(height: 16),
              _RangeCard(
                title: 'Estimated monthly generation (kWh)',
                range: result.estimatedMonthlyGenerationKwh,
                icon: Icons.solar_power,
                color: const Color(0xFF0EA5E9),
              ),
              const SizedBox(height: 12),
              _RangeCard(
                title: 'Estimated monthly savings (INR)',
                range: result.estimatedMonthlySavingsInr,
                icon: Icons.currency_rupee,
                color: const Color(0xFF16A34A),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  title: const Text('Recommended system size'),
                  subtitle: Text(
                    '${result.recommendedSystemSizeKw.toStringAsFixed(2)} kW',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  title: const Text('Confidence Label'),
                  subtitle: Text(result.confidenceLabel),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assumptions',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text('State: ${result.assumptions['state'] ?? ''}'),
                      Text('DISCOM: ${result.assumptions['discom'] ?? ''}'),
                      Text(
                        'Tariff: ${result.assumptions['tariffRateInrPerKwh'] ?? ''} INR/kWh',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Limitations',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      ...result.limitations.map((item) => Text('- $item')),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                color: const Color(0xFFFEFCE8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0xFFFEF08A)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFA16207),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Disclaimer: ${result.disclaimer}',
                          key: const Key('solarDisclaimerText'),
                          style: GoogleFonts.poppins(
                            color: const Color(0xFF854D0E),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _syncControllers(SolarDraft draft) {
    if (_monthlyUnitsController.text != draft.monthlyUnits) {
      _monthlyUnitsController.text = draft.monthlyUnits;
    }
    if (_roofAreaController.text != draft.roofArea) {
      _roofAreaController.text = draft.roofArea;
    }
    if (_stateController.text != draft.state) {
      _stateController.text = draft.state;
    }
    if (_discomController.text != draft.discom) {
      _discomController.text = draft.discom;
    }
    if (_sanctionedLoadController.text != draft.sanctionedLoadKw) {
      _sanctionedLoadController.text = draft.sanctionedLoadKw;
    }
  }

  InputDecoration _inputDecoration({required String label, String? error}) {
    return InputDecoration(
      labelText: label,
      errorText: error,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
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
        borderSide: const BorderSide(color: AppColors.primaryBlue),
      ),
    );
  }
}

class _SolarHeroCard extends StatelessWidget {
  const _SolarHeroCard();

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
            child: const Icon(Icons.solar_power, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Get a practical low-base-high estimate with transparent assumptions.',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputSection extends StatelessWidget {
  const _InputSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.text, required this.isSuccess});

  final String text;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final bg = isSuccess ? const Color(0xFFECFDF3) : const Color(0xFFFFF1F2);
    final border = isSuccess
        ? const Color(0xFFABEFC6)
        : const Color(0xFFFECACA);
    final fg = isSuccess ? const Color(0xFF027A48) : const Color(0xFFB42318);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: fg,
        ),
      ),
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({
    required this.title,
    required this.range,
    required this.icon,
    required this.color,
  });

  final String title;
  final SolarRangeValue range;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ValueRow(label: 'Low', value: range.low),
            _ValueRow(label: 'Base', value: range.base),
            _ValueRow(label: 'High', value: range.high),
          ],
        ),
      ),
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value});

  final String label;
  final double value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: AppColors.textSecondary),
          ),
          Text(
            value.toStringAsFixed(2),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
