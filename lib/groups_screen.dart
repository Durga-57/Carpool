import 'package:carpool_app/create_group_screen.dart';
import 'package:carpool_app/group_space_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// The Group model now includes the createdBy field
class Group {
  final String id;
  final String name;
  final int memberCount;
  final String createdBy; // <-- ADDED THIS LINE

  Group({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.createdBy, // <-- AND THIS LINE
  });

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Group(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Group',
      memberCount: (data['members'] as List?)?.length ?? 0,
      createdBy: data['createdBy'] ?? '', // <-- AND THIS LINE
    );
  }
}

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Your Groups'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .where('members', arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off_outlined, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No Groups Yet',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
                  ),
                   const SizedBox(height: 8),
                  Text(
                    'Create or join a group to get started.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          final groups = snapshot.data!.docs.map((doc) => Group.fromFirestore(doc)).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length,
            itemBuilder: (context, index) {
              final group = groups[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(child: Text(group.name.isNotEmpty ? group.name[0] : '')),
                  title: Text(group.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${group.memberCount} members'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => GroupSpaceScreen(group: group)),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => const CreateGroupScreen()));
        },
        label: const Text('New Group'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

