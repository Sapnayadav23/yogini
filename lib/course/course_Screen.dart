import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';
import 'package:yoga/Home/Home_Screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({Key? key}) : super(key: key);

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final supabase = Supabase.instance.client;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> basicVideos = [];
  List<Map<String, dynamic>> advancedVideos = [];

  Map<int, String> videoStatus = {};
  Map<int, double> videoProgress = {};
  Map<int, int> videoLastPosition =
      {}; // ✅ NEW: Store last watched position in seconds
  String? userId;

  bool isLoadingBasic = true;
  bool isLoadingAdvanced = true;
  bool isLoadingProgress = true;

  int totalBasicVideos = 0;
  int completedBasicVideos = 0;
  int totalAdvancedVideos = 0;
  int completedAdvancedVideos = 0;
  bool isPageLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeUser();
    fetchCourses();
  }

  Future<void> _initializeUser() async {
    setState(() => isPageLoading = true);

    final user = supabase.auth.currentUser;
    if (user != null) {
      userId = user.id;
    } else {
      final prefs = await SharedPreferences.getInstance();
      userId = prefs.getString('user_id') ?? 'guest_user';
    }

    await fetchBasicVideos();
    await fetchAdvancedVideos();
    await loadVideoProgressFromSupabase();
    await _fetchCourseProgress();

    setState(() => isPageLoading = false);
  }

  Future<void> fetchBasicVideos() async {
    try {
      print("🔍 Fetching Basic videos...");
      var response = await supabase
          .from('videos')
          .select()
          .eq('course_type', 'Basic Course')
          .order('id', ascending: true);

      print("📹 Basic Videos fetched: ${response.length}");

      setState(() {
        basicVideos = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("❌ Error fetching basic videos: $e");
    }
  }

  Future<void> fetchAdvancedVideos() async {
    try {
      print("🔍 Fetching Advanced videos...");
      var response = await supabase
          .from('videos')
          .select()
          .eq('course_type', 'Advanced Course')
          .order('id', ascending: true);

      if (response.isEmpty) {
        print("⚠️ Trying alternate spelling: 'Advance Course'");
        response = await supabase
            .from('videos')
            .select()
            .eq('course_type', 'Advance Course')
            .order('id', ascending: true);
      }

      print("📹 Advanced Videos fetched: ${response.length}");

      setState(() {
        advancedVideos = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("❌ Error fetching advanced videos: $e");
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
      Map<int, int> lastPos = {}; // ✅ Add this

      for (var record in response) {
        final videoId = record['video_id'] as int;
        status[videoId] = record['status'] as String;
        progress[videoId] = (record['progress'] as num).toDouble();
        lastPos[videoId] =
            (record['last_position'] as num?)?.toInt() ??
            0; // ✅ Load last_position
      }

      setState(() {
        videoStatus = status;
        videoProgress = progress;
        videoLastPosition = lastPos; // ✅ Update state
      });

      print("✅ Loaded progress with last positions: $lastPos");
    } catch (e) {
      print("❌ Error loading progress: $e");
    }
  }

  Future<void> fetchCourses() async {
    setState(() => isCoursesLoading = true); // ✅ Set loading state

    try {
      final response = await supabase.from('courses').select('*');
      setState(() {
        courses =
            List<Map<String, dynamic>>.from(response).map((course) {
              final rawType = course['course_type'] ?? '';
              final isBasic = rawType.toLowerCase().contains('basic');

              return {
                ...course,
                'normalized_type': isBasic ? 'basic' : 'advanced',
              };
            }).toList();

        isCoursesLoading = false; // ✅ Stop loading after data is fetched
      });
    } catch (e) {
      print('❌ Error fetching courses: $e');
      setState(() => isCoursesLoading = false); // ✅ Stop loading even on error
    }
  }

  // ✅ UPDATED: Now also saves last watched position
  Future<void> saveVideoProgressToSupabase(
    int videoId,
    double progress,
    String status,
    int lastPositionSeconds, // ✅ NEW parameter
  ) async {
    if (userId == null) return;

    try {
      final data = {
        'user_id': userId,
        'video_id': videoId,
        'progress': progress,
        'status': status,
        'last_position': lastPositionSeconds, // ✅ NEW: Save position in seconds
        'updated_at': DateTime.now().toIso8601String(),
      };

      await supabase
          .from('user_video_progress')
          .upsert(data, onConflict: 'user_id,video_id');

      setState(() {
        videoProgress[videoId] = progress;
        videoStatus[videoId] = status;
        videoLastPosition[videoId] = lastPositionSeconds; // ✅ NEW
      });

      print(
        "✅ Progress saved: Video $videoId - $status at ${lastPositionSeconds}s",
      );
    } catch (e) {
      print("❌ Error saving progress: $e");
    }
  }

  bool isVideoUnlocked(List<Map<String, dynamic>> videos, int index) {
    if (index == 0) return true;
    final previousVideo = videos[index - 1];
    final previousStatus = videoStatus[previousVideo['id']] ?? 'not_started';
    return previousStatus == 'completed';
  }

  bool get isBasicCourseCompleted {
    return totalBasicVideos > 0 && completedBasicVideos == totalBasicVideos;
  }

  Future<void> _fetchCourseProgress() async {
    await _fetchBasicCourseProgress();
    await _fetchAdvancedCourseProgress();
  }

  Future<void> _fetchBasicCourseProgress() async {
    try {
      final videosResponse = await supabase
          .from('videos')
          .select('id')
          .eq('course_type', 'Basic Course');

      final List<int> basicVideoIds =
          (videosResponse as List).map((v) => v['id'] as int).toList();

      if (basicVideoIds.isEmpty) return;

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

      setState(() {
        totalBasicVideos = basicVideoIds.length;
        completedBasicVideos = completed;
      });
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
        videosResponse = await supabase
            .from('videos')
            .select('id')
            .eq('course_type', 'Advance Course');
      }

      final List<int> advancedVideoIds =
          (videosResponse as List).map((v) => v['id'] as int).toList();

      if (advancedVideoIds.isEmpty) return;

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

  List<Map<String, dynamic>> courses = [];
  bool isCoursesLoading = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundC,
      endDrawer: ProfileDrawer(),
      body: SafeArea(
        child: Padding(
          // padding: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 10.0),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child:
              isPageLoading
                  ? _buildShimmerPlaceholder()
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GestureDetector(
                      //   onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
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

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Image.asset(
                              AppAssets.CoueseBacg,
                              height: 140,
                              width: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Text(
                            "Let's learn\nsome Asans!",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: const Text(
                          "Available Courses",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                  final courseType =
                                      course['Course_type'] ?? '';

                                  // ✅ DEBUG: Print karo
                                  print('📊 Course: $title');
                                  print(
                                    '   course_type from DB: "$courseType"',
                                  );

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
                                    padding: const EdgeInsets.only(
                                      bottom: 12.0,
                                    ),
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
                      // _courseCard(
                      //   "Basic Course",
                      //   "$totalBasicVideos lessons",
                      //   context,
                      //   completedBasicVideos,
                      //   totalBasicVideos,
                      //   isLocked: false,
                      //   courseType: 'basic',
                      // ),
                      // const SizedBox(height: 15),
                      // _courseCard(
                      //   "Advanced Course",
                      //   "$totalAdvancedVideos lessons",
                      //   context,
                      //   completedAdvancedVideos,
                      //   totalAdvancedVideos,
                      //   isLocked: !isBasicCourseCompleted,
                      //   courseType: 'advanced',
                      // ),
                      // const SizedBox(height: 120),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            height: 20,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < 2; i++) ...[
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: 120,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ],
    );
  }

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

// ✅ COMPLETE FIXED VERSION - Completed videos ki progress kabhi change nahi hogi

// ========== COURSES SCREEN ==========
class PlaylistScreen extends StatefulWidget {
  final String courseType;
  final String courseName;
  final List<Map<String, dynamic>> videos;
  final Map<int, String> initialVideoStatus;
  final Map<int, double> initialVideoProgress;
  final Map<int, int> initialVideoLastPosition;
  final Function(int, double, String, int) onVideoProgress;
  final VoidCallback onRefresh;

  const PlaylistScreen({
    Key? key,
    required this.courseType,
    required this.courseName,
    required this.videos,
    required this.initialVideoStatus,
    required this.initialVideoProgress,
    required this.initialVideoLastPosition,
    required this.onVideoProgress,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  late Map<int, String> videoStatus;
  late Map<int, double> videoProgress;
  late Map<int, int> videoLastPosition;

  @override
  void initState() {
    super.initState();

    videoStatus = Map.from(widget.initialVideoStatus);
    videoProgress = Map.from(widget.initialVideoProgress);
    videoLastPosition = Map.from(widget.initialVideoLastPosition);
  }

  bool isVideoUnlocked(int index) {
    if (index == 0) return true;
    final previousVideo = widget.videos[index - 1];
    final previousStatus = videoStatus[previousVideo['id']] ?? 'not_started';
    return previousStatus == 'completed';
  }

  String _getChapterNumber(int index) {
    final numbers = [
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine',
      'Ten',
    ];
    return index < numbers.length ? numbers[index] : '${index + 1}';
  }

  void _showLockedMessage(BuildContext context, int chapterNumber) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: const [
                Icon(Icons.lock, color: Colors.orange),
                SizedBox(width: 10),
                Text('Video Locked'),
              ],
            ),
            content: Text(
              'Please complete Chapter ${_getChapterNumber(chapterNumber - 1)} first to unlock this video.',
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

  // ✅ CRITICAL FIX: Check if video is already completed before updating
  void _handleVideoProgress(
    double progress,
    String status,
    int position,
    int videoId,
  ) {
    // ✅ Agar video already completed hai, toh update mat karo!
    final currentStatus = videoStatus[videoId];
    if (currentStatus == 'completed' && status != 'completed') {
      print("⚠️ Video $videoId already completed - ignoring progress update");
      return; // ✅ EXIT - Kuch mat karo!
    }

    // ✅ Only update if status is changing OR progress is increasing
    widget.onVideoProgress(videoId, progress, status, position);

    setState(() {
      videoStatus[videoId] = status;
      videoProgress[videoId] = progress;
      videoLastPosition[videoId] = position;
    });

    print(
      "✅ UI Updated: Video $videoId - $status at ${(progress * 100).toInt()}%",
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundC,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            widget.onRefresh();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.courseName,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(10.0),
        child:
            widget.videos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                  itemCount: widget.videos.length,
                  itemBuilder: (context, index) {
                    final video = widget.videos[index];
                    final status = videoStatus[video['id']] ?? 'not_started';
                    final progress = videoProgress[video['id']] ?? 0.0;
                    final lastPosition = videoLastPosition[video['id']] ?? 0;
                    final isUnlocked = isVideoUnlocked(index);

                    return Opacity(
                      opacity: isUnlocked ? 1.0 : 0.5,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: InkWell(
                          onTap: () {
                            if (!isUnlocked) {
                              _showLockedMessage(context, index);
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => YoutubeVideoPlayerScreen(
                                      videoUrl: video['video_url'],
                                      // videoThumb: video['thumbnail_url'],
                                      videoTitle: video['title'],
                                      videoId: video['id'],
                                      videoDescription: video['description'],
                                      lastPosition: lastPosition,
                                      currentStatus:
                                          status, // ✅ NEW: Pass current status
                                      onVideoProgress: (
                                        progress,
                                        status,
                                        position,
                                      ) {
                                        _handleVideoProgress(
                                          progress,
                                          status,
                                          position,
                                          video['id'],
                                        );
                                      },
                                    ),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 70,
                                    height: 70,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        video['thumbnail_url'],
                                        fit: BoxFit.cover,
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Icon(
                                            Icons.self_improvement,
                                            size: 40,
                                            color: Colors.grey,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  if (!isUnlocked)
                                    Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.4),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Icons.lock,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Chapter ${_getChapterNumber(index)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        if (!isUnlocked) ...[
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
                                      video['title'] ?? 'Untitled',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey[600],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    if (isUnlocked)
                                      Row(
                                        children: [
                                          Text(
                                            'Status: ',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                          if (status == 'completed')
                                            const Text(
                                              'Completed',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          else if (status == 'in_progress')
                                            Text(
                                              '${(progress * 100).toInt()}% Completed',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.orange,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            )
                                          else
                                            Text(
                                              'Not Started',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                        ],
                                      )
                                    else
                                      Text(
                                        'Complete previous chapter to unlock',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.orange[700],
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (isUnlocked)
                                if (status == 'completed')
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  )
                                else if (status == 'in_progress')
                                  Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        height: 36,
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 3,
                                          backgroundColor: Colors.grey[300],
                                          valueColor:
                                              const AlwaysStoppedAnimation<
                                                Color
                                              >(Colors.orange),
                                        ),
                                      ),
                                      Text(
                                        '${(progress * 100).toInt()}%',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
                                      ),
                                    ],
                                  )
                                else
                                  Icon(
                                    Icons.play_circle_outline,
                                    color: Colors.grey[400],
                                    size: 36,
                                  )
                              else
                                Icon(
                                  Icons.lock,
                                  color: Colors.orange[300],
                                  size: 36,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      ),
    );
  }
}

// class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   String? _videoId;
//   bool _isCompleted = false;
//   bool _hasResumed = false;
//   int _lastSavedPosition = 0;
//   int _maxWatchedPosition = 0;
//   Timer? _seekMonitorTimer;
//   bool _isAllowedSeek = false;
//   bool _isCustomFullscreen = false;
//   bool _showControls = true;
//   Timer? _controlsTimer;

//   @override
//   void initState() {
//     super.initState();

//     if (widget.currentStatus == 'completed') {
//       _isCompleted = true;
//     }

//     _maxWatchedPosition = widget.lastPosition;
//     _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

//     if (_videoId != null) {
//       _controller = YoutubePlayerController(
//         initialVideoId: _videoId!,
//         flags: const YoutubePlayerFlags(
//           autoPlay: false,
//           mute: false,
//           hideControls: true, // ✅ HIDE ALL NATIVE CONTROLS
//           disableDragSeek: true,
//           enableCaption: false,
//           forceHD: false,
//         ),
//       )..addListener(_videoListener);

//       _startSeekMonitoring();
//     }
//   }

//   void _startSeekMonitoring() {
//     _seekMonitorTimer = Timer.periodic(const Duration(milliseconds: 50), (
//       timer,
//     ) {
//       if (!mounted || !_controller.value.isReady) return;

//       final currentPos = _controller.value.position.inSeconds;

//       if (!_isAllowedSeek && currentPos > _maxWatchedPosition + 1) {
//         print('🚨 BLOCKED: $currentPos -> $_maxWatchedPosition');

//         _isAllowedSeek = true;
//         _controller.pause();
//         _controller.seekTo(Duration(seconds: _maxWatchedPosition));

//         Future.delayed(const Duration(milliseconds: 300), () {
//           if (mounted) _isAllowedSeek = false;
//         });

//         _showSkipWarning();
//         return;
//       }

//       if (_controller.value.isPlaying && currentPos > _maxWatchedPosition) {
//         _maxWatchedPosition = currentPos;
//       }
//     });
//   }

//   void _videoListener() {
//     if (!mounted || !_controller.value.isReady) return;

//     if (!_hasResumed && widget.lastPosition > 5 && !_isCompleted) {
//       setState(() => _hasResumed = true);

//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted) {
//           _isAllowedSeek = true;
//           _controller.seekTo(Duration(seconds: widget.lastPosition));
//           Future.delayed(const Duration(milliseconds: 500), () {
//             _isAllowedSeek = false;
//           });
//         }
//       });
//       return;
//     }

//     if (_isCompleted) return;

//     final position = _controller.value.position.inSeconds;
//     final duration = _controller.metadata.duration.inSeconds;

//     if (duration > 0 && position > 0) {
//       final progress = position / duration;

//       if (position % 5 == 0 && position != _lastSavedPosition) {
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//       }

//       if (progress >= 0.95) {
//         final maxProgress = _maxWatchedPosition / duration;

//         if (maxProgress >= 0.95) {
//           setState(() => _isCompleted = true);
//           widget.onVideoProgress(1.0, 'completed', duration);
//           _showCompletionDialog();
//         }
//       }
//     }
//   }

//   void _toggleFullscreen() {
//     setState(() {
//       _isCustomFullscreen = !_isCustomFullscreen;
//     });

//     if (_isCustomFullscreen) {
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
//       SystemChrome.setPreferredOrientations([
//         DeviceOrientation.landscapeLeft,
//         DeviceOrientation.landscapeRight,
//       ]);
//     } else {
//       SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//       SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
//     }
//   }

//   void _togglePlayPause() {
//     setState(() {
//       if (_controller.value.isPlaying) {
//         _controller.pause();
//       } else {
//         _controller.play();
//       }
//     });
//     _resetControlsTimer();
//   }

//   void _resetControlsTimer() {
//     _controlsTimer?.cancel();
//     setState(() => _showControls = true);

//     _controlsTimer = Timer(const Duration(seconds: 3), () {
//       if (mounted && _controller.value.isPlaying) {
//         setState(() => _showControls = false);
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _seekMonitorTimer?.cancel();
//     _controlsTimer?.cancel();

//     SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
//     SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

//     if (_controller.value.isReady && !_isCompleted) {
//       final duration = _controller.metadata.duration.inSeconds;
//       if (duration > 0) {
//         final progress = _maxWatchedPosition / duration;
//         widget.onVideoProgress(progress, 'in_progress', _maxWatchedPosition);
//       }
//     }

//     _controller.removeListener(_videoListener);
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_videoId == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Invalid video')),
//         body: const Center(child: Text('Invalid YouTube URL')),
//       );
//     }

//     if (_isCustomFullscreen) {
//       return _buildFullscreenView();
//     }

//     return _buildNormalView();
//   }

//   Widget _buildNormalView() {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'Video Player',
//           style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
//         ),
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black87),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildVideoPlayer(false),

//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     widget.videoTitle,
//                     style: const TextStyle(
//                       fontSize: 20,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87,
//                     ),
//                   ),
//                   const SizedBox(height: 16),

//                   Container(
//                     padding: const EdgeInsets.all(14),
//                     decoration: BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [Colors.red[700]!, Colors.orange[700]!],
//                       ),
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     child: Row(
//                       children: const [
//                         Icon(Icons.lock, color: Colors.white, size: 22),
//                         SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             '🚫 Video skipping is disabled. Watch in sequence.',
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontSize: 14,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),

//                   if (widget.videoDescription != null &&
//                       widget.videoDescription!.isNotEmpty) ...[
//                     const SizedBox(height: 20),
//                     const Text(
//                       'Description',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       widget.videoDescription!,
//                       style: TextStyle(
//                         fontSize: 14,
//                         color: Colors.grey[700],
//                         height: 1.5,
//                       ),
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildFullscreenView() {
//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: GestureDetector(
//         onTap: _resetControlsTimer,
//         // child: _buildVideoPlayer(true),
//       ),
//     );
//   }

//   // Widget _buildVideoPlayer(bool isFullscreen) {
//   //   return Container(
//   //     color: Colors.black,
//   //     height:
//   //         isFullscreen
//   //             ? MediaQuery.of(context).size.height
//   //             : MediaQuery.of(context).size.width * 9 / 16,
//   //     width: MediaQuery.of(context).size.width,
//   //     // child: Stack(
//   //     //   children: [
//   //     //     // YouTube Player
//   //     //     Center(
//   //     //       child: YoutubePlayer(
//   //     //         controller: _controller,
//   //     //         showVideoProgressIndicator: false,
//   //     //         onEnded: (_) {
//   //     //           final duration = _controller.metadata.duration.inSeconds;
//   //     //           final maxProgress = _maxWatchedPosition / duration;

//   //     //           if (!_isCompleted && maxProgress >= 0.95) {
//   //     //             setState(() => _isCompleted = true);
//   //     //             widget.onVideoProgress(1.0, 'completed', duration);
//   //     //             _showCompletionDialog();
//   //     //           }
//   //     //         },
//   //     //       ),
//   //     //     ),

//   //     //     // Custom Controls
//   //     //     if (_showControls || !_controller.value.isPlaying)
//   //     //       _buildCustomControls(isFullscreen),
//   //     //   ],
//   //     // ),
//   //     child: GestureDetector(
//   //       behavior: HitTestBehavior.opaque,
//   //       onTap: _resetControlsTimer, // 👈 tap karne se controls show honge
//   //       child: Stack(
//   //         children: [
//   //           // YouTube Player
//   //           Center(
//   //             child: YoutubePlayer(
//   //               controller: _controller,
//   //               showVideoProgressIndicator: false,
//   //               onEnded: (_) {
//   //                 final duration = _controller.metadata.duration.inSeconds;
//   //                 final maxProgress = _maxWatchedPosition / duration;

//   //                 if (!_isCompleted && maxProgress >= 0.95) {
//   //                   setState(() => _isCompleted = true);
//   //                   widget.onVideoProgress(1.0, 'completed', duration);
//   //                   _showCompletionDialog();
//   //                 }
//   //               },
//   //             ),
//   //           ),

//   //           // Custom Controls
//   //           if (_showControls || !_controller.value.isPlaying)
//   //             _buildCustomControls(isFullscreen),
//   //         ],
//   //       ),
//   //     ),
//   //   );
//   // }
//   Widget _buildVideoPlayer(bool isFullscreen) {
//     return Container(
//       color: Colors.black,
//       height:
//           isFullscreen
//               ? MediaQuery.of(context).size.height
//               : MediaQuery.of(context).size.width * 9 / 16,
//       width: MediaQuery.of(context).size.width,
//       child: Stack(
//         children: [
//           // YouTube Player - Main layer
//           Center(
//             child: YoutubePlayer(
//               controller: _controller,
//               showVideoProgressIndicator: false,
//               onEnded: (_) {
//                 final duration = _controller.metadata.duration.inSeconds;
//                 final maxProgress = _maxWatchedPosition / duration;

//                 if (!_isCompleted && maxProgress >= 0.95) {
//                   setState(() => _isCompleted = true);
//                   widget.onVideoProgress(1.0, 'completed', duration);
//                   _showCompletionDialog();
//                 }
//               },
//             ),
//           ),

//           // Tap detector for showing controls
//           // ✅ HitTestBehavior.translucent allows taps to pass through
//           Positioned.fill(
//             child: GestureDetector(
//               behavior: HitTestBehavior.translucent,
//               onTap: () {
//                 setState(() {
//                   _showControls = !_showControls;
//                 });
//                 if (_showControls) {
//                   _resetControlsTimer();
//                 }
//               },
//               child: Container(color: Colors.transparent),
//             ),
//           ),

//           // Custom Controls - Only shows when needed
//           if (_showControls || !_controller.value.isPlaying)
//             IgnorePointer(
//               ignoring: false, // Controls can receive taps
//               child: _buildCustomControls(isFullscreen),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildCustomControls(bool isFullscreen) {
//     return AnimatedOpacity(
//       opacity: _showControls ? 1.0 : 0.0,
//       duration: const Duration(milliseconds: 300),
//       child: Container(
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [
//               Colors.black.withOpacity(0.3),
//               Colors.transparent,
//               Colors.transparent,
//               Colors.black.withOpacity(0.7),
//             ],
//             stops: const [0.0, 0.3, 0.7, 1.0],
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             // Top bar
//             if (isFullscreen)
//               SafeArea(
//                 child: Padding(
//                   padding: const EdgeInsets.all(8.0),
//                   child: Row(
//                     children: [
//                       IconButton(
//                         onPressed: _toggleFullscreen,
//                         icon: const Icon(
//                           Icons.arrow_back,
//                           color: Colors.white,
//                           size: 28,
//                         ),
//                       ),
//                       Expanded(
//                         child: Text(
//                           widget.videoTitle,
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),

//             // Bottom controls
//             SafeArea(
//               child: Padding(
//                 padding: EdgeInsets.all(isFullscreen ? 16.0 : 12.0),
//                 child: Column(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     // Progress bar
//                     StreamBuilder<int>(
//                       stream: Stream.periodic(
//                         const Duration(milliseconds: 200),
//                         (count) => count,
//                       ),
//                       builder: (context, snapshot) {
//                         final position =
//                             _controller.value.isReady
//                                 ? _controller.value.position.inSeconds
//                                 : 0;
//                         final duration =
//                             _controller.value.isReady
//                                 ? _controller.metadata.duration.inSeconds
//                                 : 1;
//                         final progress =
//                             duration > 0 ? position / duration : 0.0;

//                         return Column(
//                           children: [
//                             IgnorePointer(
//                               child: LinearProgressIndicator(
//                                 value: progress,
//                                 backgroundColor: Colors.grey[700],
//                                 color: Colors.red,
//                                 minHeight: isFullscreen ? 5 : 4,
//                               ),
//                             ),
//                             const SizedBox(height: 8),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                               children: [
//                                 Text(
//                                   _formatDuration(position),
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: isFullscreen ? 14 : 12,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                                 Text(
//                                   _formatDuration(duration),
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: isFullscreen ? 14 : 12,
//                                     fontWeight: FontWeight.w500,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ],
//                         );
//                       },
//                     ),

//                     SizedBox(height: isFullscreen ? 16 : 8),

//                     // Control buttons
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         // Play/Pause
//                         IconButton(
//                           onPressed: _togglePlayPause,
//                           icon: Icon(
//                             _controller.value.isPlaying
//                                 ? Icons.pause
//                                 : Icons.play_arrow,
//                             color: Colors.white,
//                             size: isFullscreen ? 36 : 30,
//                           ),
//                         ),

//                         // Fullscreen toggle
//                         IconButton(
//                           onPressed: _toggleFullscreen,
//                           icon: Icon(
//                             isFullscreen
//                                 ? Icons.fullscreen_exit
//                                 : Icons.fullscreen,
//                             color: Colors.white,
//                             size: isFullscreen ? 32 : 28,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _formatDuration(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   void _showCompletionDialog() {
//     if (mounted) {
//       showDialog(
//         context: context,
//         builder:
//             (context) => AlertDialog(
//               title: const Text('🎉 Video Completed'),
//               content: const Text(
//                 'Great job! You have successfully completed this video.',
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () {
//                     Navigator.pop(context);
//                     Navigator.pop(context);
//                   },
//                   child: const Text('Close'),
//                 ),
//               ],
//             ),
//       );
//     }
//   }

//   void _showSkipWarning() {
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('⚠️ Skipping disabled. Watch sequentially.'),
//           duration: Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }

class YoutubeVideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  // final String videoThumb;
  final String videoTitle;
  final int videoId;
  final Function(double, String, int) onVideoProgress;
  final String? videoDescription;
  final int lastPosition;
  final String currentStatus;

  const YoutubeVideoPlayerScreen({
    Key? key,
    required this.videoUrl,
    // required this.videoThumb,
    required this.videoTitle,
    required this.videoId,
    required this.onVideoProgress,
    this.videoDescription,
    this.lastPosition = 0,
    this.currentStatus = 'not_started',
  }) : super(key: key);

  @override
  State<YoutubeVideoPlayerScreen> createState() =>
      _YoutubeVideoPlayerScreenState();
}

class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
  late YoutubePlayerController _controller;
  String? _videoId;
  bool _isCompleted = false;
  bool _hasResumed = false;
  int _lastSavedPosition = 0;
  int _maxWatchedPosition = 0;
  Timer? _seekMonitorTimer;
  bool _isAllowedSeek = false;

  @override
  void initState() {
    super.initState();

    if (widget.currentStatus == 'completed') {
      _isCompleted = true;
    }

    _maxWatchedPosition = widget.lastPosition;
    _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

    if (_videoId != null) {
      _controller = YoutubePlayerController(
        initialVideoId: _videoId!,
        flags: const YoutubePlayerFlags(
          autoPlay: false,
          mute: false,
          hideControls: false,
          disableDragSeek: true, // ✅ Drag seek disabled
          enableCaption: false,
          forceHD: false,
          useHybridComposition: true,
        ),
      )..addListener(_videoListener);

      _startSeekMonitoring();
    }
  }

  void _startSeekMonitoring() {
    _seekMonitorTimer = Timer.periodic(const Duration(milliseconds: 100), (
      timer,
    ) {
      if (!mounted || !_controller.value.isReady) return;

      final currentPos = _controller.value.position.inSeconds;

      // ✅ If user tries to skip ahead, reset to start
      if (!_isAllowedSeek && currentPos > _maxWatchedPosition + 2) {
        print('🚨 SEEK ATTEMPT DETECTED - RESETTING TO START');

        _controller.pause();
        _controller.seekTo(const Duration(seconds: 0)); // ✅ Reset to beginning
        _maxWatchedPosition = 0; // ✅ Reset max position

        // _showResetWarning();

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _controller.play();
          }
        });
        return;
      }

      // Update max watched position only during normal playback
      if (_controller.value.isPlaying &&
          currentPos > _maxWatchedPosition &&
          currentPos <= _maxWatchedPosition + 2) {
        _maxWatchedPosition = currentPos;
      }
    });
  }

  void _videoListener() {
    if (!mounted || !_controller.value.isReady) return;

    if (!_hasResumed && widget.lastPosition > 5 && !_isCompleted) {
      setState(() => _hasResumed = true);

      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _isAllowedSeek = true;
          _controller.seekTo(Duration(seconds: widget.lastPosition));

          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _isAllowedSeek = false;
            }
          });
        }
      });
      return;
    }

    if (_isCompleted) return;

    final position = _controller.value.position.inSeconds;
    final duration = _controller.metadata.duration.inSeconds;

    if (duration > 0 && position > 0) {
      final progress = position / duration;

      if (position % 5 == 0 && position != _lastSavedPosition) {
        _lastSavedPosition = position;
        widget.onVideoProgress(progress, 'in_progress', position);
      }

      if (progress >= 0.95) {
        final maxProgress = _maxWatchedPosition / duration;

        if (maxProgress >= 0.95) {
          setState(() => _isCompleted = true);
          widget.onVideoProgress(1.0, 'completed', duration);
          _showCompletionDialog();
        }
      }
    }
  }

  @override
  void dispose() {
    _seekMonitorTimer?.cancel();

    if (_controller.value.isReady && !_isCompleted) {
      final duration = _controller.metadata.duration.inSeconds;
      if (duration > 0) {
        final progress = _maxWatchedPosition / duration;
        widget.onVideoProgress(progress, 'in_progress', _maxWatchedPosition);
      }
    }

    _controller.removeListener(_videoListener);
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Invalid video')),
        body: const Center(child: Text('Invalid YouTube URL')),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: false, // ✅ Seek bar hidden
        topActions: [], // ✅ Remove top actions
        bottomActions: [
          // ✅ Custom bottom controls WITHOUT progress bar interaction
          // const SizedBox(width: 14.0),
          // CurrentPosition(),
          // const SizedBox(width: 8.0),
          // const Text('/'),
          // const SizedBox(width: 8.0),
          // RemainingDuration(),
          // const Spacer(),
          // PlaybackSpeedButton(),
          // FullScreenButton(),
          const SizedBox(width: 14.0),
          CurrentPosition(),
          const SizedBox(width: 8.0),
          const Text('/'),
          const SizedBox(width: 8.0),
          RemainingDuration(),
          const Spacer(),
          PlaybackSpeedButton(),
          FullScreenButton(),
        ],
        onReady: () {
          print('✅ YouTube Player Ready');
        },
        onEnded: (_) {
          final duration = _controller.metadata.duration.inSeconds;
          final maxProgress = _maxWatchedPosition / duration;

          if (!_isCompleted && maxProgress >= 0.95) {
            setState(() => _isCompleted = true);
            widget.onVideoProgress(1.0, 'completed', duration);
            _showCompletionDialog();
          }
        },
      ),
      builder: (context, player) {
        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Text(
              widget.videoTitle,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: (_) {
                    // ✅ Reset to start on any drag attempt
                    // _resetVideoToStart();
                  },
                  onHorizontalDragStart: (_) {
                    // ✅ Block drag start
                    // _resetVideoToStart();
                  },
                  onTapDown: (details) {
                    // ✅ Check if tap is on bottom control area
                    final RenderBox? box =
                        context.findRenderObject() as RenderBox?;
                    if (box != null) {
                      final localPosition = details.localPosition;

                      // Bottom 60px is control area
                      if (localPosition.dy > box.size.height - 60) {
                        final width = box.size.width;

                        // If tap is in the middle area (progress bar zone)
                        // Exclude left 80px (time) and right 100px (buttons)
                        if (localPosition.dx > 80 &&
                            localPosition.dx < width - 100) {
                          // _resetVideoToStart();
                        }
                      }
                    }
                  },
                  child: Stack(
                    children: [
                      player,
                      // ✅ Invisible shield on progress bar area
                      // Positioned(
                      //   bottom: 35, // Above bottom controls
                      //   left: 0,
                      //   right: 0,
                      //   height: 30,
                      //   child: GestureDetector(
                      //     onTap: () => _resetVideoToStart(),
                      //     onHorizontalDragUpdate: (_) => _resetVideoToStart(),
                      //     onVerticalDragUpdate: (_) => _resetVideoToStart(),
                      //     child: Container(color: Colors.transparent),
                      //   ),
                      // ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.videoTitle,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (widget.videoDescription != null &&
                          widget.videoDescription!.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Description',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.videoDescription!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('🎉 Video Completed'),
              content: const Text(
                'Great job! You have successfully completed this video.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('Close'),
                ),
              ],
            ),
      );
    }
  }

  void _showSkipWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Skipping disabled. Watch sequentially.'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetVideoToStart() {
    if (!_isAllowedSeek && mounted) {
      print('🚨 SEEK BLOCKED - RESETTING TO START');

      _isAllowedSeek = true;
      _controller.pause();
      _controller.seekTo(const Duration(seconds: 0));
      _maxWatchedPosition = 0;
      _lastSavedPosition = 0; // ✅ Reset saved position

      // ✅ Save progress as 0 to backend
      widget.onVideoProgress(0.0, 'not_started', 0);

      // _showResetWarning();

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _isAllowedSeek = false;
        }
      });
    }
  }

  void _showResetWarning() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ Video reset to start! Don\'t try to skip.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}



// class YoutubeVideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//   final String videoTitle;
//   final int videoId;
//   final Function(double, String, int) onVideoProgress;
//   final String? videoDescription;
//   final int lastPosition;
//   final String currentStatus;

//   const YoutubeVideoPlayerScreen({
//     Key? key,
//     required this.videoUrl,
//     required this.videoTitle,
//     required this.videoId,
//     required this.onVideoProgress,
//     this.videoDescription,
//     this.lastPosition = 0,
//     this.currentStatus = 'not_started',
//   }) : super(key: key);

//   @override
//   State<YoutubeVideoPlayerScreen> createState() =>
//       _YoutubeVideoPlayerScreenState();
// }

// class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   String? _videoId;
//   bool _isCompleted = false;
//   bool _hasStarted = false;
//   bool _hasResumed = false;
//   int _lastSavedPosition = 0;
//   int _maxWatchedPosition = 0;
//   Timer? _seekMonitorTimer;
//   bool _isAllowedSeek = false;
//   int _lastCheckedPosition = 0;

//   @override
//   void initState() {
//     super.initState();

//     if (widget.currentStatus == 'completed') {
//       _isCompleted = true;
//       print("✅ Video already completed - progress updates disabled");
//     }

//     _maxWatchedPosition = widget.lastPosition;
//     _lastCheckedPosition = widget.lastPosition;
//     _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

//     if (_videoId != null) {
//       _controller = YoutubePlayerController(
//         initialVideoId: _videoId!,
//         flags: const YoutubePlayerFlags(
//           autoPlay: true,
//           mute: false,
//           disableDragSeek: true,
//           enableCaption: false,
//           hideControls: false,
//         ),
//       )..addListener(_videoListener);
//       _controller.addListener(_fullScreenFixListener);

//       // ✅ ULTRA AGGRESSIVE MONITORING - Checks every 200ms
//       _startSeekMonitoring();
//     }
//   }

//   bool _wasFullScreen = false; // <-- add this field in your class (top level)

//   void _fullScreenFixListener() {
//     if (!_controller.value.isReady) return;

//     final isFull = _controller.value.isFullScreen;

//     // Detect transition (only trigger once per toggle)
//     if (isFull && !_wasFullScreen) {
//       _wasFullScreen = true;

//       // _isAllowedSeek = true;
//       final currentPos = _controller.value.position;
//       print("📺 Entering fullscreen at ${currentPos.inSeconds}s");

//       Future.delayed(const Duration(milliseconds: 600), () {
//         if (mounted && _controller.value.isReady) {
//           _controller.seekTo(currentPos);
//           _isAllowedSeek = false;
//           print("✅ Restored position after entering fullscreen");
//         }
//       });
//     } else if (!isFull && _wasFullScreen) {
//       _wasFullScreen = false;

//       // _isAllowedSeek = true;
//       final currentPos = _controller.value.position;
//       print("⬅️ Exiting fullscreen at ${currentPos.inSeconds}s");

//       Future.delayed(const Duration(milliseconds: 600), () {
//         if (mounted && _controller.value.isReady) {
//           _controller.seekTo(currentPos);
//           _isAllowedSeek = false;
//           print("✅ Restored position after exiting fullscreen");
//         }
//       });
//     }
//   }

//   void _startSeekMonitoring() {
//     _seekMonitorTimer = Timer.periodic(const Duration(milliseconds: 200), (
//       timer,
//     ) {
//       if (!mounted || !_controller.value.isReady) return;

//       final currentPos = _controller.value.position.inSeconds;
//       final isFullScreen = _controller.value.isFullScreen;

//       // ⚠️ Detect skip attempt (even in fullscreen)
//       if (!_isAllowedSeek && currentPos > _maxWatchedPosition + 2) {
//         print(
//           "🚫 SKIP BLOCKED at $currentPos → reverting to $_maxWatchedPosition (fullscreen: $isFullScreen)",
//         );

//         // immediately revert
//         _isAllowedSeek = true;
//         _controller.seekTo(Duration(seconds: _maxWatchedPosition));

//         // extra safety: double-check after small delay
//         Future.delayed(const Duration(milliseconds: 400), () {
//           if (mounted && _controller.value.isReady) {
//             final now = _controller.value.position.inSeconds;
//             if (now > _maxWatchedPosition + 2) {
//               _controller.seekTo(Duration(seconds: _maxWatchedPosition));
//               print("🔁 Forced revert (double-check)");
//             }
//           }
//           _isAllowedSeek = false;
//         });

//         _showSkipWarning();
//         return;
//       }

//       // ✅ Normal forward play tracking
//       if (currentPos > _maxWatchedPosition &&
//           currentPos - _lastCheckedPosition <= 2) {
//         _maxWatchedPosition = currentPos;
//       }

//       _lastCheckedPosition = currentPos;
//     });
//   }

//   void _videoListener() {
//     if (!_controller.value.isReady) return;

//     // ✅ Resume from last position (ONE TIME ONLY)
//     if (_controller.value.isReady &&
//         !_hasResumed &&
//         widget.lastPosition > 5 &&
//         !_isCompleted) {
//       setState(() {
//         _hasResumed = true;
//       });

//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted && _controller.value.isReady) {
//           _isAllowedSeek = true;
//           _controller.seekTo(Duration(seconds: widget.lastPosition));
//           print("▶️ Resumed from ${widget.lastPosition} seconds");

//           Future.delayed(const Duration(milliseconds: 500), () {
//             _isAllowedSeek = false;
//           });
//         }
//       });
//       return;
//     }

//     final currentPosition = _controller.value.position.inSeconds;

//     // ✅ Update max watched position (natural playback only)
//     if (currentPosition > _maxWatchedPosition && !_isAllowedSeek) {
//       _maxWatchedPosition = currentPosition;
//     }

//     if (_isCompleted) return;

//     final position = _controller.value.position.inSeconds;
//     final duration = _controller.metadata.duration.inSeconds;

//     if (duration > 0 && position > 0) {
//       final progress = position / duration;

//       if (progress > 0.01 && !_hasStarted) {
//         _hasStarted = true;
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print("▶️ Video started - saved position: $position sec");
//       }

//       if (_hasStarted &&
//           position > 0 &&
//           position % 5 == 0 &&
//           position != _lastSavedPosition) {
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print(
//           "💾 Progress saved: ${(progress * 100).toInt()}% at $position sec",
//         );
//       }

//       if (progress >= 0.95 && !_isCompleted) {
//         setState(() {
//           _isCompleted = true;
//         });
//         widget.onVideoProgress(1.0, 'completed', duration);
//         print("✅ Video completed!");
//       }
//     }
//   }

//   void _showSkipWarning() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: const [
//             Icon(Icons.block, color: Colors.white, size: 20),
//             SizedBox(width: 10),
//             Expanded(
//               child: Text(
//                 '⚠️ You cannot skip ahead in this video',
//                 style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.red[700],
//         duration: const Duration(seconds: 2),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _seekMonitorTimer?.cancel();

//     if (_controller.value.isReady && !_isCompleted) {
//       final position = _controller.value.position.inSeconds;
//       final duration = _controller.metadata.duration.inSeconds;
//       if (duration > 0) {
//         final progress = position / duration;
//         widget.onVideoProgress(progress, 'in_progress', position);
//       }
//     }

//     _controller.removeListener(_videoListener);
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_videoId == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Invalid video')),
//         body: const Center(child: Text('Invalid YouTube URL')),
//       );
//     }

//     return YoutubePlayerBuilder(
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: true,
//         progressIndicatorColor: Colors.red,
//         progressColors: const ProgressBarColors(
//           playedColor: Colors.red,
//           handleColor: Colors.transparent,
//         ),
//         onEnded: (_) {
//           if (!_isCompleted) {
//             _isCompleted = true;
//             final duration = _controller.metadata.duration.inSeconds;
//             widget.onVideoProgress(1.0, 'completed', duration);
//             _showCompletionDialog();
//           }
//         },
//       ),
//       builder:
//           (context, player) => Scaffold(
//             backgroundColor: Colors.white,
//             appBar: AppBar(
//               backgroundColor: Colors.white,
//               elevation: 0,
//               title: const Text(
//                 'Video Player',
//                 style: TextStyle(
//                   color: Colors.black87,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               leading: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.black87),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             body: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // ✅ FULL COVERAGE OVERLAY - Blocks ALL progress bar interactions
//                   Stack(
//                     children: [
//                       player,
//                       // ✅ COMPLETE PROGRESS BAR BLOCKER
//                       Positioned(
//                         bottom: 0,
//                         left: 50,
//                         right: 50,
//                         height: 50,
//                         child: AbsorbPointer(
//                           absorbing: true,
//                           child: Container(
//                             color: Colors.transparent,
//                             child: Row(
//                               children: [
//                                 // Allow play button area
//                                 const SizedBox(width: 48),
//                                 // Block entire progress bar area
//                                 Expanded(
//                                   child: GestureDetector(
//                                     behavior: HitTestBehavior.opaque,
//                                     onTap: _showProgressBarBlockedMessage,
//                                     onTapDown:
//                                         (_) => _showProgressBarBlockedMessage(),
//                                     onTapUp: (_) {},
//                                     onLongPress: _showProgressBarBlockedMessage,
//                                     onHorizontalDragStart:
//                                         (_) => _showProgressBarBlockedMessage(),
//                                     onHorizontalDragUpdate: (_) {},
//                                     onHorizontalDragEnd: (_) {},
//                                     onPanStart:
//                                         (_) => _showProgressBarBlockedMessage(),
//                                     onPanUpdate: (_) {},
//                                     onPanEnd: (_) {},
//                                     child: Container(color: Colors.transparent),
//                                   ),
//                                 ),
//                                 // Allow other controls
//                                 const SizedBox(width: 48),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.videoTitle,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         // ⚠️ SKIP WARNING BANNER
//                         Container(
//                           padding: const EdgeInsets.all(14),
//                           decoration: BoxDecoration(
//                             gradient: LinearGradient(
//                               colors: [Colors.red[700]!, Colors.orange[700]!],
//                             ),
//                             borderRadius: BorderRadius.circular(10),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.red.withOpacity(0.3),
//                                 blurRadius: 8,
//                                 offset: const Offset(0, 3),
//                               ),
//                             ],
//                           ),
//                           child: Row(
//                             children: const [
//                               Icon(Icons.lock, color: Colors.white, size: 22),
//                               SizedBox(width: 12),
//                               Expanded(
//                                 child: Text(
//                                   '🚫 Video skipping is disabled. You must watch in sequence.',
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 14,
//                                     fontWeight: FontWeight.bold,
//                                     height: 1.4,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         const SizedBox(height: 16),

//                         if (widget.currentStatus == 'completed') ...[
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.green[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.green[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.check_circle,
//                                   color: Colors.green[700],
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'You have already completed this video! 🎉',
//                                     style: TextStyle(
//                                       color: Colors.green[700],
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                         ] else if (widget.lastPosition > 0) ...[
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.blue[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.blue[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.play_arrow,
//                                   color: Colors.blue[700],
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'Resumed from ${_formatDuration(widget.lastPosition)}',
//                                     style: TextStyle(
//                                       color: Colors.blue[700],
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                         ],

//                         if (widget.videoDescription != null &&
//                             widget.videoDescription!.isNotEmpty) ...[
//                           const SizedBox(height: 12),
//                           const Text(
//                             'Description',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.videoDescription!,
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[700],
//                               height: 1.5,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                         ],

//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey[300]!),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.info_outline,
//                                 color: Colors.grey[700],
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   widget.currentStatus == 'completed'
//                                       ? 'This video is marked as completed. You can watch it again anytime!'
//                                       : 'Your progress is automatically saved. You can resume anytime!',
//                                   style: TextStyle(
//                                     color: Colors.grey[700],
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   String _formatDuration(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   void _showProgressBarBlockedMessage() {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: const [
//             Icon(Icons.block, color: Colors.white, size: 18),
//             SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Progress bar is disabled',
//                 style: TextStyle(fontSize: 13),
//               ),
//             ),
//           ],
//         ),
//         backgroundColor: Colors.red[600],
//         duration: const Duration(milliseconds: 1500),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('🎉 Video Completed'),
//             content: const Text(
//               'Great job! You finished this video successfully!',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _isAllowedSeek = true;
//                   _controller.seekTo(Duration.zero);
//                   Future.delayed(const Duration(milliseconds: 500), () {
//                     _isAllowedSeek = false;
//                   });
//                 },
//                 child: const Text('Replay'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Close'),
//               ),
//             ],
//           ),
//     );
//   }
// }//  class YoutubeVideoPlayerScreen extends StatefulWidget {



//   final String videoUrl;
//   final String videoTitle;
//   final int videoId;
//   final Function(double, String, int) onVideoProgress;
//   final String? videoDescription;
//   final int lastPosition;
//   final String currentStatus;

//   const YoutubeVideoPlayerScreen({
//     Key? key,
//     required this.videoUrl,
//     required this.videoTitle,
//     required this.videoId,
//     required this.onVideoProgress,
//     this.videoDescription,
//     this.lastPosition = 0,
//     this.currentStatus = 'not_started',
//   }) : super(key: key);

//   @override
//   State<YoutubeVideoPlayerScreen> createState() =>
//       _YoutubeVideoPlayerScreenState();
// }

// class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   String? _videoId;
//   bool _isCompleted = false;
//   bool _hasStarted = false;
//   bool _hasResumed = false;
//   int _lastSavedPosition = 0;
//   int _maxWatchedPosition = 0;
//   double _playbackSpeed = 1.0;

//   @override
//   void initState() {
//     super.initState();

//     if (widget.currentStatus == 'completed') {
//       _isCompleted = true;
//       print("✅ Video already completed - progress updates disabled");
//     }

//     _maxWatchedPosition = widget.lastPosition;
//     _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

//     if (_videoId != null) {
//       _controller = YoutubePlayerController(
//         initialVideoId: _videoId!,
//         flags: const YoutubePlayerFlags(
//           autoPlay: true,
//           mute: false,
//           disableDragSeek: true,
//           enableCaption: false,
//           hideControls: false,
//         ),
//       )..addListener(_videoListener);
//     }
//   }

//   void _videoListener() {
//     if (!_controller.value.isReady) return;

//     // Resume from last position
//     if (_controller.value.isReady &&
//         !_hasResumed &&
//         widget.lastPosition > 5 &&
//         !_isCompleted) {
//       setState(() {
//         _hasResumed = true;
//       });

//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted && _controller.value.isReady) {
//           _controller.seekTo(Duration(seconds: widget.lastPosition));
//           print("▶️ Resumed from ${widget.lastPosition} seconds");
//         }
//       });
//       return;
//     }

//     // PREVENT FORWARD SEEKING
//     final currentPosition = _controller.value.position.inSeconds;

//     if (currentPosition > _maxWatchedPosition + 2) {
//       print("⚠️ Forward seek detected! Rewinding to $_maxWatchedPosition sec");
//       _controller.seekTo(Duration(seconds: _maxWatchedPosition));

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: const [
//               Icon(Icons.warning_amber, color: Colors.white, size: 20),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'You cannot skip ahead in this video',
//                   style: TextStyle(fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//           backgroundColor: Colors.orange[700],
//           duration: const Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     if (currentPosition > _maxWatchedPosition) {
//       _maxWatchedPosition = currentPosition;
//     }

//     if (_isCompleted) {
//       return;
//     }

//     final position = _controller.value.position.inSeconds;
//     final duration = _controller.metadata.duration.inSeconds;

//     if (duration > 0 && position > 0) {
//       final progress = position / duration;

//       if (progress > 0.01 && !_hasStarted) {
//         _hasStarted = true;
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print("▶️ Video started - saved position: $position sec");
//       }

//       if (_hasStarted &&
//           position > 0 &&
//           position % 5 == 0 &&
//           position != _lastSavedPosition) {
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print(
//           "💾 Progress saved: ${(progress * 100).toInt()}% at $position sec",
//         );
//       }

//       if (progress >= 0.95 && !_isCompleted) {
//         setState(() {
//           _isCompleted = true;
//         });
//         widget.onVideoProgress(1.0, 'completed', duration);
//         print("✅ Video completed!");
//       }
//     }
//   }

//   void _changeSpeed(double speed) {
//     setState(() {
//       _playbackSpeed = speed;
//     });
//     _controller.setPlaybackRate(_playbackSpeed);
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Playback speed set to ${speed}x',
//           style: const TextStyle(fontSize: 14),
//         ),
//         backgroundColor: Colors.blue[700],
//         duration: const Duration(seconds: 1),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _showSpeedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Playback Speed'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildSpeedOption(0.25),
//             _buildSpeedOption(0.5),
//             _buildSpeedOption(0.75),
//             _buildSpeedOption(1.0),
//             _buildSpeedOption(1.25),
//             _buildSpeedOption(1.5),
//             _buildSpeedOption(1.75),
//             _buildSpeedOption(2.0),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSpeedOption(double speed) {
//     final isSelected = _playbackSpeed == speed;
//     return ListTile(
//       title: Text(
//         '${speed}x',
//         style: TextStyle(
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           color: isSelected ? Colors.blue[700] : Colors.black87,
//         ),
//       ),
//       trailing: isSelected
//           ? Icon(Icons.check, color: Colors.blue[700])
//           : null,
//       onTap: () {
//         _changeSpeed(speed);
//         Navigator.pop(context);
//       },
//     );
//   }

//   @override
//   void dispose() {
//     if (_controller.value.isReady && !_isCompleted) {
//       final position = _controller.value.position.inSeconds;
//       final duration = _controller.metadata.duration.inSeconds;
//       if (duration > 0) {
//         final progress = position / duration;
//         widget.onVideoProgress(progress, 'in_progress', position);
//       }
//     }

//     _controller.removeListener(_videoListener);
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_videoId == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Invalid video')),
//         body: const Center(child: Text('Invalid YouTube URL')),
//       );
//     }

//     return YoutubePlayerBuilder(
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: false,
//         progressIndicatorColor: Colors.transparent,
//         progressColors: const ProgressBarColors(
//           playedColor: Colors.transparent,
//           handleColor: Colors.transparent,
//           bufferedColor: Colors.transparent,
//           backgroundColor: Colors.transparent,
//         ),
//         onEnded: (_) {
//           if (!_isCompleted) {
//             _isCompleted = true;
//             final duration = _controller.metadata.duration.inSeconds;
//             widget.onVideoProgress(1.0, 'completed', duration);
//             _showCompletionDialog();
//           }
//         },
//       ),
//       builder: (context, player) => Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           title: const Text(
//             'Video Player',
//             style: TextStyle(
//               color: Colors.black87,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black87),
//             onPressed: () => Navigator.pop(context),
//           ),
//           actions: [
//             IconButton(
//               icon: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   const Icon(Icons.speed, color: Colors.black87),
//                   if (_playbackSpeed != 1.0)
//                     Positioned(
//                       right: 0,
//                       top: 0,
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[700],
//                           shape: BoxShape.circle,
//                         ),
//                         child: Text(
//                           '${_playbackSpeed}x',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 8,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               onPressed: _showSpeedDialog,
//               tooltip: 'Change Speed',
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ✅ TRIPLE LAYER PROTECTION - Progress bar pe click completely disabled
//               Stack(
//                 children: [
//                   // Video player (background)
//                   player,
                  
//                   // ✅ Transparent overlay jo SIRF progress bar (bottom 4-6px) ko cover karega
//                   Positioned(
//                     left: 0,
//                     right: 0,
//                     bottom: 0,
//                     height: 8, // ✅ Sirf progress bar ki height (4-6px typically)
//                     child: GestureDetector(
//                       onTap: () {
//                         print("⛔ Progress bar click blocked!");
//                       },
//                       onTapDown: (_) {
//                         print("⛔ Progress bar tap down blocked!");
//                       },
//                       onTapUp: (_) {
//                         print("⛔ Progress bar tap up blocked!");
//                       },
//                       onHorizontalDragStart: (_) {
//                         print("⛔ Horizontal drag blocked!");
//                       },
//                       onHorizontalDragUpdate: (_) {
//                         print("⛔ Horizontal drag update blocked!");
//                       },
//                       onVerticalDragStart: (_) {
//                         print("⛔ Vertical drag blocked!");
//                       },
//                       behavior: HitTestBehavior.opaque,
//                       child: Container(
//                         color: Colors.transparent,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
              
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.videoTitle,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     const SizedBox(height: 12),

//                     if (widget.currentStatus == 'completed') ...[
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.green[50],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.green[200]!),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.check_circle,
//                               color: Colors.green[700],
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 'You have already completed this video! 🎉',
//                                 style: TextStyle(
//                                   color: Colors.green[700],
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                     ] else if (widget.lastPosition > 0) ...[
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[50],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.blue[200]!),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.play_arrow,
//                               color: Colors.blue[700],
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 'Resumed from ${_formatDuration(widget.lastPosition)}',
//                                 style: TextStyle(
//                                   color: Colors.blue[700],
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                     ],

//                     const SizedBox(height: 12),

//                     if (widget.videoDescription != null &&
//                         widget.videoDescription!.isNotEmpty) ...[
//                       const Text(
//                         'Description',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         widget.videoDescription!,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[700],
//                           height: 1.5,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],

//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.info_outline,
//                             color: Colors.grey[700],
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               widget.currentStatus == 'completed'
//                                   ? 'This video is marked as completed. You can watch it again anytime!'
//                                   : 'Your progress is automatically saved. You can resume anytime!',
//                               style: TextStyle(
//                                 color: Colors.grey[700],
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
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

//   String _formatDuration(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('🎉 Video Completed'),
//         content: const Text(
//           'Great job! You finished this video successfully!',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _controller.seekTo(Duration.zero);
//             },
//             child: const Text('Replay'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
// }
// class YoutubeVideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//   final String videoTitle;
//   final int videoId;
//   final Function(double, String, int) onVideoProgress;
//   final String? videoDescription;
//   final int lastPosition;
//   final String currentStatus;

//   const YoutubeVideoPlayerScreen({
//     Key? key,
//     required this.videoUrl,
//     required this.videoTitle,
//     required this.videoId,
//     required this.onVideoProgress,
//     this.videoDescription,
//     this.lastPosition = 0,
//     this.currentStatus = 'not_started',
//   }) : super(key: key);

//   @override
//   State<YoutubeVideoPlayerScreen> createState() =>
//       _YoutubeVideoPlayerScreenState();
// }

// class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   String? _videoId;
//   bool _isCompleted = false;
//   bool _hasStarted = false;
//   bool _hasResumed = false;
//   int _lastSavedPosition = 0;
//   int _maxWatchedPosition = 0;
//   double _playbackSpeed = 1.0;

//   @override
//   void initState() {
//     super.initState();

//     if (widget.currentStatus == 'completed') {
//       _isCompleted = true;
//       print("✅ Video already completed - progress updates disabled");
//     }

//     _maxWatchedPosition = widget.lastPosition;
//     _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

//     if (_videoId != null) {
//       _controller = YoutubePlayerController(
//         initialVideoId: _videoId!,
//         flags: const YoutubePlayerFlags(
//           autoPlay: true,
//           mute: false,
//           disableDragSeek: true,
//           enableCaption: false,
//           hideControls: false,
//         ),
//       )..addListener(_videoListener);
//     }
//   }

//   void _videoListener() {
//     if (!_controller.value.isReady) return;

//     // Resume from last position
//     if (_controller.value.isReady &&
//         !_hasResumed &&
//         widget.lastPosition > 5 &&
//         !_isCompleted) {
//       setState(() {
//         _hasResumed = true;
//       });

//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted && _controller.value.isReady) {
//           _controller.seekTo(Duration(seconds: widget.lastPosition));
//           print("▶️ Resumed from ${widget.lastPosition} seconds");
//         }
//       });
//       return;
//     }

//     // PREVENT FORWARD SEEKING
//     final currentPosition = _controller.value.position.inSeconds;

//     if (currentPosition > _maxWatchedPosition + 2) {
//       print("⚠️ Forward seek detected! Rewinding to $_maxWatchedPosition sec");
//       _controller.seekTo(Duration(seconds: _maxWatchedPosition));

//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: const [
//               Icon(Icons.warning_amber, color: Colors.white, size: 20),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'You cannot skip ahead in this video',
//                   style: TextStyle(fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//           backgroundColor: Colors.orange[700],
//           duration: const Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     if (currentPosition > _maxWatchedPosition) {
//       _maxWatchedPosition = currentPosition;
//     }

//     if (_isCompleted) {
//       return;
//     }

//     final position = _controller.value.position.inSeconds;
//     final duration = _controller.metadata.duration.inSeconds;

//     if (duration > 0 && position > 0) {
//       final progress = position / duration;

//       if (progress > 0.01 && !_hasStarted) {
//         _hasStarted = true;
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print("▶️ Video started - saved position: $position sec");
//       }

//       if (_hasStarted &&
//           position > 0 &&
//           position % 5 == 0 &&
//           position != _lastSavedPosition) {
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print(
//           "💾 Progress saved: ${(progress * 100).toInt()}% at $position sec",
//         );
//       }

//       if (progress >= 0.95 && !_isCompleted) {
//         setState(() {
//           _isCompleted = true;
//         });
//         widget.onVideoProgress(1.0, 'completed', duration);
//         print("✅ Video completed!");
//       }
//     }
//   }

//   void _changeSpeed(double speed) {
//     setState(() {
//       _playbackSpeed = speed;
//     });
//     _controller.setPlaybackRate(_playbackSpeed);
    
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(
//           'Playback speed set to ${speed}x',
//           style: const TextStyle(fontSize: 14),
//         ),
//         backgroundColor: Colors.blue[700],
//         duration: const Duration(seconds: 1),
//         behavior: SnackBarBehavior.floating,
//       ),
//     );
//   }

//   void _showSpeedDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Playback Speed'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             _buildSpeedOption(0.25),
//             _buildSpeedOption(0.5),
//             _buildSpeedOption(0.75),
//             _buildSpeedOption(1.0),
//             _buildSpeedOption(1.25),
//             _buildSpeedOption(1.5),
//             _buildSpeedOption(1.75),
//             _buildSpeedOption(2.0),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSpeedOption(double speed) {
//     final isSelected = _playbackSpeed == speed;
//     return ListTile(
//       title: Text(
//         '${speed}x',
//         style: TextStyle(
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//           color: isSelected ? Colors.blue[700] : Colors.black87,
//         ),
//       ),
//       trailing: isSelected
//           ? Icon(Icons.check, color: Colors.blue[700])
//           : null,
//       onTap: () {
//         _changeSpeed(speed);
//         Navigator.pop(context);
//       },
//     );
//   }

//   @override
//   void dispose() {
//     if (_controller.value.isReady && !_isCompleted) {
//       final position = _controller.value.position.inSeconds;
//       final duration = _controller.metadata.duration.inSeconds;
//       if (duration > 0) {
//         final progress = position / duration;
//         widget.onVideoProgress(progress, 'in_progress', position);
//       }
//     }

//     _controller.removeListener(_videoListener);
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_videoId == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Invalid video')),
//         body: const Center(child: Text('Invalid YouTube URL')),
//       );
//     }

//     return YoutubePlayerBuilder(
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: false,
//         progressIndicatorColor: Colors.transparent,
//         progressColors: const ProgressBarColors(
//           playedColor: Colors.transparent,
//           handleColor: Colors.transparent,
//           bufferedColor: Colors.transparent,
//           backgroundColor: Colors.transparent,
//         ),
//         onEnded: (_) {
//           if (!_isCompleted) {
//             _isCompleted = true;
//             final duration = _controller.metadata.duration.inSeconds;
//             widget.onVideoProgress(1.0, 'completed', duration);
//             _showCompletionDialog();
//           }
//         },
//       ),
//       builder: (context, player) => Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: Colors.white,
//           elevation: 0,
//           title: const Text(
//             'Video Player',
//             style: TextStyle(
//               color: Colors.black87,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           leading: IconButton(
//             icon: const Icon(Icons.arrow_back, color: Colors.black87),
//             onPressed: () => Navigator.pop(context),
//           ),
//           actions: [
//             IconButton(
//               icon: Stack(
//                 alignment: Alignment.center,
//                 children: [
//                   const Icon(Icons.speed, color: Colors.black87),
//                   if (_playbackSpeed != 1.0)
//                     Positioned(
//                       right: 0,
//                       top: 0,
//                       child: Container(
//                         padding: const EdgeInsets.all(2),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[700],
//                           shape: BoxShape.circle,
//                         ),
//                         child: Text(
//                           '${_playbackSpeed}x',
//                           style: const TextStyle(
//                             color: Colors.white,
//                             fontSize: 8,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                       ),
//                     ),
//                 ],
//               ),
//               onPressed: _showSpeedDialog,
//               tooltip: 'Change Speed',
//             ),
//           ],
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // ✅ TRIPLE LAYER PROTECTION - Progress bar pe click completely disabled
//               Stack(
//                 children: [
//                   // Video player (background)
//                   player,
                  
//                   // ✅ Transparent overlay jo sirf progress bar ko cover karega
//                   Positioned(
//                     left: 0,
//                     right: 0,
//                     bottom: 0,
//                     height: 50, // Progress bar area height
//                     child: GestureDetector(
//                       onTap: () {
//                         print("⛔ Progress bar click blocked!");
//                       },
//                       onTapDown: (_) {
//                         print("⛔ Progress bar tap down blocked!");
//                       },
//                       onTapUp: (_) {
//                         print("⛔ Progress bar tap up blocked!");
//                       },
//                       onHorizontalDragStart: (_) {
//                         print("⛔ Horizontal drag blocked!");
//                       },
//                       onHorizontalDragUpdate: (_) {
//                         print("⛔ Horizontal drag update blocked!");
//                       },
//                       onVerticalDragStart: (_) {
//                         print("⛔ Vertical drag blocked!");
//                       },
//                       behavior: HitTestBehavior.opaque,
//                       child: Container(
//                         color: Colors.transparent,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
              
//               Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.videoTitle,
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 20),

//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.blue[50],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.blue[200]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.speed,
//                             color: Colors.blue[700],
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'Current Speed: ${_playbackSpeed}x',
//                               style: TextStyle(
//                                 color: Colors.blue[700],
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                               ),
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: _showSpeedDialog,
//                             child: const Text('Change'),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(height: 12),

//                     if (widget.currentStatus == 'completed') ...[
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.green[50],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.green[200]!),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.check_circle,
//                               color: Colors.green[700],
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 'You have already completed this video! 🎉',
//                                 style: TextStyle(
//                                   color: Colors.green[700],
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                     ] else if (widget.lastPosition > 0) ...[
//                       Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.blue[50],
//                           borderRadius: BorderRadius.circular(8),
//                           border: Border.all(color: Colors.blue[200]!),
//                         ),
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.play_arrow,
//                               color: Colors.blue[700],
//                               size: 20,
//                             ),
//                             const SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 'Resumed from ${_formatDuration(widget.lastPosition)}',
//                                 style: TextStyle(
//                                   color: Colors.blue[700],
//                                   fontSize: 13,
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                     ],

//                     const SizedBox(height: 12),

//                     if (widget.videoDescription != null &&
//                         widget.videoDescription!.isNotEmpty) ...[
//                       const Text(
//                         'Description',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                       Text(
//                         widget.videoDescription!,
//                         style: TextStyle(
//                           fontSize: 14,
//                           color: Colors.grey[700],
//                           height: 1.5,
//                         ),
//                       ),
//                       const SizedBox(height: 20),
//                     ],

//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(8),
//                         border: Border.all(color: Colors.grey[300]!),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.info_outline,
//                             color: Colors.grey[700],
//                             size: 20,
//                           ),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               widget.currentStatus == 'completed'
//                                   ? 'This video is marked as completed. You can watch it again anytime!'
//                                   : 'Your progress is automatically saved. You can resume anytime!',
//                               style: TextStyle(
//                                 color: Colors.grey[700],
//                                 fontSize: 13,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
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

//   String _formatDuration(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('🎉 Video Completed'),
//         content: const Text(
//           'Great job! You finished this video successfully!',
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _controller.seekTo(Duration.zero);
//             },
//             child: const Text('Replay'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               Navigator.pop(context);
//             },
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }
// }
// class YoutubeVideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//   final String videoTitle;
//   final int videoId;
//   final Function(double, String, int) onVideoProgress;
//   final String? videoDescription;
//   final int lastPosition;
//   final String currentStatus;

//   const YoutubeVideoPlayerScreen({
//     Key? key,
//     required this.videoUrl,
//     required this.videoTitle,
//     required this.videoId,
//     required this.onVideoProgress,
//     this.videoDescription,
//     this.lastPosition = 0,
//     this.currentStatus = 'not_started',
//   }) : super(key: key);

//   @override
//   State<YoutubeVideoPlayerScreen> createState() =>
//       _YoutubeVideoPlayerScreenState();
// }

// class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   String? _videoId;
//   bool _isCompleted = false;
//   bool _hasStarted = false;
//   bool _hasResumed = false;
//   int _lastSavedPosition = 0;
//   int _maxWatchedPosition = 0; // ✅ Track maximum watched position

//   @override
//   void initState() {
//     super.initState();

//     if (widget.currentStatus == 'completed') {
//       _isCompleted = true;
//       print("✅ Video already completed - progress updates disabled");
//     }

//     // ✅ Initialize max watched position
//     _maxWatchedPosition = widget.lastPosition;

//     _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

//     if (_videoId != null) {
//       _controller = YoutubePlayerController(
//         initialVideoId: _videoId!,
//         flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
//       )..addListener(_videoListener);
//     }
//   }

//   void _videoListener() {
//     if (!_controller.value.isReady) return;

//     // ✅ Resume from last position (only once, only if not completed)
//     if (_controller.value.isReady &&
//         !_hasResumed &&
//         widget.lastPosition > 5 &&
//         !_isCompleted) {
//       setState(() {
//         _hasResumed = true;
//       });

//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted && _controller.value.isReady) {
//           _controller.seekTo(Duration(seconds: widget.lastPosition));
//           print("▶️ Resumed from ${widget.lastPosition} seconds");
//         }
//       });
//       return;
//     }

//     // ✅ PREVENT FORWARD SEEKING
//     final currentPosition = _controller.value.position.inSeconds;

//     // If user tries to skip ahead, rewind to max watched position
//     if (currentPosition > _maxWatchedPosition + 2) {
//       // +2 sec buffer
//       print("⚠️ Forward seek detected! Rewinding to $_maxWatchedPosition sec");
//       _controller.seekTo(Duration(seconds: _maxWatchedPosition));

//       // Show warning message
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Row(
//             children: const [
//               Icon(Icons.warning_amber, color: Colors.white, size: 20),
//               SizedBox(width: 8),
//               Expanded(
//                 child: Text(
//                   'You cannot skip ahead in this video',
//                   style: TextStyle(fontSize: 14),
//                 ),
//               ),
//             ],
//           ),
//           backgroundColor: Colors.orange[700],
//           duration: const Duration(seconds: 2),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     // ✅ Update max watched position
//     if (currentPosition > _maxWatchedPosition) {
//       _maxWatchedPosition = currentPosition;
//     }

//     // ✅ If video already completed, DO NOT save progress
//     if (_isCompleted) {
//       return;
//     }

//     final position = _controller.value.position.inSeconds;
//     final duration = _controller.metadata.duration.inSeconds;

//     if (duration > 0 && position > 0) {
//       final progress = position / duration;

//       // ✅ Mark as 'in_progress' when video starts
//       if (progress > 0.01 && !_hasStarted) {
//         _hasStarted = true;
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print("▶️ Video started - saved position: $position sec");
//       }

//       // ✅ Save position every 5 seconds
//       if (_hasStarted &&
//           position > 0 &&
//           position % 5 == 0 &&
//           position != _lastSavedPosition) {
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print(
//           "💾 Progress saved: ${(progress * 100).toInt()}% at $position sec",
//         );
//       }

//       // ✅ Mark as 'completed' when 95% watched
//       if (progress >= 0.95 && !_isCompleted) {
//         setState(() {
//           _isCompleted = true;
//         });
//         widget.onVideoProgress(1.0, 'completed', duration);
//         print("✅ Video completed!");
//       }
//     }
//   }

//   @override
//   void dispose() {
//     // ✅ Save position before leaving (only if NOT completed)
//     if (_controller.value.isReady && !_isCompleted) {
//       final position = _controller.value.position.inSeconds;
//       final duration = _controller.metadata.duration.inSeconds;
//       if (duration > 0) {
//         final progress = position / duration;
//         widget.onVideoProgress(progress, 'in_progress', position);
//       }
//     }

//     _controller.removeListener(_videoListener);
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_videoId == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Invalid video')),
//         body: const Center(child: Text('Invalid YouTube URL')),
//       );
//     }

//     return YoutubePlayerBuilder(
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: true,
//         onEnded: (_) {
//           if (!_isCompleted) {
//             _isCompleted = true;
//             final duration = _controller.metadata.duration.inSeconds;
//             widget.onVideoProgress(1.0, 'completed', duration);
//             _showCompletionDialog();
//           }
//         },
//       ),
//       builder:
//           (context, player) => Scaffold(
//             backgroundColor: Colors.white,
//             appBar: AppBar(
//               backgroundColor: Colors.white,
//               elevation: 0,
//               title: const Text(
//                 'Video Player',
//                 style: TextStyle(
//                   color: Colors.black87,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               leading: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.black87),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             body: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   player,
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.videoTitle,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 20),

//                         // ✅ Show completion badge if already completed
//                         if (widget.currentStatus == 'completed') ...[
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.green[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.green[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.check_circle,
//                                   color: Colors.green[700],
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'You have already completed this video! 🎉',
//                                     style: TextStyle(
//                                       color: Colors.green[700],
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                         ]
//                         // ✅ Show resume indicator if in progress
//                         else if (widget.lastPosition > 0) ...[
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.blue[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.blue[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.play_arrow,
//                                   color: Colors.blue[700],
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'Resumed from ${_formatDuration(widget.lastPosition)}',
//                                     style: TextStyle(
//                                       color: Colors.blue[700],
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                         ],

//                         // ✅ NEW: Warning message about no forward seeking
//                         const SizedBox(height: 12),

//                         if (widget.videoDescription != null &&
//                             widget.videoDescription!.isNotEmpty) ...[
//                           const Text(
//                             'Description',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.videoDescription!,
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[700],
//                               height: 1.5,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                         ],

//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey[300]!),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.info_outline,
//                                 color: Colors.grey[700],
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   widget.currentStatus == 'completed'
//                                       ? 'This video is marked as completed. You can watch it again anytime!'
//                                       : 'Your progress is automatically saved. You can resume anytime!',
//                                   style: TextStyle(
//                                     color: Colors.grey[700],
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   String _formatDuration(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('🎉 Video Completed'),
//             content: const Text(
//               'Great job! You finished this video successfully!',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _controller.seekTo(Duration.zero);
//                 },
//                 child: const Text('Replay'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Close'),
//               ),
//             ],
//           ),
//     );
//   }
// }
//  class YoutubeVideoPlayerScreen extends StatefulWidget {
//   final String videoUrl;
//   final String videoTitle;
//   final int videoId;
//   final Function(double, String, int) onVideoProgress;
//   final String? videoDescription;
//   final int lastPosition;
//   final String currentStatus; // ✅ NEW: Current video status

//   const YoutubeVideoPlayerScreen({
//     Key? key,
//     required this.videoUrl,
//     required this.videoTitle,
//     required this.videoId,
//     required this.onVideoProgress,
//     this.videoDescription,
//     this.lastPosition = 0,
//     this.currentStatus = 'not_started', // ✅ NEW
//   }) : super(key: key);

//   @override
//   State<YoutubeVideoPlayerScreen> createState() =>
//       _YoutubeVideoPlayerScreenState();
// }

// class _YoutubeVideoPlayerScreenState extends State<YoutubeVideoPlayerScreen> {
//   late YoutubePlayerController _controller;
//   String? _videoId;
//   bool _isCompleted = false;
//   bool _hasStarted = false;
//   bool _hasResumed = false;
//   int _lastSavedPosition =
//       0; // ✅ Track last saved position to avoid duplicate saves

//   @override
//   void initState() {
//     super.initState();

//     // ✅ CRITICAL: Check if video already completed
//     if (widget.currentStatus == 'completed') {
//       _isCompleted = true;
//       print("✅ Video already completed - progress updates disabled");
//     }

//     _videoId = YoutubePlayer.convertUrlToId(widget.videoUrl);

//     if (_videoId != null) {
//       _controller = YoutubePlayerController(
//         initialVideoId: _videoId!,
//         flags: const YoutubePlayerFlags(autoPlay: true, mute: false),
//       )..addListener(_videoListener);
//     }
//   }

//   void _videoListener() {
//     if (!_controller.value.isReady) return;

//     // ✅ IMPROVED: Resume from last position (only once, only if not completed)
//     if (_controller.value.isReady &&
//         !_hasResumed &&
//         widget.lastPosition > 5 && // ✅ Only if significant progress (>5 sec)
//         !_isCompleted) {
//       setState(() {
//         _hasResumed = true;
//       });

//       // ✅ Wait for video to fully load before seeking
//       Future.delayed(const Duration(milliseconds: 800), () {
//         if (mounted && _controller.value.isReady) {
//           _controller.seekTo(Duration(seconds: widget.lastPosition));
//           print("▶️ Resumed from ${widget.lastPosition} seconds");
//         }
//       });
//       return; // Exit after resuming
//     }

//     // ✅ CRITICAL: If video already completed, DO NOT save progress!
//     if (_isCompleted) {
//       return;
//     }

//     final position = _controller.value.position.inSeconds;
//     final duration = _controller.metadata.duration.inSeconds;

//     if (duration > 0 && position > 0) {
//       final progress = position / duration;

//       // ✅ Mark as 'in_progress' when video starts
//       if (progress > 0.01 && !_hasStarted) {
//         _hasStarted = true;
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print("▶️ Video started - saved position: $position sec");
//       }

//       // ✅ Save position every 5 seconds (avoid duplicates)
//       if (_hasStarted &&
//           position > 0 &&
//           position % 5 == 0 &&
//           position != _lastSavedPosition) {
//         _lastSavedPosition = position;
//         widget.onVideoProgress(progress, 'in_progress', position);
//         print(
//           "💾 Progress saved: ${(progress * 100).toInt()}% at $position sec",
//         );
//       }

//       // ✅ Mark as 'completed' when 95% watched
//       if (progress >= 0.95 && !_isCompleted) {
//         setState(() {
//           _isCompleted = true;
//         });
//         widget.onVideoProgress(1.0, 'completed', duration);
//         print("✅ Video completed!");
//       }
//     }
//   }

//   @override
//   void dispose() {
//     // ✅ Save position before leaving (only if NOT completed)
//     if (_controller.value.isReady && !_isCompleted) {
//       final position = _controller.value.position.inSeconds;
//       final duration = _controller.metadata.duration.inSeconds;
//       if (duration > 0) {
//         final progress = position / duration;
//         widget.onVideoProgress(progress, 'in_progress', position);
//       }
//     }

//     _controller.removeListener(_videoListener);
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_videoId == null) {
//       return Scaffold(
//         appBar: AppBar(title: const Text('Invalid video')),
//         body: const Center(child: Text('Invalid YouTube URL')),
//       );
//     }

//     return YoutubePlayerBuilder(
//       player: YoutubePlayer(
//         controller: _controller,
//         showVideoProgressIndicator: true,
//         onEnded: (_) {
//           if (!_isCompleted) {
//             _isCompleted = true;
//             final duration = _controller.metadata.duration.inSeconds;
//             widget.onVideoProgress(1.0, 'completed', duration);
//             _showCompletionDialog();
//           }
//         },
//       ),

//       builder:
//           (context, player) => Scaffold(
//             backgroundColor: Colors.white,
//             appBar: AppBar(
//               backgroundColor: Colors.white,
//               elevation: 0,
//               title: const Text(
//                 'Video Player',
//                 style: TextStyle(
//                   color: Colors.black87,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               leading: IconButton(
//                 icon: const Icon(Icons.arrow_back, color: Colors.black87),
//                 onPressed: () => Navigator.pop(context),
//               ),
//             ),
//             body: SingleChildScrollView(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   player,
//                   Padding(
//                     padding: const EdgeInsets.all(16.0),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.videoTitle,
//                           style: const TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         const SizedBox(height: 20),

//                         // ✅ Show completion badge if already completed
//                         if (widget.currentStatus == 'completed') ...[
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.green[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.green[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.check_circle,
//                                   color: Colors.green[700],
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'You have already completed this video! 🎉',
//                                     style: TextStyle(
//                                       color: Colors.green[700],
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w600,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                         ]
//                         // ✅ Show resume indicator if in progress
//                         else if (widget.lastPosition > 0) ...[
//                           Container(
//                             padding: const EdgeInsets.all(12),
//                             decoration: BoxDecoration(
//                               color: Colors.blue[50],
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.blue[200]!),
//                             ),
//                             child: Row(
//                               children: [
//                                 Icon(
//                                   Icons.play_arrow,
//                                   color: Colors.blue[700],
//                                   size: 20,
//                                 ),
//                                 const SizedBox(width: 8),
//                                 Expanded(
//                                   child: Text(
//                                     'Resumed from ${_formatDuration(widget.lastPosition)}',
//                                     style: TextStyle(
//                                       color: Colors.blue[700],
//                                       fontSize: 13,
//                                       fontWeight: FontWeight.w500,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                           const SizedBox(height: 12),
//                         ],

//                         if (widget.videoDescription != null &&
//                             widget.videoDescription!.isNotEmpty) ...[
//                           const Text(
//                             'Description',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.black87,
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           Text(
//                             widget.videoDescription!,
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[700],
//                               height: 1.5,
//                             ),
//                           ),
//                           const SizedBox(height: 20),
//                         ],

//                         Container(
//                           padding: const EdgeInsets.all(12),
//                           decoration: BoxDecoration(
//                             color: Colors.grey[100],
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey[300]!),
//                           ),
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.info_outline,
//                                 color: Colors.grey[700],
//                                 size: 20,
//                               ),
//                               const SizedBox(width: 8),
//                               Expanded(
//                                 child: Text(
//                                   widget.currentStatus == 'completed'
//                                       ? 'This video is marked as completed. You can watch it again anytime!'
//                                       : 'Your progress is automatically saved. You can resume anytime!',
//                                   style: TextStyle(
//                                     color: Colors.grey[700],
//                                     fontSize: 13,
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//     );
//   }

//   String _formatDuration(int seconds) {
//     final minutes = seconds ~/ 60;
//     final remainingSeconds = seconds % 60;
//     return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
//   }

//   void _showCompletionDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => AlertDialog(
//             title: const Text('🎉 Video Completed'),
//             content: const Text(
//               'Great job! You finished this video successfully!',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _controller.seekTo(Duration.zero);
//                 },
//                 child: const Text('Replay'),
//               ),
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   Navigator.pop(context);
//                 },
//                 child: const Text('Close'),
//               ),
//             ],
//           ),
//     );
//   }
// }
