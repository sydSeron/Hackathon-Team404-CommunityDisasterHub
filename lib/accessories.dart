import 'dart:io';
import 'dart:math';
import 'classes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class checkID {
  FirebaseFirestore? firestore;

  Future<String> checkOrCreateUniqueIdFile() async {
    try {
      // Request storage permission
      var status = await Permission.storage.request();
      if (!status.isGranted) {
        print("Storage permission is required to proceed.");
        return "";
      }

      // Get the Downloads directory
      final Directory? downloadsDir = Directory('/storage/emulated/0/Download');
      if (downloadsDir == null || !downloadsDir.existsSync()) {
        print("Downloads folder not found!");
        return "";
      }

      // Define the file path
      final String filePath = '${downloadsDir.path}/cdh_id.txt';

      // Check if the file exists
      final File file = File(filePath);
      if (file.existsSync()) {
        print("File already exists: ${file.path}");
        // Read the content if needed
        final content = await file.readAsString();
        print("File Content: $content");
        return content;

      } else {
        // File doesn't exist, create it and write a unique ID
        String random = generateRandomString(20);
        String uniqueId = random;
        await file.writeAsString(uniqueId);
        print("Unique ID file created at: ${file.path}");

        User user = User(userID: uniqueId);
        await firestore?.collection('users').add({
          'userId': user.userID,
          'helped': user.helped
        });
        return uniqueId;
      }
    } catch (e) {
      print("An error occurred: $e");
    }

    return "";
  }
}

String generateRandomString(int length) {
  const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  Random random = Random();

  return List.generate(
      length, (index) => characters[random.nextInt(characters.length)])
      .join();
}