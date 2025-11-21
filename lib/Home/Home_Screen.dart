import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yoga/Auth/login_screen.dart';
import 'package:yoga/course/course_Screen.dart';
import 'package:yoga/profile/profile_screen.dart';
import 'package:yoga/profile/setting_Screen.dart';
import 'package:yoga/sarvices/supabase_service.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yoga/utils/colors.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String userName = '';
  String? userId;

  // Progress data
  int totalBasicVideos = 0;
  int completedBasicVideos = 0;
  double basicProgressPercentage = 0.0;

  int totalAdvancedVideos = 0;
  int completedAdvancedVideos = 0;

  // Videos data
  List<Map<String, dynamic>> basicVideos = [];
  List<Map<String, dynamic>> advancedVideos = [];
  Map<int, String> videoStatus = {};
  Map<int, double> videoProgress = {};

  bool isLoading = true;
  bool isCoursesLoading = true; // Separate loading state for courses

  // Check if Basic Course is completed
  bool get isBasicCourseCompleted {
    return totalBasicVideos > 0 && completedBasicVideos == totalBasicVideos;
  }

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkUser();
  }

  User? _currentUser;
  final SupabaseService _supabaseService = SupabaseService();
  void _checkUser() {
    _currentUser = Supabase.instance.client.auth.currentUser;
    if (_currentUser != null) {
      // User logged in hai to notifications listen karein
      _supabaseService.listenToNotifications(_currentUser!.id);
    }
    setState(() {});
  }

  List<Map<String, dynamic>> courses = [];

  Future<void> fetchCourses() async {
    try {
      final response = await supabase.from('courses').select('*');
      setState(() {
        // ✅ Normalize course types
        courses =
            List<Map<String, dynamic>>.from(response).map((course) {
              final rawType = course['course_type'] ?? '';
              final isBasic = rawType.toLowerCase().contains('basic');

              return {
                ...course,
                'normalized_type':
                    isBasic ? 'basic' : 'advanced', // Add normalized field
              };
            }).toList();
      });
    } catch (e) {
      print('❌ Error fetching courses: $e');
    }
  }

  Future<void> _initializeData() async {
    await fetchCourses();
    await _loadUserName();
    await _getUserId();
    await _fetchCourseProgress();
    await fetchAllVideos();
    await loadVideoProgressFromSupabase();

    // Set courses loading to false after all data is loaded
    setState(() {
      isCoursesLoading = false;
    });
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('name') ?? 'Guest';
    });
  }

  Future<void> _getUserId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      userId = user.id;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id') ?? 'guest_user';
    }
  }

  Future<void> fetchAllVideos() async {
    try {
      var basicResponse = await supabase
          .from('videos')
          .select()
          .eq('course_type', 'Basic Course')
          .order('id', ascending: true);

      setState(() {
        basicVideos = List<Map<String, dynamic>>.from(basicResponse);
      });

      var advancedResponse = await supabase
          .from('videos')
          .select()
          .eq('course_type', 'Advanced Course')
          .order('id', ascending: true);

      if (advancedResponse.isEmpty) {
        advancedResponse = await supabase
            .from('videos')
            .select()
            .eq('course_type', 'Advance Course')
            .order('id', ascending: true);
      }

      setState(() {
        advancedVideos = List<Map<String, dynamic>>.from(advancedResponse);
      });
    } catch (e) {
      print("❌ Error fetching videos: $e");
    }
  }

  Future<void> loadVideoProgressFromSupabase() async {
    if (userId == null) return;

    try {
      final allVideoIds = [
        ...basicVideos.map((v) => v['id']),
        ...advancedVideos.map((v) => v['id']),
      ];

      if (allVideoIds.isEmpty) return;

      final response = await supabase
          .from('user_video_progress')
          .select()
          .eq('user_id', userId!)
          .inFilter('video_id', allVideoIds);

      Map<int, String> status = {};
      Map<int, double> progress = {};

      for (var record in response) {
        final videoId = record['video_id'] as int;
        status[videoId] = record['status'] as String;
        progress[videoId] = (record['progress'] as num).toDouble();
      }

      setState(() {
        videoStatus = status;
        videoProgress = progress;
      });
    } catch (e) {
      print("❌ Error loading progress: $e");
    }
  }

  Map<int, int> videoLastPosition = {};
  Future<void> saveVideoProgressToSupabase(
    int videoId,
    double progress,
    String status,
    int lastPositionSeconds,
  ) async {
    if (userId == null) return;

    try {
      // ✅ NEW: Check current status first
      final existing =
          await supabase
              .from('user_video_progress')
              .select()
              .eq('user_id', userId!)
              .eq('video_id', videoId)
              .maybeSingle();

      // ✅ Agar already completed hai, update mat karo!
      if (existing != null &&
          existing['status'] == 'completed' &&
          status != 'completed') {
        print("⚠️ Video $videoId already completed - skipping update");
        return;
      }

      final data = {
        'user_id': userId,
        'video_id': videoId,
        'progress': progress,
        'status': status,
        'last_position': lastPositionSeconds,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('user_video_progress')
          .upsert(data, onConflict: 'user_id,video_id');

      setState(() {
        videoProgress[videoId] = progress;
        videoStatus[videoId] = status;
        videoLastPosition[videoId] = lastPositionSeconds;
      });
    } catch (e) {
      print("❌ Error saving progress: $e");
    }
  }

  Future<void> _fetchCourseProgress() async {
    if (userId == null) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      await _fetchBasicCourseProgress();
      await _fetchAdvancedCourseProgress();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("❌ Error fetching progress: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _fetchBasicCourseProgress() async {
    try {
      final videosResponse = await supabase
          .from('videos')
          .select('id')
          .eq('course_type', 'Basic Course');

      final List<int> basicVideoIds =
          (videosResponse as List).map((v) => v['id'] as int).toList();

      if (basicVideoIds.isEmpty) {
        return;
      }

      final progressResponse = await supabase
          .from('user_video_progress')
          .select()
          .eq('user_id', userId!)
          .inFilter('video_id', basicVideoIds);

      int completed = 0;
      for (var record in progressResponse) {
        if (record['status'] == 'completed') {
          completed++;
        }
      }

      double percentage =
          basicVideoIds.length > 0
              ? (completed / basicVideoIds.length) * 100
              : 0.0;

      setState(() {
        totalBasicVideos = basicVideoIds.length;
        completedBasicVideos = completed;
        basicProgressPercentage = percentage;
      });

      print(
        "✅ Basic Course Progress: $completed/$totalBasicVideos (${percentage.toStringAsFixed(1)}%)",
      );
    } catch (e) {
      print("❌ Error fetching basic course progress: $e");
    }
  }

  Future<void> _fetchAdvancedCourseProgress() async {
    try {
      var videosResponse = await supabase
          .from('videos')
          .select('id')
          .eq('course_type', 'Advanced Course');

      if ((videosResponse as List).isEmpty) {
        print("⚠️ Trying alternate spelling: 'Advance Course'");
        videosResponse = await supabase
            .from('videos')
            .select('id')
            .eq('course_type', 'Advance Course');
      }

      final List<int> advancedVideoIds =
          (videosResponse as List).map((v) => v['id'] as int).toList();

      if (advancedVideoIds.isEmpty) {
        return;
      }

      final progressResponse = await supabase
          .from('user_video_progress')
          .select()
          .eq('user_id', userId!)
          .inFilter('video_id', advancedVideoIds);

      int completed = 0;
      for (var record in progressResponse) {
        if (record['status'] == 'completed') {
          completed++;
        }
      }

      setState(() {
        totalAdvancedVideos = advancedVideoIds.length;
        completedAdvancedVideos = completed;
      });

      print("✅ Advanced Course Progress: $completed/$totalAdvancedVideos");
    } catch (e) {
      print("❌ Error fetching advanced course progress: $e");
    }
  }

  void _showLockedMessage(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.lock, color: Colors.orange),
                SizedBox(width: 10),
                Text('Course Locked'),
              ],
            ),
            content: Text(
              'Please complete all Basic Course videos to unlock Advanced Course.\n\nProgress: $completedBasicVideos/$totalBasicVideos videos completed',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  // Shimmer widget for progress card
  Widget _buildProgressShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.only(left: 18, right: 18, bottom: 8, top: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 100,
              height: 14,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: 150,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: 120,
                height: 13,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer widget for course cards
  Widget _buildCourseShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 100,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(3),
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

  Future<String> _fetchUserProfilePic() async {
    print("🔹 _fetchUserProfilePic called");
    // final user = Supabase.instance.client.auth.currentUser;
    // print("👤 Current user: ${user?.id}");

    try {
      // final user = Supabase.instance.client.auth.currentUser;
      // if (user == null) {
        // print("⚠️ No logged-in user found");
        // return '';
      // }
      final prefs = await SharedPreferences.getInstance();
      final localUserId = prefs.getString('user_id');

      // final userId = user['id'];
      print("✅ Logged in userId: $localUserId");

      final response =
          await Supabase.instance.client
              .from('Users')
              .select('profile_image')
              .eq(
                'id',
                localUserId.toString(),
              ) // 👈 actual UUID pass kar rahe hain
              .maybeSingle();

      print("🔹 Response: $response");

      if (response != null && response['profile_image'] != null) {
        print("✅ Image URL: ${response['profile_image']}");
        return response['profile_image'];
      } else {
        print("⚠️ No image URL found for user");
        return '';
      }
    } catch (e) {
      print("❌ Error in _fetchUserProfilePic: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageHeight = MediaQuery.of(context).size.height * 0.4;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      endDrawer: ProfileDrawer(),
      body: Column(
        children: [
          Stack(
            children: [
              Image.asset(
                AppAssets.home,
                fit: BoxFit.fitWidth,
                width: double.infinity,
                height: imageHeight,
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  child: Column(
                    children: [
                      // GestureDetector(
                      //   onTap: () {
                      //     _scaffoldKey.currentState?.openEndDrawer();
                      //   },
                      //   child: Align(
                      //     alignment: Alignment.topRight,
                      //     child: Container(
                      //       height: 40,
                      //       width: 40,
                      //       decoration: BoxDecoration(
                      //         color: Colors.white,
                      //         borderRadius: BorderRadius.circular(20),
                      //         boxShadow: [
                      //           BoxShadow(
                      //             color: Colors.black.withOpacity(0.1),
                      //             blurRadius: 4,
                      //             offset: const Offset(0, 2),
                      //           ),
                      //         ],
                      //       ),
                      //       child: Center(
                      //         child: Image.asset(
                      //           AppAssets.profileImages,
                      //           height: 28,
                      //           width: 28,
                      //           fit: BoxFit.contain,
                      //         ),
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      GestureDetector(
                        onTap: () {
                          _scaffoldKey.currentState?.openEndDrawer();
                        },
                        child: Align(
                          alignment: Alignment.topRight,
                          child: FutureBuilder(
                            future:
                                _fetchUserProfilePic(), // 👈 Supabase se fetch karega
                            builder: (context, snapshot) {
                              final imageUrl = snapshot.data as String?;
                              return Container(
                                height: 40,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child:
                                      imageUrl == null || imageUrl.isEmpty
                                          ? Image.asset(
                                            AppAssets
                                                .profileImages, // 👈 Default asset image
                                            height: 28,
                                            width: 28,
                                            fit: BoxFit.cover,
                                          )
                                          : Image.network(
                                            imageUrl, // 👈 Supabase image
                                            height: 28,
                                            width: 28,
                                            fit: BoxFit.cover,
                                            errorBuilder: (
                                              context,
                                              error,
                                              stackTrace,
                                            ) {
                                              // Agar URL invalid ho to fallback image dikhao
                                              return Image.asset(
                                                AppAssets.profileImages,
                                                height: 28,
                                                width: 28,
                                                fit: BoxFit.cover,
                                              );
                                            },
                                          ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text.rich(
                          TextSpan(
                            text: "Namaste,\n",
                            style: const TextStyle(
                              fontSize: 22,
                              color: Colors.black87,
                            ),
                            children: [
                              TextSpan(
                                text: userName,
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text.rich(
                      TextSpan(
                        text: "Let's start basic\n",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          height: 1.3,
                        ),
                        children: [
                          TextSpan(
                            text: "yoga and meditation",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Progress Card with Shimmer
                    isLoading
                        ? _buildProgressShimmer()
                        : Container(
                          padding: const EdgeInsets.only(
                            left: 18,
                            right: 18,
                            bottom: 8,
                            top: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Your Progress",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Text(
                                  isBasicCourseCompleted
                                      ? "Advanced Course"
                                      : "Basic Course",
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value:
                                      isBasicCourseCompleted
                                          ? (totalAdvancedVideos == 0
                                              ? 0
                                              : completedAdvancedVideos /
                                                  totalAdvancedVideos)
                                          : (basicProgressPercentage / 100),
                                  minHeight: 10,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: AlwaysStoppedAnimation(
                                    isBasicCourseCompleted
                                        ? AppColors.ProgressB
                                        : AppColors.ProgressB,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: Text.rich(
                                  TextSpan(
                                    text: "",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                    children: [
                                      TextSpan(
                                        text:
                                            isBasicCourseCompleted
                                                ? "${completedAdvancedVideos}/${totalAdvancedVideos} videos"
                                                : "${basicProgressPercentage.toStringAsFixed(0)}%",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color:
                                              isBasicCourseCompleted
                                                  ? AppColors.ProgressB
                                                  : AppColors.ProgressB,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: " completed!",
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                    const SizedBox(height: 30),
                    const Text(
                      "Recommended Courses",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Course Cards with Shimmer
                    isCoursesLoading
                        ? Column(
                          children: [
                            _buildCourseShimmer(),
                            const SizedBox(height: 12),
                            _buildCourseShimmer(),
                          ],
                        )
                        // : Column(
                        //   children:
                        //       courses.map((course) {
                        //         final title = course['name'] ?? 'Untitled';
                        //         final lessons =
                        //             "${course['lesson_count'] ?? 0} lessons";
                        //         final imageUrl =
                        //             course['icon_url'] ??
                        //             ''; // ✅ image column in Supabase
                        //         final courseType =
                        //             (course['type'] ?? '').toLowerCase();
                        //         bool isLocked =
                        //             courseType == 'advanced' &&
                        //             !isBasicCourseCompleted;
                        : Column(
                          children:
                              courses.map((course) {
                                final title = course['name'] ?? 'Untitled';
                                final lessons =
                                    "${course['lesson_count'] ?? 0} lessons";
                                final imageUrl = course['icon_url'] ?? '';
                                final courseType = course['Course_type'] ?? '';

                                // ✅ DEBUG: Print karo
                                print('📊 Course: $title');
                                print('   course_type from DB: "$courseType"');

                                final isBasic = courseType
                                    .toLowerCase()
                                    .contains('basic');
                                print('   isBasic: $isBasic');

                                bool isLocked =
                                    !isBasic && !isBasicCourseCompleted;
                                print('   isLocked: $isLocked');
                                print('---');

                                final completedCount =
                                    isBasic
                                        ? completedBasicVideos
                                        : completedAdvancedVideos;
                                final totalCount =
                                    isBasic
                                        ? totalBasicVideos
                                        : totalAdvancedVideos;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12.0),
                                  child: _courseCard(
                                    title,
                                    lessons,
                                    context,
                                    completedCount,
                                    totalCount,
                                    isLocked: isLocked,
                                    courseType: courseType,
                                    imageUrl: imageUrl,
                                  ),
                                );
                              }).toList(),
                        ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _courseCard(
    String title,
    String lessons,
    BuildContext context,
    int completed,
    int total, {
    required bool isLocked,
    required String courseType,
    required String imageUrl,
  }) {
    return InkWell(
      onTap: () {
        // Check if course is locked
        if (isLocked) {
          _showLockedMessage(context);
          return;
        }

        // ✅ UPDATED: Direct navigation to PlaylistScreen with videoLastPosition
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => PlaylistScreen(
                  courseType: courseType,
                  courseName: title,
                  // videos: courseType == 'basic' ? basicVideos : advancedVideos,
                  videos:
                      courseType.toLowerCase().contains('basic')
                          ? basicVideos
                          : advancedVideos,
                  initialVideoStatus: videoStatus, // ✅ RENAMED
                  initialVideoProgress: videoProgress, // ✅ RENAMED
                  initialVideoLastPosition: videoLastPosition, // ✅ RENAMED
                  onVideoProgress: saveVideoProgressToSupabase,
                  onRefresh: () {
                    loadVideoProgressFromSupabase();
                    _fetchCourseProgress();
                  },
                ),
          ),
        ).then((_) {
          loadVideoProgressFromSupabase();
          _fetchCourseProgress();
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 15,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    height: 70,
                    width: 70,
                    decoration: BoxDecoration(
                      color: AppColors.imageB,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Image.network(imageUrl),
                  ),
                  if (isLocked)
                    Container(
                      height: 70,
                      width: 70,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (isLocked) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.lock,
                            size: 16,
                            color: Colors.orange,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$total lessons",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    if (total > 0 && !isLocked) ...[
                      // Text(
                      //   " · ",
                      //   style: TextStyle(
                      //     fontSize: 13,
                      //     color: Colors.grey[700],
                      //   ),
                      // ),
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Text(
                          "$completed/$total",
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.ProgressB,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (isLocked) ...[
                      // Text(
                      //   " · ",
                      //   style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      // ),
                      Text(
                        "Complete Basic first",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileDrawer extends StatelessWidget {
  const ProfileDrawer({Key? key}) : super(key: key);

  Future<void> _handleLogout(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        // 1. Clear all SharedPreferences data
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();

        // 2. Sign out from Supabase (if using Supabase auth)
        final supabase = Supabase.instance.client;
        await supabase.auth.signOut();

        // 3. Navigate to login screen and remove all previous routes
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => LoginScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        // Show error message if logout fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logout failed: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.grey.shade300,
      width: MediaQuery.of(context).size.width * 0.7,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),

            // Profile Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfileScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Setting Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SettingsScreen()),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Text(
                      'Setting',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () async {
                  final prefs = await SharedPreferences.getInstance();

                  final userId = prefs.getString('user_id') ?? '';
                  // Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => ChangePasswordScreen(userId: userId),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Center(
                    child: Text(
                      'Change Password',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const Spacer(),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => _handleLogout(context),
                child: const Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 24),
                    SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
