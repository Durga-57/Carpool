import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JoinGroupDialog extends StatefulWidget {
  const JoinGroupDialog({super.key});

  @override
  State<JoinGroupDialog> createState() => _JoinGroupDialogState();
}

class _JoinGroupDialogState extends State<JoinGroupDialog> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("You are not logged in.");

      final groupId = _controller.text.trim();
      final groupRef = FirebaseFirestore.instance.collection('groups').doc(groupId);
      
      final groupDoc = await groupRef.get();
      if (!groupDoc.exists) {
        throw Exception("No group found with that ID.");
      }

      // Add user to the 'pendingInvites' array of the group
      await groupRef.update({
        'pendingInvites': FieldValue.arrayUnion([user.uid])
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request sent! The group owner has been notified.'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Join a Group'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          decoration: const InputDecoration(
            labelText: 'Group ID',
            hintText: 'Enter the group ID here',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a Group ID';
            }
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitRequest,
          child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Send Request'),
        ),
      ],
    );
  }
}
