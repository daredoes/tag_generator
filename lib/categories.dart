import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
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
    return tempTags.length > 0 ? prefix + tempTags.join(separator + prefix) : '';
  }

  Future<void> copyTags(tags, key) async {
      await Clipboard.setData(ClipboardData(
        text: tags
      ));
      key.currentState.showSnackBar(SnackBar(
        content: Text('Copied To Clipboard'),
      ));
    }
  
  @override
  Widget build(BuildContext context) {
    final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
    TextEditingController newTag = new TextEditingController();
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        centerTitle: true,
        title: Text('Tag Generator'),
        actions: <Widget>[      // Add 3 lines from here...
          new IconButton(icon: const Icon(Icons.settings), onPressed: goToSettings),
        ],  
      ),
      body: _buildSuggestions(_scaffoldKey, copyTags),
      floatingActionButton: new FloatingActionButton(
        child: new Icon(Icons.add), onPressed: () {
          //editCategory(null);
          showDialog(
            context: context,
            builder: (BuildContext contxt) {
              return AlertDialog(
                title: Text('New Category'),
                content: TextField(
                  controller: newTag,
                  onEditingComplete: () {
                    addCategoryFromController(newTag);
                    Navigator.of(contxt).pop();
                  },
                ),
                actions: <Widget>[
                  FlatButton(
                    onPressed: () {
                      Navigator.of(contxt).pop();
                    },
                    child: Text("Cancel"),
                  ),
                  FlatButton(
                    child: Text("Save"),
                    onPressed: () {
                      addCategoryFromController(newTag);
                      Navigator.of(contxt).pop();
                    },
                  ),
                  
                ],
              );
            },
          );
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
    var totalTags = tags[category].length.toString();
    var activeTags = tags[category].values.where((status) {return status == true;}).length.toString();
    var activeCount = activeTags + '/' + totalTags;
    return ListTile(
      title: Text(
        category,
        style: _biggestFont,
      ),
      leading: Text(
        activeCount
      ),
      trailing: new Icon(   // Add the lines from here... 
        active ? Icons.visibility : Icons.visibility_off,
        color: active ? Colors.blue : null,
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

  void deleteCategory(category) async {
    setState(() {
      tags.remove(category);
      saveTags();
    });
  }

  void deleteTagInCategory(String category, String tag) async {
    setState(() {
      if (tags.containsKey(category) && tags[category].keys.contains(tag)) {
        setState(() {
          tags[category].remove(tag);
          saveTags();       
        });
      }
      
    });
  }

  bool addCategoryFromController(TextEditingController controller) {
    if (controller.text != '' && !tags.keys.contains(controller.text)) {
      setState(() {
        tags[controller.text] = {};
        saveTags();
      });
      return true;
    }
    return false;
  }

  bool updateTagFromController(TextEditingController controller, String category) {
    if (controller.text != category && controller.text != '') {
      setState(() {
        tags[controller.text] = tags[category];
        tags.remove(category);
        saveTags();
      });
      return true;
    }
    return false;
  }

  bool updateTagInCategoryFromController(TextEditingController controller, String category, String tag) {
    if (controller.text != '' && !tags[category].keys.contains(controller.text)) {
      setState(() {
        tags[category][controller.text] = tags[category][tag];
        tags[category].remove(tag);
        saveTags();
      });
      return true;
    }
    return false;
  }

  bool addTagFromController(TextEditingController controller, String category) {
    if (controller.text != '' && !tags[category].keys.contains(controller.text)) {
      setState(() {
        tags[category][controller.text] = true;
        saveTags();
      });
      return true;
    }
    return false;
  }

  Widget editableTagCategory(String category, bool active, update) {
    var totalTags = tags[category].length.toString();
    String activeCount = '';
    if (totalTags != '0') {
      var activeTags = tags[category].values.where((status) {return status == true;}).length.toString();
      activeCount = activeTags + '/' + totalTags;
    }
    TextEditingController t = new TextEditingController();
    TextEditingController newTag = new TextEditingController();
    t.text = category;
    return new Slidable(
      delegate: new SlidableScrollDelegate(),
      child: new ListTile(
        title: Text(
          category,
          style: _biggestFont,
        ),
        leading: totalTags != '0' ? Text(
          activeCount
        ) : null,
        trailing: totalTags != '0' ? new Icon(   // Add the lines from here... 
          active ? Icons.visibility : Icons.visibility_off,
          color: active ? Colors.blue : null,
        ) : null,
        onTap: () {      // Add 9 lines from here...
          setState(() {
            update();  
          });
        },
        onLongPress: () {
          editCategory(category);
        },
      ),
      actions: <Widget>[
         new IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete_forever,
          onTap: () {
            deleteCategory(category);
          },
        ),
        new IconSlideAction(
          caption: 'Add',
          color: Colors.blue,
          icon: Icons.add,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext contxt) {
                return AlertDialog(
                  title: Text('New Tag'),
                  content: TextField(
                    controller: newTag,
                    onEditingComplete: () {
                      addTagFromController(newTag, category);
                      Navigator.of(contxt).pop();
                    },
                  ),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () {
                        Navigator.of(contxt).pop();
                      },
                      child: Text("Cancel"),
                    ),
                    FlatButton(
                      child: Text("Save"),
                      onPressed: () {
                        addTagFromController(newTag, category);
                        Navigator.of(contxt).pop();
                      },
                    ),
                    
                  ],
                  );
              }
            );
          },
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: 'Rename',
          color: Colors.green,
          icon: Icons.edit,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext contxt) {
                return AlertDialog(
                  title: Text('Edit Category'),
                  content: TextField(
                    key: Key(category),
                    controller: t,
                    onEditingComplete: () {
                      updateTagFromController(t, category);
                      Navigator.of(contxt).pop();
                    },
                  ),
                  actions: <Widget>[
                    FlatButton(
                      onPressed: () {
                        Navigator.of(contxt).pop();
                      },
                      child: Text("Cancel"),
                    ),
                    FlatButton(
                      child: Text("Save"),
                      onPressed: () {
                        updateTagFromController(t, category);
                        Navigator.of(contxt).pop();
                      },
                    ),
                    
                  ],
                  );
              }
            );
          },
        ),
      ],
    );
  }

  Widget editableTagInCategory(String tag, bool active, String category, update) {
    TextEditingController t = new TextEditingController();
    t.text = tag;
    return new Slidable(
      delegate: new SlidableScrollDelegate(),
      child: new ListTile(
        title: Text(
          tag,
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
      ),
      actions: <Widget>[
         new IconSlideAction(
          caption: 'Delete',
          color: Colors.red,
          icon: Icons.delete_forever,
          onTap: () {
            deleteTagInCategory(category, tag);
          },
        ),
      ],
      secondaryActions: <Widget>[
        new IconSlideAction(
          caption: 'Rename',
          color: Colors.green,
          icon: Icons.edit,
          onTap: () {
            showDialog(
              context: context,
              builder: (BuildContext contxt) {
                return AlertDialog(
                  title: Text('Edit Tag'),
                  content: TextField(
                    key: Key(category),
                    controller: t,
                    onEditingComplete: () {
                      updateTagInCategoryFromController(t, category, tag);
                      Navigator.of(contxt).pop();
                    },
                  ),
                  actions: <Widget>[
                    FlatButton(
                      child: Text("Save"),
                      onPressed: () {
                        updateTagInCategoryFromController(t, category, tag);
                        Navigator.of(contxt).pop();
                      },
                    )
                  ],
                  );
              }
            );
          },
        ),
      ],
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

  Widget checkableList(key, copy) {
    var fields = <Widget>[];
    var text = buildTags();
      fields.add(
        ListTile(
          title: Text(text, style: _biggestFont),
          onTap: text == '' ? null : () {
            copy(text, key);
          },
        )
      );
      fields.add(Divider());
    
    tags.forEach((k, v) {
      bool active = activeTags.contains(k);
      void updateCategory() {
        if (active) {
          activeTags.remove(k);
        } else {
          activeTags.add(k);
        }
      }
      fields.add(editableTagCategory(k, active, updateCategory));
      if (active) {
        v.forEach((tag, status) {
          void updateTag() {
            tags[k][tag] = !tags[k][tag];
          }
          fields.add(editableTagInCategory(tag, status, k, updateTag));
        });
      }
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

  Widget _buildSuggestions(key, copy) {
    return checkableList(key, copy);
  }
}