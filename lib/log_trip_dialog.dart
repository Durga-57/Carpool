import 'package:carpool_app/groups_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Models for the new workflow
class Member {
  final String id;
  final String name;
  Member({required this.id, required this.name});
}

class Participant {
  final String id;
  final String name;
  String? joinPoint;
  String? leavePoint;
  TextEditingController distanceController = TextEditingController();

  Participant({required this.id, required this.name});
}

class LogTripDialog extends StatefulWidget {
  final Group group;
  const LogTripDialog({super.key, required this.group});

  @override
  State<LogTripDialog> createState() => _LogTripDialogState();
}

class _LogTripDialogState extends State<LogTripDialog> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Step 1: Trip Details
  final _step1FormKey = GlobalKey<FormState>();
  DateTime _tripDate = DateTime.now();
  TimeOfDay _tripTime = TimeOfDay.now();
  final _routeController = TextEditingController();
  final _totalDistanceController = TextEditingController();

  // Step 2: Participants
  List<Member> _groupMembers = [];
  final Map<String, Participant> _participants = {};
  Participant? _driverParticipant;

  // Step 3: Costs
  final _step3FormKey = GlobalKey<FormState>();
  final _fuelCostController = TextEditingController();
  final _tollsController = TextEditingController();

  bool _isLoading = false;

  final List<String> _checkpoints = ['Hostel Gate', 'Metro Station', 'Bus Stand', 'College Library', 'College Main Gate'];

  @override
  void initState() {
    super.initState();
    _fetchGroupMembers();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _routeController.dispose();
    _totalDistanceController.dispose();
    _fuelCostController.dispose();
    _tollsController.dispose();
    _driverParticipant?.distanceController.dispose();
    for (var p in _participants.values) {
      p.distanceController.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchGroupMembers() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final groupDoc = await FirebaseFirestore.instance.collection('groups').doc(widget.group.id).get();
    final memberIds = List<String>.from(groupDoc.data()?['members'] ?? []);
    
    final List<Member> members = [];
    for (String id in memberIds) {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(id).get();
      final member = Member(id: id, name: userDoc.data()?['name'] ?? 'Unknown');
      if (id == currentUser.uid) {
        _driverParticipant = Participant(id: id, name: member.name);
      } else {
        members.add(member);
      }
    }
    setState(() {
      _groupMembers = members;
    });
  }

  void _validateAndGoToNext() {
    if (_currentPage == 0) {
      if (_step1FormKey.currentState!.validate()) {
        _goToNextPage();
      }
    } else {
      _goToNextPage();
    }
  }
  
  void _goToNextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  void _goToPreviousPage() {
    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
  }
  
  void _onParticipantSelected(bool? selected, Member member) {
    setState(() {
      if (selected == true) {
        _participants[member.id] = Participant(id: member.id, name: member.name);
      } else {
        _participants.remove(member.id)?.distanceController.dispose();
      }
    });
  }
  
  Future<void> _submitTrip() async {
    if (!_step3FormKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("User not logged in");

      final fuelCost = double.tryParse(_fuelCostController.text) ?? 0.0;
      final tollCost = double.tryParse(_tollsController.text) ?? 0.0;
      final totalCost = fuelCost + tollCost;

      final allParticipants = [_driverParticipant!, ..._participants.values];
      double totalParticipantDistance = 0;
      for (var p in allParticipants) {
        totalParticipantDistance += double.tryParse(p.distanceController.text) ?? 0.0;
      }
      
      final costPerKm = totalParticipantDistance > 0 ? totalCost / totalParticipantDistance : 0.0;

      final participantsData = allParticipants.map((p) {
        final distance = double.tryParse(p.distanceController.text) ?? 0.0;
        return {
          'userId': p.id,
          'name': p.name,
          'joinPoint': p.joinPoint,
          'leavePoint': p.leavePoint,
          'distance': distance,
          'costShare': distance * costPerKm,
        };
      }).toList();

      final tripDateTime = DateTime(_tripDate.year, _tripDate.month, _tripDate.day, _tripTime.hour, _tripTime.minute);

      await FirebaseFirestore.instance.collection('groups').doc(widget.group.id).collection('trips').add({
        'createdAt': FieldValue.serverTimestamp(),
        'driverId': user.uid,
        'driverName': _driverParticipant?.name,
        'tripDate': Timestamp.fromDate(tripDateTime),
        'route': _routeController.text,
        'totalDistance': double.tryParse(_totalDistanceController.text) ?? 0.0,
        'fuelCost': fuelCost,
        'tollCost': tollCost,
        'totalCost': totalCost,
        'participants': participantsData,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip saved successfully!'), backgroundColor: Colors.green));
        Navigator.of(context).pop();
      }
    } catch (e) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save trip: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Log New Trip', style: Theme.of(context).textTheme.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
                ],
              ),
            ),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: [
                  _buildStep1TripDetails(),
                  _buildStep2Participants(),
                  _buildStep3Costs(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
     return Container(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1),
          Expanded(child: Divider(color: _currentPage >= 1 ? Colors.green : Colors.grey.shade300, thickness: 2)),
          _buildStepCircle(2),
          Expanded(child: Divider(color: _currentPage >= 2 ? Colors.green : Colors.grey.shade300, thickness: 2)),
          _buildStepCircle(3),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step) {
    bool isActive = _currentPage + 1 >= step;
    return CircleAvatar(
      radius: 15,
      backgroundColor: isActive ? Colors.green : Colors.grey.shade300,
      child: Text('$step', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildStep1TripDetails() {
    return Form(
      key: _step1FormKey,
      child: _buildStepContainer(
        title: 'Trip Details',
        content: [
          _buildDateTimePicker(context, 'Date', DateFormat.yMMMMd().format(_tripDate), () async {
            final pickedDate = await showDatePicker(context: context, initialDate: _tripDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
            if (pickedDate != null) setState(() => _tripDate = pickedDate);
          }),
          const SizedBox(height: 16),
          _buildDateTimePicker(context, 'Time', _tripTime.format(context), () async {
            final pickedTime = await showTimePicker(context: context, initialTime: _tripTime);
            if (pickedTime != null) setState(() => _tripTime = pickedTime);
          }),
          const SizedBox(height: 16),
          _buildTextField(controller: _routeController, label: 'Route (e.g., Home -> Office)'),
          const SizedBox(height: 16),
          _buildTextField(controller: _totalDistanceController, label: 'Total Distance (km)', keyboardType: TextInputType.number),
        ],
        onNext: _validateAndGoToNext,
      ),
    );
  }

  Widget _buildStep2Participants() {
    return _buildStepContainer(
      title: 'Participants & Invites',
      content: [
        if (_driverParticipant != null)
          _ParticipantCard(
            isDriver: true,
            member: Member(id: _driverParticipant!.id, name: _driverParticipant!.name),
            isSelected: true,
            checkpoints: _checkpoints,
            onChanged: (selected) {},
            participant: _driverParticipant,
          ),
        const Divider(height: 24),
        Expanded(
          child: _groupMembers.isEmpty
              ? const Center(child: Text("No other members to invite in this group."))
              : ListView(
                  children: _groupMembers.map((member) {
                    return _ParticipantCard(
                      member: member,
                      isSelected: _participants.containsKey(member.id),
                      checkpoints: _checkpoints,
                      onChanged: (selected) => _onParticipantSelected(selected, member),
                      participant: _participants[member.id],
                    );
                  }).toList(),
                ),
        ),
      ],
      onNext: _goToNextPage,
      onBack: _goToPreviousPage,
    );
  }

  Widget _buildStep3Costs() {
     return Form(
       key: _step3FormKey,
       child: _buildStepContainer(
        title: 'Costs & Split Preview',
        content: [
          _buildTextField(controller: _fuelCostController, label: 'Fuel Cost (₹)', keyboardType: TextInputType.number),
          const SizedBox(height: 16),
          _buildTextField(controller: _tollsController, label: 'Toll Cost (₹)', keyboardType: TextInputType.number),
        ],
        onNext: _submitTrip,
        onBack: _goToPreviousPage,
        isFinalStep: true,
           ),
     );
  }

  Widget _buildStepContainer({required String title, required List<Widget> content, required VoidCallback onNext, VoidCallback? onBack, bool isFinalStep = false}) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 16),
                  ...content,
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (onBack != null) TextButton(onPressed: onBack, child: const Text('Back')),
              const Spacer(),
              ElevatedButton(
                onPressed: _isLoading ? null : onNext,
                child: _isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(isFinalStep ? 'Save Trip' : 'Next'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFinalStep ? Colors.green : Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
  
  Widget _buildTextField({required TextEditingController controller, required String label, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
      validator: (value) => (value == null || value.isEmpty) ? 'This field is required' : null,
    );
  }

  Widget _buildDateTimePicker(BuildContext context, String label, String value, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        ),
        child: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}

class _ParticipantCard extends StatelessWidget {
  final Member member;
  final bool isSelected;
  final bool isDriver;
  final List<String> checkpoints;
  final Function(bool?) onChanged;
  final Participant? participant;

  const _ParticipantCard({
    required this.member,
    required this.isSelected,
    this.isDriver = false,
    required this.checkpoints,
    required this.onChanged,
    this.participant,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade300),
      ),
      child: Column(
        children: [
          CheckboxListTile(
            title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: isDriver ? const Text('You (Driver)') : const Text('Invite to trip'),
            value: isSelected,
            onChanged: isDriver ? null : onChanged,
            activeColor: Theme.of(context).colorScheme.primary,
            controlAffinity: isDriver ? ListTileControlAffinity.leading : ListTileControlAffinity.trailing,
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildDropdown('Join Point', participant?.joinPoint, (val) => participant?.joinPoint = val)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildDropdown('Leave Point', participant?.leavePoint, (val) => participant?.leavePoint = val)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: participant!.distanceController,
                    decoration: InputDecoration(labelText: 'Distance for ${member.name} (km)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String? value, Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(labelText: label),
      items: checkpoints.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}

