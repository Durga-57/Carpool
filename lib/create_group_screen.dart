import 'package:carpool_app/groups_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _carCapacityController = TextEditingController();
  final _carMileageController = TextEditingController();
  final _fuelCostController = TextEditingController();
  final _inviteController = TextEditingController();

  final List<String> _invitedMemberEmails = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _groupNameController.dispose();
    _carCapacityController.dispose();
    _carMileageController.dispose();
    _fuelCostController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _addInvitee() {
    if (_inviteController.text.isNotEmpty && !_invitedMemberEmails.contains(_inviteController.text.trim())) {
      setState(() {
        _invitedMemberEmails.add(_inviteController.text.trim());
        _inviteController.clear();
      });
    }
  }

  void _removeInvitee(String email) {
    setState(() {
      _invitedMemberEmails.remove(email);
    });
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      // Find UIDs for invited emails
      List<String> pendingMemberIds = [];
      for (String email in _invitedMemberEmails) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          pendingMemberIds.add(querySnapshot.docs.first.id);
        } else {
          // Optionally, handle cases where email is not found
          print("User with email $email not found.");
        }
      }

      await FirebaseFirestore.instance.collection('groups').add({
        'name': _groupNameController.text.trim(),
        'carCapacity': int.tryParse(_carCapacityController.text) ?? 4,
        'carMileage': double.tryParse(_carMileageController.text) ?? 15.0,
        'fuelCostPerLitre': double.tryParse(_fuelCostController.text) ?? 100.0,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [user.uid], // Creator is the first member
        'pendingMembers': pendingMemberIds, // Store UIDs of invitees
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Group created successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create group: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Group')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(controller: _groupNameController, decoration: const InputDecoration(labelText: 'Group Name'), validator: (val) => val!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _carCapacityController, decoration: const InputDecoration(labelText: 'Car Capacity'), keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _carMileageController, decoration: const InputDecoration(labelText: 'Car Mileage (km/l)'), keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Required' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _fuelCostController, decoration: const InputDecoration(labelText: 'Current Fuel Cost (per litre)'), keyboardType: TextInputType.number, validator: (val) => val!.isEmpty ? 'Required' : null),
            const Divider(height: 32),
            Text('Invite Members', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _inviteController, decoration: const InputDecoration(labelText: 'Member Email'))),
                IconButton(icon: const Icon(Icons.add), onPressed: _addInvitee),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _invitedMemberEmails.map((email) => Chip(label: Text(email), onDeleted: () => _removeInvitee(email))).toList(),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _createGroup,
              child: _isLoading ? const CircularProgressIndicator() : const Text('Create Group'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

