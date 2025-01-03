import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:video_player/video_player.dart';  // Import video_player package
import 'package:spotify/common/helpers/is_dark_mode.dart';
import 'package:spotify/core/configs/assets/app_images.dart';
import 'package:spotify/core/configs/theme/app_colors.dart';
import 'package:spotify/presentation/home/widgets/news_songs.dart';
import 'package:spotify/presentation/home/widgets/play_list.dart';
import 'package:spotify/presentation/profile/pages/profile.dart';
import '../../../common/widgets/appbar/app_bar.dart';
import '../../../core/configs/assets/app_vectors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, String>> _songs = [];
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;  // Trạng thái phát nhạc
  bool _isLooping = false;  // Trạng thái lặp lại
  bool _isShuffling = false;  // Trạng thái ngẫu nhiên
  Duration _currentPosition = Duration.zero;  // Thời gian hiện tại của bài hát
  Duration _totalDuration = Duration.zero;  // Thời gian tổng của bài hát

  int? _currentSongIndex;  // Chỉ số bài hát đang phát
  VideoPlayerController? _videoPlayerController;  // Video player controller
  bool _isVideoPlaying = false;  // Trạng thái phát video

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMusicFiles();

    // Lắng nghe sự thay đổi của trạng thái nhạc
    _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _currentPosition = p;
      });
    });

    _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _totalDuration = d;
      });
    });
  }

  // Hàm load các file nhạc
  Future<void> _loadMusicFiles() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final musicFiles = manifestMap.keys
          .where((String key) =>
      key.contains('assets/musics/') && key.endsWith('.mp3'))
          .toList();

      setState(() {
        _songs = musicFiles.map((path) {
          final fileName = path.split('/').last;
          final title = fileName.replaceAll('.mp3', '');
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

  // Hàm phát video từ thư mục assets/videos
  Future<void> _playVideo(String assetPath) async {
    _videoPlayerController = VideoPlayerController.asset(assetPath)
      ..initialize().then((_) {
        setState(() {
          _isVideoPlaying = true;
        });
        _videoPlayerController?.play();
      });
  }

  // Hàm dừng video
  void _stopVideo() {
    setState(() {
      _isVideoPlaying = false;
    });
    _videoPlayerController?.pause();
  }

  // Hàm để dừng bài hát hiện tại và phát bài mới
  void _playSong(int index) async {
    // Dừng bài hát hiện tại nếu có
    if (_currentSongIndex != null) {
      await _audioPlayer.stop();
    }

    String assetPath = _songs[index]['filePath']!;
    await _audioPlayer.play(AssetSource(assetPath));
    setState(() {
      _isPlaying = true;
      _currentSongIndex = index;  // Lưu chỉ số bài hát đang phát
    });
  }

  void _stopSong() async {
    await _audioPlayer.stop();
    setState(() {
      _isPlaying = false;
      _currentSongIndex = null;  // Xóa chỉ số bài hát đang phát
    });
  }

  void _toggleLoop() {
    setState(() {
      _isLooping = !_isLooping;
      _audioPlayer.setReleaseMode(
        _isLooping ? ReleaseMode.loop : ReleaseMode.release,
      );
    });
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffling = !_isShuffling;
    });
  }

  void _playRandomSong() {
    final randomIndex = (List.generate(_songs.length, (index) => index)..shuffle()).first;
    _playSong(randomIndex);
  }

  void _nextSong() async {
    if (_isShuffling) {
      _playRandomSong(); // Nếu shuffle, chọn bài ngẫu nhiên
    } else {
      int nextIndex = (_currentSongIndex! + 1) % _songs.length;
      _playSong(nextIndex);
    }
  }

  void _previousSong() async {
    if (_isShuffling) {
      _playRandomSong(); // Nếu shuffle, chọn bài ngẫu nhiên
    } else {
      int previousIndex = (_currentSongIndex! - 1 + _songs.length) % _songs.length;
      _playSong(previousIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        hideBack: true,
        action: IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (BuildContext context) => const ProfilePage(),
              ),
            );
          },
          icon: const Icon(Icons.person),
        ),
        title: SvgPicture.asset(
          AppVectors.logo,
          height: 40,
          width: 40,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _homeTopCard(),
            _tabs(),
            SizedBox(
              height: 260,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMusicList(),
                  _buildVideoTab(),  // Cập nhật tab videos để phát video
                  Container(),
                  Container(),
                ],
              ),
            ),
            const PlayList(),
            _buildMusicPlayerControls(), // Trình phát nhạc ở dưới
          ],
        ),
      ),
    );
  }

  // Tab Video
  Widget _buildVideoTab() {
    return _isVideoPlaying
        ? AspectRatio(
      aspectRatio: 16 / 9,
      child: VideoPlayer(_videoPlayerController!),
    )
        : Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Tap to play video", style: TextStyle(fontSize: 18)),
          ElevatedButton(
            onPressed: () {
              _playVideo('assets/videos/sample_video.mp4');
            },
            child: Text("Play Video"),
          ),
        ],
      ),
    );
  }

  // Tab Music List
  Widget _buildMusicList() {
    return _songs.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
      itemCount: _songs.length,
      itemBuilder: (context, index) {
        final song = _songs[index];
        return GestureDetector(
          onDoubleTap: () => _stopSong(),
          child: ListTile(
            title: Text(
              song['title']!,
              style: TextStyle(
                color: context.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            trailing: IconButton(
              icon: Icon(
                _currentSongIndex == index && _isPlaying
                    ? Icons.pause
                    : Icons.play_arrow,
                color: AppColors.primary,
              ),
              onPressed: () {
                if (_currentSongIndex == index && _isPlaying) {
                  _stopSong();  // Nếu bài đang phát, dừng lại
                } else {
                  _playSong(index);  // Phát bài này và dừng bài trước đó
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _homeTopCard() {
    return Center(
      child: SizedBox(
        height: 140,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: SvgPicture.asset(AppVectors.homeTopCard),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 60),
                child: Image.asset(AppImages.homeArtist),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabs() {
    return TabBar(
      controller: _tabController,
      isScrollable: true,
      labelColor: context.isDarkMode ? Colors.white : Colors.black,
      indicatorColor: AppColors.primary,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
      tabs: const [
        Text(
          'News',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Text(
          'Videos',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Text(
          'Artists',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
        Text(
          'Podcasts',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildMusicPlayerControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(40),
      ),
      child: Column(
        children: [
          // Thanh Timeline
          Slider(
            value: _currentPosition.inSeconds.toDouble(),
            min: 0.0,
            max: _totalDuration.inSeconds.toDouble(),
            onChanged: (double value) {
              setState(() {
                _audioPlayer.seek(Duration(seconds: value.toInt()));
              });
            },
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(color: Colors.black),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(
                  _isShuffling ? Icons.shuffle : Icons.shuffle_outlined,
                  color: Colors.black,
                ),
                onPressed: _toggleShuffle,
                iconSize: 24,
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_previous,
                  color: Colors.black,
                ),
                onPressed: _previousSong,
                iconSize: 24,
              ),
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause : Icons.play_arrow,
                  color: Colors.black,
                ),
                onPressed: () {
                  if (_isPlaying) {
                    _stopSong();
                  } else {
                    _playSong(_currentSongIndex ?? 0);
                  }
                },
                iconSize: 32,
              ),
              IconButton(
                icon: Icon(
                  Icons.skip_next,
                  color: Colors.black,
                ),
                onPressed: _nextSong,
                iconSize: 24,
              ),
              IconButton(
                icon: Icon(
                  _isLooping ? Icons.repeat_one : Icons.repeat,
                  color: Colors.black,
                ),
                onPressed: _toggleLoop,
                iconSize: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}
