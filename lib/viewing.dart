import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'classes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:io';

class Viewing extends StatefulWidget {
  const Viewing({super.key});

  @override
  State<Viewing> createState() => _ViewingState();
}

class _ViewingState extends State<Viewing> {
  FirebaseFirestore? firestore;
  String postId = "";

  @override
  void initState() {
    super.initState();
    initializeFirebase();
    _checkOrCreateUserId();
  }

  void initializeFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    setState(() {
      firestore = FirebaseFirestore.instance;
    });
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
        String newId = await file.readAsString();
        setState(() {
          postId = newId;
        });
        print("Existing User ID: $postId");
      } else {
        String randomUserId = _generateRandomString(20);
        await file.writeAsString(randomUserId);
        print("New User ID generated and saved at: ${file.path}");
        setState(() {
          postId = randomUserId;
        });

        User user = User(userID: randomUserId);
        await firestore?.collection('users').add({
          'userId': user.userID,
          'helped': user.helped,
        });
      }
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

  Future<List<Post>> fetch() async {
    if (firestore == null) {
      print("Firestore instance is null");
      return [];
    }

    List<Post> posts = [];
    QuerySnapshot querySnapshot = await firestore!.collection('posts').get();

    for (var doc in querySnapshot.docs) {
      Post post = Post(
        name: doc['name'],
        location: doc['location'],
        description: doc['description'],
        postID: doc['postId'],
        docID: doc['docId']
      );

      post.PostSet(
          doc['year'],
          doc['month'],
          doc['day'],
          doc['hour'],
          doc['minute'],
          doc['responses']
      );
      posts.add(post);
    }

    return posts;
  }
  Future<void> addResponseNotification(String postId) async {
    await FirebaseFirestore.instance.collection('posts').doc(postId).update({
      'notifications': FieldValue.arrayUnion(["Someone responded to your request"]),
    });
  }
  Future<Widget> postCard(Post post) async {
    bool helping = false;
    Color color = Colors.orange;

    QuerySnapshot<Map<String, dynamic>> currentUserSnapshot =
    await FirebaseFirestore.instance
        .collection('users')
        .where('userId', isEqualTo: postId)
        .get();

    if (currentUserSnapshot.docs.isNotEmpty) {
      List<dynamic> currentUserHelped =
          currentUserSnapshot.docs[0].get("helped") ?? [];
      if (currentUserHelped.contains(post.docID)) {
        helping = true;
        addResponseNotification(postId);
      }
    }

 //color
    color = helping ? Colors.green : Colors.black;

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Container(
        decoration: BoxDecoration(
          color: helping ? Colors.green[100] : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: helping ? Colors.green : Colors.grey),
        ),
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              post.name ?? "Unknown Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: Text(
                post.description ?? "No description",
                style: TextStyle(fontSize: 20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 5, 5, 0),
              child: Text(
                post.location ?? "Unknown location",
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 15,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
              child: Text(
                "${post.month}/${post.day}/${post.year}; ${post.hour}:${post.minute}",
                style: TextStyle(
                  color: Colors.black38,
                  fontSize: 15,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                respond(post, helping);
              },
              child: Row(
                children: [
                  Text(
                    post.responses.toString(),
                    style: TextStyle(color: color),
                  ),
                  Icon(Icons.person, color: color),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  void respond(Post post, bool helped) async {
    if (!helped) {
      //Update response count
      QuerySnapshot querySnapshotPost = (await firestore?.collection('posts')
          .where('docId', isEqualTo: post.docID ?? '')
          .get()) as QuerySnapshot<Object?>;

      if (querySnapshotPost != null && querySnapshotPost.docs.isNotEmpty) {
        await querySnapshotPost.docs[0].reference.update({
          'name': post.name,
          'location': post.location,
          'description': post.description,
          'postId': post.postID,
          'docId': post.docID,
          'responses': post.responses! + 1,
          'year': post.year,
          'month': post.month,
          'day': post.day,
          'hour': post.hour,
          'minute': post.minute
        });
      }

      // Query Firestore to find the document where userId == postId
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the first matching document (assuming there's only one)
        DocumentReference userDocRef = querySnapshot.docs.first.reference;

        // Update the "helped" array
        await userDocRef.update({
          "helped": FieldValue.arrayUnion([post.docID]) // Add new data to the array
        });

        print("Successfully updated helped array.");
      } else {
        print("No user found with userId: $postId");
      }
    }

    else {
      //Update response count
      QuerySnapshot querySnapshotPost = (await firestore?.collection('posts')
          .where('docId', isEqualTo: post.docID ?? '')
          .get()) as QuerySnapshot<Object?>;

      if (querySnapshotPost != null && querySnapshotPost.docs.isNotEmpty) {
        await querySnapshotPost.docs[0].reference.update({
          'name': post.name,
          'location': post.location,
          'description': post.description,
          'postId': post.postID,
          'docId': post.docID,
          'responses': post.responses! - 1,
          'year': post.year,
          'month': post.month,
          'day': post.day,
          'hour': post.hour,
          'minute': post.minute
        });
      }

      // Query Firestore to find the document where userId == postId
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('userId', isEqualTo: postId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // Get the first matching document reference
        DocumentReference userDocRef = querySnapshot.docs.first.reference;

        // Fetch document snapshot
        DocumentSnapshot snapshot = await userDocRef.get();

        if (snapshot.exists) {
          List<dynamic> helpedList = snapshot.get("helped") ?? []; // Get the array safely

          if (helpedList.contains(post.docID)) {
            // Remove the specific value from the array
            await userDocRef.update({
              "helped": FieldValue.arrayRemove([post.docID])
            });

            print("Successfully removed ${post.docID} from helped array.");
          } else {
            print("${post.docID} is not in the helped array.");
          }
        }
      } else {
        print("No user found with userId: $postId");
      }


    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Viewing"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {setState(() {});},
        child: Icon(Icons.refresh),
      ),
      body: firestore == null
        ? Center(child: CircularProgressIndicator())
      : SafeArea(
        child: FutureBuilder<List<Post>>(
          future: fetch(),
          builder: (context, snapshot) {
            //Needed checker to avoid redscreen while loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            // Create a list of Animal cards
            List<Future<Widget>> postCards = snapshot.data!.map((post) {
              return postCard(post);
            }).toList();
        
            return FutureBuilder<List<Widget>>(
              future: Future.wait(postCards), // Wait for all Future<Widget> to resolve
              builder: (context, AsyncSnapshot<List<Widget>> snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snap.hasError) {
                  print("Error: ${snap.error}");
                  print("Stack Trace: ${snap.stackTrace}");
                  return Center(child: Text("Error loading posts: ${snap.error}"));
                } else if (!snap.hasData || snap.data!.isEmpty) {
                  print("No posts found!");
                  return Center(child: Text("No posts available."));
                } else {
                  print("Posts loaded successfully.");
                  return SingleChildScrollView(
                    child: Column(
                      children: snap.data!,
                    ),
                  );
                }
              },
            );
          },
        ),
      ),
    );
  }
}