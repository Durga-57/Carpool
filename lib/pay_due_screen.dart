import 'package:carpool_app/payments_screen.dart';
import 'package:flutter/material.dart';

class PayDueScreen extends StatelessWidget {
  final PaymentRecord payment;
  const PayDueScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pay Due'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      'PAYING TO',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      payment.personName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '₹${payment.amount.abs().toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Payment Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black),
            ),
            const SizedBox(height: 16),
            _buildPaymentOptionTile('GPAY'),
            _buildPaymentOptionTile('PHONEPE'),
            _buildPaymentOptionTile('FAMPAY'),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOptionTile(String optionName) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
       shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        title: Text(
          optionName,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
        onTap: () {
          // TODO: Integrate with a payment gateway or mark as paid
        },
      ),
    );
  }
}
