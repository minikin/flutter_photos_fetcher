import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' show Client;

void main() => runApp(const App());

class App extends StatelessWidget {
  const App({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatelessWidget {
  const MainScreen({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        brightness: Brightness.light,
        elevation: 1,
        title: Text(
          'Photos',
          style: TextStyle(
            fontSize: 24,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Photo>>(
          future: fetchPhotos(client: Client()),
          builder: (context, snapshot) {
            if (snapshot.hasError)
              return Center(
                child: Text('Something went wrong:\n ${snapshot.error}'),
              );

            return snapshot.hasData
                ? PhotosList(photosList: snapshot.data)
                : Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class PhotosList extends StatelessWidget {
  final List<Photo> photosList;

  const PhotosList({
    @required this.photosList,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: photosList.length,
      itemBuilder: (context, index) {
        return PhotoItem(
          photo: photosList[index],
          onTap: (photo) => _showAlert(context: context, photo: photo),
        );
      },
    );
  }

  void _showAlert({
    @required BuildContext context,
    @required Photo photo,
  }) {
    if (Platform.isIOS) {
      showDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text('Author'),
            content: Text(photo.author.toUpperCase()),
            actions: <Widget>[
              CupertinoButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: Text('Author'),
            content: Text(photo.author.toUpperCase()),
            actions: <Widget>[
              FlatButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          );
        },
      );
    }
  }
}

class PhotoItem extends StatelessWidget {
  final Photo photo;
  final ValueChanged<Photo> onTap;

  const PhotoItem({
    @required this.photo,
    @required this.onTap,
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(photo),
      child: Container(
        padding: EdgeInsets.all(4),
        child: Image.network(
          photo.imagePreviewUrl,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

Future<List<Photo>> fetchPhotos({@required Client client}) async {
  final response =
      await client.get('https://picsum.photos/v2/list?page=2&limit=50');
  return compute(Photo.parsePhotos, response.body);
}

class Photo {
  final String id;
  final String author;
  final int width;
  final int height;
  final String url;
  final String downloadUrl;

  Photo({
    @required this.id,
    @required this.author,
    @required this.width,
    @required this.height,
    @required this.url,
    @required this.downloadUrl,
  });

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(
      id: json['id'] as String,
      author: json['author'] as String,
      width: json['width'] as int,
      height: json['height'] as int,
      url: json['url'] as String,
      downloadUrl: json['download_url'] as String,
    );
  }

  static List<Photo> parsePhotos(String responseBody) {
    final parsed = json.decode(responseBody).cast<Map<String, dynamic>>();
    return parsed.map<Photo>((json) => Photo.fromJson(json)).toList();
  }

  String get imagePreviewUrl => 'https://picsum.photos/id/${this.id}/400/400';
}
