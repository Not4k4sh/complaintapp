import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeProvider extends ChangeNotifier{
   bool isSidebarOpen = false;
   String filter = "All";

   QueryDocumentSnapshot<Object?>? complaint;

   void sidebarFunction(){
    isSidebarOpen = !isSidebarOpen;
    notifyListeners();
   }

   void closeSideBar(){
    isSidebarOpen = false;
    notifyListeners();
   }



   void setComplaint(QueryDocumentSnapshot<Object?> data){
complaint = data;
notifyListeners();
   }

   void setFilter(String value){
     filter = value;
     notifyListeners();
   }
}