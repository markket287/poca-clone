import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'video_call_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userName;
  final String userGender;

  const HomeScreen({
    super.key,
    required this.userName,
    required this.userGender,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late IO.Socket socket;
  bool isSearching = false;
  late String selectedTargetGender;

  @override
  void initState() {
    super.initState();
    // ইউজার যদি Male হয় তবে ডিফল্ট Target Female, আর ইউজার Female হলে Target Male
    selectedTargetGender = widget.userGender == 'male' ? 'female' : 'male';
    _requestPermissions();
    _connectSocket();
  }

  Future<void> _requestPermissions() async {
    await [Permission.camera, Permission.microphone].request();
  }

  void _connectSocket() {
    socket = IO.io('http://10.0.2.2:3000', IO.OptionBuilder().setTransports(['websocket']).build());
    socket.connect();

    socket.on('match_found', (data) {
      setState(() => isSearching = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoCallScreen(channelName: data['channelName']),
        ),
      );
    });
  }

  void _startMatching() {
    setState(() => isSearching = true);
    // ব্যাকএন্ডে ডাইনামিক প্রোফাইল ডাটা পাঠানো হচ্ছে
    socket.emit('find_match', {
      'userName': widget.userName,
      'gender': widget.userGender,
      'targetGender': selectedTargetGender,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${widget.userName}'),
        backgroundColor: Colors.pinkAccent,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your Gender: ${widget.userGender.toUpperCase()}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Match Female'),
                  selected: selectedTargetGender == 'female',
                  selectedColor: Colors.pinkAccent,
                  onSelected: (val) => setState(() => selectedTargetGender = 'female'),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Match Male'),
                  selected: selectedTargetGender == 'male',
                  selectedColor: Colors.pinkAccent,
                  onSelected: (val) => setState(() => selectedTargetGender = 'male'),
                ),
              ],
            ),
            const SizedBox(height: 30),
            isSearching
                ? const CircularProgressIndicator(color: Colors.pink)
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.pink,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    ),
                    onPressed: _startMatching,
                    child: const Text('Start Match', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}