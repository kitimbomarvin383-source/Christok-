import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const ChrisTokApp());

class ChrisTokApp extends StatelessWidget {
  const ChrisTokApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ChrisTok',
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: const FeedPage(),
    );
  }
}

class VideoItem {
  final String url; final String caption; final String user;
  VideoItem({required this.url, required this.caption, required this.user});
}

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});
  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  List<VideoItem> videos = [
    VideoItem(url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4', caption: 'Welcome to ChrisTok 🇺🇬 #Uganda', user: '@christok'),
    VideoItem(url: 'https://flutter.github.io/assets-for-api-docs/assets/videos/butterfly.mp4', caption: 'First video on ChrisTok! 🔥', user: '@marvin'),
  ];
  bool uploading = false;

  Future<void> pickAndUpload() async {
    final XFile? file = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() => uploading = true);
    try {
      var req = http.MultipartRequest('POST', Uri.parse('https://api.cloudinary.com/v1_1/lkb5goug/video/upload'));
      req.fields['upload_preset'] = 'K-group company';
      req.files.add(await http.MultipartFile.fromPath('file', file.path));
      var res = await req.send();
      var body = await res.stream.bytesToString();
      var url = jsonDecode(body)['secure_url'] ?? '';
      if (url != '') {
        setState(() => videos.insert(0, VideoItem(url: url, caption: 'New upload 🔥 #ChrisTok', user: '@you')));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploaded! 🎉')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $body')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => uploading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: videos.length,
        itemBuilder: (context, i) => VideoCard(video: videos[i]),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: uploading ? null : pickAndUpload,
        child: uploading ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black, selectedItemColor: Colors.white, unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add_box), label: 'Upload'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class VideoCard extends StatefulWidget {
  final VideoItem video; const VideoCard({super.key, required this.video});
  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  VideoPlayerController? c; bool liked = false; int likes = 124;
  @override
  void initState() {
    super.initState();
    c = VideoPlayerController.networkUrl(Uri.parse(widget.video.url))
      ..initialize().then((_) { setState(() {}); c!.setLooping(true); c!.play(); });
  }
  @override
  void dispose() { c?.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Center(child: c != null && c!.value.isInitialized ? AspectRatio(aspectRatio: c!.value.aspectRatio, child: VideoPlayer(c!)) : const CircularProgressIndicator(color: Colors.red)),
      Positioned(left: 12, bottom: 80, right: 80, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.video.user, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        const SizedBox(height: 6),
        Text(widget.video.caption, style: const TextStyle(fontSize: 14)),
      ])),
      Positioned(right: 12, bottom: 100, child: Column(children: [
        IconButton(icon: Icon(liked ? Icons.favorite : Icons.favorite_border, color: liked ? Colors.red : Colors.white, size: 32), onPressed: () => setState(() { liked = !liked; likes += liked ? 1 : -1; })),
        Text('$likes'),
        const SizedBox(height: 16),
        const Icon(Icons.comment, size: 30), const Text('12'),
        const SizedBox(height: 16),
        const Icon(Icons.share, size: 30), const Text('Share'),
      ])),
      const Positioned(top: 40, left: 0, right: 0, child: Center(child: Text('ChrisTok', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)))),
    ]);
  }
}
