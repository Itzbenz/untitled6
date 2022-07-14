import 'dart:convert';
import 'dart:io';

import 'package:filesystem_picker/filesystem_picker.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled6/widget/PackageViewerWidget.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discord Data Exporter Explorer', //DDEE
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Map<String, String> _files = {};

  @override
  void initState() {
    SharedPreferences.getInstance().then((prefs) {
      List<String> l = prefs.getStringList('files') ?? [];
      for (String s in l) {
        _loadPackage(s).then((value) {
          try {
            _files["${value['username']}#${value['discriminator']}"] = s;
          } catch (e) {
            print(e);
          }
          setState(() {});
        });
      }
    });
    super.initState();
  }

  _savePref() {
    SharedPreferences.getInstance().then((prefs) {
      prefs.setStringList("files", _files.values.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    _savePref();
    List<ListTile> children = [
      for (final key in _files.keys)
        ListTile(
          title: Text("$key (${_files[key]})"),
          tileColor: Colors.redAccent,
          onTap: () => _openFile(_files[key], context),
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: ListView(
                children: children,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          FilesystemPicker.open(
                  title: 'Select Discord Package folder',
                  context: context,
                  fsType: FilesystemType.folder,
                  pickText: 'Choose',
                  rootDirectory: Directory.current)
              .then((path) {
            if (path != null) {
              String pathString = path;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ImportPage(
                      path: pathString,
                      onSuccess: (String name) {
                        setState(() {
                          _files[name] = pathString;
                        });
                      }),
                ),
              );
            }
          });
        },
        tooltip: 'Load Discord Package',
        child: const Icon(Icons.folder),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  _openFile(String? path, BuildContext context) {
    if (path == null) {
      return;
    }
    _loadPackage(path).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading package: $error"),
        ),
      );
    }).then((value) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PackageViewerWidget(
            package: value,
            path: path,
          ),
        ),
      );
    });
  }
}

validateJson(Map<String, dynamic>? a) {
  if (a == null) throw Exception("Json is Null");
  Map<String, dynamic> userData = a;
  if (userData['username'] == null) {
    throw ("No username found");
  }
  if (userData['id'] == null) {
    throw ("No id found");
  }
}

Future<Map<String, dynamic>> _loadPackage(String path) async {
  //check for path/account/user.json
  final userFile = File('$path/account/user.json');
  if (await userFile.exists()) {
    final userJson = await userFile.readAsString();
    final userData = json.decode(userJson);
    validateJson(userData);
    return userData;
  }
  throw '$path/account/user.json not found';
}

class ImportPage extends StatelessWidget {
  const ImportPage({Key? key, required this.path, this.onSuccess})
      : super(key: key);

  final String path;
  final Function(String name)? onSuccess;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Importing Discord Package'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPackage(path),
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            Map<String, dynamic> data = snapshot.data!;
            return _buildBody(context, data);
          } else if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else {
            Text error = const Text("No Data Found");
            if (snapshot.error != null) {
              error = Text(snapshot.error.toString());
            }
            //show dialog
            return AlertDialog(
              title: const Text('Error'),
              content: error,
              actions: <Widget>[
                MaterialButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, Map<String, dynamic> data) {
    return AlertDialog(
      title: const Text('Success'),
      content: Text('${data['username']}#${data['discriminator']}'),
      actions: <Widget>[
        MaterialButton(
          child: const Text('OK'),
          onPressed: () {
            onSuccess?.call("${data['username']}#${data['discriminator']}");
            Navigator.pop(context);
          },
        ),
      ],
    );
  }
}
