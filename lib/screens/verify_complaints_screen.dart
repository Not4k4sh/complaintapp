// verify_complaints_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class VerifyComplaintsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify Complaints")),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('complaints').where('verified', isEqualTo: false).snapshots(),
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
                margin: EdgeInsets.all(10),
                child: ListTile(
                  title: Text(complaint['title']),
                  subtitle: Text(complaint['description']),
                  trailing: ElevatedButton(
                    onPressed: () {
                      FirebaseFirestore.instance.collection('complaints').doc(complaint.id).update({'verified': true});
                    },
                    child: Text("Verify"),
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
