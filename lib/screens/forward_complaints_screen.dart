import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForwardComplaintsScreen extends StatefulWidget {
  @override
  _ForwardComplaintsScreenState createState() => _ForwardComplaintsScreenState();
}

class _ForwardComplaintsScreenState extends State<ForwardComplaintsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void forwardComplaint(String complaintId, String department) async {
    await _firestore.collection('complaints').doc(complaintId).update({
      'status': 'Forwarded',
      'forwardedTo': department,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Complaint forwarded to $department")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forward Complaints")),
      body: StreamBuilder(
        stream: _firestore.collection('complaints').where('status', isEqualTo: 'Pending').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          final complaints = snapshot.data!.docs;
          return ListView.builder(
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              var complaint = complaints[index];
              return Card(
                margin: EdgeInsets.all(8),
                child: ListTile(
                  title: Text(complaint['title']),
                  subtitle: Text(complaint['description']),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) => forwardComplaint(complaint.id, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'Police', child: Text('Police')),
                      PopupMenuItem(value: 'Water Authority', child: Text('Water Authority')),
                      PopupMenuItem(value: 'Electricity Board', child: Text('Electricity Board')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
