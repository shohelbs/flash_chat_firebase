import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/constants.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';

class ChatScreen extends StatefulWidget {
  static const String id = 'ChatScreen';
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _auth = FirebaseAuth.instance;
  final _fireStore = FirebaseFirestore.instance;
  User firebaseUser;
  bool showSpinner = false;
  String messageText;

  void getCurrentUser() {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        firebaseUser = user;
        print(user.email);
      }
    } catch (e) {
      print(e);
    }
  }

  void getMessages() async {
    final messages = await _fireStore.collection('messages').get();

    for (var message in messages.docs) {
      print(message.data());
    }
  }

  void messageStream() async {
    await for (var snapshot in _fireStore.collection('messages').snapshots()) {
      for (var message in snapshot.docs) {
        print(message.data());
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getCurrentUser();
    // getMessages();
    messageStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: null,
        actions: <Widget>[
          IconButton(
              icon: Icon(Icons.logout),
              onPressed: () {
                _auth.signOut();
                Navigator.pop(context);
              }),
        ],
        title: Text('⚡️Chat'),
        backgroundColor: Colors.lightBlueAccent,
      ),
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              StreamBuilder<QuerySnapshot>(
                stream: _fireStore.collection('messages').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final messages = snapshot.data.docs;
                    List<Text> messageWidgets = [];
                    for (var message in messages) {
                      final author = message.get('author');
                      final text = message.get('text');

                      final messageWidget = Text('$text from $author');
                      messageWidgets.add(messageWidget);
                    }
                    return Column(
                      children: messageWidgets,
                    );
                  }
                },
              ),
              Container(
                decoration: kMessageContainerDecoration,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        onChanged: (value) {
                          messageText = value;
                        },
                        decoration: kMessageTextFieldDecoration,
                      ),
                    ),
                    FlatButton(
                      onPressed: () async {
                        setState(() {
                          showSpinner = true;
                        });
                        await _fireStore.collection("messages").add({
                          "text": messageText,
                          "author": firebaseUser.email,
                        });
                        setState(() {
                          showSpinner = false;
                        });
                      },
                      child: Text(
                        'Send',
                        style: kSendButtonTextStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
