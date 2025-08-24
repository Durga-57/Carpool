import 'package:carpool_app/all_trips_screen.dart'; // Import the new screen
import 'package:carpool_app/groups_screen.dart';
import 'package:carpool_app/my_profile_screen.dart';
import 'package:carpool_app/payments_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// Enum to manage the currently selected page
enum AppPage { overview, trips, groups, dues }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppPage _selectedPage = AppPage.overview;

  // Method to get the current page widget
  Widget _getCurrentPage() {
    switch (_selectedPage) {
      case AppPage.overview:
        return const OverviewDashboard();
      case AppPage.trips:
        return const AllTripsScreen(); // Show the new AllTripsScreen
      case AppPage.groups:
        return const GroupsScreen();
      case AppPage.dues:
        return const PaymentsScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Light grey background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              'CarPool',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.black54),
            onPressed: () {
               Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const MyProfileScreen()),
              );
            },
            tooltip: 'My Profile',
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Navigation Bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200))
            ),
            child: Row(
              children: [
                _buildNavButton(AppPage.overview, 'Overview', Icons.dashboard_outlined),
                const SizedBox(width: 8),
                _buildNavButton(AppPage.trips, 'Trips', Icons.mode_of_travel_outlined),
                const SizedBox(width: 8),
                _buildNavButton(AppPage.groups, 'Groups', Icons.group_outlined),
                const SizedBox(width: 8),
                _buildNavButton(AppPage.dues, 'Dues', Icons.receipt_long_outlined),
              ],
            ),
          ),
          // Page Content
          Expanded(
            child: _getCurrentPage(),
          ),
        ],
      ),
    );
  }

  // Helper widget for building the navigation buttons
  Widget _buildNavButton(AppPage page, String label, IconData icon) {
    final isSelected = _selectedPage == page;
    final color = isSelected ? Theme.of(context).colorScheme.primary : Colors.black54;
    return TextButton.icon(
      onPressed: () => setState(() => _selectedPage = page),
      icon: Icon(icon, color: color, size: 20),
      label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      style: TextButton.styleFrom(
        backgroundColor: isSelected ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

// The new "Overview" dashboard widget
class OverviewDashboard extends StatelessWidget {
  const OverviewDashboard({super.key});

  Future<String> _getUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Guest";
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    return userDoc.data()?['name'] ?? 'User';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        // Dynamic Greeting
        FutureBuilder<String>(
          future: _getUserName(),
          builder: (context, snapshot) {
            final name = snapshot.data ?? '...';
            return Text(
              'Welcome back, $name!',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: Colors.black),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          "Here's a summary of your carpool activity.",
          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),
        // Summary Cards
        GridView.count(
          crossAxisCount: 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: const [
            _SummaryCard(title: 'Upcoming Trips', value: '2', icon: Icons.calendar_today, color: Colors.green),
            _SummaryCard(title: 'Active Groups', value: '2', icon: Icons.group, color: Colors.purple),
            _SummaryCard(title: 'You Owe', value: '\$35.00', icon: Icons.arrow_upward, color: Colors.red),
            _SummaryCard(title: 'Owed to You', value: '\$15.00', icon: Icons.arrow_downward, color: Colors.blue),
          ],
        ),
        const SizedBox(height: 32),
        // Recent Activity Section
        Text('Recent Activity', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
        const SizedBox(height: 16),
        _ActivityCard(
          type: 'Trip',
          title: 'Trip to Downtown Office',
          subtitle: 'You are the driver',
          date: 'Jan 15, 2025',
          amount: '+\$25.00',
          amountColor: Colors.green,
          icon: Icons.directions_car,
          iconColor: Colors.blue,
        ),
        _ActivityCard(
          type: 'Due',
          title: 'Bob Johnson paid you',
          subtitle: 'For trip to Airport',
          date: 'Jan 12, 2025',
          amount: '+\$12.50',
          amountColor: Colors.green,
          icon: Icons.receipt,
          iconColor: Colors.orange,
        ),
        _ActivityCard(
          type: 'Due',
          title: 'You paid Alice Smith',
          subtitle: 'For trip to Shopping Mall',
          date: 'Jan 10, 2025',
          amount: '-\$22.50',
          amountColor: Colors.red,
          icon: Icons.receipt,
          iconColor: Colors.orange,
        ),
      ],
    );
  }
}

// --- NEW WIDGETS FOR THE REDESIGNED DASHBOARD ---

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  const _SummaryCard({required this.title, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const Spacer(),
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String type, title, subtitle, date, amount;
  final Color amountColor, iconColor;
  final IconData icon;
  
  const _ActivityCard({
    required this.type, required this.title, required this.subtitle,
    required this.date, required this.amount, required this.amountColor,
    required this.icon, required this.iconColor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: iconColor.withOpacity(0.1),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                  Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(amount, style: TextStyle(fontWeight: FontWeight.bold, color: amountColor, fontSize: 16)),
                Text(date, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
