import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TripDetailsScreen extends StatefulWidget {
  final String groupId;
  final String tripId;

  const TripDetailsScreen({
    super.key,
    required this.groupId,
    required this.tripId,
  });

  @override
  State<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends State<TripDetailsScreen> {
  Future<String> _getUserName(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    return userDoc.data()?['name'] ?? 'Unknown User';
  }

  void _joinOrLeaveTrip(List<dynamic> currentPassengers) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final tripRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(widget.groupId)
        .collection('trips')
        .doc(widget.tripId);

    if (currentPassengers.contains(user.uid)) {
      tripRef.update({
        'passengers': FieldValue.arrayRemove([user.uid])
      });
    } else {
      tripRef.update({
        'passengers': FieldValue.arrayUnion([user.uid])
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('groups')
            .doc(widget.groupId)
            .collection('trips')
            .doc(widget.tripId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final tripData = snapshot.data!.data() as Map<String, dynamic>;
          final passengers = List<String>.from(tripData['passengers'] ?? []);
          final driverId = tripData['driverId'];
          final bool isPassenger = passengers.contains(currentUser?.uid);
          final bool isDriver = driverId == currentUser?.uid;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildTripInfoCard(tripData),
              const SizedBox(height: 24),
              _buildDriverCard(driverId),
              const SizedBox(height: 24),
              Text('Passengers (${passengers.length})', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
              const SizedBox(height: 16),
              if (passengers.isEmpty)
                const Text('No passengers have joined yet.')
              else
                ...passengers.map((userId) => _buildPassengerTile(userId)),
              const SizedBox(height: 32),
              if (!isDriver)
                ElevatedButton(
                  onPressed: () => _joinOrLeaveTrip(passengers),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPassenger ? Colors.red : Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text(isPassenger ? 'LEAVE TRIP' : 'JOIN TRIP', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTripInfoCard(Map<String, dynamic> tripData) {
    final tripDate = (tripData['tripDate'] as Timestamp).toDate();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.my_location, 'FROM', tripData['startPoint']),
            const Divider(height: 20),
            _buildInfoRow(Icons.flag, 'TO', tripData['destination']),
            const Divider(height: 20),
            _buildInfoRow(Icons.calendar_today, 'DATE', DateFormat('EEE, MMM d, yyyy').format(tripDate)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDriverCard(String driverId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Driver', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
        const SizedBox(height: 16),
        FutureBuilder<String>(
          future: _getUserName(driverId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(snapshot.data!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPassengerTile(String userId) {
    return FutureBuilder<String>(
      future: _getUserName(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const ListTile(title: Text("Loading..."));
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(snapshot.data!, style: const TextStyle(color: Colors.black)),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 16),
        Text('$label: ', style: TextStyle(color: Colors.grey.shade600)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
