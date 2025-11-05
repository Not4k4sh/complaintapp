// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_functions/cloud_functions.dart';  //

// class OfficerHomeScreen extends StatefulWidget {
//   @override
//   _OfficerHomeScreenState createState() => _OfficerHomeScreenState();
// }

// class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseFunctions _functions = FirebaseFunctions.instance;

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Officer Dashboard"),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.logout),
//             onPressed: () async {
//               await _auth.signOut();
//               Navigator.pushReplacementNamed(context, '/signin');
//             },
//           ),
//         ],
//       ),
//       body: StreamBuilder(
//         stream: _firestore.collection('complaints').where('status', isNotEqualTo: 'Resolved').snapshots(),
//         builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return Center(child: CircularProgressIndicator());
//           }
//           if (snapshot.hasError) {
//             return Center(child: Text("Error fetching complaints"));
//           }
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return Center(child: Text("No complaints assigned"));
//           }
//           return ListView(
//             children: snapshot.data!.docs.map((doc) {
//               Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
//               return Card(
//                 margin: EdgeInsets.all(10),
//                 elevation: 4,
//                 child: ListTile(
//                   title: Text("${data['title']}", style: TextStyle(fontWeight: FontWeight.bold)),
//                   subtitle: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text("Status: ${data['status']}", style: TextStyle(color: Colors.blueAccent)),
//                       Text("Department: ${data['department']}"),
//                       Text("User: ${data['userEmail'] ?? 'No email'}"),
//                     ],
//                   ),
//                   trailing: ElevatedButton(
//                     onPressed: () {
//                       _updateComplaintStatus(doc.id, data['status'], data['userEmail'] ?? '', data['title']);
//                     },
//                     child: Text("Update Status"),
//                   ),
//                 ),
//               );
//             }).toList(),
//           );
//         },
//       ),
//     );
//   }

//   void _updateComplaintStatus(String complaintId, String currentStatus, String userEmail, String complaintTitle) async {
//     if (userEmail.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error: User email missing, cannot send notification.")),
//       );
//       return;
//     }

//     String newStatus;
//     if (currentStatus == "Pending") {
//       newStatus = "In Progress";
//     } else if (currentStatus == "In Progress") {
//       newStatus = "Resolved";
//     } else {
//       return;
//     }

//     try {
//       await _firestore.collection('complaints').doc(complaintId).update({'status': newStatus});

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Status updated to $newStatus.")),
//       );

//       // Call Firebase Function to send email
//       await _functions.httpsCallable('sendEmailNotification').call({
//         "email": userEmail,
//         "title": complaintTitle,
//         "status": newStatus,
//       });

//     } catch (error) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error updating status: $error")),
//       );
//     }
//   }
// }

import 'dart:convert';

import 'package:complaint_app/controller/home_provider.dart';
import 'package:complaint_app/main.dart';
import 'package:complaint_app/screens/email_sender_screen.dart';
import 'package:complaint_app/screens/splash_screen.dart';
import 'package:complaint_app/services/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class OfficerHomeScreen extends StatefulWidget {
  @override
  _OfficerHomeScreenState createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  String _status = "Pending";
  String _priority = "High";

  late AnimationController _animationController;
  late Animation<double> _animation;

  String statusFilter = "Pending"; // Default filter option
  List<String> statusFilterOptions = [
    "All",
    "Pending",
    "In Progress",
    "Resolved"
  ];

  String priorityFilter = "Pending"; // Default filter option
  List<String> priorityFilterOptions = ["Low", "Medium", "High"];
   FirebaseMessaging messaging = FirebaseMessaging.instance;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    getFilteredComplaints(_status);

    _initializeFCM();
  }


  /// Initialize Firebase Messaging & Local Notifications
  void _initializeFCM() async {
    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ User granted permission');
    } else {
      print('❌ User denied permission');
    }

    // Get device FCM token
    String? token = await messaging.getToken();
    print("📲 FCM Token: $token");

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleNotificationClick();
      },
    );

    // Foreground Notification Handling
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground Notification: ${message.notification?.title}");
      _showNotification(message);
    });

    // Background Notification Click Handling
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("🔄 Notification Clicked (Background): ${message.notification?.title}");
      _handleNotificationClick();
    });

    // Terminated App Notification Handling
    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print("🚀 App Launched from Notification: ${message.notification?.title}");
        _handleNotificationClick();
      }
    });
  }

  /// Show Local Notification when app is in Foreground
  void _showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      message.notification?.title ?? "No Title",
      message.notification?.body ?? "No Body",
      notificationDetails,
    );
  }

  /// Handle notification click and navigate to `UserHomeScreen`
  void _handleNotificationClick() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => OfficerHomeScreen()),
    );
  }


  Stream<QuerySnapshot> getFilteredComplaints(String status) {
    CollectionReference complaints = _firestore
        .collection('officers')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection("complaints");

    Query query = complaints;

    if (status.isNotEmpty && status != "All") {
      query = query.where('status', isEqualTo: status);
    }

    // if (priority.isNotEmpty) {
    //   query = query.where('priority', isEqualTo: priority);
    // }

    return query.snapshots();
  }

  void toggleSidebar() {
    final provider = Provider.of<HomeProvider>(context, listen: false);
    provider.sidebarFunction();
    if (provider.isSidebarOpen) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Consumer<HomeProvider>(builder: (context, provider, child) {
        return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("officers")
                .doc(FirebaseAuth.instance.currentUser!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    "Error fetching officer data",
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.data() == null) {
                return Center(
                  child: Text(
                    "No officer data found",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                );
              }

              final officerData = snapshot.data;
              print(officerData!["role"]);

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade200,
                      Colors.pink.shade200,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Custom App Bar
                            Padding(
                              padding: const EdgeInsets.only(
                                  top: 16, right: 16, left: 16),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Officer Dashboard",
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Colors.black45,
                                          offset: Offset(3.0, 3.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "Complaint Management System",
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10.0,
                                          color: Colors.black45,
                                          offset: Offset(3.0, 3.0),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: () {},
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(50),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.1),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(0),
                                          child: const CircleAvatar(
                                            // radius: 20,
                                            backgroundColor: Colors.white,
                                            backgroundImage: NetworkImage(
                                                'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBwgHBgkIBwgKCgkLDRYPDQwMDRsUFRAWIB0iIiAdHx8kKDQsJCYxJx8fLT0tMTU3Ojo6Iys/RD84QzQ5OjcBCgoKDQwNGg8PGjclHyU3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3N//AABEIAJQApwMBIgACEQEDEQH/xAAbAAEAAgMBAQAAAAAAAAAAAAAABgcDBAUCAf/EADgQAAICAQIDBAcFCAMAAAAAAAABAgMEBREGIUESMVFxEyIyUmHB0VNigZGxFCNyk6Gy4fAzQmP/xAAWAQEBAQAAAAAAAAAAAAAAAAAAAQL/xAAWEQEBAQAAAAAAAAAAAAAAAAAAARH/2gAMAwEAAhEDEQA/ALSABpkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAY8i+rGqlbkWRrrj3ykyM53GVcW44OPKa6TtfZ38kBKgQVcYah2t3VQ14bP6nVwOMMe2ShnVSo35ekj60fx6oCSg81yjZCM65RnGS3Ti90z0AAAAAAAAAAAAAAAAAAAAxZN9WNj2X3y7NcI7yZlIjxznPenAg9l/yWfHpFfqwOHrOrX6pkuc240xf7qtd0V9TnAFQAAHY4e1qzTL1XbJyxJv14vn2X7yLCjJTipxalGSTTXc0VKTngrOeRgTxbJbyofqv7j+j3IqRAAAAAAAAAAAAAAAAAAAVxxPY7Ndym/+slFfgkWOVvxNDsa7l/Gaf9EBzAAaQAAA7/BVjhrEodJ1STXlscA7/BUO1rLfu1S+RlU8AAAAAAAAAAAAAAAAAADu5kI45xXVqFWQl6lsOzv96P8Agm5o6zp0NUwJ483tL2oS92S6gVkDLk41uJfOjJg4WQezi/l4oxFAABMCYcCYrVeTlyXJ/u4/Hbm/kRnTsC/UcqOPjxbb9qW3KC8WWVg4teDiVY1O6hXHbzfVvzIrO+8AAAAAAAAAAAAAAAAAAAABp6jpmJqVXYyqu017M09pR8mRzJ4Ll2t8TNTj7t0Of5r6EqvyKMePayLa614zkkc23iXSKns8vtv/AMq5S+QVHlwdn787sfb+J/Q3MXgtJ75mY5L3KYbf1f0N9cWaTv7d38lmxTxHpNz2jmRi/C2Lj+qCN3CwsbBpVWLUq4d78W/i+psHiqyu2PapnCcfGDTPYUAAQAAAAAAAAAAAAAADna1q1OlYvpJrt2y5V1p+18fIDYz87GwKHdlWqEOnjLyXUh+pcWZV7lXgr9nq7u33zf0OLn5uRn5DvybHKb5LwivBLoa4Hu6yy6bnbZKcn1k92eACoAAYMuPkXY01PHusqkusHsSPTOLrYNV6lD0kPtYLaS811IuARa2NkU5VMbseyNlcu6UXuZSstK1TI0vI9LRLeL9ut+zNf71LC03Po1LEjkY75PlKL74PwZFbYAAAAAAAAAAAADBm5VWFi2ZF72hWt3t1+H4laalnXajlzyb360nsku6K8Ed/jfUHZkV4Fb9StduzbrJ9y/BfqRcAACpQAFAAAAAAOhoeqWaVmRtW7plyth7y+qOeCVYtiuyFtcbK5KUJJOMl1R7IvwTqDsx7MCx+tV61f8PVfn+pKCAAAAAAAAAeZyjCMpS5KK3b+HU9HP1+10aJnTjyfonFPw35fMCuszIll5V2RN7u2blz+JhALCgAKgAAAAAAAAACUjoaDlfser41re0e32J+T5FllSNtLdPZ9GWvj2emx6rftK4y/NbhWQAEAAAAAAORxa2uH8rb7v8AcgAK7ABYgACgAAAAAAAAAAD7i0NHe+k4Tf2EP7UfASkbgAI0AAI//9k='),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 15,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.pink.shade300,
                                              Colors.blue.shade300
                                            ],
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 10,
                                              offset: Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: IconButton(
                                          icon: Icon(Icons.logout,
                                              color: Colors.white),
                                          onPressed: () async {
                                            await _auth.signOut();
                                            final prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            prefs.clear();

                                            Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                    builder: (context) =>
                                                        SplashScreen()),
                                                (route) => false);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${officerData["department"]} ",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      DropdownButton<String>(
                                        value: provider.filter,
                                        borderRadius: BorderRadius.circular(15),
                                        icon: Icon(Icons.arrow_drop_down),
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 16),
                                        underline: Container(
                                          height: 2,
                                          color: Colors
                                              .blue, // Customize the underline color
                                        ),
                                        onChanged: (String? newValue) {
                                          Provider.of<HomeProvider>(context,
                                                  listen: false)
                                              .setFilter(newValue!);
                                          getFilteredComplaints(
                                              provider.filter);
                                        },
                                        items: statusFilterOptions
                                            .map<DropdownMenuItem<String>>(
                                                (String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            ),

                            // Complaints List
                            Expanded(
                              child: StreamBuilder(
                                stream: getFilteredComplaints(provider.filter),
                                builder: (context,
                                    AsyncSnapshot<QuerySnapshot> snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                        child:
                                            Text("Error fetching complaints"));
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.docs.isEmpty) {
                                    return Center(
                                        child: Text("No complaints found"));
                                  }

                                  return ListView(
                                    children:
                                        snapshot.data!.docs.map((complaint) {
                                      return AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                        margin: EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 15),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.blue.shade50,
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(15),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.blue.shade100
                                                  .withOpacity(0.5),
                                              spreadRadius: 2,
                                              blurRadius: 10,
                                              offset: Offset(0, 5),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Header with Name and Priority
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      complaint["name"],
                                                      style:
                                                          GoogleFonts.poppins(
                                                        fontSize: 20,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors
                                                            .blue.shade800,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5),
                                                    decoration: BoxDecoration(
                                                      color: _getPriorityColor(
                                                          complaint[
                                                              "priority"]),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      complaint["priority"],
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SizedBox(height: 15),

                                              // Complaint Details
                                              _buildDetailRow(
                                                icon: Icons.location_on,
                                                label: "Location",
                                                value: complaint["location"],
                                              ),
                                              _buildDetailRow(
                                                icon: Icons.calendar_today,
                                                label: "Submitted On",
                                                value: DateFormat.yMMMd()
                                                    .format(
                                                        complaint['timestamp']
                                                            .toDate()),
                                              ),

                                              // Status Row
                                              SizedBox(height: 10),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  // Status Indicator
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 6),
                                                    decoration: BoxDecoration(
                                                      color: _getStatusColor(
                                                          complaint["status"]),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                    ),
                                                    child: Text(
                                                      complaint["status"],
                                                      style:
                                                          GoogleFonts.poppins(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),

                                                  Row(
                                                    children: [
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          Navigator.push(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          EmailSenderScreen()));
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              Colors.purple,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 10),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.visibility,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Text(
                                                              "Send Email",
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 15,
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          updateStatusDialogue(
                                                              complaintId:
                                                                  complaint[
                                                                      'complaintId'],
                                                              userId: complaint[
                                                                  'userId']);
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              Colors.blue
                                                                  .shade400,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 10),
                                                        ),
                                                        child: Text(
                                                          "Update Status",
                                                          style: GoogleFonts
                                                              .poppins(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(
                                                        width: 15,
                                                      ),
                                                      ElevatedButton(
                                                        onPressed: () {
                                                          // _buildDetailBottomSheet(complaint: complaint);
                                                          Provider.of<HomeProvider>(
                                                                  context,
                                                                  listen: false)
                                                              .setComplaint(
                                                                  complaint);
                                                          toggleSidebar();
                                                        },
                                                        style: ElevatedButton
                                                            .styleFrom(
                                                          foregroundColor:
                                                              Colors.white,
                                                          backgroundColor:
                                                              Colors.purple
                                                                  .shade400,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                          ),
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      20,
                                                                  vertical: 10),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .center,
                                                          children: [
                                                            Icon(
                                                              Icons.visibility,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                            const SizedBox(
                                                              width: 5,
                                                            ),
                                                            Text(
                                                              "View Details",
                                                              style: GoogleFonts
                                                                  .poppins(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
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
                                    }).toList(),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      provider.isSidebarOpen == true
                          ? _buildDetailBottomSheet(
                              complaint: provider.complaint)
                          : const SizedBox.shrink()
                    ],
                  ),
                ),
              );
            });
      }),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red.shade600;
      case 'medium':
        return Colors.orange.shade600;
      case 'low':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _buildDetailRow(
      {required IconData icon, required String label, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.blue.shade600,
              size: 20,
            ),
          ),
          SizedBox(width: 12),

          // Label and Value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComplaintCard(String docId, Map<String, dynamic> data) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white70, Colors.white54],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        title: Text(
          "${data['title']}",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Status: ${data['status']}",
              style: GoogleFonts.poppins(
                color: _getStatusColor(data['status']),
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              "Department: ${data['department']}",
              style: GoogleFonts.poppins(),
            ),
            Text(
              "User: ${data['userEmail'] ?? 'No email'}",
              style: GoogleFonts.poppins(),
            ),
          ],
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.transparent,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Colors.blue.shade300),
            ),
            elevation: 5,
            shadowColor: Colors.blue.shade100,
          ),
          onPressed: () {
            updateStatusDialogue(complaintId: docId, userId: data['userId']);
          },
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "Update Status",
              style: GoogleFonts.poppins(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange.shade700;
      case 'In Progress':
        return Colors.blue.shade700;
      case 'Resolved':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  void updateStatusDialogue(
      {required String complaintId, required String userId}) {
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
                      updateComplaintStatus(
                        complaintId: complaintId,
                        newStatus: selectedStatus,
                        userId: userId,
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

  void updateComplaintStatus(
      {required String complaintId,
      required String newStatus,
      required String userId}) async {
    WriteBatch batch = FirebaseFirestore.instance.batch();

    // Get current officer ID
    String officerId = FirebaseAuth.instance.currentUser!.uid;

    // Reference to officer's complaint document
    DocumentReference officerComplaintRef = FirebaseFirestore.instance
        .collection('officers')
        .doc(officerId)
        .collection('complaints')
        .doc(complaintId);

    // Reference to user's complaint document
    DocumentReference userComplaintRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId) // Ensure you pass the correct userId
        .collection('complaints')
        .doc(complaintId);

    // Add updates to batch
    batch.update(officerComplaintRef, {'status': newStatus});
    batch.update(userComplaintRef, {'status': newStatus});

    // Commit batch update
    await batch.commit().then((_) async {
      Provider.of<HomeProvider>(context, listen: false).closeSideBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Status updated successfully!")),
      );

      // Fetch User FCM Token
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

          DocumentSnapshot complaintDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('complaints')
        .doc(complaintId)
        .get();

      if (userDoc.exists && userDoc.data() != null  && complaintDoc.exists) {
        String? userFcmToken = userDoc['fcmToken'];
        String complaintType = complaintDoc['fields'][0]["value"] ?? 'Complaint';

        print("tttttt   $userFcmToken");

        if (userFcmToken != null && userFcmToken.isNotEmpty) {
          // sendPushNotification(userFcmToken, newStatus);
          sendFCMNotification(userFcmToken, "Updated Status From ${complaintDoc["department"] ?? "Department"}", 
          "The complaint $complaintType is updated");
        }
      }
    }).catchError((error) {
      print("Failed to update status: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status!")),
      );
    });
  }

  Future<void> sendFCMNotification(String token, String title, String body) async {
  String? accessToken = await getAccessToken();
  if (accessToken == null) return;

  print("fff $token");

  final url = "https://fcm.googleapis.com/v1/projects/hello-b441f/messages:send";
  
  final payload = {
    "message": {
      "token": token, // Receiver's FCM Token
      "notification": {
        "title": title,
        "body": body
      },
      "android": {
        "priority": "high"
      },
      "apns": {
        "payload": {
          "aps": {
            "content-available": 1
          }
        }
      }
    }
  };

  final response = await http.post(
    Uri.parse(url),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $accessToken",
    },
    body: json.encode(payload),
  );

  if (response.statusCode == 200) {
    print("Notification Sent Successfully!");
  } else {
    print("Failed to Send Notification: ${response.body}");
  }
}


  void sendPushNotification(String fcmToken, String newStatus) async {
    try {
      const String serverKey =
          'YOUR_SERVER_KEY_HERE'; 
      const String fcmUrl = 'https://fcm.googleapis.com/fcm/send';

      final Map<String, dynamic> notificationPayload = {
        "to": fcmToken,
        "notification": {
          "title": "Complaint Status Updated",
          "body": "Your complaint status has been changed to $newStatus",
          "sound": "default"
        },
        "data": {
          "click_action": "FLUTTER_NOTIFICATION_CLICK",
          "status": newStatus,
          "complaint_id": "complaintId"
        }
      };

      final response = await http.post(
        Uri.parse(fcmUrl),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Authorization": "key=$serverKey",
        },
        body: jsonEncode(notificationPayload),
      );

      if (response.statusCode == 200) {
        print("Notification sent successfully!");
      } else {
        print("Error sending notification: ${response.body}");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  Widget _buildDetailBottomSheet({QueryDocumentSnapshot? complaint}) {
    // Convert timestamp to readable format

    if (complaint != null) {
      String formattedDate = complaint['timestamp'] != null
          ? DateFormat('dd MMM yyyy, hh:mm a')
              .format(complaint['timestamp'].toDate())
          : 'Not available';
    }

    return complaint != null
        ? AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(250 * (1 - _animation.value), 0),
                child: child,
              );
            },
            child: Container(
              // height: MediaQuery.of(context).size.height * 0.95,
              width: MediaQuery.of(context).size.width * 0.5,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Handle
                    Container(
                      width: 50,
                      height: 6,
                      margin: EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),

                    // Title and Priority
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                InkWell(
                                    onTap: () {
                                      Provider.of<HomeProvider>(context,
                                              listen: false)
                                          .closeSideBar();
                                    },
                                    child: Icon(Icons.arrow_back)),
                                Text(
                                  complaint['department'] ?? 'No Title',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(
                                  complaint['priority'] ?? 'Low'),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              complaint['priority'] ?? 'Low',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Complaint Details
                    SingleChildScrollView(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Status and Department
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                      complaint['status'] ?? 'Pending'),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  complaint['status'] ?? 'Pending',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                complaint['department'] ?? 'Not Specified',
                                style: GoogleFonts.poppins(
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 20),

                          // Dynamic Fields
                          ..._buildDynamicFields(complaint['fields'] ?? []),

                          // Additional Details
                          _buildDetailRow(
                            icon: Icons.person,
                            label: 'Complainant Name',
                            value: complaint['name'] ?? 'Not Provided',
                          ),
                          _buildDetailRow(
                            icon: Icons.location_on,
                            label: 'Location',
                            value: complaint['location'] ?? 'Not Specified',
                          ),
                          _buildDetailRow(
                            icon: Icons.calendar_today,
                            label: 'Submitted On',
                            value: DateFormat.yMMMd()
                                .format(complaint['timestamp'].toDate()),
                          ),
                          _buildDetailRow(
                            icon: Icons.description,
                            label: 'Description',
                            value: complaint['complaint'],
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              print(complaint['complaintId']);
                              updateStatusDialogue(
                                  complaintId: complaint["complaintId"],
                                  userId: complaint['userId']);
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
                          const SizedBox(
                            width: 15,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EmailSenderScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade400,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: Text(
                              'Send Email',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : Text("Error");
  }

// Helper method to build dynamic fields
  List<Widget> _buildDynamicFields(List<dynamic> fields) {
    return fields.map((field) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field['label'] ?? 'Unnamed Field',
              style: GoogleFonts.poppins(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              field['value'] ?? 'Not Provided',
              style: GoogleFonts.poppins(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            Divider(color: Colors.grey.shade300),
          ],
        ),
      );
    }).toList();
  }
}
