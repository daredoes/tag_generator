import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CategoryScreen extends StatefulWidget {
  final String category;
  final RouteObserver routeObserver;
  CategoryScreen({Key key, this.category, this.routeObserver}) : super(key: key);
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
    widget.routeObserver.subscribe(this, ModalRoute.of(context));
  }

  @override
  void dispose() {
    widget.routeObserver.unsubscribe(this);
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
    var field = TextFormField(
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
    if ( tags != null && tags.containsKey(widget.category) && tags[widget.category][1].length > 0 ) {
      data = tags[widget.category][1];
      data.forEach((tag) {
        if (tag != "") {
          fields.addAll(<Widget>[tagField(tag: tag), SizedBox(height: 24.0)]);
        }
      });
    }
    fields.add(tagField());
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

  void saveForm() {
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
  }

  void addBlankTag() async {
    setState(() {
      
      fields.addAll(<Widget>[SizedBox(height: 24.0), tagField(tag: '')]);  
    });
  }

  void saveTagsAndExit() async {
    saveForm();
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
          addBlankTag();
        },
      ),
      body: Form(
        child: Container(
          child: ListView.builder(
            reverse: true,
            shrinkWrap: true,
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