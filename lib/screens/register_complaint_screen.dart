

import 'package:complaint_app/models/complaint_form.dart';
import 'package:complaint_app/services/complaint_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';

class RegisterComplaintScreen extends StatefulWidget {
  final String name;
  final String department;
  const RegisterComplaintScreen(
      {Key? key, required this.name, required this.department})
      : super(key: key);

  @override
  _RegisterComplaintScreenState createState() =>
      _RegisterComplaintScreenState();
}

class _RegisterComplaintScreenState extends State<RegisterComplaintScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _customComplaintController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AnimationController _animationController;
  late Animation<double> _animation;

  String? selectedDepartment;
  String? selectedTemplate;
  String complaintText = "";
  bool _isSubmitting = false;

  ComplaintForm? complaintForm;
  bool isLoading = true;
  final Map<String, TextEditingController> controllers = {};

  final Map<String, List<String>> complaintTemplates = {
    "Water Authority": [
      "No Water Supply",
      "Leakage in Water Line",
      "Low Water Pressure",
      "Water Quality Issue",
      "Water Meter Problem",
      "Other"
    ],
    "Electricity Board": [
      "Power Outage",
      "Electricity Bill Issue",
      "Street Light Not Working",
      "Voltage Fluctuation",
      "Damaged Electric Pole",
      "Other"
    ],
    "Transport Department": [
      "Road Damage",
      "Traffic Signal Not Working",
      "Illegal Parking",
      "Public Transport Delay",
      "Overloaded Vehicles",
      "Accident Spot Reporting",
      "Encroachment on Roads",
      "Street Sign Missing/Damaged",
      "Drainage Blockage on Roads",
      "Other"
    ],

   
   
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubic,
    );
    _animationController.forward();

    setState(() {
      selectedDepartment = widget.department;
      _nameController.text = widget.name;
    });
    loadForm(selectedDepartment.toString());
  }

  void loadForm(String dept) async {
    ComplaintForm? form = await ComplaintService().fetchComplaintForm(dept);

    setState(() {
      complaintForm = form;
      isLoading = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _customComplaintController.dispose();
    super.dispose();
  }


void _submitComplaint() async {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  setState(() {
    _isSubmitting = true;
  });

  User? user = _auth.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("User not logged in")));
    setState(() {
      _isSubmitting = false;
    });
    return;
  }

  // Validate complaintForm
  if (complaintForm == null || complaintForm!.fields.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Complaint form is empty")),
    );
    setState(() {
      _isSubmitting = false;
    });
    return;
  }

  // Collect form data safely
  List<Map<String, String>> formData = complaintForm!.fields.map((field) {
    return {
      "label": field.label,
      "value": controllers[field.label]?.text.trim() ?? "",
    };
  }).toList();

  try {
    DocumentReference complaintRef = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection("complaints")
        .add({
      'userId': user.uid,
      'name': _nameController.text.trim(),
      'location': _locationController.text.trim(),
      'department': selectedDepartment,
      'complaint': complaintText.isNotEmpty
          ? complaintText
          : _customComplaintController.text.trim(),
      'status': 'Pending',
      'priority': 'Medium',
      'timestamp': Timestamp.now(),
      'fields': formData,
    });

    String complaintId = complaintRef.id;

    // Fetch officers in the selected department
    QuerySnapshot officerDocs = await _firestore
        .collection('officers')
        .where('department', isEqualTo: selectedDepartment)
        .get();

    if (officerDocs.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No officers found for this department")),
      );
    } else {
      // Store all officer complaint updates in a list
      List<Future> updateTasks = [];

      for (var officerDoc in officerDocs.docs) {
        updateTasks.add(
          _firestore
              .collection('officers')
              .doc(officerDoc.id)
              .collection("complaints")
              .doc(complaintId)
              .set({
            'userId': user.uid,
            'name': _nameController.text.trim(),
            'location': _locationController.text.trim(),
            'department': selectedDepartment,
            'complaint': complaintText.isNotEmpty
                ? complaintText
                : _customComplaintController.text.trim(),
            'status': 'Pending',
            'priority': 'Medium',
            'timestamp': Timestamp.now(),
            'fields': formData,
            'complaintId': complaintId,
          }),
        );

        // Update user complaint with officer ID
        updateTasks.add(
          _firestore
              .collection("users")
              .doc(user.uid)
              .collection("complaints")
              .doc(complaintId)
              .update({
            "officerId": officerDoc.id,
            'complaintId': complaintId,
          }),
        );
      }

      // Execute all Firestore updates in parallel
      await Future.wait(updateTasks);
    }

    HapticFeedback.mediumImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Complaint Registered Successfully"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ));

      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error: ${_getFirebaseErrorMessage(e.toString())}"),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}




// Function to map Firebase errors to user-friendly messages
  String _getFirebaseErrorMessage(String error) {
    if (error.contains('network-request-failed')) {
      return "Network error. Please check your internet connection.";
    } else if (error.contains('permission-denied')) {
      return "You don't have permission to perform this action.";
    } else {
      return "Something went wrong. Please try again.";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              // image: DecorationImage(
              //   image: NetworkImage(
              //     "https://www.shutterstock.com/image-illustration/complaints-concept-word-on-folder-260nw-269047922.jpg",
              //     )),
              gradient: LinearGradient(
                colors: [Color(0xFF1A73E8), Color(0xFFFF4081)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                isLoading == true
                    ? Center(child: CircularProgressIndicator())
                    : Expanded(
                        child: FadeTransition(
                          opacity: _animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.05),
                              end: Offset.zero,
                            ).animate(_animation),
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              width: MediaQuery.of(context).size.width > 600
                                  ? 500
                                  : MediaQuery.of(context).size.width * 0.9,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: _buildForm(),
                              ),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredefinedForm() {
    return Column(
      // padding: EdgeInsets.all(16),
      children: [
        ...complaintForm!.fields.map((field) {
          controllers[field.label] = TextEditingController();
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextFormField(
              controller: controllers[field.label],
              validator: (_) {
                if (controllers[field.label]!.text.isEmpty) {
                  return "Please enter ${field.label}";
                }
                return null;
              },
              decoration: InputDecoration(
                labelText: field.label,
                // prefixIcon: Icon(prefixIcon, color: const Color(0xFF1A73E8)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFF1A73E8), width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.red, width: 1),
                ),
                filled: true,
                fillColor: Colors.grey[50],
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),

            // TextField(
            //   controller: controllers[field.label],
            //   keyboardType: field.type == "number" ? TextInputType.number : TextInputType.text,
            //   decoration: InputDecoration(labelText: field.label),
            // ),
          );
        }).toList(),
        // SizedBox(height: 20),
        // ElevatedButton(
        //   onPressed: _submitComplaint,
        //   child: Text("Submit Complaint"),
        // )
      ],
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            "Register New Complaint",
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4081).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.support_agent,
                color: Color(0xFFFF4081),
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Submit Your Complaint",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1A73E8),
            ),
          ),
          Text(
            "Please fill in the details to register your complaint",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 32),

          // Personal Information Section
          _buildSectionHeader("Personal Information", Icons.person_outline),
          const SizedBox(height: 16),

          // Name Field
          _buildTextField(
            controller: _nameController,
            label: "Your Full Name",
            prefixIcon: Icons.person,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter your name";
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Location Field
          _buildTextField(
            controller: _locationController,
            label: "Complaint Location",
            prefixIcon: Icons.location_on_outlined,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Please enter the location";
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Complaint Details Section
          _buildSectionHeader(
              "Complaint Details", Icons.report_problem_outlined),
          const SizedBox(height: 16),

          // Department Dropdown
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("complaintForm")
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return const Center(
                    child: Text("Error loading department data"));
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Center(
                    child: Text("Department in database is empty"));
              }

              final data = snapshot.data!.docs;

              return _buildDropdown(
                value: selectedDepartment,
                hint: "Select Department",
                icon: Icons.business_outlined,
                items: data.map((doc) {
                  String departmentName =
                      doc["department"]; // Ensure correct field name
                  return DropdownMenuItem(
                    value: departmentName,
                    child: Text(departmentName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDepartment = value;
                    selectedTemplate = null;
                    complaintText = "";
                  });

                  loadForm(selectedDepartment.toString());
                },
                validator: (value) {
                  if (value == null) {
                    return "Please select a department";
                  }
                  return null;
                },
              );
            },
          ),

          const SizedBox(height: 16),
          _buildDropdown(
            value: selectedTemplate,
            hint: "Select Complaint Type",
            icon: Icons.description_outlined,
            items:
                (complaintTemplates[selectedDepartment] ?? []).map((complaint) {
              return DropdownMenuItem(
                value: complaint,
                child: Text(complaint),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedTemplate = value;
                complaintText =
                    "Complaint regarding $value at ${_locationController.text}.";
                _customComplaintController.text = complaintText;
              });
            },
          ),
          const SizedBox(height: 16),

          _buildPredefinedForm(),
          if (selectedDepartment != null) ...[
            const SizedBox(height: 16),
          ],
          // Custom Complaint TextField
          _buildTextField(
            controller: _customComplaintController,
            label: "Describe Your Complaint in Detail",
            prefixIcon: Icons.edit_note,
            maxLines: 4,
            validator: (value) {
              if ((selectedTemplate == null) &&
                  (value == null || value.isEmpty)) {
                return "Please describe your complaint";
              }
              return null;
            },
          ),
          const SizedBox(height: 32),

          // Media Attachments (Optional for future implementation)
          // _buildSectionHeader("Media Attachments (Optional)", Icons.attach_file),
          // const SizedBox(height: 16),

          // Container(
          //   padding: const EdgeInsets.all(16),
          //   decoration: BoxDecoration(
          //     color: Colors.grey[100],
          //     borderRadius: BorderRadius.circular(16),
          //     border: Border.all(color: Colors.grey[300]!),
          //   ),
          //   child: Row(
          //     children: [
          //       Container(
          //         padding: const EdgeInsets.all(12),
          //         decoration: BoxDecoration(
          //           color: Colors.white,
          //           borderRadius: BorderRadius.circular(12),
          //           border: Border.all(color: Colors.grey[300]!),
          //         ),
          //         child: const Icon(
          //           Icons.camera_alt_outlined,
          //           color: Color(0xFF1A73E8),
          //         ),
          //       ),
          //       const SizedBox(width: 16),
          //       Expanded(
          //         child: Text(
          //           "Tap to add photos or videos as evidence",
          //           style: TextStyle(
          //             color: Colors.grey[600],
          //             fontSize: 14,
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
          // const SizedBox(height: 32),

          // Submit Button
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitComplaint,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A73E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
            child: _isSubmitting
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        "Submitting...",
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  )
                : Text(
                    "SUBMIT COMPLAINT",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: const Color(0xFF1A73E8),
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A73E8),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(prefixIcon, color: const Color(0xFF1A73E8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?)? onChanged,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      validator: validator,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1A73E8)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF1A73E8), width: 2),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      hint: Text(hint),
      isExpanded: true,
      icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A73E8)),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      items: items,
      onChanged: onChanged,
    );
  }
}
