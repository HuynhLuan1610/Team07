import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Map<String, String>> _songs = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadMusicFiles();
  }

  Future<void> _loadMusicFiles() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final musicFiles = manifestMap.keys
          .where((String key) => key.contains('assets/musics/') && key.endsWith('.mp3'))
          .toList();

      setState(() {
        _songs = musicFiles.map((path) {
          final fileName = path.split('/').last;
          final title = fileName.replaceAll('.mp3', '');
          // Loại bỏ "assets/" từ đường dẫn
          final assetPath = path.replaceFirst('assets/', '');
          return {
            "title": title,
            "filePath": assetPath,
          };
        }).toList();
      });
    } catch (e) {
      debugPrint("Error loading music files: $e");
    }
  }

  void _playSong(String filePath) async {
    String assetPath = filePath.replaceFirst('assets/', '');
    await _audioPlayer.play(AssetSource(filePath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Music Player"),
        backgroundColor: Colors.purple,
      ),
      body: _songs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _songs.length,
        itemBuilder: (context, index) {
          final song = _songs[index];
          return ListTile(
            title: Text(song['title']!),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () => _playSong(song['filePath']!),
            ),
          );
        },
      ),
    );
  }
}
