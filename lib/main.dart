import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:community_disaster_hub/classes.dart';
import 'package:community_disaster_hub/history.dart';
import 'package:community_disaster_hub/posting.dart';
import 'package:flutter/material.dart';
import 'viewing.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'posting.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'posting.dart';




void main () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}


class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();

}
class _HomeState extends State<Home> {
  String? postId;
  FirebaseFirestore? firestore;
  @override



  void initState() {
    super.initState();
    firestore = FirebaseFirestore.instance;
    _checkOrCreateUserId();
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
          'userId': user.userID,
          'helped': user.helped,
        });
      }
      setState(() {
        _listenForNotficiations(postId!);
      });
    } catch (e) {
      print("Error generating User ID: $e");
    }
  }

  void _listenForNotficiations(String postId) {
    if (postId == null) return;

    FirebaseFirestore.instance
        .collection('posts')
        .doc(postId)
        .snapshots()
        .listen((doc) {
      if (doc.exists && doc.data()?['notifications'] != null) {
        List<dynamic> notifications = doc.data()?['notifications'];
        if (notifications.isNotEmpty) {
          _showNotification(notifications.last);
          FirebaseFirestore.instance.collection('posts').doc(postId).update({
            'notifications': [],
          });
        }
      }
    });
  }

  void _showNotification(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
      ),
    );
  }

  String _generateRandomString(int length) {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    Random random = Random();
    return String.fromCharCodes(
      List.generate(
          length, (index) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Stack(
          children: [
            // Background Image
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("assets/images/VIEW.png"),
                  fit: BoxFit.cover,
                ),
              ),
            ),


            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 280),

                ),

                SizedBox(height: 50),

                // Buttons
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 190),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (context) => Viewing()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.visibility, color: Colors.black),
                            SizedBox(width: 10),
                            Text("View"),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (context) => PostingScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upload, color: Colors.black), // 📤 Upload icon
                            SizedBox(width: 10),
                            Text("Post"),
                          ],
                        ),
                      ),

                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context, rootNavigator: true).push(
                            MaterialPageRoute(builder: (context) => HistoryScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(horizontal: 70, vertical: 15),
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 5,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history, color: Colors.black),
                            SizedBox(width: 10),
                            Text("History"),
                          ],
                        ),
                      ),

                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}