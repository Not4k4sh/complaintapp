import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UpdateStatusScreen extends StatefulWidget {
  final String complaintId;

  UpdateStatusScreen({required this.complaintId});

  @override
  _UpdateStatusScreenState createState() => _UpdateStatusScreenState();
}

class _UpdateStatusScreenState extends State<UpdateStatusScreen> {
  final _statusController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _updateStatus() async {
    if (_statusController.text.isEmpty) return;
    try {
      await _firestore.collection('complaints').doc(widget.complaintId).update({
        'status': _statusController.text,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Complaint status updated successfully")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: \$e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Update Complaint Status")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Enter new status:", style: TextStyle(fontSize: 18)),
            TextField(controller: _statusController, decoration: InputDecoration(hintText: "Status")),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _updateStatus,
              child: Text("Update Status"),
            ),
          ],
        ),
      ),
    );
  }
}
