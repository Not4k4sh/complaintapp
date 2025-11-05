import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_app/models/complaint_form.dart';

class ComplaintService {
  final CollectionReference complaints = FirebaseFirestore.instance.collection('complaints');

  // Add a new complaint
  Future<void> addComplaint(String userId, String department, String title, String description) async {
    await complaints.add({
      'userId': userId,
      'department': department,
      'title': title,
      'description': description,
      'status': 'Pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Get complaints by user
  Stream<QuerySnapshot> getUserComplaints(String userId) {
    return complaints.where('userId', isEqualTo: userId).snapshots();
  }

  // Get all complaints for Admin
  Stream<QuerySnapshot> getAllComplaints() {
    return complaints.snapshots();
  }

  // Update complaint status (Admin or Officer)
  Future<void> updateComplaintStatus(String complaintId, String status) async {
    await complaints.doc(complaintId).update({'status': status});
  }

  // Forward complaint to department
  Future<void> forwardComplaintToDepartment(String complaintId, String officerId) async {
    await complaints.doc(complaintId).update({
      'officerId': officerId,
      'status': 'Forwarded',
    });
  }

 Future<ComplaintForm?> fetchComplaintForm(String department) async {
  final doc = await FirebaseFirestore.instance
      .collection('complaintForm')
      .doc(department) // Use dynamic department value
      .get();

  print(department);

  print(doc.exists);

  if (doc.exists) {
    return ComplaintForm.fromMap(doc.data()!);
  } else {
    return null; // No predefined form, fallback to manual form
  }
}


}
