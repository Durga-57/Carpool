import 'package:carpool_app/create_group_screen.dart';
import 'package:carpool_app/join_group_dialog.dart';
import 'package:carpool_app/log_trip_dialog.dart';
import 'package:carpool_app/groups_screen.dart';
import 'package:carpool_app/group_space_screen.dart';
import 'package:carpool_app/group_invites_screen.dart';
import 'package:carpool_app/my_profile_screen.dart';
import 'package:carpool_app/settle_up_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreenV3 extends StatefulWidget {
  const HomeScreenV3({super.key});

  @override
  State<HomeScreenV3> createState() => _HomeScreenV3State();
}

class _HomeScreenV3State extends State<HomeScreenV3> {
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _fetchUserName();
  }

  Future<void> _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists && userDoc.data()!.containsKey('name')) {
        setState(() {
          _userName = userDoc.data()!['name'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(
              child: _buildGroupsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $_userName',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const Text(
                'Here are your group commute expenses.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const GroupInvitesScreen()));
                },
                tooltip: 'Invitations',
              ),
              IconButton(
                icon: const Icon(Icons.account_circle_outlined),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const MyProfileScreen()));
                },
                tooltip: 'My Profile',
              ),
              const SizedBox(width: 10),
               OutlinedButton(
                onPressed: () {
                  showDialog(context: context, builder: (context) => const JoinGroupDialog());
                },
                child: const Text('Join Group'),
                 style: OutlinedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const CreateGroupScreen()));
                },
                icon: const Icon(Icons.add),
                label: const Text('New Group'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGroupsList() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid)
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
                Icon(Icons.group_add_outlined, size: 80, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                const Text(
                  'No Groups Yet',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                 const SizedBox(height: 8),
                Text(
                  'Create a new group or join one to get started.',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        final groups =
            snapshot.data!.docs.map((doc) => Group.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: groups.length,
          itemBuilder: (context, index) {
            final group = groups[index];
            return _GroupCard(group: group);
          },
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final Group group;
  const _GroupCard({required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shadowColor: Colors.grey.withOpacity(0.1),
      margin: const EdgeInsets.only(bottom: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F7FA),
                  child: Icon(Icons.directions_car, color: Color(0xFF00796B)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const Text("Hostel <-> College | Mon-Fri 8:30 AM",
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.group, color: Colors.grey, size: 16),
                    const SizedBox(width: 4),
                    Text(group.memberCount.toString()),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _BalanceCard(
                    title: 'You Owe',
                    amount: 584.62,
                    color: Colors.red.shade50),
                const SizedBox(width: 16),
                _BalanceCard(
                    title: 'You\'re Owed',
                    amount: 57.04,
                    color: Colors.green.shade50),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text("Last trip: 22 Jan, 02:00 PM",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const Spacer(),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                        context: context,
                        builder: (context) => LogTripDialog(group: group));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white),
                  child: const Text('Log Trip'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SettleUpScreen(group: group)));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white),
                  child: const Text('Settle Up'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => GroupSpaceScreen(group: group)));
                  },
                  child: const Text('View'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _BalanceCard(
      {required this.title, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 14, color: Colors.black.withOpacity(0.6))),
            const SizedBox(height: 4),
            Text('₹${amount.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black)),
          ],
        ),
      ),
    );
  }
}

