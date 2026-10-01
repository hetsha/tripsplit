import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/transaction.dart';

class ExpenseService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic>? _dashboardData;
  List<Transaction> _transactionsList = [];
  List<Map<String, dynamic>> _categories = [];
  Map<String, dynamic>? _settlementData;
  bool _isLoading = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<Transaction> get transactionsList => _transactionsList;
  List<Map<String, dynamic>> get categories => _categories;
  Map<String, dynamic>? get settlementData => _settlementData;
  bool get isLoading => _isLoading;

  // Load Dashboard Data
  Future<void> loadDashboard({int? tripId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = tripId != null ? {'trip_id': tripId} : null;
      final res = await _apiClient.get(ApiEndpoints.dashboard, queryParameters: queryParams);
      if (res['success'] == true && res['data'] != null) {
        _dashboardData = res['data'];
      }
    } catch (e) {
      print('loadDashboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Full Transactions list (all, expenses, settlements etc)
  Future<void> loadTransactions({int? tripId, String type = 'all', String search = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = {
        'type': type,
        if (tripId != null) 'trip_id': tripId,
        if (search.isNotEmpty) 'search': search,
      };
      final res = await _apiClient.get(ApiEndpoints.transactions, queryParameters: queryParams);
      if (res['success'] == true && res['data'] != null) {
        final List rawTx = res['data']['transactions'] ?? [];
        _transactionsList = rawTx.map((t) => Transaction.fromJson(t)).toList();
      }
    } catch (e) {
      print('loadTransactions error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Categories list
  Future<void> loadCategories({int? tripId}) async {
    try {
      final queryParams = tripId != null ? {'trip_id': tripId} : null;
      final res = await _apiClient.get(ApiEndpoints.categories, queryParameters: queryParams);
      if (res['success'] == true && res['data'] != null) {
        final List rawCats = res['data']['categories'] ?? [];
        _categories = List<Map<String, dynamic>>.from(rawCats);
      }
    } catch (_) {}
  }

  // Scan & Read Receipt via AI / OCR
  Future<Map<String, dynamic>?> scanReceipt({
    String? imageBase64,
    bool isDemo = false,
    int? tripId,
  }) async {
    try {
      final payload = {
        if (imageBase64 != null) 'image_base64': imageBase64,
        if (isDemo) 'is_demo': true,
        if (tripId != null) 'trip_id': tripId,
      };
      final res = await _apiClient.post(ApiEndpoints.scanReceipt, payload);
      if (res['success'] == true && res['data'] != null) {
        return {
          'receipt_url': res['receipt_url'],
          'receipt_id': res['receipt_id'],
          'data': res['data'],
        };
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Add/Save Expense (both shared and personal)
  Future<void> saveExpense({
    required double amount,
    required String description,
    required int categoryId,
    required int paidBy,
    required String paymentMethod,
    required bool isPersonal,
    required String clientRequestId,
    required List<Map<String, dynamic>> splits,
    List<Map<String, dynamic>>? payers,
    int? tripId,
    String? notes,
    String? receiptUrl,
    int? expenseId,
  }) async {
    final payload = {
      'action': expenseId != null ? 'update' : 'create',
      if (expenseId != null) 'id': expenseId,
      'amount': amount,
      'description': description,
      'category_id': categoryId,
      'paid_by': paidBy,
      'payment_method': paymentMethod,
      'is_personal': isPersonal,
      if (tripId != null && !isPersonal) 'trip_id': tripId,
      'client_request_id': clientRequestId,
      'splits': splits,
      if (payers != null && payers.isNotEmpty) 'payers': payers,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (receiptUrl != null && receiptUrl.isNotEmpty) 'receipt_url': receiptUrl,
    };

    try {
      await _apiClient.post(ApiEndpoints.expenses, payload);
      await loadDashboard(tripId: tripId); // refresh dashboard stats
    } catch (e) {
      rethrow;
    }
  }

  // Delete Transaction
  Future<void> deleteTransaction(int id) async {
    try {
      await _apiClient.post(ApiEndpoints.transactions, {
        'action': 'delete',
        'id': id,
      });
      await loadDashboard(); // refresh
    } catch (e) {
      rethrow;
    }
  }

  // Load Settlements Data (Suggestions, Balances, History)
  Future<Map<String, dynamic>?> loadSettlements({int? tripId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = tripId != null ? {'trip_id': tripId} : null;
      final res = await _apiClient.get(ApiEndpoints.settlements, queryParameters: queryParams);
      if (res['success'] == true && res['data'] != null) {
        _settlementData = Map<String, dynamic>.from(res['data']);
        return _settlementData;
      }
    } catch (e) {
      print('loadSettlements error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
  }

  // Settle Up Single Direct Debt Payment
  Future<void> recordSettlement({
    required int tripId,
    required int fromUser,
    required int toUser,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    final payload = {
      'action': 'settle',
      'trip_id': tripId,
      'from_user': fromUser,
      'to_user': toUser,
      'amount': amount,
      'payment_method': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      await _apiClient.post(ApiEndpoints.settlements, payload);
      await loadSettlements(tripId: tripId);
      await loadDashboard(tripId: tripId);
    } catch (e) {
      rethrow;
    }
  }

  // Settle All Debts for the trip at once
  Future<void> settleAllDebts({required int tripId}) async {
    final payload = {
      'action': 'settle_all',
      'trip_id': tripId,
    };

    try {
      await _apiClient.post(ApiEndpoints.settlements, payload);
      await loadSettlements(tripId: tripId);
      await loadDashboard(tripId: tripId);
    } catch (e) {
      rethrow;
    }
  }
}
