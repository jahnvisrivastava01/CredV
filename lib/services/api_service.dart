import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/card_model.dart';
import '../models/transaction.dart';

class ApiService {
  // ============================================================
  // BASE URL
  // ============================================================

  static const String baseUrl = 'https://credv.onrender.com';

  // ============================================================
  // REGISTER
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
        Map<String, dynamic>.from(data['user'] ?? data);

    return {
      'message': data['message'] ?? 'Registration successful',
      'userId': user['id'],
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
    };
  }

  // ============================================================
  // LOGIN
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
        Map<String, dynamic>.from(data['user'] ?? data);

    return {
      'message': data['message'] ?? 'Login successful',
      'userId': user['id'],
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
    };
  }

  // ============================================================
  // GOOGLE LOGIN
  // ============================================================

  Future<Map<String, dynamic>> googleLogin({
    required String name,
    required String email,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
      }),
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        data['detail'] ?? 'Google login failed',
      );
    }

    final Map<String, dynamic> user =
        Map<String, dynamic>.from(data['user'] ?? {});

    if (user['id'] == null) {
      throw Exception(
        'Google login succeeded but user ID was not returned',
      );
    }

    return {
      'message': data['message'] ?? 'Google login successful',
      'userId': user['id'],
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
      'isNewUser': data['isNewUser'] ?? false,
    };
  }

  // ============================================================
  // FORGOT PASSWORD
  // ============================================================

  Future<Map<String, dynamic>> forgotPassword({
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
        data['detail'] ?? 'Failed to reset password',
      );
    }

    return data;
  }

  // ============================================================
  // UPDATE PROFILE
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
        Map<String, dynamic>.from(data['user'] ?? data);

    return {
      'message': data['message'] ?? 'Profile updated successfully',
      'userId': user['id'],
      'id': user['id'],
      'name': user['name'],
      'email': user['email'],
    };
  }

  // ============================================================
  // FETCH USER CARD
  // ============================================================

  Future<CreditCardModel> fetchCard({
    required int userId,
  }) async {
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
  // UPDATE / CREATE USER CARD
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

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to update card (${res.statusCode})',
      );
    }

    return CreditCardModel.fromJson(
      data['card'] ?? data,
    );
  }

  // ============================================================
  // FETCH USER TRANSACTIONS
  // ============================================================

  Future<List<Transaction>> fetchTransactions({
    required int userId,
  }) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/transactions/$userId'),
    );

    if (res.statusCode != 200) {
      throw Exception(
        'Failed to load transactions (${res.statusCode})',
      );
    }

    final List<dynamic> data = jsonDecode(res.body);

    return data.map((t) => Transaction.fromJson(t)).toList();
  }

  // ============================================================
  // ADD USER TRANSACTION
  // ============================================================

  Future<Transaction> addTransaction({
    required int userId,
    required String title,
    required double amount,
    required TxnCategory category,
    required DateTime date,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/transactions/$userId'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        // Backend currently uses merchant
        'merchant': title.trim(),
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
      }),
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception(
        data['detail'] ?? 'Failed to add transaction (${res.statusCode})',
      );
    }

    return Transaction.fromJson(
      data['transaction'] ?? data,
    );
  }

  // ============================================================
  // UPDATE USER TRANSACTION
  // ============================================================

  Future<Transaction> updateTransaction({
    required int userId,
    required String transactionId,
    required String title,
    required double amount,
    required TxnCategory category,
    required DateTime date,
  }) async {
    final res = await http.put(
      Uri.parse(
        '$baseUrl/api/transactions/$userId/$transactionId',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'merchant': title.trim(),
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
      }),
    );

    final Map<String, dynamic> data = jsonDecode(res.body);

    if (res.statusCode != 200) {
      throw Exception(
        data['detail'] ?? 'Failed to update transaction (${res.statusCode})',
      );
    }

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
      Uri.parse(
        '$baseUrl/api/transactions/$userId/$id',
      ),
    );

    if (res.statusCode != 200 && res.statusCode != 204) {
      final Map<String, dynamic> data = jsonDecode(res.body);

      throw Exception(
        data['detail'] ?? 'Failed to delete transaction (${res.statusCode})',
      );
    }
  }

  // ============================================================
  // USER REWARDS
  // ============================================================

  Future<int> fetchTotalCoins({
    required int userId,
  }) async {
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
