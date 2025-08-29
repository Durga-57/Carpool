import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageRequestsScreen extends StatefulWidget {
  final String groupId;
  const ManageRequestsScreen({super.key, required this.groupId});

  @override
  State<ManageRequestsScreen> createState() => _ManageRequestsScreenState();
}

class _ManageRequestsScreenState extends State<ManageRequestsScreen> {

  Future<void> _handleRequest(String requesterId, bool accepted) async {
    try {
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(widget.groupId);

      if (accepted) {
        // Add to members and remove from pending
        await groupRef.update({
          'members': FieldValue.arrayUnion([requesterId]),
          'pendingMembers': FieldValue.arrayRemove([requesterId])
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Member accepted.'), backgroundColor: Colors.green));
      } else {
        // Just remove from pending
        await groupRef.update({
          'pendingMembers': FieldValue.arrayRemove([requesterId])
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request rejected.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Join Requests'),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(widget.groupId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Group not found.'));
          }

          final pendingMembers = List<String>.from(snapshot.data!.get('pendingMembers') ?? []);

          if (pendingMembers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_add_disabled_outlined, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No pending requests.', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: pendingMembers.length,
            itemBuilder: (context, index) {
              final requesterId = pendingMembers[index];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(requesterId).get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) {
                    return const ListTile(title: Text("Loading user..."));
                  }
                  final userName = userSnapshot.data?.get('name') ?? 'Unknown User';
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(userName),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(onPressed: () => _handleRequest(requesterId, false), child: const Text('REJECT', style: TextStyle(color: Colors.red))),
                          const SizedBox(width: 8),
                          ElevatedButton(onPressed: () => _handleRequest(requesterId, true), child: const Text('ACCEPT')),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
