import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  final RouteObserver routeObserver;
  SettingsScreen({Key key, this.routeObserver}) : super(key: key);

  @override
  SettingsScreenState createState() => new SettingsScreenState();
}

class SettingsScreenState extends State<SettingsScreen> with RouteAware {
  @override SettingsScreen get widget => super.widget;
  final GlobalKey<FormState> _formSettingsKey = new GlobalKey<FormState>();
  var settings = {};
  List<Widget> fields = <Widget>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPushNext() {
    loadAndStart();
  }

  @override
  void initState() {
    super.initState();
    loadAndStart();
  }

  @override
  void didPop() {
  }

  Future<void> loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this.settings = json.decode(prefs.getString('settings') ?? '{"separator": ", ", "prefix": "#"}');
    });
  }

  void loadAndStart() async {
    await loadSettings();
    fields = <Widget>[
      new TextFormField(
        key: Key("Separator"),
        autocorrect: false,
          decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              hintText: '',
              labelText: 'Separator',
          ),
          onSaved: (value) {
            settings['separator'] = value;
          },
          initialValue: settings['separator'],
      ),
      SizedBox(height: 24.0),
      new TextFormField(
        key: Key("Prefix"),
        autocorrect: false,
          decoration: const InputDecoration(
              border: UnderlineInputBorder(),
              filled: true,
              hintText: '',
              labelText: 'Prefix',
          ),
          onSaved: (value) {
            settings['prefix'] = value;
          },
          initialValue: settings['prefix'],
      ),
    ];
  }

  Future<void> saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('settings', json.encode(settings));
  }

  Future<void> saveAndExit(BuildContext context) async {
    _formSettingsKey.currentState.save();
    await saveSettings();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Settings"),
        leading: new IconButton(
          icon: const Icon(Icons.chevron_left, size: 40.0), onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Save',
        child: Icon(Icons.save),
        elevation: 2.0,
        onPressed: () {
          saveAndExit(context);
        },
      ),
      body: Form(
        child: Container(
          child: ListView.builder(
            itemBuilder: (context, index) {
              if (index < fields.length) {
                return fields[index];
              }
            },
          ),
          padding: new EdgeInsets.all(10.0),
        ),
        key: _formSettingsKey,
      ),
    );
  }
}