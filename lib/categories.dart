import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'category.dart';
import 'settings.dart';

final _biggerFont = const TextStyle(fontSize: 18.0);
final _biggestFont = const TextStyle(fontSize: 24.0);

class Tags extends StatefulWidget {
  final RouteObserver routeObserver;
  Tags({Key key, this.routeObserver}) : super(key: key);
  @override
  TagsState createState() => new TagsState();
}

class TagsState extends State<Tags> with RouteAware {
  @override Tags get widget => super.widget;
  var tags = {};
  var activeTags = [];
  var activeTagStrings = [];
  var suggestions;
  var settings = {};

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
    tags.forEach((tag, values) {
      values.forEach((content, status) {
        if (status) tempTags.add(content);
      });
    });
    var prefix = settings['prefix'] ?? "#";
    var separator = settings['separator'] ?? ', ';
    return prefix + tempTags.join(separator + prefix);
  }
  
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
    Future<void> copyTags(tags) async {
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
              copyTags(tagString);
              Navigator.of(tagContext).pop();
            },
          ),
          ],
      );
    }
    
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        leading: new IconButton(
          icon: const Icon(Icons.add), onPressed: () {
            editCategory(null);
          },
        ),
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
    tags.forEach((k, values) {
      if (values != null) {
        for ( var content in values.keys ) {
          if (values[content]) {
            activeTags.add(k);
            break;
          }
        }
      }
      
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
        return new SettingsScreen(routeObserver: widget.routeObserver,);
      }
    )); 
  }

  void createNewCategory() {
    Navigator.of(context).push(new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new CategoryScreen(category: null, routeObserver: widget.routeObserver,);
      }
    )); 
  }

  void editCategory(category) {
    Navigator.of(context).push(new MaterialPageRoute<void>(
      builder: (BuildContext context) {
        return new CategoryScreen(category: category, routeObserver: widget.routeObserver);
      }
    )); 
  }

  Widget tagCategory(String category, bool active, update) {
    return ListTile(
      title: Text(
        category,
        style: _biggestFont,
      ),
      trailing: new Icon(   // Add the lines from here... 
        active ? Icons.favorite : Icons.favorite_border,
        color: active ? Colors.red : null,
      ),
      onTap: () {      // Add 9 lines from here...
        setState(() {
          update();  
        });
      },
      onLongPress: () {
        editCategory(category);
      },
    );
  }

  Widget tagInCategory(String category, bool active, update) {
    return ListTile(
      title: Text(
        category,
        style: _biggerFont,
      ),
      leading: new Icon(   // Add the lines from here... 
        active ? Icons.check_box : Icons.check_box_outline_blank,
        color: active ? Colors.blue : Colors.blue,
      ),
      onTap: () {      // Add 9 lines from here...
        setState(() {
         update(); 
        });
      },
    );
  }

  Widget checkableList() {
    var fields = <Widget>[];
    tags.forEach((k, v) {
      bool active = true;
      for ( var content in v.keys ) {
        if (!v[content]) {
          active = false;
          break;
        }
      }
      void updateCategory() {
        v.forEach((tag, status) {
          tags[k][tag] = !active;
        });
      }
      fields.add(tagCategory(k, active, updateCategory));
      v.forEach((tag, status) {
        void updateTag() {
          tags[k][tag] = !tags[k][tag];
        }
        fields.add(tagInCategory(tag, status, updateTag));
      });
      fields.add(Divider());
    });
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemBuilder: /*1*/ (context, i) {
        if (i < fields.length) {
          return fields[i];
        }
        
      }
    );
  }

  Widget _buildSuggestions() {
    return checkableList();
  }
}