import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'category.dart';
import 'settings.dart';

final _biggerFont = const TextStyle(fontSize: 18.0);

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
    activeTags.shuffle();
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