import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';

const String appId = "90968e54379c4bbab2376478da2b0d15";

class VideoCallScreen extends StatefulWidget {
  final String channelName;
  final int initialCoins;

  const VideoCallScreen({
    super.key, 
    required this.channelName, 
    this.initialCoins = 100 // ডেমো হিসেবে ১০০ কয়েন
  });

  @override
  State<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends State<VideoCallScreen> {
  int? _remoteUid; // int এর পর একটি ? চিহ্ন এবং সেমিকোলন
  bool _localUserJoined = false;
  bool _muted = false;
  late RtcEngine _engine;
  
  late int userCoins;
  Timer? _coinTimer;
  int _callDurationSeconds = 0;

  @override
  void initState() {
    super.initState();
    userCoins = widget.initialCoins;
    initAgora();
  }

  // প্রতি ১ মিনিটে ১০ কয়েন কাটার লজিক
  void _startCoinDeduction() {
    _coinTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _callDurationSeconds++;
      });

      // প্রতি ৬০ সেকেন্ডে ১০ কয়েন কাটা যাবে
      if (_callDurationSeconds % 60 == 0) {
        setState(() {
          userCoins -= 10;
        });

        // কয়েন শেষ হয়ে গেলে কল অটোমেটিক কেটে যাবে
        if (userCoins <= 0) {
          _coinTimer?.cancel();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coins finished! Call ended.')),
          );
          Navigator.pop(context);
        }
      }
    });
  }

  Future<void> initAgora() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
          _startCoinDeduction(); // পার্টনার জয়েন করলেই টাইমার চালু হবে
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _coinTimer?.cancel();
          if (mounted) Navigator.pop(context);
        },
      ),
    );

    await _engine.enableVideo();
    await _engine.startPreview();
    await _engine.joinChannel(
      token: '',
      channelId: widget.channelName,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _coinTimer?.cancel();
    _engine.leaveChannel();
    _engine.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),

          // টপ লেফট: কয়েন ও কল টাইমার কাউন্টার UI (Poca Style)
          Positioned(
            top: 45,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                  const SizedBox(width: 5),
                  Text('$userCoins', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 15),
                  const Icon(Icons.timer, color: Colors.white70, size: 18),
                  const SizedBox(width: 4),
                  Text('${_callDurationSeconds}s', style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),

          // নিজের ভিডিও
          Positioned(
            top: 45,
            right: 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 100,
                height: 140,
                child: _localUserJoined
                    ? AgoraVideoView(controller: VideoViewController(rtcEngine: _engine, canvas: const VideoCanvas(uid: 0)))
                    : const Center(child: CircularProgressIndicator(color: Colors.pink)),
              ),
            ),
          ),

          // কন্ট্রোল বাটন
          Positioned(
            bottom: 35,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: IconButton(
                    icon: Icon(_muted ? Icons.mic_off : Icons.mic, color: Colors.white),
                    onPressed: () {
                      setState(() => _muted = !_muted);
                      _engine.muteLocalAudioStream(_muted);
                    },
                  ),
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.call_end, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    }
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: Colors.pink),
        SizedBox(height: 12),
        Text('Matching with user...', style: TextStyle(color: Colors.white)),
      ],
    );
  }
}






//--- coin styem none------------




// import 'package:agora_rtc_engine/agora_rtc_engine.dart';
// import 'package:flutter/material.dart';
// import 'package:permission_handler/permission_handler.dart';

// // আপনার Agora App ID এখানে বসান
// const String appId = "90968e54379c4bbab2376478da2b0d15"; 

// class VideoCallScreen extends StatefulWidget {
//   final String channelName;
//   const VideoCallScreen({super.key, required this.channelName});

//   @override
//   State<VideoCallScreen> createState() => _VideoCallScreenState();
// }

// class _VideoCallScreenState extends State<VideoCallScreen> {
//   int? _remoteUid;
//   bool _localUserJoined = false;
//   late RtcEngine _engine;

//   @override
//   void initState() {
//     super.initState();
//     initAgora();
//   }

//   Future<void> initAgora() async {
//     // ক্যামেরা ও মাইক্রোফোনের পারমিশন নেওয়া
//     await [Permission.camera, Permission.microphone].request();

//     // Agora Engine ইনিশিয়ালাইজ করা
//     _engine = createAgoraRtcEngine();
//     await _engine.initialize(const RtcEngineContext(
//       appId: appId,
//       channelProfile: ChannelProfileType.channelProfileCommunication,
//     ));

//     // ইভেন্ট হ্যান্ডলার যুক্ত করা
//     _engine.registerEventHandler(
//       RtcEngineEventHandler(
//         onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
//           setState(() {
//             _localUserJoined = true;
//           });
//         },
//         onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
//           setState(() {
//             _remoteUid = remoteUid;
//           });
//         },
//         onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
//           setState(() {
//             _remoteUid = null;
//           });
//           Navigator.pop(context); // কল কেটে গেলে স্ক্রিন বন্ধ করা
//         },
//       ),
//     );

//     await _engine.enableVideo();
//     await _engine.startPreview();

//     // চ্যানেলে জয়েন করা (টেস্টিংয়ের জন্য টোকেন ফাঁকা রাখা হয়েছে)
//     await _engine.joinChannel(
//       token: '',
//       channelId: widget.channelName,
//       uid: 0,
//       options: const ChannelMediaOptions(),
//     );
//   }

//   @override
//   void dispose() {
//     _engine.leaveChannel();
//     _engine.release();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         children: [
//           // অপর পাশের ইউজারের ভিডিও (Full Screen)
//           Center(child: _remoteVideo()),
          
//           // নিজের ভিডিও (ছোট উইন্ডো)
//           Align(
//             alignment: Alignment.topRight,
//             child: SizedBox(
//               width: 120,
//               height: 160,
//               child: Center(
//                 child: _localUserJoined
//                     ? AgoraVideoView(
//                         controller: VideoViewController(
//                           rtcEngine: _engine,
//                           canvas: const VideoCanvas(uid: 0),
//                         ),
//                       )
//                     : const CircularProgressIndicator(),
//               ),
//             ),
//           ),

//           // কল এন্ড বাটন
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 30.0),
//               child: FloatingActionButton(
//                 backgroundColor: Colors.red,
//                 onPressed: () => Navigator.pop(context),
//                 child: const Icon(Icons.call_end, color: Colors.white),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // অপর পাশের ভিডিও রেন্ডার করা
//   Widget _remoteVideo() {
//     if (_remoteUid != null) {
//       return AgoraVideoView(
//         controller: VideoViewController.remote(
//           rtcEngine: _engine,
//           canvas: VideoCanvas(uid: _remoteUid),
//           connection: RtcConnection(channelId: widget.channelName),
//         ),
//       );
//     } else {
//       return const Text(
//         'Matching with user...',
//         style: TextStyle(color: Colors.white, fontSize: 18),
//       );
//     }
//   }
// }