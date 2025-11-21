import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:video_player/video_player.dart';
import 'package:yoga/Auth/login_screen.dart';
import 'package:yoga/firebase_options.dart';
import 'package:yoga/navBar/bottom_navbar.dart';
import 'package:yoga/sarvices/notification_services.dart';
import 'package:yoga/utils/app_assests.dart';

const supabaseUrl = 'https://dwsddpfjjdrvnvmusghn.supabase.co';
const supabaseKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3c2RkcGZqamRydm52bXVzZ2huIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE1NDE3MzQsImV4cCI6MjA3NzExNzczNH0.xQjg__QTT1c_ZEKie9Wwu6sviS_ta59BzVxxyxgBIuo';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  print('🚀 ========== APP INITIALIZATION STARTED ==========');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final prefs = await SharedPreferences.getInstance();
      final isEnabled = prefs.getBool('notification_enabled') ?? true;

      if (!isEnabled) {
        print("🔕 Notifications OFF → Not showing popup");
        return;
      }

      NotificationService().showNotification(
        id: 1,
        title: message.notification?.title ?? "",
        body: message.notification?.body ?? "",
      );
    });

    // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    //   print("📩 Foreground Message Received");
    //   print("Title: ${message.notification?.title}");
    //   print("Body: ${message.notification?.body}");

    //   NotificationService().showNotification(
    //     title: message.notification?.title ?? "No Title",
    //     body: message.notification?.body ?? "No Body", id: 1,
    //   );
    // });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("📲 App opened from notification");
    });

    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      print("🚀 App opened from terminated state via notification");
    }

    print('✅ Firebase initialized');
  } catch (e) {
    print('❌ Firebase initialization failed: $e');
    print('⚠️ Continuing without Firebase...');
  }

  try {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseKey);
    print('✅ Supabase initialized');
  } catch (e) {
    print('❌ Supabase initialization failed: $e');
  }

  // ✅ 3. WebView Init
  try {
    await InAppWebViewController.getDefaultUserAgent();
    print('✅ WebView initialized');
  } catch (e) {
    print('⚠️ WebView init failed: $e');
  }

  // ✅ 4. Local Notification Init
  try {
    await NotificationService().initialize();
    print('✅ Local notifications initialized');
  } catch (e) {
    print('⚠️ Notification service failed: $e');
  }

  // ✅ 5. FCM Token Setup (with error handling)
  String? fcmToken;
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('📲 Notification permission: ${settings.authorizationStatus}');

    // Get FCM token with timeout
    fcmToken = await messaging.getToken().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('⏰ FCM token fetch timeout');
        return null;
      },
    );

    if (fcmToken != null) {
      print('✅ FCM TOKEN = $fcmToken');
    } else {
      print('⚠️ FCM token is null');
    }
  } catch (e) {
    print('❌ FCM setup failed: $e');
    print('📱 Continuing without push notifications...');
  }

  // ✅ 6. Check Auto Login
  final prefs = await SharedPreferences.getInstance();
  final savedUserId = prefs.getString('user_id');
  final isLoggedIn = prefs.getBool('is_logged_in') ?? false;

  print('🔍 Checking login status...');
  print('   User ID: $savedUserId');
  print('   Is Logged In: $isLoggedIn');

  // ✅ 7. Save FCM token to Supabase (if user is logged in)
  if (savedUserId != null && fcmToken != null && isLoggedIn) {
    try {
      final client = Supabase.instance.client;

      await client.from('user_tokens').upsert({
        'user_id': savedUserId,
        'token': fcmToken,
        'updated_at': DateTime.now().toIso8601String(),
      });

      print('✅ FCM token saved to Supabase');
    } catch (e) {
      print('⚠️ Failed to save FCM token: $e');
    }
  }

  // ✅ 8. Select Start Screen
  Widget startScreen;
  if (savedUserId != null && savedUserId.isNotEmpty && isLoggedIn) {
    print('🔁 User already logged in with ID: $savedUserId');
    startScreen = const MainNavbar();
  } else {
    print('👋 No logged in user, showing onboarding');
    startScreen = const YogaOnboardingScreen();
  }

  print('🎉 ========== INITIALIZATION COMPLETE ==========\n');

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => MyApp(startScreen: startScreen),
    ),
  );
}

class MyApp extends StatelessWidget {
  final Widget startScreen;
  const MyApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Yoga App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Lora',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.bold),
          bodyMedium: TextStyle(fontWeight: FontWeight.w400),
          labelLarge: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      home: startScreen,
    );
  }
}

class YogaOnboardingScreen extends StatefulWidget {
  const YogaOnboardingScreen({super.key});

  @override
  State<YogaOnboardingScreen> createState() => _YogaOnboardingScreenState();
}

class _YogaOnboardingScreenState extends State<YogaOnboardingScreen> {
  late VideoPlayerController _controller;
  bool _isVideoInitialized = false;
  bool _svgExists = false;
  String _svgError = '';
  String? _svgString;

  @override
  void initState() {
    super.initState();

    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.asset(AppAssets.yogaVideo);
      await _controller.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      _controller.setLooping(true);
      _controller.play();
      print('✅ Video initialized successfully!');
    } catch (e) {
      print('❌ Asset video error: $e');
      try {
        _controller = VideoPlayerController.networkUrl(
          Uri.parse(
            'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          ),
        );
        await _controller.initialize();
        setState(() {
          _isVideoInitialized = true;
        });
        _controller.setLooping(true);
        _controller.play();
        print('✅ Network video loaded as fallback');
      } catch (networkError) {
        print('❌ Network video also failed: $networkError');
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Logo SVG - WITHOUT ColorFilter (try direct rendering)
              Container(
                height: 120,
                width: 120,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(
                    60,
                  ), // optional, to match container shape
                  child: Image(
                    image: AssetImage(AppAssets.yogaGirl),
                    fit: BoxFit.cover, // optional, to fill the container
                  ),
                ),
              ),

              // YOGINI Text
              const Text(
                'YOGINI',
                style: TextStyle(
                  fontSize: 32,
                  fontFamily: 'OFL',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 4,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 10),

              // Subtitle
              Text(
                'Have the best',
                style: TextStyle(
                  fontSize: 25,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w300,
                ),
              ),

              const Text(
                'Yoga Experience',
                style: TextStyle(
                  fontSize: 26,
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              // Video Player Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (_isVideoInitialized)
                          SizedBox.expand(
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: SizedBox(
                                width: _controller.value.size.width,
                                height: _controller.value.size.height,
                                child: VideoPlayer(_controller),
                              ),
                            ),
                          )
                        else
                          Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFFF7043),
                              ),
                            ),
                          ),

                        // Mute/Unmute Button - Right Bottom Corner
                        if (_isVideoInitialized)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_controller.value.volume > 0) {
                                    _controller.setVolume(0);
                                  } else {
                                    _controller.setVolume(1);
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Icon(
                                  _controller.value.volume > 0
                                      ? Icons.volume_up
                                      : Icons.volume_off,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Start Journey Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF7043),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Start Journey',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
//           ),
//         ),
//         child: SafeArea(
//           child: Column(
//             children: [
//               const SizedBox(height: 20),

//               // Logo SVG - WITHOUT ColorFilter (try direct rendering)
//               Container(
//                 height: 120,
//                 width: 120,
//                 child: ClipRRect(
//                   borderRadius: BorderRadius.circular(
//                     60,
//                   ), // optional, to match container shape
//                   child: Image(
//                     image: AssetImage(AppAssets.yogaGirl),
//                     fit: BoxFit.cover, // optional, to fill the container
//                   ),
//                 ),
//               ),

//               // YOGINI Text
//               const Text(
//                 'YOGINI',
//                 style: TextStyle(
//                   fontSize: 32,
//                   fontFamily: 'OFL',
//                   fontWeight: FontWeight.bold,
//                   letterSpacing: 4,
//                   color: Colors.black87,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               // Subtitle
//               Text(
//                 'Have the best',
//                 style: TextStyle(
//                   fontSize: 25,
//                   color: Colors.grey[800],
//                   fontWeight: FontWeight.w300,
//                 ),
//               ),

//               const Text(
//                 'Yoga Experience',
//                 style: TextStyle(
//                   fontSize: 26,
//                   color: Colors.black87,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 10),

//               // Video Player Section
//               Expanded(
//                 child: Container(
//                   // Remove horizontal margin to cover full width
//                   // margin: const EdgeInsets.symmetric(horizontal: 20),
//                   decoration: BoxDecoration(
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 20,
//                         offset: const Offset(0, 10),
//                       ),
//                     ],
//                   ),
//                   child: ClipRRect(
//                     child: Stack(
//                       alignment: Alignment.center,
//                       children: [
//                         if (_isVideoInitialized)
//                           SizedBox.expand(
//                             child: FittedBox(
//                               fit: BoxFit.cover,
//                               child: SizedBox(
//                                 width: _controller.value.size.width,
//                                 height: _controller.value.size.height,
//                                 child: VideoPlayer(_controller),
//                               ),
//                             ),
//                           )
//                         else
//                           Container(
//                             color: Colors.grey[300],
//                             child: const Center(
//                               child: CircularProgressIndicator(
//                                 color: Color(0xFFFF7043),
//                               ),
//                             ),
//                           ),

//                         // Play/Pause Button Overlay
//                         // if (_isVideoInitialized)
//                         //   GestureDetector(
//                         //     onTap: () {
//                         //       setState(() {
//                         //         _controller.value.isPlaying
//                         //             ? _controller.pause()
//                         //             : _controller.play();
//                         //       });
//                         //     },
//                         //     child: Container(
//                         //       decoration: BoxDecoration(
//                         //         color: Colors.black.withOpacity(0.3),
//                         //         shape: BoxShape.circle,
//                         //       ),
//                         //       padding: const EdgeInsets.all(20),
//                         //       child: Icon(
//                         //         _controller.value.isPlaying
//                         //             ? Icons.pause
//                         //             : Icons.play_arrow,
//                         //         color: Colors.white,
//                         //         size: 50,
//                         //       ),
//                         //     ),
//                         //   ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),

//               // Start Journey Button
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 40),
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 56,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) =>  LoginScreen(),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFFFF7043),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       elevation: 5,
//                     ),
//                     child: const Text(
//                       'Start Journey',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),

//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
