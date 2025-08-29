import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MyProfileScreen extends StatelessWidget {
  const MyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(appBar: AppBar(title: const Text('My Profile')), body: const Center(child: Text('Not logged in.')));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Could not load profile.'));
          }

          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userName = userData['name'] ?? 'No Name';
          final userEmail = user.email ?? 'No Email'; // Get email from Auth

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              CircleAvatar(radius: 50, child: Text(userName.isNotEmpty ? userName[0] : '', style: const TextStyle(fontSize: 40))),
              const SizedBox(height: 16),
              Text(userName, textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
              Text(userEmail, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey.shade600)),
              const Divider(height: 32),
              ListTile(leading: const Icon(Icons.settings_outlined), title: const Text('Settings'), onTap: () { /* TODO: Navigate to Settings screen */ }),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                   // The AuthWrapper will handle navigation
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

