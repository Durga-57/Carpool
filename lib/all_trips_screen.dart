import 'package:carpool_app/groups_screen.dart';
import 'package:carpool_app/trip_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add intl package to pubspec.yaml

// Data model for a Trip
class Trip {
  final String id;
  final String groupId;
  final String groupName;
  final String startPoint;
  final String destination;
  final DateTime tripDate;

  Trip({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.startPoint,
    required this.destination,
    required this.tripDate,
  });
}

class AllTripsScreen extends StatefulWidget {
  const AllTripsScreen({super.key});

  @override
  State<AllTripsScreen> createState() => _AllTripsScreenState();
}

class _AllTripsScreenState extends State<AllTripsScreen> {
  // This function fetches groups, then fetches trips for each group.
  Future<List<Trip>> _fetchUpcomingTrips() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    // 1. Get all groups the user is a member of
    final groupsSnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .get();

    final List<Trip> allTrips = [];

    // 2. For each group, fetch its upcoming trips
    for (var groupDoc in groupsSnapshot.docs) {
      final tripsSnapshot = await groupDoc.reference
          .collection('trips')
          .where('tripDate', isGreaterThan: Timestamp.now())
          .get();

      for (var tripDoc in tripsSnapshot.docs) {
        final tripData = tripDoc.data();
        allTrips.add(
          Trip(
            id: tripDoc.id,
            groupId: groupDoc.id,
            groupName: groupDoc.data()['groupName'] ?? 'Unknown Group',
            startPoint: tripData['startPoint'] ?? 'N/A',
            destination: tripData['destination'] ?? 'N/A',
            tripDate: (tripData['tripDate'] as Timestamp).toDate(),
          ),
        );
      }
    }

    // 3. Sort all trips by date
    allTrips.sort((a, b) => a.tripDate.compareTo(b.tripDate));

    return allTrips;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: FutureBuilder<List<Trip>>(
        future: _fetchUpcomingTrips(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState(context);
          }

          final trips = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Upcoming Trips', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black)),
                    ElevatedButton.icon(
                      onPressed: () {
                        // To create a trip, user must first select a group
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) => const GroupsScreen()));
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Schedule New'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: trips.length,
                  itemBuilder: (context, index) {
                    return _TripCard(trip: trips[index]);
                  },
                ),
              ),
            ],
          );
        },
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
          Text(
            'No Upcoming Trips',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 8),
          Text(
            'Schedule a new trip in one of your groups.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

// A reusable card to display trip information
class _TripCard extends StatelessWidget {
  final Trip trip;
  const _TripCard({required this.trip});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TripDetailsScreen(
                groupId: trip.groupId,
                tripId: trip.id,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                trip.groupName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${trip.startPoint} to ${trip.destination}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEE, MMM d, yyyy \'at\' h:mm a').format(trip.tripDate),
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
