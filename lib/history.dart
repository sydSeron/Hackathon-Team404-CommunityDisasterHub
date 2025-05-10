import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String? userId;
  List<Map<String, dynamic>> userPosts = [];

  @override
  void initState() {
    super.initState();
    _loadUserIdAndFetchData();
  }

  Future<void> _loadUserIdAndFetchData() async {
    try {
      final Directory downloadsDir = Directory('/storage/emulated/0/Download');
      final String filePath = '${downloadsDir.path}/cdh_id.txt';
      final File file = File(filePath);

      if (!file.existsSync()) {
        print("User ID file not found!");
        return;
      }

      userId = await file.readAsString();
      print("Loaded User ID: $userId");

      if (userId != null) {
        await _fetchUserData(userId!);
      }
    } catch (e) {
      print("Error loading user ID: $e");
    }
  }

  Future<void> _fetchUserData(String userId) async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('postId', isEqualTo: userId)
          .get();

      setState(() {
        userPosts = snapshot.docs.map((doc) {
          var data = doc.data() as Map<String, dynamic>? ?? {};
          return data;
        }).toList();
      });
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  Future<void> _deletePost(int docId, int index) async {
    if (docId == null) {
      print("Error: docID is null!");
      return;
    }

    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('docId', isEqualTo: docId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.delete();
        setState(() {
          userPosts.removeAt(index);
        });
        print("Post deleted successfully.");
      } else {
        print("Error: No matching document found!");
      }
    } catch (e) {
      print("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("History"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: userPosts.isEmpty
          ? Center(child: Text("No posts found for this user."))
          : ListView.builder(
        itemCount: userPosts.length,
        itemBuilder: (context, index) {
          final post = userPosts[index];
          return Card(
            elevation: 2,
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                title: Text(
                  post['name'] ?? "No Title",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4),
                    Text(
                      post['description'] ?? "No Description",
                      style: TextStyle(fontSize: 14, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      post['location'] ?? "No Location",
                      style: TextStyle(
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                        color: Colors.blueGrey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deletePost(post['docId'], index),
                ),
              ),
            ),
          );

        },
      ),
    );
  }
}

//