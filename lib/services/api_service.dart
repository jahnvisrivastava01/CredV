import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/card_model.dart';
import '../models/transaction.dart';

class ApiConfig {
  // Android device connected using adb reverse
  static const String baseUrl = 'https://credv.onrender.com';
}

class ApiService {
  final String baseUrl;

  ApiService({this.baseUrl = ApiConfig.baseUrl});

  // ============================================================
  // AUTH - REGISTER
  // ============================================================

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        data['detail'] ?? 'Registration failed',
      );
    }

    final Map<String, dynamic> user =
        Map<String, dynamic>.from(data['user'] ?? {});

    if (user['id'] == null) {
      throw Exception(
        'Registration succeeded but user ID was not returned',
      );
    }

    return {
      'message': data['message'],
      'userId': user['id'],
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
    };
  }

  // ============================================================
  // AUTH - LOGIN
  // ============================================================

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Login failed',
      );
    }

    final Map<String, dynamic> user =
        Map<String, dynamic>.from(data['user'] ?? {});

    if (user['id'] == null) {
      throw Exception(
        'Login succeeded but user ID was not returned',
      );
    }

    return {
      'message': data['message'],
      'userId': user['id'],
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
    };
  }

  // ============================================================
  // AUTH - FORGOT PASSWORD
  // ============================================================

  Future<String> forgotPassword({
    required String email,
    required String newPassword,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/forgot-password'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'new_password': newPassword,
      }),
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Password reset failed',
      );
    }

    return data['message'] ?? 'Password reset successfully';
  }

  // ============================================================
  // UPDATE USER PROFILE
  // ============================================================

  Future<Map<String, dynamic>> updateProfile({
    required int userId,
    required String name,
    required String email,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
      }),
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to update profile',
      );
    }

    final Map<String, dynamic> user =
        Map<String, dynamic>.from(data['user'] ?? {});

    if (user['id'] == null) {
      throw Exception(
        'Profile updated but user data was not returned',
      );
    }

    return {
      'message': data['message'],
      'userId': user['id'],
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
    };
  }

  // ============================================================
  // FETCH USER CARD
  // ============================================================

  Future<CreditCardModel> fetchCard(int userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/card/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load card (${res.statusCode})',
      );
    }

    return CreditCardModel.fromJson(
      jsonDecode(res.body),
    );
  }

  // ============================================================
  // UPDATE USER CARD
  // ============================================================

  Future<CreditCardModel> updateCard({
    required int userId,
    required String bankName,
    required String last4,
    required double creditLimit,
    required double outstanding,
    required int creditScore,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/card/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'bankName': bankName,
        'last4': last4,
        'creditLimit': creditLimit,
        'outstanding': outstanding,
        'creditScore': creditScore,
      }),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);

      throw Exception(
        data['detail'] ??
            'Failed to update card (${res.statusCode})',
      );
    }

    final Map<String, dynamic> data = jsonDecode(res.body);

    return CreditCardModel.fromJson(
      data['card'] ?? data,
    );
  }

  // ============================================================
  // FETCH USER TRANSACTIONS
  // ============================================================

  Future<List<Transaction>> fetchTransactions(int userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/transactions/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load transactions (${res.statusCode})',
      );
    }

    final List<dynamic> data = jsonDecode(res.body);

    return data
        .map((t) => Transaction.fromJson(t))
        .toList();
  }

  // ============================================================
  // ADD USER TRANSACTION
  // ============================================================

  Future<Transaction> addTransaction({
    required int userId,
    required String merchant,
    required double amount,
    required String category,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/transactions/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'merchant': merchant.trim(),
        'amount': amount,
        'category': category,
      }),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      final data = jsonDecode(res.body);

      throw Exception(
        data['detail'] ??
            'Failed to add transaction (${res.statusCode})',
      );
    }

    final Map<String, dynamic> data = jsonDecode(res.body);

    return Transaction.fromJson(
      data['transaction'] ?? data,
    );
  }

  // ============================================================
  // UPDATE USER TRANSACTION
  // ============================================================

  Future<Transaction> updateTransaction({
    required int userId,
    required String id,
    required String merchant,
    required double amount,
    required String category,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/api/transactions/$userId/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'merchant': merchant.trim(),
        'amount': amount,
        'category': category,
      }),
    );

    if (res.statusCode != 200) {
      final data = jsonDecode(res.body);

      throw Exception(
        data['detail'] ??
            'Failed to update transaction (${res.statusCode})',
      );
    }

    final Map<String, dynamic> data = jsonDecode(res.body);

    return Transaction.fromJson(
      data['transaction'] ?? data,
    );
  }

  // ============================================================
  // DELETE USER TRANSACTION
  // ============================================================

  Future<void> deleteTransaction({
    required int userId,
    required String id,
  }) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/api/transactions/$userId/$id'),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      final data = jsonDecode(res.body);

      throw Exception(
        data['detail'] ??
            'Failed to delete transaction (${res.statusCode})',
      );
    }
  }

  // ============================================================
  // USER REWARDS
  // ============================================================

  Future<int> fetchTotalCoins(int userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/rewards/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load rewards (${res.statusCode})',
      );
    }

    final Map<String, dynamic> data = jsonDecode(res.body);

    return (data['totalCoins'] as num?)?.toInt() ?? 0;
  }
}