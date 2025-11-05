import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageComplaintsScreen extends StatefulWidget {
  @override
  _ManageComplaintsScreenState createState() => _ManageComplaintsScreenState();
}

class _ManageComplaintsScreenState extends State<ManageComplaintsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _deleteComplaint(String complaintId) async {
    await _firestore.collection('complaints').doc(complaintId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Manage Complaints')),
      body: StreamBuilder(
        stream: _firestore.collection('complaints').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No complaints available'));
          }

          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var complaint = doc.data() as Map<String, dynamic>;
              return ListTile(
                title: Text(complaint['title'] ?? 'No Title'),
                subtitle: Text(complaint['description'] ?? 'No Description'),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteComplaint(doc.id),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}