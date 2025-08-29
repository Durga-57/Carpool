import 'package:carpool_app/home_screen_v3.dart'; // Import the new Home Screen
import 'package:carpool_app/main.dart';
import 'package:carpool_app/profile_onboarding_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return ProfileCheck(userId: snapshot.data!.uid);
        }
        return const AuthScreen();
      },
    );
  }
}

class ProfileCheck extends StatelessWidget {
  final String userId;
  const ProfileCheck({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || !snapshot.data!.exists || snapshot.data!.get('name') == null) {
          return const ProfileOnboardingScreen();
        }
        // Show the new HomeScreenV3
        return const HomeScreenV3();
      },
    );
  }
}
