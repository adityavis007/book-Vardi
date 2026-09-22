import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/location_repository.dart';
import '../../domain/location_hub_model.dart';

/// State of location management
@immutable
class LocationState {
  final LocationHubModel currentHub;
  final bool isLoadingGps;
  final String? errorMessage;
  final bool hasPromptedAutoThisSession;

  const LocationState({
    this.currentHub = LocationHubModel.defaultHub,
    this.isLoadingGps = false,
    this.errorMessage,
    this.hasPromptedAutoThisSession = false,
  });

  LocationState copyWith({
    LocationHubModel? currentHub,
    bool? isLoadingGps,
    String? errorMessage,
    bool clearError = false,
    bool? hasPromptedAutoThisSession,
  }) {
    return LocationState(
      currentHub: currentHub ?? this.currentHub,
      isLoadingGps: isLoadingGps ?? this.isLoadingGps,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      hasPromptedAutoThisSession:
          hasPromptedAutoThisSession ?? this.hasPromptedAutoThisSession,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationState &&
          runtimeType == other.runtimeType &&
          currentHub == other.currentHub &&
          isLoadingGps == other.isLoadingGps &&
          errorMessage == other.errorMessage &&
          hasPromptedAutoThisSession == other.hasPromptedAutoThisSession;

  @override
  int get hashCode =>
      currentHub.hashCode ^
      isLoadingGps.hashCode ^
      errorMessage.hashCode ^
      hasPromptedAutoThisSession.hashCode;
}

/// StateNotifier managing current location hub, GPS acquisition, and auto prompt logic.
class LocationController extends StateNotifier<LocationState> {
  final ILocationRepository _repository;

  LocationController(this._repository) : super(const LocationState()) {
    _initializeSavedLocation();
  }

  Future<void> _initializeSavedLocation() async {
    final saved = await _repository.getSavedHub();
    state = state.copyWith(currentHub: saved);
  }

  /// Manually select a hub from the Popular Cities & Hubs list
  Future<void> selectHub(LocationHubModel hub) async {
    state = state.copyWith(currentHub: hub, clearError: true);
    await _repository.saveSelectedHub(hub);
  }

  /// Determine user's current GPS location with reverse geocoding and 25 km operational radius check.
  /// Returns [GpsLocationResult] if successful, or null on permission deny/error.
  Future<GpsLocationResult?> useCurrentGpsLocation() async {
    state = state.copyWith(isLoadingGps: true, clearError: true);

    try {
      final result = await _repository.determineGpsLocation();
      if (result == null) {
        state = state.copyWith(
          isLoadingGps: false,
          errorMessage: 'Location permission was not granted or service is disabled.',
        );
        return null;
      }

      state = state.copyWith(
        currentHub: result.hub,
        isLoadingGps: false,
        clearError: true,
      );

      await _repository.saveSelectedHub(result.hub);
      return result;
    } catch (e) {
      state = state.copyWith(
        isLoadingGps: false,
        errorMessage: 'Unable to acquire GPS coordinates: $e',
      );
      return null;
    }
  }

  void markPromptedThisSession() {
    state = state.copyWith(hasPromptedAutoThisSession: true);
  }
}

/// Main Provider managing location state
final locationControllerProvider =
    StateNotifierProvider<LocationController, LocationState>((ref) {
  final repo = ref.watch(locationRepositoryProvider);
  return LocationController(repo);
});

/// Convenience provider for current selected [LocationHubModel]
final selectedLocationProvider = Provider<LocationHubModel>((ref) {
  return ref.watch(locationControllerProvider).currentHub;
});
