import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';

// ⚠️ APNAR PC-ER IPv4 ADDRESS BOSAN (CMD -> ipconfig)
// Example: 'http://192.168.0.105:3000'
const String SERVER_URL = 'http://192.168.0.105:3000';

// ⚠️ AGORA APP ID (Agora Console theke paben)
const String AGORA_APP_ID = "YOUR_AGORA_APP_ID_HERE";

void main() {
  runApp(const PocaApp());
}

class PocaApp extends StatelessWidget {
  const PocaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Poca Live Clone',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.pink,
        scaffoldBackgroundColor: const Color(0xFFFAF7F2),
      ),
      home: const MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 1; // Default to Match Tab

  final List<Widget> _screens = [
    const HomeScreen(),
    const MatchScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.pinkAccent,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded, size: 28),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore_rounded, size: 32),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded, size: 28),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ------------------- 1. HOME TAB -------------------
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> dummyUsers = [
      {'name': 'Roman Faria', 'age': '21', 'img': 'https://picsum.photos/200/300?random=1'},
      {'name': 'Rupa Rane', 'age': '22', 'img': 'https://picsum.photos/200/300?random=2'},
      {'name': 'Cute Girl', 'age': '19', 'img': 'https://picsum.photos/200/300?random=3'},
      {'name': 'Rani Rai', 'age': '23', 'img': 'https://picsum.photos/200/300?random=4'},
      {'name': 'Pori', 'age': '20', 'img': 'https://picsum.photos/200/300?random=5'},
      {'name': 'Sohana', 'age': '24', 'img': 'https://picsum.photos/200/300?random=6'},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF7F2),
        elevation: 0,
        title: Row(
          children: const [
            Text('Popular', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
            SizedBox(width: 15),
            Text('Follow', style: TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: GridView.builder(
          itemCount: dummyUsers.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemBuilder: (context, index) {
            final user = dummyUsers[index];
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                image: DecorationImage(
                  image: NetworkImage(user['img']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.greenAccent,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${user['name']}, ${user['age']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ------------------- 2. MATCH TAB (Real-time Video Match) -------------------
class MatchScreen extends StatefulWidget {
  const MatchScreen({super.key});

  @override
  State<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends State<MatchScreen> {
  late IO.Socket socket;
  bool isMatching = false;
  String targetGender = 'female'; // Default target gender

  @override
  void initState() {
    super.initState();
    _connectSocket();
  }

  void _connectSocket() {
    socket = IO.io(SERVER_URL, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket.onConnect((_) {
      print('Connected to Socket Server: ${socket.id}');
    });

    // Handle Match Found from Node.js Server
    socket.on('match_found', (data) {
      if (mounted) {
        setState(() => isMatching = false);
        String channelName = data['channelName'] ?? 'test_channel';
        
        // Navigate to Call View Screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CallScreen(channelName: channelName),
          ),
        );
      }
    });

    socket.onDisconnect((_) => print('Socket Disconnected'));
  }

  void _startMatching() async {
    await [Permission.camera, Permission.microphone].request();

    if (!socket.connected) {
      socket.connect();
    }

    setState(() => isMatching = true);

    // Emit 'find_match' with Gender preferences to Node.js Backend
    socket.emit('find_match', {
      'gender': 'male',
      'targetGender': targetGender,
    });
  }

  void _cancelMatching() {
    socket.emit('cancel_match');
    setState(() => isMatching = false);
  }

  @override
  void dispose() {
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Top Filter Options
            Positioned(
              top: 15,
              right: 20,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Female'),
                    selected: targetGender == 'female',
                    onSelected: (val) => setState(() => targetGender = 'female'),
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Male'),
                    selected: targetGender == 'male',
                    onSelected: (val) => setState(() => targetGender = 'male'),
                  ),
                ],
              ),
            ),

            // Center Glowing Match Button
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: isMatching ? _cancelMatching : _startMatching,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Color(0xFFFFF3A0), Color(0xFFFF8EAB)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.pink.withOpacity(0.3),
                            blurRadius: 25,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Center(
                        child: isMatching
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  CircularProgressIndicator(color: Colors.white),
                                  SizedBox(height: 12),
                                  Text(
                                    'Searching...',
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Free',
                                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white24,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.flash_on, color: Colors.yellow, size: 14),
                                        Text(' Match', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- 3. AGORA VIDEO CALL SCREEN -------------------
class CallScreen extends StatefulWidget {
  final String channelName;
  const CallScreen({super.key, required this.channelName});

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    await [Permission.camera, Permission.microphone].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(const RtcEngineContext(
      appId: AGORA_APP_ID,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          setState(() => _localUserJoined = true);
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          setState(() => _remoteUid = null);
          Navigator.pop(context);
        },
      ),
    );

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
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
          Positioned(
            top: 40,
            right: 20,
            width: 100,
            height: 140,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: _engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: FloatingActionButton(
                backgroundColor: Colors.red,
                onPressed: () => Navigator.pop(context),
                child: const Icon(Icons.call_end, color: Colors.white),
              ),
            ),
          )
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
    } else {
      return const Text(
        'Connecting to Partner...',
        style: TextStyle(color: Colors.white, fontSize: 16),
      );
    }
  }
}

// ------------------- 4. PROFILE TAB -------------------
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.grey,
                    icon: Icon(Icons.person, size: 40, color: Colors.white),
                  ),
                  const SizedBox(width: 15),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Masum Islam', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Row(
                        children: const [
                          Icon(Icons.male, color: Colors.blue, size: 16),
                          Text(' 22  🇧🇩 Bangladesh', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}






//-------------------------- mina poca-app-------------------

// import 'package:flutter/material.dart';

// void main() {
//   runApp(const PocaApp());
// }

// class PocaApp extends StatelessWidget {
//   const PocaApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Poca Live Clone',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         primarySwatch: Colors.pink,
//         scaffoldBackgroundColor: const Color(0xFFFAF7F2),
//       ),
//       home: const MainTabScreen(),
//     );
//   }
// }

// class MainTabScreen extends StatefulWidget {
//   const MainTabScreen({super.key});

//   @override
//   State<MainTabScreen> createState() => _MainTabScreenState();
// }

// class _MainTabScreenState extends State<MainTabScreen> {
//   int _currentIndex = 1; // Default to Match Tab

//   final List<Widget> _screens = [
//     const HomeScreen(),
//     const MatchScreen(),
//     const ProfileScreen(),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: IndexedStack(
//         index: _currentIndex,
//         children: _screens,
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _currentIndex,
//         onTap: (index) => setState(() => _currentIndex = index),
//         selectedItemColor: Colors.pinkAccent,
//         unselectedItemColor: Colors.grey,
//         showSelectedLabels: false,
//         showUnselectedLabels: false,
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.grid_view_rounded, size: 28),
//             label: 'Home',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.explore_rounded, size: 32),
//             label: 'Match',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person_rounded, size: 28),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
// }

// // ------------------- 1. HOME TAB (Profiles Grid) -------------------
// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     final List<Map<String, String>> dummyUsers = [
//       {'name': 'Roman Faria', 'age': '21', 'img': 'https://picsum.photos/200/300?random=1'},
//       {'name': 'Rupa Rane', 'age': '22', 'img': 'https://picsum.photos/200/300?random=2'},
//       {'name': 'Cute Girl', 'age': '19', 'img': 'https://picsum.photos/200/300?random=3'},
//       {'name': 'Rani Rai', 'age': '23', 'img': 'https://picsum.photos/200/300?random=4'},
//       {'name': 'Pori', 'age': '20', 'img': 'https://picsum.photos/200/300?random=5'},
//       {'name': 'Sohana', 'age': '24', 'img': 'https://picsum.photos/200/300?random=6'},
//     ];

//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: const Color(0xFFFAF7F2),
//         elevation: 0,
//         title: Row(
//           children: const [
//             Text('Popular', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
//             SizedBox(width: 15),
//             Text('Follow', style: TextStyle(color: Colors.grey, fontSize: 16)),
//           ],
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 10),
//         child: GridView.builder(
//           itemCount: dummyUsers.length,
//           gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//             crossAxisCount: 2,
//             childAspectRatio: 0.85,
//             crossAxisSpacing: 10,
//             mainAxisSpacing: 10,
//           ),
//           itemBuilder: (context, index) {
//             final user = dummyUsers[index];
//             return Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(15),
//                 image: DecorationImage(
//                   image: NetworkImage(user['img']!),
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               child: Stack(
//                 children: [
//                   Container(
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(15),
//                       gradient: LinearGradient(
//                         begin: Alignment.topCenter,
//                         end: Alignment.bottomCenter,
//                         colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
//                       ),
//                     ),
//                   ),
//                   Positioned(
//                     bottom: 10,
//                     left: 10,
//                     child: Row(
//                       children: [
//                         const CircleAvatar(
//                           radius: 5,
//                           backgroundColor: Colors.greenAccent,
//                         ),
//                         const SizedBox(width: 5),
//                         Text(
//                           '${user['name']}, ${user['age']}',
//                           style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//                         ),
//                       ],
//                     ),
//                   )
//                 ],
//               ),
//             );
//           },
//         ),
//       ),
//     );
//   }
// }

// // ------------------- 2. MATCH TAB (Poca Center Glowing Match) -------------------
// class MatchScreen extends StatefulWidget {
//   const MatchScreen({super.key});

//   @override
//   State<MatchScreen> createState() => _MatchScreenState();
// }

// class _MatchScreenState extends State<MatchScreen> {
//   bool isMatching = false;

//   void _startMatching() {
//     setState(() => isMatching = true);
//     // 3 Second simulated matching delay
//     Future.delayed(const Duration(seconds: 3), () {
//       if (mounted) {
//         setState(() => isMatching = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Server not connected! Set PC IP in backend code.')),
//         );
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Stack(
//           alignment: Alignment.center,
//           children: [
//             // Top Bar Icons
//             Positioned(
//               top: 15,
//               right: 20,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Row(
//                   children: const [
//                     Icon(Icons.flash_on, color: Colors.orange, size: 18),
//                     SizedBox(width: 4),
//                     Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
//                   ],
//                 ),
//               ),
//             ),
//             // Center Poca Match Ring
//             Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   GestureDetector(
//                     onTap: _startMatching,
//                     child: Container(
//                       width: 220,
//                       height: 220,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: const RadialGradient(
//                           colors: [Color(0xFFFFF3A0), Color(0xFFFF8EAB)],
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: Colors.pink.withOpacity(0.3),
//                             blurRadius: 25,
//                             spreadRadius: 10,
//                           )
//                         ],
//                       ),
//                       child: Center(
//                         child: isMatching
//                             ? const CircularProgressIndicator(color: Colors.white)
//                             : Column(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   const Text(
//                                     'Free',
//                                     style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
//                                   ),
//                                   const SizedBox(height: 5),
//                                   Container(
//                                     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
//                                     decoration: BoxDecoration(
//                                       color: Colors.white24,
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     child: Row(
//                                       mainAxisSize: MainAxisSize.min,
//                                       children: const [
//                                         Icon(Icons.flash_on, color: Colors.yellow, size: 14),
//                                         Text(' 3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // ------------------- 3. PROFILE TAB (User & Daily Rewards) -------------------
// class ProfileScreen extends StatelessWidget {
//   const ProfileScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             children: [
//               // Profile Header
//               Row(
//                 children: [
//                   const CircleAvatar(
//                     radius: 35,
//                     backgroundColor: Colors.grey,
//                     child: Icon(Icons.person, size: 40, color: Colors.white),
//                   ),
//                   const SizedBox(width: 15),
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       const Text('Masum Islam', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                       const SizedBox(height: 4),
//                       Row(
//                         children: const [
//                           Icon(Icons.male, color: Colors.blue, size: 16),
//                           Text(' 22  🇧🇩 Bangladesh', style: TextStyle(color: Colors.grey)),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 25),

//               // Wallet Cards
//               Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.all(15),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFFF7E6),
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: const [
//                           Icon(Icons.flash_on, color: Colors.orange),
//                           SizedBox(height: 8),
//                           Text('Tokens', style: TextStyle(color: Colors.grey)),
//                           Text('0', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.all(15),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFFFFF0F5),
//                         borderRadius: BorderRadius.circular(15),
//                       ),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: const [
//                           Icon(Icons.diamond, color: Colors.pinkAccent),
//                           SizedBox(height: 8),
//                           Text('Free Match', style: TextStyle(color: Colors.grey)),
//                           Text('Plus', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.pinkAccent)),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 25),

//               // Sign-in Rewards Box
//               Container(
//                 padding: const EdgeInsets.all(15),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(15),
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: const [
//                         Text('Sign in Rewards (1/7)', style: TextStyle(fontWeight: FontWeight.bold)),
//                       ],
//                     ),
//                     const SizedBox(height: 15),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceAround,
//                       children: List.generate(4, (index) {
//                         return Container(
//                           width: 60,
//                           height: 70,
//                           decoration: BoxDecoration(
//                             color: index == 0 ? Colors.orange.shade50 : Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(10),
//                             border: index == 0 ? Border.all(color: Colors.orange) : null,
//                           ),
//                           child: Column(
//                             mainAxisAlignment: MainAxisAlignment.center,
//                             children: [
//                               Text('Day ${index + 1}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
//                               const Icon(Icons.card_giftcard, color: Colors.pinkAccent, size: 20),
//                               Text('+3', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: index == 0 ? Colors.orange : Colors.grey)),
//                             ],
//                           ),
//                         );
//                       }),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }




// import 'package:flutter/material.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   // This widget is the root of your application.
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         // This is the theme of your application.
//         //
//         // TRY THIS: Try running your application with "flutter run". You'll see
//         // the application has a purple toolbar. Then, without quitting the app,
//         // try changing the seedColor in the colorScheme below to Colors.green
//         // and then invoke "hot reload" (save your changes or press the "hot
//         // reload" button in a Flutter-supported IDE, or press "r" if you used
//         // the command line to start the app).
//         //
//         // Notice that the counter didn't reset back to zero; the application
//         // state is not lost during the reload. To reset the state, use hot
//         // restart instead.
//         //
//         // This works for code too, not just values: Most code changes can be
//         // tested with just a hot reload.
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   // This widget is the home page of your application. It is stateful, meaning
//   // that it has a State object (defined below) that contains fields that affect
//   // how it looks.

//   // This class is the configuration for the state. It holds the values (in this
//   // case the title) provided by the parent (in this case the App widget) and
//   // used by the build method of the State. Fields in a Widget subclass are
//   // always marked "final".

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   int _counter = 0;

//   void _incrementCounter() {
//     setState(() {
//       // This call to setState tells the Flutter framework that something has
//       // changed in this State, which causes it to rerun the build method below
//       // so that the display can reflect the updated values. If we changed
//       // _counter without calling setState(), then the build method would not be
//       // called again, and so nothing would appear to happen.
//       _counter++;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     // This method is rerun every time setState is called, for instance as done
//     // by the _incrementCounter method above.
//     //
//     // The Flutter framework has been optimized to make rerunning build methods
//     // fast, so that you can just rebuild anything that needs updating rather
//     // than having to individually change instances of widgets.
//     return Scaffold(
//       appBar: AppBar(
//         // TRY THIS: Try changing the color here to a specific color (to
//         // Colors.amber, perhaps?) and trigger a hot reload to see the AppBar
//         // change color while the other colors stay the same.
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         // Here we take the value from the MyHomePage object that was created by
//         // the App.build method, and use it to set our appbar title.
//         title: Text(widget.title),
//       ),
//       body: Center(
//         // Center is a layout widget. It takes a single child and positions it
//         // in the middle of the parent.
//         child: Column(
//           // Column is also a layout widget. It takes a list of children and
//           // arranges them vertically. By default, it sizes itself to fit its
//           // children horizontally, and tries to be as tall as its parent.
//           //
//           // Column has various properties to control how it sizes itself and
//           // how it positions its children. Here we use mainAxisAlignment to
//           // center the children vertically; the main axis here is the vertical
//           // axis because Columns are vertical (the cross axis would be
//           // horizontal).
//           //
//           // TRY THIS: Invoke "debug painting" (choose the "Toggle Debug Paint"
//           // action in the IDE, or press "p" in the console), to see the
//           // wireframe for each widget.
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text('You have pushed the button this many times:'),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: _incrementCounter,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ), // This trailing comma makes auto-formatting nicer for build methods.
//     );
//   }
// }
