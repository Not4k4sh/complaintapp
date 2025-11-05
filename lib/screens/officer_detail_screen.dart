

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class OfficerDetailScreen extends StatefulWidget {
  final String id;

  OfficerDetailScreen({super.key, required this.id});

  @override
  State<OfficerDetailScreen> createState() => _OfficerDetailScreenState();
}

class _OfficerDetailScreenState extends State<OfficerDetailScreen> {
  final TextEditingController _remarksController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _remainingCharacters = 500;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('officers')
              .doc(widget.id)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text("Error loading user role."));
            }

            if (snapshot.hasError || !snapshot.hasData) {
              return Center(child: Text("Error loading user role."));
            }

            final data = snapshot.data!;

            return Row(
              children: [
                // Sidebar
                Container(
                  width: 300,
                  color: Color(0xFF2C3E50),
                  child: Column(
                    children: [
                      SizedBox(height: 50),
                      CircleAvatar(
                        radius: 80,
                        backgroundColor: Colors.white24,
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 30),
                      Text(
                        data["name"],
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        data["department"],
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                        ),
                      ),
                      SizedBox(height: 30),
                      _buildSidebarInfo('Email', data["email"]),
                      SizedBox(height: 20),
                      _buildSidebarInfo(
                          'Created At',
                          DateFormat.yMMMd()
                              .format(data['createdAt'].toDate())),
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
                              'Complaint History',
                              style: TextStyle(
                                fontSize: 32,
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
                              .collection("officers")
                              .doc(widget.id)
                              .collection("complaints")
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data == null) {
                              return Center(child: CircularProgressIndicator());
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return Center(
                                  child: Text("Error loading user role."));
                            }

                            if (snapshot.hasError || !snapshot.hasData) {
                              return Center(
                                  child: Text("Error loading user role."));
                            }

                            if (snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Text("No complaints found."),
                              );
                            }

                            return Expanded(
                              child: ListView.builder(
                                padding: EdgeInsets.all(20),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final complaint = snapshot.data!.docs[index];
                                  return _buildComplaintCard(complaint);
                                },
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
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
      ),
    );
  }

  Widget _buildComplaintCard(QueryDocumentSnapshot<Object?> complaint) {
    Color statusColor = _getStatusColor(complaint.get('status'));

    // Extract fields array from Firestore
    List fields = complaint.get('fields');
    String vehicleReg = "";
    String contactInfo = "";

    // Extract required values from fields array
    for (var field in fields) {
      if (field['label'] == "Vehicle Registration Number") {
        vehicleReg = field['value'];
      } else if (field['label'] == "Contact Information(Phone)") {
        contactInfo = field['value'];
      }
    }

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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "Complaint by: ${complaint.get('name')}",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    complaint.get('status'),
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
              children: [
                _buildDetailItem('Vehicle Reg', vehicleReg),
                _buildDetailItem('Contact', contactInfo),
                _buildDetailItem('Location', complaint.get('location')),
                _buildPriorityChip(complaint.get('priority')),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showRemarkALert(context, 
                complaintId: complaint.get("complaintId"));
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
                'Add Remarks',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  void _submitRemarks() {
    if (_formKey.currentState!.validate()) {
      Navigator.of(context).pop(_remarksController.text.trim());
    }
  }

  Future<void> updateRemarks(String complaintId, String remarks) async {
    try {

      
      
      await FirebaseFirestore.instance
          .collection('officers')
          .doc(widget.id)
          .collection('complaints')
          .doc(complaintId)
          .update({'remarks': remarks});
            Navigator.of(context).pop();

      print('Remarks updated successfully');
    } catch (e) {
      print('Error updating remarks: $e');
    }
  }

  void showRemarkALert(BuildContext context, {required String complaintId}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "widget.title",
                  style: TextStyle(
                    color: Colors.deepPurple.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade600),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Remarks Text Field
                  TextFormField(
                    controller: _remarksController,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Enter your remarks here...',
                      hintStyle: TextStyle(color: Colors.grey.shade500),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Colors.deepPurple.shade100),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.deepPurple.shade300, width: 2),
                      ),
                      counterText: '$_remainingCharacters characters remaining',
                      counterStyle: TextStyle(
                        color: _remainingCharacters >= 0
                            ? Colors.grey.shade600
                            : Colors.red,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter remarks';
                      }
                      if (value.length > 500) {
                        return 'Remarks cannot exceed 500 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Quick Remarks Section
                  Text(
                    'Quick Remarks',
                    style: TextStyle(
                      color: Colors.deepPurple.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  
                 if(_formKey.currentState!.validate()){
                   updateRemarks(complaintId, _remarksController.text.trim());
                 
                 }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: const Text(
                    'Submit',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        });
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String priority) {
    Color priorityColor = _getPriorityColor(priority);
    return Container(
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
