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

  // Alias getter for trip
  Trip? get trip => activeTrip;

  List<Map<String, dynamic>> _detailedTrips = [];
  Map<String, dynamic> _tripStats = {};
  bool _isFetchingTrips = false;

  List<Map<String, dynamic>> get detailedTrips => _detailedTrips;
  Map<String, dynamic> get tripStats => _tripStats;
  bool get isFetchingTrips => _isFetchingTrips;

  // Load Trips with full aggregated financial & member details from database
  Future<void> fetchTripsList() async {
    _isFetchingTrips = true;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiEndpoints.tripsList);
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        if (data['trips'] is List) {
          _detailedTrips = List<Map<String, dynamic>>.from(data['trips']);
          _trips = _detailedTrips.map((t) => Trip.fromJson(t)).toList();
        }
        if (data['stats'] is Map) {
          _tripStats = Map<String, dynamic>.from(data['stats']);
        }
        if (data['user'] != null && _currentUser == null) {
          _currentUser = User.fromJson(data['user']);
        }
        if (_activeTripId == null && _detailedTrips.isNotEmpty) {
          _activeTripId = _detailedTrips.first['id'] as int?;
        }
      }
    } catch (e) {
      print('fetchTripsList error: $e');
    } finally {
      _isFetchingTrips = false;
      notifyListeners();
    }
  }

  // Create Trip in Database
  Future<Map<String, dynamic>> createTrip({
    required String name,
    String? description,
    double? startingMoney,
    List<String>? members,
  }) async {
    final payload = {
      'action': 'create',
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (startingMoney != null && startingMoney > 0) 'starting_money': startingMoney,
      if (members != null && members.isNotEmpty) 'members': members,
    };

    final res = await _apiClient.post(ApiEndpoints.createTrip, payload);
    if (res['success'] == true && res['data'] != null) {
      final newId = res['data']['trip_id'];
      if (newId != null) {
        _activeTripId = int.tryParse(newId.toString());
      }
      await fetchTripsList();
      return res['data'];
    } else {
      throw Exception(res['message'] ?? 'Failed to create trip');
    }
  }

  // Update Trip Settings
  Future<void> updateTrip({
    required int tripId,
    required String name,
    String? description,
    double? startingMoney,
  }) async {
    final payload = {
      'action': 'update',
      'trip_id': tripId,
      'name': name,
      if (description != null) 'description': description,
      if (startingMoney != null) 'starting_money': startingMoney,
      'starting_payment_method': 'cash',
    };

    final res = await _apiClient.post(ApiEndpoints.trips, payload);
    if (res['success'] == true) {
      await fetchTripsList();
    } else {
      throw Exception(res['message'] ?? 'Failed to update trip');
    }
  }

  // Delete Trip
  Future<void> deleteTrip({required int tripId}) async {
    final payload = {
      'action': 'delete',
      'trip_id': tripId,
    };

    final res = await _apiClient.post(ApiEndpoints.trips, payload);
    if (res['success'] == true) {
      if (_activeTripId == tripId) {
        _activeTripId = null;
      }
      await fetchTripsList();
    } else {
      throw Exception(res['message'] ?? 'Failed to delete trip');
    }
  }

  // Load Members for a Trip
  Future<Map<String, dynamic>> loadTripMembers({required int tripId}) async {
    final res = await _apiClient.get(ApiEndpoints.members, queryParameters: {'trip_id': tripId});
    if (res['success'] == true && res['data'] != null) {
      return Map<String, dynamic>.from(res['data']);
    }
    return {};
  }

  // Add Member to Trip
  Future<void> addMemberToTrip({
    required int tripId,
    required String name,
    String? email,
    String? phone,
  }) async {
    final payload = {
      'action': 'add',
      'trip_id': tripId,
      'name': name,
      if (email != null && email.isNotEmpty) 'email': email,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
    };

    final res = await _apiClient.post(ApiEndpoints.members, payload);
    if (res['success'] == true) {
      await fetchTripsList();
    } else {
      throw Exception(res['message'] ?? 'Failed to add member');
    }
  }

  // Remove Member from Trip
  Future<void> removeMemberFromTrip({
    required int tripId,
    required int userId,
  }) async {
    final payload = {
      'action': 'remove',
      'trip_id': tripId,
      'user_id': userId,
    };

    final res = await _apiClient.post(ApiEndpoints.members, payload);
    if (res['success'] == true) {
      await fetchTripsList();
    } else {
      throw Exception(res['message'] ?? 'Failed to remove member');
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
        _apiClient.setUserId(_currentUser?.id);
        
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
    
    // Also load detailed trips list from DB
    await fetchTripsList();
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
