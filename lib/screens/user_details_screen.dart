import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_app/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class UserDetailsScreen extends StatefulWidget {
  final String id;
  const UserDetailsScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<UserDetailsScreen> createState() => _UserDetailsScreenState();
}

class _UserDetailsScreenState extends State<UserDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(widget.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }

            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            }

            if (snapshot.data == null) {
              return Center(
                child: Text('No data found'),
              );
            }

            final userData = snapshot.data;
            print(userData!["name"]);

            return Row(
              children: [
                // Sidebar
                Container(
                  width: 300,
                  color: Color(0xFF2C3E50),
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 70,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        userData["name"],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      _buildSidebarInfo('Email', userData["email"]),
                      SizedBox(height: 20),
                    ],
                  ),
                ),

                // Main Content
                Expanded(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        color: Colors.white,
                        padding:
                            EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User Complaint History',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2C3E50),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Complaints List
                      StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(widget.id)
                              .collection("complaints")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (!snapshot.hasData) {
                              return Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            if (snapshot.hasError) {
                              return Center(
                                child: Text('Error: ${snapshot.error}'),
                              );
                            }

                            if (snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text("No complaints found."),
                              );
                            }

                            return Expanded(
                              child: ListView(
                                padding: EdgeInsets.all(20),
                                children: List.generate(
                                  snapshot.data!.docs.length,
                                  (index) {
                                    final complaintData =
                                        snapshot.data!.docs[index];
                                    return _buildComplaintCard(
                                        complaintData: complaintData);
                                  },
                                ),
                              ),
                            );
                          }),
                    ],
                  ),
                ),
              ],
            );
          }),
    );
  }

  Widget _buildSidebarInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildComplaintCard(
      {required QueryDocumentSnapshot<Object?> complaintData}) {
    Color statusColor = _getStatusColor(complaintData["status"]);
    Color priorityColor = _getPriorityColor(complaintData["priority"]);

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    complaintData["department"] ?? "Department",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Status Chip
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    complaintData["status"],
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: complaintData["fields"].map<Widget>((field) {
                return _buildDetailItem(field['label'], field['value']);
              }).toList(),
            ),

            SizedBox(height: 15),
            // Timestamp
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Logged: ${DateFormat.yMMMd().format(complaintData['timestamp'].toDate())}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        updateStatusDialogue(
                          complaintId: complaintData['complaintId'],
                          userId: complaintData['userId'],
                          officerId: complaintData["officerId"]
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade400,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        'Update Status',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void updateStatusDialogue(
      {required String complaintId, required String userId, required String officerId}) {
    String selectedStatus = ''; // Variable to store selected status

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Rounded corners
              ),
              title: Column(
                children: [
                  Icon(
                    Icons.update,
                    color: Colors.blue,
                    size: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    "Update Complaint Status",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // In Progress Status
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedStatus == "In Progress"
                          ? Colors.blue.shade50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedStatus == "In Progress"
                            ? Colors.blue
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        "In Progress",
                        style: TextStyle(
                          color: selectedStatus == "In Progress"
                              ? Colors.blue[800]
                              : Colors.black87,
                          fontWeight: selectedStatus == "In Progress"
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      secondary: Icon(
                        Icons.hourglass_bottom,
                        color: selectedStatus == "In Progress"
                            ? Colors.blue
                            : Colors.grey,
                      ),
                      value: selectedStatus == "In Progress",
                      onChanged: (bool? value) {
                        setState(() {
                          selectedStatus = value! ? "In Progress" : '';
                        });
                      },
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: Colors.blue,
                    ),
                  ),

                  // Resolved Status
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selectedStatus == "Resolved"
                          ? Colors.green.shade50
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selectedStatus == "Resolved"
                            ? Colors.green
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        "Resolved",
                        style: TextStyle(
                          color: selectedStatus == "Resolved"
                              ? Colors.green[800]
                              : Colors.black87,
                          fontWeight: selectedStatus == "Resolved"
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      secondary: Icon(
                        Icons.check_circle_outline,
                        color: selectedStatus == "Resolved"
                            ? Colors.green
                            : Colors.grey,
                      ),
                      value: selectedStatus == "Resolved",
                      onChanged: (bool? value) {
                        setState(() {
                          selectedStatus = value! ? "Resolved" : '';
                        });
                      },
                      controlAffinity: ListTileControlAffinity.trailing,
                      activeColor: Colors.green,
                    ),
                  ),
                ],
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                  ),
                  child: Text(
                    "Cancel",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),

                // Save Button
                ElevatedButton(
                  onPressed: () {
                    if (selectedStatus.isNotEmpty) {
                      _updateComplaintStatus(
                        complaintId: complaintId,
                        newStatus: selectedStatus,
                        userId: userId,
                        officerId: officerId
                      );
                      Navigator.pop(context); // Close dialog after updating
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Please select a status!"),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    "Save Changes",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }





void _updateComplaintStatus({
  required String complaintId,
  required String newStatus,
  required String userId,
   required String officerId,
}) async {
  WriteBatch batch = FirebaseFirestore.instance.batch();

  // Get current officer ID

  // Reference to officer's complaint document
  DocumentReference officerComplaintRef = FirebaseFirestore.instance
      .collection('officers')
      .doc(officerId)
      .collection('complaints')
      .doc(complaintId);

  // Reference to user's complaint document
  DocumentReference userComplaintRef = FirebaseFirestore.instance
      .collection('users')
      .doc(userId)
      .collection('complaints')
      .doc(complaintId);

  // Update status in batch
  batch.update(officerComplaintRef, {'status': newStatus});
  batch.update(userComplaintRef, {'status': newStatus});

  // Commit batch update
  await batch.commit().then((_) async {
    print("Complaint status updated successfully!");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Status updated successfully!")),
    );

    // Fetch FCM tokens of User and Officer
    String? userFcmToken;
    String? officerFcmToken;
    String complaintType = "Complaint"; // Default if type not found

    // Get user data
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (userDoc.exists) {
      userFcmToken = userDoc['fcmToken'];
    }

    // Get officer data
    DocumentSnapshot officerDoc = await FirebaseFirestore.instance
        .collection('officers')
        .doc(officerId)
        .get();

    if (officerDoc.exists) {
      officerFcmToken = officerDoc['fcmToken'];
    }

    // Get complaint type
    DocumentSnapshot complaintDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('complaints')
        .doc(complaintId)
        .get();

    if (complaintDoc.exists) {
      complaintType = complaintDoc['fields'][0]["value"] ?? "Complaint";
    }

    // Notification message
    String notificationTitle = "Complaint Updated";
    String notificationBody = "The complaint $complaintType is updated.";

    // Send notification to user
    if (userFcmToken != null && userFcmToken.isNotEmpty) {
      sendFCMNotification(userFcmToken, notificationTitle, notificationBody);
    }

    // Send notification to officer
    if (officerFcmToken != null && officerFcmToken.isNotEmpty) {
      sendFCMNotification(officerFcmToken, notificationTitle, notificationBody);
    }
  }).catchError((error) {
    print("Failed to update status: $error");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error updating status!")),
    );
  });
}






  void updateComplaintStatus(
      {required String complaintId,
      required String newStatus,
      required String officerId,
      required String userId}) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Get current officer ID
    // String officerId = FirebaseAuth.instance.currentUser!.uid;

    // Reference to officer's complaint document
    DocumentReference officerComplaintRef = FirebaseFirestore.instance
        .collection('officers')
        .doc(officerId)
        .collection('complaints')
        .doc(complaintId);

  //   // Reference to user's complaint document
    DocumentReference userComplaintRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId) // Ensure you pass the correct userId
        .collection('complaints')
        .doc(complaintId);

    // Add updates to batch
    batch.update(officerComplaintRef, {'status': newStatus});
    batch.update(userComplaintRef, {'status': newStatus});

    // Commit batch update
    await batch.commit().then((_) {
      print("Complaint status updated successfully in both collections!");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated successfully!")),
      );
    }).catchError((error) {
      print("Failed to update status: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status!")),
      );
    });
  }




  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPriorityItem(String priority, Color priorityColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Priority',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 3),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: priorityColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: priorityColor.withOpacity(0.3)),
          ),
          child: Text(
            priority,
            style: TextStyle(
              color: priorityColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Resolved':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'Pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
