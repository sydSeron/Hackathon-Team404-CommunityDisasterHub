import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'classes.dart';

class PostingScreen extends StatefulWidget {
  @override
  _PostingScreenState createState() => _PostingScreenState();
}

class _PostingScreenState extends State<PostingScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  FirebaseFirestore? firestore;
  String userLocation = "Fetching location...";
  String? postId; // Unique user ID stored in the file

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    _getCurrentLocation();
    _checkOrCreateUserId();
  }

  void initializeFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    setState(() {
      firestore = FirebaseFirestore.instance;
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        userLocation = "Location services are disabled";
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          userLocation = "Location permission denied.";
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        userLocation = "Location permission permanently denied.";
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, position.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          userLocation = "${place.street}, ${place.locality}, ${place.country}";
        });
      } else {
        setState(() {
          userLocation = "Address not found!";
        });
      }
    } catch (e) {
      setState(() {
        userLocation = "Error getting address: $e";
      });
    }
  }

  Future<void> _checkOrCreateUserId() async {
    try {
      if (Platform.isAndroid) {
        var status = await Permission.storage.request();
        if (!status.isGranted) {
          print("Permission is not granted!");
          return;
        }
      }

      final Directory downloadsDir = Directory('/storage/emulated/0/Download');
      if (!downloadsDir.existsSync()) {
        print("Downloads folder not found!");
        return;
      }

      final String filePath = '${downloadsDir.path}/cdh_id.txt';
      final File file = File(filePath);

      if (file.existsSync()) {
        print("File already exists: ${file.path}");
        postId = await file.readAsString();
        print("Existing User ID: $postId");
      } else {
        String randomUserId = _generateRandomString(20);
        await file.writeAsString(randomUserId);
        print("New User ID generated and saved at: ${file.path}");
        postId = randomUserId;
        User user = User(userID: randomUserId);
        await firestore?.collection('users').add({
          'userId': randomUserId,
          'helped': user.helped,
        });
      }
      setState(() {});
    } catch (e) {
      print("Error generating User ID: $e");
    }
  }

  String _generateRandomString(int length) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    Random random = Random();
    return String.fromCharCodes(
      List.generate(
          length, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  void savePost() async {
    if (firestore == null || postId == null) {
      print("Firestore is not initialized or postId is null");
      return;
    }

    try {
      QuerySnapshot snapshot = await firestore!.collection('posts').orderBy('docId',descending: true).limit(1).get();
      int newDocId = snapshot.docs.isNotEmpty ? (snapshot.docs.first['docId'] as int) + 1 : 1;

      Post post = Post(
        name: nameController.text,
        location: userLocation,
        description: descriptionController.text,
        postID: postId,
        docID: newDocId,
      );

      final newPost = {
        'name': post.name,
        'location': post.location,
        'description': post.description,
        'postId': post.postID,
        'docId': post.docID,
        'responses': post.responses,
        'year': post.year,
        'month': post.month,
        'day': post.day,
        'hour': post.hour,
        'minute': post.minute,
        'notifications' : post.notifID,
      };

      // Save the post in Firestore
      await firestore!.collection('posts').add(newPost);

      setState(() {
        nameController.clear();
        descriptionController.clear();
      });

      print("Post saved with postId: $postId");
    } catch (e) {
      print("Error adding post: $e");
    }
  }

  @override

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Create a Post"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Name",
                hintText: "Enter your name",
                prefixIcon: Icon(Icons.person, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                hintText: "Write something...",
                prefixIcon: Icon(Icons.description, color: Colors.black),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.black, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              ),
            ),
            SizedBox(height: 10),
            Text("Location: $userLocation"),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: savePost,
              child: Text("Post"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: EdgeInsets.symmetric(horizontal: 90, vertical: 20),
                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.black, width: 2),
                ),
                elevation: 5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//