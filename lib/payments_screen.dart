import 'package:carpool_app/pay_due_screen.dart';
import 'package:flutter/material.dart';

class PaymentRecord {
  final String personName;
  final double amount;
  final bool isPending;

  const PaymentRecord({required this.personName, required this.amount, this.isPending = false});
}

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  static const List<PaymentRecord> _pendingPayments = [
    PaymentRecord(personName: 'John Doe', amount: -200.0, isPending: true),
    PaymentRecord(personName: 'Jane Smith', amount: -50.0, isPending: true),
  ];

  static const List<PaymentRecord> _paymentHistory = [
    PaymentRecord(personName: 'Peter Jones', amount: 150.0),
    PaymentRecord(personName: 'John Doe', amount: -75.0),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionHeader(context, 'Pending Payments'),
          ..._pendingPayments.map((payment) => _buildPaymentTile(context, payment)),
          const SizedBox(height: 24),
          _buildSectionHeader(context, 'Payment History'),
          ..._paymentHistory.map((payment) => _buildPaymentTile(context, payment)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
      ),
    );
  }

  Widget _buildPaymentTile(BuildContext context, PaymentRecord record) {
    final bool isOwedToUser = record.amount > 0;
    final String amountString = '₹${record.amount.abs().toStringAsFixed(2)}';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: isOwedToUser ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          child: Icon(
            isOwedToUser ? Icons.arrow_downward : Icons.arrow_upward,
            color: isOwedToUser ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          record.personName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          isOwedToUser ? 'Owes you' : 'You owe',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        trailing: Text(
          amountString,
          style: TextStyle(
            color: isOwedToUser ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        onTap: () {
          if (record.isPending && !isOwedToUser) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PayDueScreen(payment: record),
              ),
            );
          }
        },
      ),
    );
  }
}
