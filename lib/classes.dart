class Post {
  String? name;
  String? location;
  String? description;

  String? postID;
  int? docID;
  int? responses;
  String? notifID;

  int? year;
  int? month;
  int? day;
  int? hour;
  int? minute;

  Post({this.postID, this.docID, this.name, this.location, this.description, this.notifID}) {
    responses = 0;
    final now = DateTime.now();
    year = now.year;
    month = now.month;
    day = now.day;
    hour = now.hour;
    minute = now.minute;
    notifID = "test";
  }

  PostSet(int year, int month, int day, int hour, int minute, int responses) {
    this.year = year;
    this.month = month;
    this.day = day;
    this.hour = hour;
    this.minute = minute;
    this.responses = responses;
  }
}

class User {
  String? userID;
  List<int>? helped;

  User({this.userID}) {
    helped = [];
  }


  UserSet(List<int> helped) {
    this.helped = helped;
  }
}

