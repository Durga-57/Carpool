import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class GroupInvitesScreen extends StatefulWidget {
  const GroupInvitesScreen({super.key});

  @override
  State<GroupInvitesScreen> createState() => _GroupInvitesScreenState();
}

class _GroupInvitesScreenState extends State<GroupInvitesScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _acceptInvite(String groupId) async {
    if (user == null) return;
    try {
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
      await groupRef.update({
        'members': FieldValue.arrayUnion([user!.uid]),
        'pendingMembers': FieldValue.arrayRemove([user!.uid])
      });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Joined group successfully!'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _rejectInvite(String groupId) async {
    if (user == null) return;
    try {
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
      await groupRef.update({'pendingMembers': FieldValue.arrayRemove([user!.uid])});
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite rejected.')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Group Invites')),
      body: user == null
          ? const Center(child: Text('Please log in to see invites.'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('groups').where('pendingMembers', arrayContains: user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.mail_outline, size: 80, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No pending invites.', style: TextStyle(fontSize: 18)),
                      ],
                    ),
                  );
                }

                final invites = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: invites.length,
                  itemBuilder: (context, index) {
                    final invite = invites[index];
                    final groupName = invite['name'] ?? 'Unnamed Group';
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        title: Text(groupName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('You have been invited to join this group.'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton(
                              onPressed: () => _rejectInvite(invite.id),
                              child: const Text('REJECT'),
                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => _acceptInvite(invite.id),
                              child: const Text('ACCEPT'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}

