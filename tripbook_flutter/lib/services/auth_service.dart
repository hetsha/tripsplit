import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/user.dart';
import '../models/trip.dart';

enum AuthState { uninitialized, authenticated, unauthenticated, loading }

class AuthService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  
  User? _currentUser;
  List<Trip> _trips = [];
  int? _activeTripId;
  
  AuthState _state = AuthState.uninitialized;
  bool _needsTripSelection = false;

  User? get currentUser => _currentUser;
  List<Trip> get trips => _trips;
  int? get activeTripId => _activeTripId;
  AuthState get state => _state;
  bool get needsTripSelection => _needsTripSelection;

  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  Trip? get activeTrip {
    if (_activeTripId == null || _trips.isEmpty) return null;
    try {
      return _trips.firstWhere((t) => t.id == _activeTripId);
    } catch (_) {
      return null;
    }
  }

  // Initialize and check current session status
  Future<void> checkAuth() async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiEndpoints.me);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        _currentUser = User.fromJson(data['user']);
        
        if (data['trips'] is List) {
          final List rawTrips = data['trips'];
          _trips = rawTrips.map((t) => Trip.fromJson(t)).toList();
        }
        
        if (data['active_trip'] != null) {
          _activeTripId = int.parse(data['active_trip'].toString());
        }
        
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  // Phone OTP Flow
  Future<void> requestPhoneOtp(String phone) async {
    await _apiClient.post(ApiEndpoints.sendOtp, {'phone': phone});
  }

  Future<void> verifyPhoneOtp(String phone, String otpCode) async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiEndpoints.verifyOtp, {
        'phone': phone,
        'otp_code': otpCode,
      });

      if (res['success'] == true && res['data'] != null) {
        await checkAuth();
        _needsTripSelection = true;
        notifyListeners();
      } else {
        _state = AuthState.unauthenticated;
        notifyListeners();
        throw Exception(res['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Email OTP Flow
  Future<void> requestEmailOtp(String email) async {
    await _apiClient.post(ApiEndpoints.sendEmailOtp, {'email': email});
  }

  Future<void> verifyEmailOtp(String email, String otpCode) async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiEndpoints.verifyEmailOtp, {
        'email': email,
        'otp_code': otpCode,
      });

      if (res['success'] == true && res['data'] != null) {
        await checkAuth();
        _needsTripSelection = true;
        notifyListeners();
      } else {
        _state = AuthState.unauthenticated;
        notifyListeners();
        throw Exception(res['message'] ?? 'Email verification failed');
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Google Sign-In Flow
  Future<void> loginWithGoogle(String credential) async {
    _state = AuthState.loading;
    notifyListeners();

    try {
      final res = await _apiClient.post(ApiEndpoints.googleLogin, {
        'credential': credential,
      });

      if (res['success'] == true && res['data'] != null) {
        await checkAuth();
        _needsTripSelection = true;
        notifyListeners();
      } else {
        _state = AuthState.unauthenticated;
        notifyListeners();
        throw Exception(res['message'] ?? 'Google login failed');
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      notifyListeners();
      rethrow;
    }
  }

  // Switch Active Trip
  Future<void> switchTrip(int tripId) async {
    try {
      final res = await _apiClient.post(ApiEndpoints.switchTrip, {'trip_id': tripId});
      if (res['success'] == true) {
        _activeTripId = tripId;
        _needsTripSelection = false;
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Logout Session
  Future<void> logout() async {
    try {
      await _apiClient.get(ApiEndpoints.logout);
    } catch (_) {}
    
    _currentUser = null;
    _trips = [];
    _activeTripId = null;
    _state = AuthState.unauthenticated;
    await _apiClient.clearSession();
    notifyListeners();
  }
}
