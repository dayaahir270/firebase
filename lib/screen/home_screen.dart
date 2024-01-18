import 'package:animate_do/animate_do.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_by/screen/signup.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../note_model.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {
  //final String userId;

  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userId = "";
  String searchQuery = "";
  bool isSearching = false;

  late FirebaseFirestore fireStore;

  TextEditingController titleController = TextEditingController();
  TextEditingController descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fireStore = FirebaseFirestore.instance;
    getUidFromPrefs();
  }

  getUidFromPrefs() async {
    var prefs = await SharedPreferences.getInstance();
    userId = prefs.getString(MyLogin.LOGIN_PREFS_KEY)!;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: isSearching
            ? SizedBox(
          height: 40,
          child: TextFormField(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
        )
            : const Text(
          "Firebase Note App",
          style:
          TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        leading: IconButton(
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
            setState(() {});
          },
          icon: const Icon(
            Icons.menu,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
              });
            },
            icon: const Icon(
              Icons.search,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () async {
              showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) {
                    return AlertDialog(
                      title: const Text("Logout?"),
                      content: const Text("Are sure want to logout ?"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Cancel",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            var pref = await SharedPreferences.getInstance();
                            pref.setString(MyLogin.LOGIN_PREFS_KEY, "");

                            Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (ctx) =>  MyLogin()));
                          },
                          child: const Text(
                            "Logout",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    );
                  });
            },
            icon: const Icon(
              Icons.logout,
              color: Colors.white,
            ),
          ),
        ],
        backgroundColor: Colors.blue,
      ),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
        future: fireStore
            .collection("users")
            .doc(userId)
            .collection("notes")
            .orderBy("time", descending: true)
            .get(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text("Note not loaded ${snapshot.hasError}"),
            );
          } else if (snapshot.hasData) {
            var mData = snapshot.data!.docs;
            var filteredNotes = mData
                .where((note) => note
                .data()["title"]
                .toLowerCase()
                .contains(searchQuery.toLowerCase()))
                .toList();
            return filteredNotes.isNotEmpty
                ? ListView.builder(
              itemCount: filteredNotes.length,
              itemBuilder: (_, index) {
                NoteModel currNote =
                NoteModel.fromMap(mData[index].data());
                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade200,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                  ),
                  child: ListTile(
                    title: Text(
                      currNote.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    subtitle: Text(currNote.desc),
                    trailing: SizedBox(
                      width: 100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            onPressed: () {
                              bottomSheet(
                                isUpdate: true,
                                title: currNote.title,
                                desc: currNote.desc,
                                docId: mData[index].id,
                              );
                            },
                            icon: const Icon(Icons.edit),
                          ),
                          IconButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text("Delete?"),
                                      content: const Text(
                                          "Are you want to sure delete?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            fireStore
                                                .collection("users")
                                                .doc(userId)
                                                .collection("notes")
                                                .doc(mData[index].id)
                                                .delete();
                                            setState(() {});
                                            Navigator.pop(context);
                                          },
                                          child: const Text("Yes"),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                          child: const Text("No"),
                                        )
                                      ],
                                    );
                                  });
                            },
                            icon: const Icon(
                              Icons.delete,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
                : const Center(
              child: Text(
                "No notes yet!!!",
                style:
                TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
              ),
            );
          }
          return Container();
        },
      ),
      drawer: const Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Text(
                "User",
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 18),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        onPressed: () {
          bottomSheet();
        },
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 34,
        ),
      ),
    );
  }

  void bottomSheet({
    bool isUpdate = false,
    String title = "",
    String desc = "",
    String docId = "",
  }) {
    titleController.text = title;
    descController.text = desc;
    showModalBottomSheet(
        context: context,
        builder: (_) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                TextField(

                  controller: titleController,
                ),
                TextField(

                  controller: descController,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Cancel",
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (titleController.text.isNotEmpty &&
                            descController.text.isNotEmpty) {
                          var collRef = fireStore.collection("users");
                          if (isUpdate) {
                            /// For Update Note
                            collRef
                                .doc(userId)
                                .collection("notes")
                                .doc(docId)
                                .update(NoteModel(
                              title: titleController.text.toString(),
                              desc: descController.text.toString(),
                              time: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                            ).toMap());
                          } else {
                            /// For Add New Note
                            collRef
                                .doc(userId)
                                .collection("notes")
                                .add(NoteModel(
                              title: titleController.text.toString(),
                              desc: descController.text.toString(),
                              time: DateTime.now()
                                  .millisecondsSinceEpoch
                                  .toString(),
                            ).toMap());
                          }
                          titleController.clear();
                          descController.clear();

                          setState(() {});
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15))),
                      child: Text(
                        isUpdate ? "Update" : "Add",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        });
  }
}
class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).size.height,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Column(
                children: <Widget>[
                  FadeInUp(duration: Duration(milliseconds: 1000), child:Text("Welcome", style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30
                  ),)),
                  SizedBox(height: 20,),
                  FadeInUp(duration: Duration(milliseconds: 1200), child: Text("Automatic identity verification which enables you to verify your identity",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 15
                    ),)),
                ],
              ),
              FadeInUp(duration: Duration(milliseconds: 1400), child: Container(
                height: MediaQuery.of(context).size.height / 3,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage('assets/illustration.png')
                    )
                ),
              )),
              Column(
                children: <Widget>[
                  FadeInUp(duration: Duration(milliseconds: 1500), child: MaterialButton(
                    minWidth: double.infinity,
                    height: 60,
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => MyLogin()));
                    },
                    shape: RoundedRectangleBorder(
                        side: BorderSide(
                            color: Colors.black
                        ),
                        borderRadius: BorderRadius.circular(50)
                    ),
                    child: Text("Login", style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 18
                    ),),
                  )),
                  SizedBox(height: 20,),
                  FadeInUp(duration: Duration(milliseconds: 1600), child: Container(
                    padding: EdgeInsets.only(top: 3, left: 3),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        border: Border(
                          bottom: BorderSide(color: Colors.black),
                          top: BorderSide(color: Colors.black),
                          left: BorderSide(color: Colors.black),
                          right: BorderSide(color: Colors.black),
                        )
                    ),
                    child: MaterialButton(
                      minWidth: double.infinity,
                      height: 60,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => MyRegister()));
                      },
                      color: Colors.yellow,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50)
                      ),
                      child: Text("Sign up", style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 18
                      ),),
                    ),
                  ))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

