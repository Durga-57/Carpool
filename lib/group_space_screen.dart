import 'package:carpool_app/log_trip_dialog.dart';
import 'package:carpool_app/groups_screen.dart';
import 'package:carpool_app/manage_requests_screen.dart';
import 'package:carpool_app/settle_up_screen.dart';
import 'package:carpool_app/trip_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GroupSpaceScreen extends StatelessWidget {
  final Group group;
  const GroupSpaceScreen({super.key, required this.group});

  void _showGroupInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(group.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Group ID:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            SelectableText(group.id),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: group.id));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group ID copied to clipboard!')));
            },
            child: const Text('Copy ID'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isOwner = currentUser?.uid == group.createdBy;

    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          if (isOwner) _ManageRequestsButton(groupId: group.id),
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => SettleUpScreen(group: group)));
            },
            icon: const Icon(Icons.payments_outlined, size: 20),
            label: const Text('Settle Up'),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showGroupInfo(context),
            tooltip: 'Group Info',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('groups').doc(group.id).collection('trips').orderBy('tripDate', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }
          final trips = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: trips.length,
            itemBuilder: (context, index) {
              final tripDoc = trips[index];
              return _TripTimelineCard(group: group, tripDoc: tripDoc);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(context: context, builder: (context) => LogTripDialog(group: group));
        },
        label: const Text('Log New Trip'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No Trips Logged Yet', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
          const SizedBox(height: 8),
          Text('Log your first trip to get started.', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

class _ManageRequestsButton extends StatelessWidget {
  final String groupId;
  const _ManageRequestsButton({required this.groupId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('groups').doc(groupId).snapshots(),
      builder: (context, snapshot) {
        final pendingCount = (snapshot.data?.data() as Map<String, dynamic>?)?['pendingMembers']?.length ?? 0;
        
        return Stack(
          alignment: Alignment.center,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (context) => ManageRequestsScreen(groupId: groupId)));
              },
              child: const Text('Requests'),
            ),
            if (pendingCount > 0)
              Positioned(
                right: 0,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text('$pendingCount', style: const TextStyle(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TripTimelineCard extends StatelessWidget {
  final Group group;
  final DocumentSnapshot tripDoc;
  const _TripTimelineCard({required this.group, required this.tripDoc});

  @override
  Widget build(BuildContext context) {
    final tripData = tripDoc.data() as Map<String, dynamic>;
    final tripDate = (tripData['tripDate'] as Timestamp).toDate();
    final bool isUpcoming = tripDate.isAfter(DateTime.now());

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => TripDetailsScreen(groupId: group.id, tripId: tripDoc.id)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    DateFormat('EEE, MMM d, yyyy').format(tripDate),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                  ),
                  const Spacer(),
                  if (isUpcoming)
                    Chip(
                      label: const Text('Upcoming'),
                      backgroundColor: Colors.blue.withAlpha(25),
                      labelStyle: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${tripData['route']}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const Divider(height: 24),
              Row(
                children: [
                  _buildInfoChip(Icons.person_outline, 'Driver: ${tripData['driverName'] ?? 'N/A'}'),
                  const SizedBox(width: 16),
                  _buildInfoChip(Icons.group_outlined, '${(tripData['participants'] as List?)?.length ?? 0} people'),
                  const SizedBox(width: 16),
                  _buildInfoChip(Icons.attach_money, '₹${(tripData['totalCost'] as num? ?? 0.0).toStringAsFixed(2)} total'),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey.shade700)),
      ],
    );
  }
}

