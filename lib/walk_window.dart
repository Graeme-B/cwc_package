import "dart:async";
import "package:flutter/material.dart";
import "package:gps_tracker_db/gps_tracker_db.dart";
import "constants.dart";

class WalkWindow extends StatefulWidget {
  const WalkWindow({Key? key, required this.currentWalkName}) : super(key: key);
  final String currentWalkName;
  @override
  State<WalkWindow> createState() => _WalkWindowState(currentWalkName: currentWalkName);
}

class _WalkWindowState extends State<WalkWindow> {

  _WalkWindowState({required this.currentWalkName});
  late DatabaseHelper db;
  List<String> items          = [];
  var selectedItem            = 0;
  bool currentWalkNameChanged = false;
  bool currentWalkDeleted     = false;
  late String currentWalkName;

  @override
  @protected
  void initState() {
    super.initState();
    DatabaseHelper.getDatabaseHelper().then((dbase) {
      db = dbase;
      repopulateList();
    });
  }

  void repopulateList() {
    items = [];
    db.walks().then((walks) {
      // ignore: avoid_function_literals_in_foreach_calls
      walks.forEach((walk) => items.add(walk));
      setState(() {
        if (selectedItem >= items.length) {
          selectedItem = items.length - 1;
        }
      });
    });
  }

  Future<bool> _onBackPressed() {
    if (currentWalkNameChanged) {
      Navigator.of(context, rootNavigator: true).pop(currentWalkName);
      return Future(() => false);
    } else if (currentWalkDeleted) {
      Navigator.of(context, rootNavigator: true).pop("");
      return Future(() => false);
    }
    return Future(() => true);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return WillPopScope(
        onWillPop: _onBackPressed,
        child:
        Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: const Text(Constants.WALK_WINDOW_TITLE),
      ),
      body:
      Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  var bgColor = Colors.transparent;
                  if (index == selectedItem) {
                    bgColor = Colors.blue;
                  }
                  return Container(
                    decoration: BoxDecoration(color: bgColor),
                    height: 50,
                    child: ListTile(
                      onTap: () {
                        setState(() {
                          selectedItem = index;
                        });
                      },
                      title: Text(items[index]),
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // use whichever suits your need
              children: <Widget>[
                ElevatedButton(
                  onPressed: items.isNotEmpty ? () {
                    Navigator.of(context, rootNavigator: true).pop(
                        (items.isNotEmpty && selectedItem < items.length) ? items[selectedItem] : "");
                  } : null,
                  child: const Text(Constants.PROMPT_LOAD),
                ),
                ElevatedButton(
                  onPressed: items.isNotEmpty ? () {
                    if (items.isNotEmpty && selectedItem < items.length) {
                      renameDialog();
                    }
                  } : null,
                  child: const Text(Constants.PROMPT_RENAME),
                ),
                ElevatedButton(
                  onPressed: items.isNotEmpty ? () async {
                    if (items.isNotEmpty && selectedItem < items.length) {
                      final String result = await yesNoDialog(
                          Constants.PROMPT_DELETE_WALK);
                      if (result == "yes") {
                        if (currentWalkName == items[selectedItem]) {
                          currentWalkName    = "";
                          currentWalkDeleted = true;
                        }
                        await db.deleteWalk(items[selectedItem]);
                      }
                      repopulateList();
                    }
                  } : null,
                  child: const Text(Constants.PROMPT_DELETE),
                ),
              ],
            ),
            const SizedBox( //Use of SizedBox
              height: 30,
            ),
          ],
        ),
      ),
    ),
    );
  }

  // void itemSelected(index) {
  //   selectedItem = index;
  // }

  void renameDialog() {
    final nameController = TextEditingController(text: items[selectedItem]);

    showDialog(
        barrierDismissible: false, // user must tap button!
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text(Constants.RENAME_DIALOG_TITLE),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              //position
              mainAxisSize: MainAxisSize.min,
              // wrap content in flutter
              children: <Widget>[
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: Constants.PROMPT_NAME,
                  ),
                ),
              ],
            ),
            actions: <Widget>[
              TextButton(
                  onPressed: () async {
// 1) Walk name must be unique
// 2) Walk name must not be blank
                    try {
                      if (nameController.text.isEmpty || nameController.text.trim().isEmpty) {
                        throw Exception(Constants.ERR_WALK_NAME_INVALID);
                      }
                      if (currentWalkName == items[selectedItem]) {
                        currentWalkName        = nameController.text;
                        currentWalkNameChanged = true;
                      }
                      await db.updateWalkName(items[selectedItem], nameController.text);
                      repopulateList();
                      _dismissDialog();
                    } catch (err) {
                      showErrorMessage(err.toString());
                    }
                  },
                  child: const Text(Constants.PROMPT_RENAME)),
              TextButton(
                onPressed: () {
                  _dismissDialog();
                },
                child: const Text(Constants.PROMPT_CANCEL),
              )
            ],
          );
        });
  }

  void _dismissDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> showErrorMessage(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(Constants.ERROR_DIALOG_TITLE),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(Constants.PROMPT_OK),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<String> yesNoDialog(String message) async {
    final String val = await showDialog(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(Constants.INFORMATION_DIALOG_TITLE),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(Constants.PROMPT_YES),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop("yes");
              },
            ),
            TextButton(
              child: const Text(Constants.PROMPT_NO),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop("no");
              },
            ),
          ],
        );
      },
    );
    return val;
  }
}
