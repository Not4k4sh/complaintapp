

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:complaint_app/controller/home_provider.dart';
import 'package:complaint_app/screens/register_complaint_screen.dart';
import 'package:complaint_app/screens/signin_screen.dart';
import 'package:complaint_app/screens/splash_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({Key? key}) : super(key: key);

  @override
  _UserHomeScreenState createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen>
    with SingleTickerProviderStateMixin {
  // bool isSidebarOpen = false;
  bool isNotificationExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
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

    _initializeFCM();
  }

  // Request notification permissions
  Future<void> requestPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User denied permission');
    }
  }


 
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
      MaterialPageRoute(builder: (context) => UserHomeScreen()),
    );
  }




  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

 
  void toggleNotifications() {
    setState(() {
      isNotificationExpanded = !isNotificationExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text("Error loading user data."),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return Scaffold(
              body: Center(
                child: Text("No user data found."),
              ),
            );
          }

          final user = snapshot.data;

          return GestureDetector(
            child: Scaffold(
              body: Stack(
                children: [
                  // Background gradient
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1A73E8), Color(0xFFFF4081)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Column(
                      children: [
                        // App Bar with glass effect
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20.0, vertical: 25.0),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.support_agent,
                                      color: Colors.white, size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    "User Complaints",
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      if (user != null) {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    RegisterComplaintScreen(
                                                      department:
                                                          user["department"],
                                                      name: user["name"],
                                                    )));
                                      }
                                    },
                                    icon: const Icon(Icons.add_circle_outline),
                                    label: const Text("Register Complaint"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1A73E8),
                                      elevation: 3,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Stack(
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.notifications,
                                            color: Colors.white),
                                        onPressed: toggleNotifications,
                                      ),
                                      Positioned(
                                        right: 0,
                                        child: Container(
                                          padding: EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            '3',
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 15),
                                  GestureDetector(
                                    onTap: toggleSidebar,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(50),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.1),
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
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Complaints list with animation
                        StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                                .collection("users")
                                .doc(FirebaseAuth.instance.currentUser!.uid)
                                .collection("complaints")
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return const Center(
                                    child: Text("Error loading complaints."));
                              }

                              if (!snapshot.hasData || snapshot.data == null) {
                                return const Center(
                                    child: Text("No complaints found."));
                              }

                              final complaintLists = snapshot.data!.docs;

                              return Expanded(
                                child: Consumer<HomeProvider>(
                                    builder: (context, provider, child) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(16),
                                    margin: EdgeInsets.only(
                                        left: provider.isSidebarOpen ? 250 : 0),
                                    child: ListView.builder(
                                      itemCount: complaintLists.length,
                                      itemBuilder: (context, index) {
                                        final complaint = complaintLists[index];
                                        // var complaintData = complaint.data() as Map<String, dynamic>;

                                        final statusTypes = [
                                          {
                                            'text': 'Pending',
                                            'color': Colors.orange
                                          },
                                          {
                                            'text': 'In Progress',
                                            'color': Colors.blue
                                          },
                                          {
                                            'text': 'Resolved',
                                            'color': Colors.green
                                          },
                                        ];

                                        final randomStatus =
                                            statusTypes[index % 3];
                                        final complaintTypes = [
                                          {
                                            'title': 'Technical Issue',
                                            'icon': Icons.computer_outlined
                                          },
                                          {
                                            'title': 'Billing Problem',
                                            'icon': Icons.receipt_outlined
                                          },
                                          {
                                            'title': 'Service Request',
                                            'icon': Icons
                                                .miscellaneous_services_outlined
                                          },
                                        ];

                                        final complaintType =
                                            complaintTypes[index % 3];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withOpacity(0.06),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: Theme(
                                              data: ThemeData(
                                                dividerColor:
                                                    Colors.transparent,
                                              ),
                                              child: ExpansionTile(
                                                backgroundColor: Colors.white,
                                                title: Container(
                                                  margin: const EdgeInsets.only(
                                                      bottom: 16),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                  ),
                                                  child: Column(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 20,
                                                                vertical: 16),
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              padding:
                                                                  const EdgeInsets
                                                                      .all(12),
                                                              decoration:
                                                                  BoxDecoration(
                                                                color: const Color(
                                                                        0xFF1A73E8)
                                                                    .withOpacity(
                                                                        0.1),
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            12),
                                                              ),
                                                              child: Icon(
                                                                  Icons
                                                                      .report_problem,
                                                                  color: const Color(
                                                                      0xFF1A73E8),
                                                                  size: 28),
                                                            ),
                                                            const SizedBox(
                                                                width: 16),
                                                            Expanded(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceBetween,
                                                                    children: [
                                                                      Text(
                                                                        complaint['department']
                                                                            .toString(),
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            fontSize: 18),
                                                                      ),
                                                                      Container(
                                                                        padding: const EdgeInsets
                                                                            .symmetric(
                                                                            horizontal:
                                                                                12,
                                                                            vertical:
                                                                                6),
                                                                        decoration:
                                                                            BoxDecoration(
                                                                          border:
                                                                              Border.all(color: Colors.grey),
                                                                          borderRadius:
                                                                              BorderRadius.circular(20),
                                                                        ),
                                                                        child:
                                                                            Text(
                                                                          complaint[
                                                                              'status'],
                                                                          style: const TextStyle(
                                                                              color: Colors.grey,
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 12),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          6),
                                                                  Text(
                                                                    complaint['fields'][0]
                                                                            [
                                                                            'value']
                                                                        .toString(),
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .w500,
                                                                        fontSize:
                                                                            16),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          4),
                                                                  Text(
                                                                    "Submitted on ${DateFormat.yMMMd().format(complaint['timestamp'].toDate())}",
                                                                    style: TextStyle(
                                                                        color: Colors.grey[
                                                                            600],
                                                                        fontSize:
                                                                            14),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 20,
                                                                vertical: 12),
                                                        decoration:
                                                            BoxDecoration(
                                                          color:
                                                              Colors.grey[50],
                                                          borderRadius:
                                                              const BorderRadius
                                                                  .only(
                                                            bottomLeft:
                                                                Radius.circular(
                                                                    16),
                                                            bottomRight:
                                                                Radius.circular(
                                                                    16),
                                                          ),
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Text(
                                                              "Priority: ${complaint['priority']}",
                                                              style: TextStyle(
                                                                color: complaint[
                                                                            'priority'] ==
                                                                        "High"
                                                                    ? Colors.red
                                                                    : complaint['priority'] ==
                                                                            "Medium"
                                                                        ? Colors
                                                                            .orange
                                                                        : Colors
                                                                            .green,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600,
                                                              ),
                                                            ),
                                                            // TextButton.icon(
                                                            //   onPressed: () {},
                                                            //   icon: const Icon(
                                                            //       Icons
                                                            //           .visibility_outlined,
                                                            //       size: 18),
                                                            //   label: const Text(
                                                            //       "View Details"),
                                                            //   style: TextButton
                                                            //       .styleFrom(
                                                            //     foregroundColor:
                                                            //         const Color(
                                                            //             0xFF1A73E8),
                                                            //   ),
                                                            // ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                children: [
                                                  Divider(
                                                    color: Colors.grey[300],
                                                    thickness: 1,
                                                    height: 1,
                                                  ),
                                                  const SizedBox(height: 16),
                                                  Column(
                                                    // mainAxisAlignment: ai,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: (complaint[
                                                                    'fields']
                                                                as List<
                                                                    dynamic>?)
                                                            ?.map((field) {
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                                    right: 8.0),
                                                            child: Chip(
                                                              side: BorderSide(
                                                                  color: Colors
                                                                      .white),
                                                              label: Text(
                                                                  "${field['label']}: ${field['value']}"),
                                                            ),
                                                          );
                                                        }).toList() ??
                                                        [],
                                                  ),
                                                  Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            right: 35,
                                                            left: 35,
                                                            bottom: 35),
                                                    child: Row(
                                                      children: [
                                                        Text(
                                                            "Description : ${complaint['complaint']}"),
                                                      ],
                                                    ),
                                                  )
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                }),
                              );
                            }),
                      ],
                    ),
                  ),

                  // Sidebar with animation
                  AnimatedBuilder(
                    animation: _animation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(-250 * (1 - _animation.value), 0),
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap:
                          () {}, // Prevents taps inside the sidebar from closing it
                      child: Container(
                        width: 250,
                        height: MediaQuery.of(context).size.height,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 15,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 40),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF1A73E8),
                                    Color(0xFF5C27FE)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomRight: Radius.circular(24),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.close,
                                            color: Colors.white),
                                        onPressed: toggleSidebar,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  const CircleAvatar(
                                    radius: 40,
                                    backgroundImage: NetworkImage(
                                        'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBwgHBgkIBwgKCgkLDRYPDQwMDRsUFRAWIB0iIiAdHx8kKDQsJCYxJx8fLT0tMTU3Ojo6Iys/RD84QzQ5OjcBCgoKDQwNGg8PGjclHyU3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3Nzc3N//AABEIAJQApwMBIgACEQEDEQH/xAAbAAEAAgMBAQAAAAAAAAAAAAAABgcDBAUCAf/EADgQAAICAQIDBAcFCAMAAAAAAAABAgMEBREGIUESMVFxEyIyUmHB0VNigZGxFCNyk6Gy4fAzQmP/xAAWAQEBAQAAAAAAAAAAAAAAAAAAAQL/xAAWEQEBAQAAAAAAAAAAAAAAAAAAARH/2gAMAwEAAhEDEQA/ALSABpkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAY8i+rGqlbkWRrrj3ykyM53GVcW44OPKa6TtfZ38kBKgQVcYah2t3VQ14bP6nVwOMMe2ShnVSo35ekj60fx6oCSg81yjZCM65RnGS3Ti90z0AAAAAAAAAAAAAAAAAAAAxZN9WNj2X3y7NcI7yZlIjxznPenAg9l/yWfHpFfqwOHrOrX6pkuc240xf7qtd0V9TnAFQAAHY4e1qzTL1XbJyxJv14vn2X7yLCjJTipxalGSTTXc0VKTngrOeRgTxbJbyofqv7j+j3IqRAAAAAAAAAAAAAAAAAAAVxxPY7Ndym/+slFfgkWOVvxNDsa7l/Gaf9EBzAAaQAAA7/BVjhrEodJ1STXlscA7/BUO1rLfu1S+RlU8AAAAAAAAAAAAAAAAAADu5kI45xXVqFWQl6lsOzv96P8Agm5o6zp0NUwJ483tL2oS92S6gVkDLk41uJfOjJg4WQezi/l4oxFAABMCYcCYrVeTlyXJ/u4/Hbm/kRnTsC/UcqOPjxbb9qW3KC8WWVg4teDiVY1O6hXHbzfVvzIrO+8AAAAAAAAAAAAAAAAAAAABp6jpmJqVXYyqu017M09pR8mRzJ4Ll2t8TNTj7t0Of5r6EqvyKMePayLa614zkkc23iXSKns8vtv/AMq5S+QVHlwdn787sfb+J/Q3MXgtJ75mY5L3KYbf1f0N9cWaTv7d38lmxTxHpNz2jmRi/C2Lj+qCN3CwsbBpVWLUq4d78W/i+psHiqyu2PapnCcfGDTPYUAAQAAAAAAAAAAAAAADna1q1OlYvpJrt2y5V1p+18fIDYz87GwKHdlWqEOnjLyXUh+pcWZV7lXgr9nq7u33zf0OLn5uRn5DvybHKb5LwivBLoa4Hu6yy6bnbZKcn1k92eACoAAYMuPkXY01PHusqkusHsSPTOLrYNV6lD0kPtYLaS811IuARa2NkU5VMbseyNlcu6UXuZSstK1TI0vI9LRLeL9ut+zNf71LC03Po1LEjkY75PlKL74PwZFbYAAAAAAAAAAAADBm5VWFi2ZF72hWt3t1+H4laalnXajlzyb360nsku6K8Ed/jfUHZkV4Fb9StduzbrJ9y/BfqRcAACpQAFAAAAAAOhoeqWaVmRtW7plyth7y+qOeCVYtiuyFtcbK5KUJJOMl1R7IvwTqDsx7MCx+tV61f8PVfn+pKCAAAAAAAAAeZyjCMpS5KK3b+HU9HP1+10aJnTjyfonFPw35fMCuszIll5V2RN7u2blz+JhALCgAKgAAAAAAAAACUjoaDlfser41re0e32J+T5FllSNtLdPZ9GWvj2emx6rftK4y/NbhWQAEAAAAAAORxa2uH8rb7v8AcgAK7ABYgACgAAAAAAAAAAD7i0NHe+k4Tf2EP7UfASkbgAI0AAI//9k='),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    user?["name"],
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    user?["email"],
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildMenuTile(
                                Icons.dashboard_outlined, "Dashboard", () {
                              final provider = Provider.of<HomeProvider>(
                                  context,
                                  listen: false);
                              provider.sidebarFunction();
                              _animationController.reverse();
                            }),
                            // _buildMenuTile(Icons.history_outlined, "Complaint History"),
                            // _buildMenuTile(Icons.notifications_outlined, "Notifications"),
                            // _buildMenuTile(Icons.settings_outlined, "Settings"),
                            const Spacer(),
                            const Divider(),
                            ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child:
                                    const Icon(Icons.logout, color: Colors.red),
                              ),
                              title: const Text(
                                "Logout",
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red,
                                ),
                              ),
                              onTap: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                prefs.clear();
                                Provider.of<HomeProvider>(context,
                                        listen: false)
                                    .closeSideBar();

                                Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => SplashScreen()),
                                    (route) => false);
                              },
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Expanded Notification Widget with animation
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    top: 80,
                    right: isNotificationExpanded ? 20 : -300,
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 280,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    "Notifications",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close),
                                    onPressed: toggleNotifications,
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            _buildNotificationItem(
                              "Complaint Resolved",
                              "Your complaint #2 has been resolved",
                              Icons.check_circle_outline,
                              Colors.green,
                              "2h ago",
                            ),
                            _buildNotificationItem(
                              "Status Updated",
                              "Complaint #3 is now in progress",
                              Icons.update,
                              Colors.blue,
                              "5h ago",
                            ),
                            _buildNotificationItem(
                              "New Response",
                              "Admin responded to your complaint #1",
                              Icons.chat_bubble_outline,
                              Colors.orange,
                              "1d ago",
                            ),
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A73E8),
                                  minimumSize: const Size(double.infinity, 45),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text("View All Notifications"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  String formatTimestamp(int timestamp) {
    DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateFormat('dd-MM.yyyy').format(date);
  }

  Widget _buildMenuTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: const Color(0xFF1A73E8)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildNotificationItem(
      String title, String message, IconData icon, Color color, String time) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }
}
