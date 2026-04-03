import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:watt_sense/feature/on_boarding/repository/appliance_repository.dart';
import 'package:watt_sense/feature/on_boarding/model/appliance_model.dart';
import 'package:watt_sense/feature/on_boarding/provider/selected_appliance_notifier.dart';
import 'package:watt_sense/feature/on_boarding/provider/on_boarding_page_5_notifier.dart';
import 'package:watt_sense/feature/on_boarding/model/on_boarding_state.dart';

final manageApplianceBaselineProvider =
    StateProvider.autoDispose<Map<String, Map<String, dynamic>>>((ref) {
      return <String, Map<String, dynamic>>{};
    });

final manageAppliancesInitProvider = FutureProvider.autoDispose<bool>((
  ref,
) async {
  final repository = ref.read(applianceRepositoryProvider);
  final appliancesData = await repository.getAppliances();

  final selectedNotifier = ref.read(selectedAppliancesProvider.notifier);
  final page5Notifier = ref.read(onBoardingPage5Provider.notifier);

  // Clear previous state just in case
  selectedNotifier.clearAll();

  final baseline = <String, Map<String, dynamic>>{};
  for (final appliance in appliancesData) {
    final applianceId = appliance['applianceId']?.toString();
    if (applianceId != null && applianceId.isNotEmpty) {
      baseline[applianceId] = Map<String, dynamic>.from(appliance);
    }
  }
  ref.read(manageApplianceBaselineProvider.notifier).state = baseline;

  if (appliancesData.isEmpty) {
    return true; // No data, start fresh
  }

  List<ApplianceModel> prefilledAppliances = [];
  Map<String, ApplianceLocalState> prefilledStates = {};

  for (var data in appliancesData) {
    final applianceId = data['applianceId'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final category = data['category'] as String? ?? '';
    final svgPath = data['svgPath'] as String? ?? '';
    final usageHours = (data['usageHours'] as num?)?.toDouble() ?? 2.0;

    final model = ApplianceModel(
      id: applianceId,
      title: title,
      category: category,
      usageHours: usageHours,
      svgPath: svgPath,
      description: '',
    );

    prefilledAppliances.add(model);

    // Parse dropdowns carefully
    final dropdownMap =
        data['selectedDropdowns'] as Map<String, dynamic>? ?? {};
    final Map<String, String> mappedDropdowns = {};
    dropdownMap.forEach((k, v) {
      mappedDropdowns[k] = v.toString();
    });

    prefilledStates[applianceId] = ApplianceLocalState(
      usageLevel: data['usageLevel'] as String? ?? 'Medium',
      count: data['count'] as int? ?? 1,
      selectedDropdowns: mappedDropdowns,
    );
  }

  // Pre-load logic into the global providers
  selectedNotifier.setAppliances(prefilledAppliances);
  page5Notifier.preloadState(prefilledStates);

  return true;
});

final manageApplianceMutationProvider =
    StateNotifierProvider.autoDispose<
      ManageApplianceMutationController,
      ManageApplianceMutationState
    >((ref) {
      final repository = ref.read(applianceRepositoryProvider);
      return ManageApplianceMutationController(repository: repository);
    });

enum ManageApplianceMutationStatus {
  idle,
  saving,
  success,
  validationError,
  conflict,
  retryableError,
}

class ManageApplianceMutationState {
  final ManageApplianceMutationStatus status;
  final String retryHint;
  final String recoveryActionLabel;
  final String? requestId;
  final String? timestamp;
  final String? errorCode;
  final Map<String, dynamic>? preservedDraft;

  const ManageApplianceMutationState({
    required this.status,
    required this.retryHint,
    required this.recoveryActionLabel,
    this.requestId,
    this.timestamp,
    this.errorCode,
    this.preservedDraft,
  });

  factory ManageApplianceMutationState.idle() {
    return const ManageApplianceMutationState(
      status: ManageApplianceMutationStatus.idle,
      retryHint: '',
      recoveryActionLabel: '',
    );
  }

  ManageApplianceMutationState copyWith({
    ManageApplianceMutationStatus? status,
    String? retryHint,
    String? recoveryActionLabel,
    String? requestId,
    String? timestamp,
    String? errorCode,
    Map<String, dynamic>? preservedDraft,
    bool clearPreservedDraft = false,
  }) {
    return ManageApplianceMutationState(
      status: status ?? this.status,
      retryHint: retryHint ?? this.retryHint,
      recoveryActionLabel: recoveryActionLabel ?? this.recoveryActionLabel,
      requestId: requestId ?? this.requestId,
      timestamp: timestamp ?? this.timestamp,
      errorCode: errorCode ?? this.errorCode,
      preservedDraft: clearPreservedDraft
          ? null
          : (preservedDraft ?? this.preservedDraft),
    );
  }
}

class ManageApplianceMutationController
    extends StateNotifier<ManageApplianceMutationState> {
  final ApplianceRepository _repository;

  ManageApplianceMutationController({required ApplianceRepository repository})
    : _repository = repository,
      super(ManageApplianceMutationState.idle());

  Future<bool> Function()? _lastAction;

  void reset() {
    state = ManageApplianceMutationState.idle();
    _lastAction = null;
  }

  Future<bool> retry() async {
    if (_lastAction == null) {
      return false;
    }
    return _lastAction!.call();
  }

  Future<bool> saveApplianceDraft({
    required Map<String, dynamic> draft,
    String? applianceId,
    String? expectedVersion,
  }) async {
    Future<bool> run() async {
      state = state.copyWith(
        status: ManageApplianceMutationStatus.saving,
        retryHint: 'Saving appliance changes...',
        recoveryActionLabel: '',
      );

      try {
        if (applianceId == null || applianceId.isEmpty) {
          await _repository.createAppliance(payload: draft);
        } else {
          await _repository.updateAppliance(
            applianceId: applianceId,
            payload: draft,
            expectedVersion: expectedVersion,
          );
        }

        state = state.copyWith(
          status: ManageApplianceMutationStatus.success,
          retryHint: 'Appliance changes saved successfully.',
          recoveryActionLabel: '',
          clearPreservedDraft: true,
          requestId: null,
          timestamp: null,
          errorCode: null,
        );
        return true;
      } catch (error) {
        _applyMutationFailure(error, draft: draft);
        return false;
      }
    }

    _lastAction = run;
    return run();
  }

  Future<bool> deleteApplianceWithRecovery({
    required String applianceId,
    required Map<String, dynamic> draft,
    String? expectedVersion,
  }) async {
    Future<bool> run() async {
      state = state.copyWith(
        status: ManageApplianceMutationStatus.saving,
        retryHint: 'Deleting appliance...',
        recoveryActionLabel: '',
      );

      try {
        await _repository.deleteAppliance(
          applianceId: applianceId,
          expectedVersion: expectedVersion,
        );

        state = state.copyWith(
          status: ManageApplianceMutationStatus.success,
          retryHint: 'Appliance removed successfully.',
          recoveryActionLabel: '',
          clearPreservedDraft: true,
          requestId: null,
          timestamp: null,
          errorCode: null,
        );
        return true;
      } catch (error) {
        _applyMutationFailure(error, draft: draft);
        return false;
      }
    }

    _lastAction = run;
    return run();
  }

  void _applyMutationFailure(
    Object error, {
    required Map<String, dynamic> draft,
  }) {
    if (error is ApplianceMutationException) {
      if (error.type == ApplianceMutationErrorType.validation) {
        state = state.copyWith(
          status: ManageApplianceMutationStatus.validationError,
          retryHint:
              'Some appliance fields are invalid. Update the values and retry.',
          recoveryActionLabel: 'Fix and retry',
          requestId: error.requestId,
          timestamp: error.timestamp,
          errorCode: error.errorCode,
          preservedDraft: draft,
        );
        return;
      }

      if (error.type == ApplianceMutationErrorType.conflict) {
        state = state.copyWith(
          status: ManageApplianceMutationStatus.conflict,
          retryHint:
              'Your draft was preserved. Please reload latest appliance state and retry.',
          recoveryActionLabel: 'Reload latest',
          requestId: error.requestId,
          timestamp: error.timestamp,
          errorCode: error.errorCode,
          preservedDraft: draft,
        );
        return;
      }

      state = state.copyWith(
        status: ManageApplianceMutationStatus.retryableError,
        retryHint:
            'We could not complete the update. Check your connection and retry.',
        recoveryActionLabel: 'Retry',
        requestId: error.requestId,
        timestamp: error.timestamp,
        errorCode: error.errorCode,
        preservedDraft: draft,
      );
      return;
    }

    state = state.copyWith(
      status: ManageApplianceMutationStatus.retryableError,
      retryHint:
          'Unexpected error. Retry after reloading latest appliance data.',
      recoveryActionLabel: 'Retry',
      preservedDraft: draft,
    );
  }
}
