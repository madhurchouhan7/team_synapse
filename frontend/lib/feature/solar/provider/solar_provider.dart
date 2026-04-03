import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/solar/models/solar_models.dart';
import 'package:watt_sense/feature/solar/repository/solar_repository.dart';

final solarRepositoryProvider = Provider<ISolarRepository>((ref) {
  return SolarRepository();
});

final solarProvider =
    StateNotifierProvider.autoDispose<SolarController, SolarState>((ref) {
      return SolarController(repository: ref.read(solarRepositoryProvider));
    });

enum SolarStatus {
  idle,
  loading,
  validationError,
  success,
  retryableError,
  fatalError,
}

class SolarDraft {
  const SolarDraft({
    this.monthlyUnits = '',
    this.roofArea = '',
    this.state = '',
    this.discom = '',
    this.shadingLevel = 'medium',
    this.sanctionedLoadKw = '',
  });

  final String monthlyUnits;
  final String roofArea;
  final String state;
  final String discom;
  final String shadingLevel;
  final String sanctionedLoadKw;

  SolarDraft copyWith({
    String? monthlyUnits,
    String? roofArea,
    String? state,
    String? discom,
    String? shadingLevel,
    String? sanctionedLoadKw,
  }) {
    return SolarDraft(
      monthlyUnits: monthlyUnits ?? this.monthlyUnits,
      roofArea: roofArea ?? this.roofArea,
      state: state ?? this.state,
      discom: discom ?? this.discom,
      shadingLevel: shadingLevel ?? this.shadingLevel,
      sanctionedLoadKw: sanctionedLoadKw ?? this.sanctionedLoadKw,
    );
  }
}

class SolarState {
  const SolarState({
    required this.status,
    required this.draft,
    required this.fieldErrors,
    this.result,
    this.message,
  });

  final SolarStatus status;
  final SolarDraft draft;
  final Map<String, String> fieldErrors;
  final SolarEstimateResult? result;
  final String? message;

  factory SolarState.initial() {
    return const SolarState(
      status: SolarStatus.idle,
      draft: SolarDraft(),
      fieldErrors: <String, String>{},
      result: null,
      message: null,
    );
  }

  SolarState copyWith({
    SolarStatus? status,
    SolarDraft? draft,
    Map<String, String>? fieldErrors,
    SolarEstimateResult? result,
    String? message,
    bool preserveResult = true,
  }) {
    return SolarState(
      status: status ?? this.status,
      draft: draft ?? this.draft,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      result: preserveResult ? (result ?? this.result) : result,
      message: message ?? this.message,
    );
  }
}

class SolarController extends StateNotifier<SolarState> {
  SolarController({required ISolarRepository repository})
    : _repository = repository,
      super(SolarState.initial());

  final ISolarRepository _repository;

  void updateMonthlyUnits(String value) {
    _updateDraft(
      state.draft.copyWith(monthlyUnits: value),
      clearField: 'monthlyUnits',
    );
  }

  void updateRoofArea(String value) {
    _updateDraft(state.draft.copyWith(roofArea: value), clearField: 'roofArea');
  }

  void updateStateName(String value) {
    _updateDraft(state.draft.copyWith(state: value), clearField: 'state');
  }

  void updateDiscom(String value) {
    _updateDraft(state.draft.copyWith(discom: value), clearField: 'discom');
  }

  void updateShadingLevel(String value) {
    _updateDraft(state.draft.copyWith(shadingLevel: value));
  }

  void updateSanctionedLoad(String value) {
    _updateDraft(state.draft.copyWith(sanctionedLoadKw: value));
  }

  Future<bool> calculate() async {
    final errors = _validate(state.draft);
    if (errors.isNotEmpty) {
      state = state.copyWith(
        status: SolarStatus.validationError,
        fieldErrors: errors,
        message: 'Please complete required calculator inputs.',
      );
      return false;
    }

    return _performEstimate();
  }

  Future<bool> _performEstimate() async {
    state = state.copyWith(
      status: SolarStatus.loading,
      fieldErrors: const <String, String>{},
      message: 'Calculating estimate range...',
    );

    try {
      final estimate = await _repository.estimate(_buildRequest(state.draft));
      state = state.copyWith(
        status: SolarStatus.success,
        result: estimate,
        message: 'Solar estimate updated.',
      );
      return true;
    } on SolarEstimateException catch (error) {
      state = state.copyWith(
        status: error.isRetryable
            ? SolarStatus.retryableError
            : SolarStatus.fatalError,
        message: error.message,
      );
      return false;
    }
  }

  void _updateDraft(SolarDraft draft, {String? clearField}) {
    var fieldErrors = state.fieldErrors;
    if (clearField != null && fieldErrors.containsKey(clearField)) {
      fieldErrors = Map<String, String>.from(fieldErrors)..remove(clearField);
    }

    state = state.copyWith(
      status: SolarStatus.idle,
      draft: draft,
      fieldErrors: fieldErrors,
      message: null,
    );

    if (state.result != null && _validate(draft).isEmpty) {
      _performEstimate();
    }
  }

  Map<String, String> _validate(SolarDraft draft) {
    final errors = <String, String>{};

    final monthlyUnits = double.tryParse(draft.monthlyUnits.trim());
    if (monthlyUnits == null) {
      errors['monthlyUnits'] = 'Monthly units are required.';
    } else if (monthlyUnits < 1) {
      errors['monthlyUnits'] = 'Monthly units must be at least 1.';
    }

    final roofArea = double.tryParse(draft.roofArea.trim());
    if (roofArea == null) {
      errors['roofArea'] = 'Roof area is required.';
    } else if (roofArea < 20) {
      errors['roofArea'] = 'Roof area must be at least 20 sq ft.';
    }

    if (draft.state.trim().isEmpty) {
      errors['state'] = 'State is required.';
    }

    if (draft.discom.trim().isEmpty) {
      errors['discom'] = 'DISCOM is required.';
    }

    return errors;
  }

  SolarEstimateRequest _buildRequest(SolarDraft draft) {
    return SolarEstimateRequest(
      monthlyUnits: double.parse(draft.monthlyUnits.trim()),
      roofArea: double.parse(draft.roofArea.trim()),
      state: draft.state.trim(),
      discom: draft.discom.trim(),
      shadingLevel: draft.shadingLevel.trim(),
      sanctionedLoadKw: double.tryParse(draft.sanctionedLoadKw.trim()),
    );
  }
}
