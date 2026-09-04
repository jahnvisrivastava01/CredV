import 'package:flutter/material.dart';

import '../models/card_model.dart';

class CreditCardWidget extends StatelessWidget {
  final CreditCardModel card;

  const CreditCardWidget({
    super.key,
    required this.card,
  });

  @override
  Widget build(BuildContext context) {
    final utilizationPercent = card.utilization * 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E1E2E),
            Color(0xFF3A2E5C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // Bank Name + Card Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card.bankName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.credit_card,
                color: Colors.white70,
              ),
            ],
          ),

          const SizedBox(height: 26),

          // Card Number
          Text(
            '•••• •••• •••• ${card.last4}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 28),

          // Outstanding
          const Text(
            'OUTSTANDING BALANCE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            '₹${card.outstanding.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 22),

          // Available Credit
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _stat(
                'Available Credit',
                '₹${card.available.toStringAsFixed(0)}',
              ),
              _stat(
                'Credit Limit',
                '₹${card.creditLimit.toStringAsFixed(0)}',
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Utilization Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Credit Utilization',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 12,
                ),
              ),
              Text(
                '${utilizationPercent.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.tealAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: card.utilization.clamp(0.0, 1.0),
              minHeight: 7,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation(
                Colors.tealAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}