import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:audioplayers/audio_cache.dart';
import 'dart:io';
import 'dart:async';
import 'player_widget.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'My Music Player'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterAudioQuery audioQuery = FlutterAudioQuery();
  List<ArtistInfo> artists;
  List<SongInfo> songs;
  AudioCache audioCache = AudioCache();
  AudioPlayer advancedPlayer = AudioPlayer();
  _MyHomePageState() {print_list();}
  void print_list() async{
    var list = [];
    print("Running...");
    songs = await audioQuery.getSongs();
    songs.removeWhere((element) => (double.parse(element.fileSize)/1024/1024).floor()<=2);
    setState(() {

    });
  }
  String name(String s){
    return s.substring(s.lastIndexOf("/")+1);
  }
  void _navigateToNextScreen(BuildContext context,int index) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) => PlayScreen(songs[index].filePath,songs)));
  }
  Future buildText() {
    setState(() {

    });
    return new Future.delayed(
        const Duration(seconds: 5), () => print('waiting'));
  }
@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      title: Text("Music Player"),
      backgroundColor: Colors.black,
    ),
    body: Center(
      child: FutureBuilder(
        future: buildText(),
        builder: (BuildContext context,AsyncSnapshot snap){
          if(snap.connectionState != ConnectionState.done){
            return CircularProgressIndicator(backgroundColor: Colors.deepPurple,);
          }
          else{
           return Scrollbar(

               child:ListView.builder(itemCount: songs.length,itemBuilder: (BuildContext context,int index){
                 return ListTile(
                   leading: Image.asset("assets/music.jpg"),
                   title: Text(name(songs[index].filePath),style: TextStyle(color: Colors.white),overflow: TextOverflow.ellipsis),
                  subtitle:Text(songs[index].artist+ ' artist',style: TextStyle(color: Colors.white),overflow: TextOverflow.ellipsis),
                   onTap:(){ _navigateToNextScreen(context,index);},

                 );
               }),

           ) ;
          }
        },
      ),
    ),// This trailing comma makes auto-formatting nicer for build methods.
  );
}
//  Container(
//  padding: EdgeInsets.all(10),
//  child: GestureDetector(
//  child: Card(elevation: 50,child: Container(
//  padding: EdgeInsets.only(top: 20,bottom: 20,left: 10,right: 10),
//  child: Row(
//  children: [ Flexible(child: Text(name(songs[index].filePath),style: TextStyle(fontWeight: FontWeight.bold),overflow: TextOverflow.clip,),) ],
//  ),
//  ),
//  ),
//  onTap: (){ print("size : "+getInMb(double.parse(songs[index].fileSize)));_navigateToNextScreen(context,index);},
//  ));
  String getInMb(double parse) {
    return (parse/1024/1024).floor().toString();
  }
}

class PlayScreen extends StatefulWidget {
  String path;
  List<SongInfo> songs;
  PlayScreen(String path,List<SongInfo> songs){
    this.path=path;
    this.songs=songs;
  }
  @override
  _PlayScreenState createState() => _PlayScreenState(path,songs);
}

class _PlayScreenState extends State<PlayScreen> {
  String path;
  List<SongInfo> songs;
  _PlayScreenState(String path,List<SongInfo> songs){
    this.path=path;
    this.songs=songs;
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(child: Card( child:PlayerWidget(url: path,songs: songs,),elevation: 100,),) ,
    );
  }
}

