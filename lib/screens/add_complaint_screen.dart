import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/complaint_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddComplaintScreen extends StatefulWidget {
  @override
  _AddComplaintScreenState createState() => _AddComplaintScreenState();
}

class _AddComplaintScreenState extends State<AddComplaintScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedDepartment = "Water Department"; // Default value

  final List<String> departments = ["Water Department", "Electricity", "Roads", "Police"];

  @override
  Widget build(BuildContext context) {
    final complaintService = Provider.of<ComplaintService>(context);
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text("Register Complaint")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _selectedDepartment,
              items: departments.map((String department) {
                return DropdownMenuItem<String>(
                  value: department,
                  child: Text(department),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedDepartment = value!;
                });
              },
            ),
            TextField(controller: _titleController, decoration: InputDecoration(labelText: 'Title')),
            TextField(controller: _descriptionController, decoration: InputDecoration(labelText: 'Description')),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (user != null) {
                  await complaintService.addComplaint(
                    user.uid,
                    _selectedDepartment,
                    _titleController.text,
                    _descriptionController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: Text("Submit Complaint"),
            ),
          ],
        ),
      ),
    );
  }
}
