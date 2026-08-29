import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;

  // Guest (Anonymous) Login Logic
  Future<void> _signInAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 50,
                backgroundColor: Colors.pinkAccent,
                child: Icon(Icons.video_call, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Poca Live',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.pinkAccent,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Instant Video Matching App',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 50),

              _isLoading
                  ? const CircularProgressIndicator(color: Colors.pink)
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pinkAccent,
                        foregroundColor: Colors.white,
                        elevation: 3,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      icon: const Icon(Icons.person, size: 28),
                      label: const Text(
                        'Continue as Guest',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _signInAsGuest,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}





// widwout sdk java --------------


// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart';
// import 'home_screen.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   bool _isLoading = false;

//   Future<void> _signInWithGoogle() async {
//     setState(() => _isLoading = true);
//     try {
//       final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
//       if (googleUser == null) {
//         setState(() => _isLoading = false);
//         return;
//       }

//       final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//       final AuthCredential credential = GoogleAuthProvider.credential(
//         accessToken: googleAuth.accessToken,
//         idToken: googleAuth.idToken,
//       );

//       await FirebaseAuth.instance.signInWithCredential(credential);

//       if (mounted) {
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const HomeScreen()),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Login Failed: $e')),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const CircleAvatar(
//               radius: 50,
//               backgroundColor: Colors.pinkAccent,
//               child: Icon(Icons.video_call, size: 60, color: Colors.white),
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               'Poca Live',
//               style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.pinkAccent),
//             ),
//             const SizedBox(height: 40),
//             _isLoading
//                 ? const CircularProgressIndicator(color: Colors.pink)
//                 : ElevatedButton.icon(
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black87,
//                       elevation: 3,
//                       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                     ),
//                     icon: const Icon(Icons.g_mobiledata, size: 35, color: Colors.red),
//                     label: const Text('Continue with Google'),
//                     onPressed: _signInWithGoogle,
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }