import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  runApp(MyApp());
}

final _biggerFont = const TextStyle(fontSize: 18.0);
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tag Generator',
      theme: new ThemeData(          // Add the 3 lines from here... 
        primaryColor: Colors.red,
      ),                     
      home: Tags(),
      navigatorObservers: [routeObserver],
    );
  }
}

class SettingsScreen extends StatefulWidget {
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
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
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
      this.settings = json.decode(prefs.getString('settings') ?? '{}');
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

class CategoryScreen extends StatefulWidget {
  final String category;
  CategoryScreen({Key key, this.category}) : super(key: key);
  @override
  CategoryScreenState createState() => new CategoryScreenState();
}

class CategoryScreenState extends State<CategoryScreen> with RouteAware {
  @override CategoryScreen get widget => super.widget;
  final titleController = TextEditingController();
  var title;
  bool isNew = true;
  var data;
  var temporaryData = {};
  var tags = {};
  var tagCounts = {};
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  var fields = <Widget>[];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    titleController.dispose();
    super.dispose();
  }

  @override
  void didPushNext() {
    loadTags();
  }

  @override
  void didPop() {
  }
  
  Widget tagField({String tag}) {
    var field = new TextFormField(
      key: Key(tag),
      autocorrect: false,
        decoration: const InputDecoration(
            border: UnderlineInputBorder(),
            filled: true,
            hintText: '',
            labelText: 'Tag',
        ),
        onSaved: (value) {
          if (value != '') {
            temporaryData[value] = true;
          }
        },
        initialValue: tag,
  );
  return field;
  }
  @override
  void initState() {
    super.initState();
    loadTagsAndStart();
    isNew = widget.category == null;
    title = isNew ? "New Category" : "Edit";
    titleController.text = widget.category;
    
  }
  
  Future<void> loadTags() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      this.tags = json.decode(prefs.getString('tags') ?? '{}');
    });
  }

  void loadTagsAndStart() async {
    await loadTags();
    fields.add(tagField());
    if ( tags != null && tags.containsKey(widget.category) && tags[widget.category][1].length > 0 ) {
      data = tags[widget.category][1];
      data.forEach((tag) {
        if (tag != "") {
          fields.addAll(<Widget>[SizedBox(height: 24.0), tagField(tag: tag)]);
        }
      });
    }
  }

  Future<void> saveTags() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tags', json.encode(tags));
  }

  void deleteAndExit() async {
    tags.remove(widget.category);
    await saveTags();
    Navigator.pop(context);
  }

  void saveTagsAndExit() async {
    _formKey.currentState.save();
    data = temporaryData.keys.toList();
    var titleText = titleController.text;
    if ( titleText != "" && titleText != widget.category ) {
      tags.remove(widget.category);
      tags[titleText] = [
        tags.containsKey(titleText) && tags[titleText][0] < data.length ? tags[titleText][0] : data.length,
         data];
    } else if ( widget.category != null ) {
      tags[widget.category] = [
        tags.containsKey(widget.category) && tags[widget.category][0] < data.length ? tags[widget.category][0] : data.length,
         data];
    }
    await saveTags();
    Navigator.pop(context);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextFormField(
          controller: titleController,
          decoration: const InputDecoration(
            border: null,
            filled: false,
            hintText: 'Category Title',
        ),
        ),
        leading: new IconButton(
          icon: const Icon(Icons.chevron_left, size: 40.0), onPressed: () {
            saveTagsAndExit();
          },
        ),
        actions: isNew ? [] : <Widget>[new IconButton(
          icon: const Icon(Icons.delete_forever, size: 40.0), onPressed: () {
              deleteAndExit();
          },
        )],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add',
        child: Icon(Icons.add),
        elevation: 2.0,
        onPressed: () {
          
          setState(() {
            fields.insertAll(0, <Widget>[tagField(tag: ''), SizedBox(height: 24.0)]);  
          });
        },
      ),
      body: Form(
        child: Container(
          child: ListView.builder(
            itemBuilder: (context, index) {
              if ( index < fields.length ) {
                return fields[index];
              }
            },
          ),
          padding: new EdgeInsets.all(10.0),
        ),
        key: _formKey,
      ),
    );
  }
}

class Tags extends StatefulWidget {
  @override
  TagsState createState() => new TagsState();
}

class TagsState extends State<Tags> with RouteAware {
  var tags = {};
  var activeTags = [];
  var suggestions;
  var settings = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    loadTagsAndStart();
  }


  @override
  void initState() {
    super.initState();
    loadTagsAndStart();
  }

  String buildTags() {
    var tempTags = [];
    activeTags.forEach((tag) {
      tags[tag][1].shuffle();
      var length = tags[tag][0];
      tempTags.addAll(tags[tag][1].sublist((tags[tag][1].length - length).toInt()));
    });
    print(settings);
    return settings['prefix'] + tempTags.join((settings['separator'] + settings['prefix']) ?? ', ');
  }

  
  
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
    Future<void> copyTags(tags, contxt) async {
      await Clipboard.setData(ClipboardData(
        text: tags
      ));
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Copied To Clipboard'),
      ));
    }

    Widget tagAlert(tagContext){
      var tagString = buildTags();
      return AlertDialog(
        title: Text('Tags'),
        content: Text(tagString),
        actions: <Widget>[
          new FlatButton(
            child: new Text("Regenerate"),
            onPressed: () {
              Navigator.of(tagContext).pop();
              showDialog(
                context: context,
                builder: (BuildContext contxt) {
                  return tagAlert(tagContext);
                },
              );
            },
          ),
          new FlatButton(
            child: new Text("Copy"),
            onPressed: () {
              copyTags(tagString, context);
              Navigator.of(tagContext).pop();
            },
          ),
          ],
      );
    }
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Tag Generator'),
        actions: <Widget>[      // Add 3 lines from here...
          new IconButton(icon: const Icon(Icons.settings), onPressed: goToSettings),
        ],  
      ),
      body: _buildSuggestions(),
      floatingActionButton: new FloatingActionButton(
        tooltip: 'Create',
        child: Icon(Icons.refresh),
        elevation: 2.0,
        onPressed: () {
          if (activeTags.length > 0) {
            showDialog(
              context: context,
              builder: (BuildContext contxt) {
                return tagAlert(context);
              },
            );
          } else {
            _scaffoldKey.currentState.showSnackBar(
              SnackBar(
                content: Text('Please select a category'),
              )
            );
          }
          
          
        },
      ),
      
    );
  }
  void loadTagsAndStart() async {
    await loadTags();
    tags.keys.forEach((key) {
      if ( tags[key][0] > 0 && !activeTags.contains(key) ) activeTags.add(key);
    });
  }

  Future<void> loadTags() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      tags = json.decode(prefs.getString('tags') ?? '{}');
      settings = json.decode(prefs.getString('settings') ?? '{}');
    });
  }

  void saveTags() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('tags', json.encode(tags));
  }

  void goToSettings() {
    Navigator.of(context).push(new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new SettingsScreen();
      }
    )); 
  }

  void createNewCategory() {
    Navigator.of(context).push(new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new CategoryScreen(category: null);
      }
    )); 
  }

  void editCategory(category) {
    Navigator.of(context).push(new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new CategoryScreen(category: category);
      }
    )); 
  }

  Widget tagCategory(String category) {
    final bool active = activeTags.contains(category);
    return ListTile(
      title: Text(
        category,
        style: _biggerFont,
      ),
      trailing: new Icon(   // Add the lines from here... 
        active ? Icons.favorite : Icons.favorite_border,
        color: active ? Colors.red : null,
      ),
      onTap: () {      // Add 9 lines from here...
        setState(() {
          if (active) {
            activeTags.remove(category);
          } else {
            activeTags.add(category);
          }
        });
      },
      onLongPress: () {
        editCategory(category);
      },
    );
  }

  Widget _buildSuggestions() {
    var keys = tags.keys.toList();
    return ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemBuilder: /*1*/ (context, i) {
          if (i == 0) {
            return ListTile(
              title: Text("Add New Category"),
              onTap: createNewCategory,
              );
          }
          if (i == 1) return Divider(); /*2*/
          if (i % 3 == 1) return Divider();

          final index = (i ~/ 3); /*3*/
          if (index < keys.length && i % 3 == 2) {
            
            return tagCategory(keys[index]);
          }
          if (index <= keys.length && i % 3 == 0) {
            final myIndex = index -1;
            var length = tags[keys[myIndex]][1].length;
            return Slider(
                value: tags[keys[myIndex]][0].toDouble(),
                min: 0.0,
                divisions: length > 0 ? length : null,
                label: tags[keys[myIndex]][0].toString(),
                max: length.toDouble(),
                onChanged: (v) {
                  if (v > 0) {
                    if (!activeTags.contains(keys[myIndex])) activeTags.add(keys[myIndex]);
                  }
                  if (v == 0) {
                    if (activeTags.contains(keys[myIndex])) activeTags.remove(keys[myIndex]);
                  }
                  setState(() {
                    tags[keys[myIndex]][0] = v;       
                  });
                  
                },
              );
          }
        });
  }
}