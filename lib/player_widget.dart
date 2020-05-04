import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_query/flutter_audio_query.dart';

enum PlayerState { stopped, playing, paused }
enum PlayingRouteState { speakers, earpiece }

class PlayerWidget extends StatefulWidget {
  final String url;
  final PlayerMode mode;
  int index;
  List<SongInfo> songs;
  PlayerWidget(
      {Key key, @required this.url,@required this.songs ,this.mode = PlayerMode.MEDIA_PLAYER})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    index = songs.indexOf(songs.singleWhere((element) => element.filePath==url));
    return _PlayerWidgetState(url, mode,index,songs);
  }
}

class _PlayerWidgetState extends State<PlayerWidget> {
  String url;
  PlayerMode mode;
  int index;
  List<SongInfo> songs;
  AudioPlayer _audioPlayer;
  AudioPlayerState _audioPlayerState;
  Duration _duration;
  Duration _position;

  PlayerState _playerState = PlayerState.stopped;
  PlayingRouteState _playingRouteState = PlayingRouteState.speakers;
  StreamSubscription _durationSubscription;
  StreamSubscription _positionSubscription;
  StreamSubscription _playerCompleteSubscription;
  StreamSubscription _playerErrorSubscription;
  StreamSubscription _playerStateSubscription;

  get _isPlaying => _playerState == PlayerState.playing;
  get _isPaused => _playerState == PlayerState.paused;
  get _durationText => _duration?.toString()?.split('.')?.first ?? '';
  get _positionText => _position?.toString()?.split('.')?.first ?? '';

  get _isPlayingThroughEarpiece =>
      _playingRouteState == PlayingRouteState.earpiece;

  _PlayerWidgetState(this.url, this.mode,this.index,this.songs);

  @override
  void initState() {
    super.initState();
    _stop();
    _initAudioPlayer();
    _play();
  }
  @override
  void dispose() {
    _audioPlayer.dispose();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _playerErrorSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }
  String name(String s){
    return s.substring(s.lastIndexOf("/")+1);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title:   Text(name(songs[index].filePath)),
        leading: IconButton(icon: Icon(Icons.arrow_back), onPressed: (){_stop();Navigator.of(context).pop();}),

      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Container(height: 30,),
            Container(height: 50,),
            Container(child: Image.asset("assets/music.jpg",),height: 400,),
            Container(height: 80,),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: EdgeInsets.only(left:38.0),
                  child: Row(
                      children:[Text(_position != null
                          ? '${_positionText ?? ''}'
                          : '00:00:00',style: TextStyle(color: Colors.white70),
                      ),Stack(
                        children: [
                          Slider(
                            onChanged: (v) {
                              final Position = v * _duration.inMilliseconds;
                              _audioPlayer
                                  .seek(Duration(milliseconds: Position.round()));
                            },

                            value: (_position != null &&
                                _duration != null &&
                                _position.inMilliseconds > 0 &&
                                _position.inMilliseconds < _duration.inMilliseconds)
                                ? _position.inMilliseconds / _duration.inMilliseconds
                                : 0.0,
                          ),
                        ],
                      ),
                        Text(
                            _durationText,style: TextStyle(color: Colors.white70),
                        ),
                      ]),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [

                IconButton(
                  onPressed: (this.index!=0) ? (){_stop();setState(() {
                    index--;
                    url=songs[index-1].filePath;
                    _duration=Duration(seconds: 0);
                    _position=Duration(seconds: 0);
                  });_play();}: null,
                  iconSize: 64.0,
                  icon:  Icon(Icons.skip_previous),
                  color: Colors.white,
                ),
                IconButton(
                  key: Key('play_button'),
                  onPressed: _isPlaying ? ()=> _pause()  : () => _play(),
                  iconSize: 64.0,
                  icon: _isPlaying ? Icon(Icons.pause):Icon(Icons.play_arrow),
                  color: Colors.white,
                ),
                IconButton(
                  onPressed: (this.index!=(songs.length-1)) ? (){_stop();setState(() {
                    url=songs[index+1].filePath;
                    index++;
                    _duration=Duration(seconds: 0);
                    _position=Duration(seconds: 0);
                  });_play();} : null,
                  iconSize: 64.0,
                  icon:  Icon(Icons.skip_previous),
                  color: Colors.white,
                ),
              ],
            ),

          ],
        ),
      )
    );
  }

  void _initAudioPlayer() {
    _audioPlayer = AudioPlayer(mode: mode);

    _durationSubscription = _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);

      // TODO implemented for iOS, waiting for android impl
      if (Theme.of(context).platform == TargetPlatform.iOS) {
        // (Optional) listen for notification updates in the background
        _audioPlayer.startHeadlessService();

        // set at least title to see the notification bar on ios.
        _audioPlayer.setNotification(
            title: 'App Name',
            artist: 'Artist or blank',
            albumTitle: 'Name or blank',
            imageUrl: 'url or blank',
            forwardSkipInterval: const Duration(seconds: 30), // default is 30s
            backwardSkipInterval: const Duration(seconds: 30), // default is 30s
            duration: duration,
            elapsedTime: Duration(seconds: 0));
      }
    });

    _positionSubscription =
        _audioPlayer.onAudioPositionChanged.listen((p) => setState(() {
          _position = p;
        }));

    _playerCompleteSubscription =
        _audioPlayer.onPlayerCompletion.listen((event) {
          _onComplete();
        });

    _playerErrorSubscription = _audioPlayer.onPlayerError.listen((msg) {
      print('audioPlayer error : $msg');
      setState(() {
        _playerState = PlayerState.stopped;
        _duration = Duration(seconds: 0);
        _position = Duration(seconds: 0);
      });
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() {
        _audioPlayerState = state;
      });
    });

    _audioPlayer.onNotificationPlayerStateChanged.listen((state) {
      if (!mounted) return;
      setState(() => _audioPlayerState = state);
    });

    _playingRouteState = PlayingRouteState.speakers;
  }
  Future<int> _play() async {
    final playPosition = (_position != null &&
        _duration != null &&
        _position.inMilliseconds > 0 &&
        _position.inMilliseconds < _duration.inMilliseconds)
        ? _position
        : null;
    final result = await _audioPlayer.play(url, position: playPosition);
    if (result == 1) setState(() => _playerState = PlayerState.playing);

    // default playback rate is 1.0
    // this should be called after _audioPlayer.play() or _audioPlayer.resume()
    // this can also be called everytime the user wants to change playback rate in the UI
    _audioPlayer.setPlaybackRate(playbackRate: 1.0);

    return result;
  }

  Future<int> _pause() async {
    final result = await _audioPlayer.pause();
    if (result == 1) setState(() => _playerState = PlayerState.paused);
    return result;
  }

  Future<int> _earpieceOrSpeakersToggle() async {
    final result = await _audioPlayer.earpieceOrSpeakersToggle();
    if (result == 1)
      setState(() => _playingRouteState =
      _playingRouteState == PlayingRouteState.speakers
          ? PlayingRouteState.earpiece
          : PlayingRouteState.speakers);
    return result;
  }

  Future<int> _stop() async {
    final result = await _audioPlayer.stop();
    if (result == 1) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration();
      });
    }
    return result;
  }

  void _onComplete() {
    print("songs copmpleted");
    setState(() {
      _stop();
      _position = _duration;
      url=songs[index+1].filePath;
      index++;
      _duration=Duration(seconds: 0);
      _position=Duration(seconds: 0);
      sleep(Duration(seconds: 2));
      _play();
    });
  }
}