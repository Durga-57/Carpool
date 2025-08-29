import 'package:carpool_app/groups_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class GroupDetailsScreen extends StatelessWidget {
  final Group group;
  const GroupDetailsScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(group.id).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Group not found.'));
          }

          final groupData = snapshot.data!.data() as Map<String, dynamic>;
          final memberIds = List<String>.from(groupData['members'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildInfoSection(context, groupData),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.directions_car),
                label: const Text('MANAGE TRIPS'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TripManagementScreen(group: group),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Members (${memberIds.length})',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
              ),
              const SizedBox(height: 16),
              if (memberIds.isEmpty)
                const Center(child: Text('No members in this group yet.'))
              else
                // Removed unnecessary .toList()
                ...memberIds.map((userId) => _buildMemberTile(userId)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoSection(BuildContext context, Map<String, dynamic> groupData) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Group Info', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.black)),
            const Divider(height: 20),
            _buildInfoRow('Car Capacity:', '${groupData['carCapacity'] ?? 'N/A'}'),
            _buildInfoRow('Mileage:', '${groupData['mileage'] ?? 'N/A'} km/l'),
            _buildInfoRow('Fuel Cost:', '₹${groupData['fuelCost'] ?? 'N/A'} / litre'),
            const SizedBox(height: 16),
            const Text('Group ID', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    group.id,
                    style: const TextStyle(color: Colors.black54, fontFamily: 'monospace', fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: group.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Group ID copied to clipboard!')),
                    );
                  },
                  tooltip: 'Copy Group ID',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600)),
          Text(value, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildMemberTile(String userId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const ListTile(title: Text('Loading...'));
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>?;
        final userName = userData?['name'] ?? 'Unknown User';
        final userInitial = userName.isNotEmpty ? userName[0].toUpperCase() : '?';

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
           shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              child: Text(userInitial, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            ),
            title: Text(
              userName,
              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
