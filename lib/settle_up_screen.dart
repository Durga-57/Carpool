import 'package:carpool_app/groups_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Model to hold the final calculated debt between two members
class Debt {
  final String from;
  final String to;
  final double amount;
  Debt({required this.from, required this.to, required this.amount});
}

class SettleUpScreen extends StatefulWidget {
  final Group group;
  const SettleUpScreen({super.key, required this.group});

  @override
  State<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends State<SettleUpScreen> {
  Future<List<Debt>> _calculateDebts() async {
    // This is a simplified debt calculation for the MVP.
    // A real-world scenario would involve a more complex debt simplification algorithm.
    
    // 1. Fetch all trips for the group
    final tripsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.group.id)
        .collection('trips')
        .get();

    // 2. Calculate the net balance for each member
    final Map<String, double> memberBalances = {};

    for (var tripDoc in tripsSnapshot.docs) {
      final tripData = tripDoc.data();
      final driverId = tripData['driverId'] as String;
      final passengers = List<String>.from(tripData['passengers'] ?? []);
      final totalCost = (tripData['totalCost'] as num).toDouble();
      
      // The driver initially "paid" the whole cost
      memberBalances[driverId] = (memberBalances[driverId] ?? 0) + totalCost;
      
      // Each person (driver + passengers) owes a share
      final totalPeople = passengers.length + 1;
      if (totalPeople > 0) {
        final perPersonShare = totalCost / totalPeople;
        memberBalances[driverId] = (memberBalances[driverId] ?? 0) - perPersonShare;
        for (var passengerId in passengers) {
          memberBalances[passengerId] = (memberBalances[passengerId] ?? 0) - perPersonShare;
        }
      }
    }

    // 3. Simplify debts (basic version)
    // Separate members into those who are owed money (creditors) and those who owe (debtors)
    final creditors = memberBalances.entries.where((e) => e.value > 0).toList();
    final debtors = memberBalances.entries.where((e) => e.value < 0).toList();
    
    final List<Debt> debts = [];

    // This is a naive implementation. A full algorithm is more complex.
    // For now, we'll just show who owes what to whom based on a simple pairing.
    for (var debtor in debtors) {
       for (var creditor in creditors) {
         // In a real app, you'd transfer amounts between them until balances are zero.
         // For the MVP, we'll just create a placeholder debt.
         if (debtor.value.abs() > 0) {
            final amountToSettle = debtor.value.abs();
            // Fetch names for display
            final debtorDoc = await FirebaseFirestore.instance.collection('users').doc(debtor.key).get();
            final creditorDoc = await FirebaseFirestore.instance.collection('users').doc(creditor.key).get();
            
            debts.add(Debt(
              from: debtorDoc.data()?['name'] ?? 'Unknown',
              to: creditorDoc.data()?['name'] ?? 'Unknown',
              amount: amountToSettle,
            ));
         }
       }
    }
    
    return debts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settle Up - ${widget.group.name}'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<List<Debt>>(
        future: _calculateDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error calculating debts: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildAllSettled(context);
          }

          final debts = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                'Who Owes Whom',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 16),
              ...debts.map((debt) => _buildDebtCard(context, debt)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAllSettled(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 16),
          Text(
            'All Settled Up!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'There are no pending dues in this group.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildDebtCard(BuildContext context, Debt debt) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  debt.from,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
                Text(
                  'owes',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                Text(
                  debt.to,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                ),
              ],
            ),
            const Spacer(),
            Text(
              '₹${debt.amount.toStringAsFixed(2)}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.check_circle, color: Colors.green),
              onPressed: () {
                // TODO: Implement "Record Payment" functionality
              },
              tooltip: 'Record as Paid',
            )
          ],
        ),
      ),
    );
  }
}
