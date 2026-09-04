import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/transaction.dart';

IconData _iconFor(TxnCategory c) {
  switch (c) {
    case TxnCategory.food:
      return Icons.restaurant;
    case TxnCategory.shopping:
      return Icons.shopping_bag;
    case TxnCategory.travel:
      return Icons.flight;
    case TxnCategory.bills:
      return Icons.receipt_long;
    case TxnCategory.entertainment:
      return Icons.movie;
    case TxnCategory.other:
      return Icons.more_horiz;
  }
}

class TransactionTile extends StatelessWidget {
  final Transaction txn;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.txn,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 4,
      ),

      leading: CircleAvatar(
        backgroundColor: const Color(0xFF3A2E5C),
        child: Icon(
          _iconFor(txn.category),
          color: Colors.white,
          size: 20,
        ),
      ),

      title: Text(
        txn.merchant,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),

      subtitle: Text(
        DateFormat('MMM d, yyyy').format(txn.date),
        style: const TextStyle(
          color: Colors.white54,
        ),
      ),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${txn.amount.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '+${txn.rewardCoins} coins',
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.tealAccent,
                ),
              ),
            ],
          ),

          const SizedBox(width: 2),

          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.white70,
            ),
            color: const Color(0xFF2A2A3E),

            onSelected: (value) {
              if (value == 'edit') {
                onEdit?.call();
              }

              if (value == 'delete') {
                onDelete?.call();
              }
            },

            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Edit',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),

              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(
                      Icons.delete_outline,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Delete',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}