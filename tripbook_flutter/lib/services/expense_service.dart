import 'package:flutter/material.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';
import '../models/transaction.dart';

class ExpenseService extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  Map<String, dynamic>? _dashboardData;
  List<Transaction> _transactionsList = [];
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = false;

  Map<String, dynamic>? get dashboardData => _dashboardData;
  List<Transaction> get transactionsList => _transactionsList;
  List<Map<String, dynamic>> get categories => _categories;
  bool get isLoading => _isLoading;

  // Load Dashboard Data
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiEndpoints.dashboard);
      if (res['success'] == true && res['data'] != null) {
        _dashboardData = res['data'];
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Full Transactions list (all, expenses, settlements etc)
  Future<void> loadTransactions({String type = 'all', String search = ''}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = {
        'type': type,
        if (search.isNotEmpty) 'search': search,
      };
      final res = await _apiClient.get(ApiEndpoints.transactions, queryParameters: queryParams);
      if (res['success'] == true && res['data'] != null) {
        final List rawTx = res['data']['transactions'] ?? [];
        _transactionsList = rawTx.map((t) => Transaction.fromJson(t)).toList();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load Categories list
  Future<void> loadCategories() async {
    try {
      final res = await _apiClient.get(ApiEndpoints.categories);
      if (res['success'] == true && res['data'] != null) {
        final List rawCats = res['data']['categories'] ?? [];
        _categories = List<Map<String, dynamic>>.from(rawCats);
      }
    } catch (_) {}
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
    String? notes,
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
      'client_request_id': clientRequestId,
      'splits': splits,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      await _apiClient.post(ApiEndpoints.expenses, payload);
      await loadDashboard(); // refresh dashboard stats
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

  // Settle Up Payment
  Future<void> recordSettlement({
    required int fromUser,
    required int toUser,
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    final payload = {
      'from_user': fromUser,
      'to_user': toUser,
      'amount': amount,
      'payment_method': paymentMethod,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };

    try {
      await _apiClient.post(ApiEndpoints.settleUp, payload);
      await loadDashboard(); // refresh
    } catch (e) {
      rethrow;
    }
  }

}
