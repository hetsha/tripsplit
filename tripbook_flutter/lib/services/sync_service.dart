import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

class SyncService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  Timer? _timer;
  
  String? _cachedVersion;
  bool _isPolling = false;
  bool _isOffline = false;
  int? _activeTripId;
  
  VoidCallback? _onSyncTriggered;

  bool get isOffline => _isOffline;
  String? get cachedVersion => _cachedVersion;

  void registerCallback(VoidCallback callback) {
    _onSyncTriggered = callback;
  }

  void setOffline(bool offline) {
    if (_isOffline != offline) {
      _isOffline = offline;
      notifyListeners();
      if (_isOffline) {
        stopPolling();
      } else {
        startPolling(_activeTripId);
      }
    }
  }

  Future<void> startPolling(int? tripId) async {
    if (tripId == null) {
      stopPolling();
      return;
    }
    
    _activeTripId = tripId;
    if (_isPolling || _isOffline) return;
    _isPolling = true;

    final prefs = await SharedPreferences.getInstance();
    _cachedVersion = prefs.getString('trip_sync_version_$tripId');

    // Run immediately first
    _checkSync();

    _timer = Timer.periodic(const Duration(seconds: 8), (timer) {
      _checkSync();
    });
  }

  void stopPolling() {
    _timer?.cancel();
    _isPolling = false;
  }

  Future<void> _checkSync() async {
    if (_activeTripId == null || _isOffline) return;

    try {
      final res = await _apiClient.get(ApiEndpoints.sync, queryParameters: {
        'trip_id': _activeTripId,
        if (_cachedVersion != null) 'version': _cachedVersion,
      });

      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final hasChanges = data['has_changes'] == true;
        final newVersion = data['version'] as String;

        if (hasChanges) {
          _cachedVersion = newVersion;
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('trip_sync_version_$_activeTripId', newVersion);
          
          if (_onSyncTriggered != null) {
            _onSyncTriggered!();
          }
        }
        
        if (_isOffline) {
          _isOffline = false;
          notifyListeners();
        }
      }
    } catch (e) {
      if (e.toString().contains('connection timed out') || e.toString().contains('Failed to connect')) {
        setOffline(true);
      }
    }
  }
}
