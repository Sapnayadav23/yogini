import 'dart:io';
import 'dart:math' as math;

// import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
// import 'package:ffmpeg_kit_flutter_min/ffmpeg_kit.dart';
// import 'package:ffmpeg_kit_flutter_min/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yoga/AnlayzAI/Ai_Analyze_response_screen.dart';
import 'package:yoga/Home/Home_Screen.dart';
import 'package:yoga/utils/Button.dart';
import 'package:yoga/utils/app_assests.dart';
import 'package:yoga/utils/colors.dart';
import 'package:path_provider/path_provider.dart';

// ============ VIDEO PROCESSOR ============
class VideoProcessor {
  static Future<File?> extractFrameFromVideo(
    File videoFile, {
    int atSecond =
        5, // ✅ Changed default to 5 seconds (safer for shorter videos)
  }) async {
    try {
      // ✅ Check if video file exists first
      if (!await videoFile.exists()) {
        print('❌ Video file does not exist: ${videoFile.path}');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${appDir.path}/frame_$timestamp.jpg';

      print('🎬 Extracting frame from video at ${atSecond}s...');
      print('📁 Input video: ${videoFile.path}');
      print('📁 Output path: $outputPath');

      // ✅ Better FFmpeg command with error handling
      // -y = overwrite output file
      // -ss = seek position (before input for faster processing)
      // -i = input file
      // -vframes 1 = extract 1 frame
      // -f image2 = force image format
      // -q:v 2 = quality (2-5 is good, lower = better)
      final command =
          '-y -ss $atSecond -i "${videoFile.path}" -vframes 1 -f image2 -q:v 2 "$outputPath"';

      print('🔧 FFmpeg command: $command');

      final session = await FFmpegKit.execute(command);

      final returnCode = await session.getReturnCode();
      final output = await session.getOutput();
      final failStackTrace = await session.getFailStackTrace();

      print('📊 FFmpeg Return Code: ${returnCode?.getValue()}');
      print('📋 FFmpeg Output: $output');

      if (failStackTrace != null && failStackTrace.isNotEmpty) {
        print('⚠️ FFmpeg Stack Trace: $failStackTrace');
      }

      if (ReturnCode.isSuccess(returnCode)) {
        // ✅ Wait a bit for file system
        await Future.delayed(Duration(milliseconds: 500));

        final file = File(outputPath);
        if (await file.exists()) {
          final fileSize = await file.length();
          print('✅ Frame extracted successfully!');
          print('📦 File size: ${fileSize} bytes');

          if (fileSize == 0) {
            print('❌ File is empty, extraction failed');
            await file.delete();
            return null;
          }

          return file;
        } else {
          print('❌ File was not created at expected path');
          print('📂 Checking directory contents...');
          final dir = Directory(appDir.path);
          final files = await dir.list().toList();
          print('📂 Files in directory: ${files.map((f) => f.path).toList()}');
          return null;
        }
      } else {
        print('❌ FFmpeg failed with return code: ${returnCode?.getValue()}');

        // ✅ Try alternative method with frame at 1 second
        if (atSecond > 1) {
          print('🔄 Retrying with frame at 1 second...');
          return await extractFrameFromVideo(videoFile, atSecond: 1);
        }

        return null;
      }
    } catch (e, stackTrace) {
      print('❌ Error extracting frame: $e');
      print('📋 Stack trace: $stackTrace');
      return null;
    }
  }

  // ✅ Alternative method using different approach
  static Future<File?> extractFirstFrame(File videoFile) async {
    try {
      if (!await videoFile.exists()) {
        print('❌ Video file does not exist');
        return null;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outputPath = '${appDir.path}/first_frame_$timestamp.jpg';

      print('🎬 Extracting first available frame...');

      // ✅ Simple command to get first frame
      final command =
          '-i "${videoFile.path}" -vframes 1 -f image2 "$outputPath"';

      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        await Future.delayed(Duration(milliseconds: 500));
        final file = File(outputPath);

        if (await file.exists() && await file.length() > 0) {
          print('✅ First frame extracted successfully');
          return file;
        }
      }

      return null;
    } catch (e) {
      print('❌ Error in extractFirstFrame: $e');
      return null;
    }
  }
}

class AIPoweredPoseDetector {
  final PoseDetector poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  final String geminiApiKey = 'AIzaSyBPxz-uyfTd2B9jKbWjqjNui5lETCdQGbk';
  late GenerativeModel model;

  AIPoweredPoseDetector() {
    model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
  }

  // ✅ NEW: Extract English pose name from full name
  String _extractEnglishPoseName(String fullName) {
    // Remove everything after the first "(" if present
    // "Tree Pose (Tadasana / Vrikshasana)" -> "Tree Pose"
    final englishName = fullName.split('(')[0].trim();
    print('📝 Extracted English name: "$englishName" from "$fullName"');
    return englishName;
  }

  Future<Map<String, dynamic>> detectPose(
    File imageFile,
    String selectedPose,
  ) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final poses = await poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return {
          'poseDetected': 'No Person',
          'selectedPose': selectedPose,
          'accuracy': 0.0,
          'feedback': '❌ No person detected!\n\nEnsure full body is visible.',
          'isCorrectPose': false,
        };
      }

      final pose = poses.first;
      final landmarks = pose.landmarks.values.toList();

      final keypoints = _extractKeypoints(landmarks);
      final detectedPose = await _detectPoseML(imageFile);

      // ✅ Extract English names for comparison
      final englishSelectedPose = _extractEnglishPoseName(selectedPose);
      final englishDetectedPose = _extractEnglishPoseName(detectedPose);

      final isMatch = _compareNames(englishDetectedPose, englishSelectedPose);

      print('🔍 Comparison:');
      print('   Selected (full): $selectedPose');
      print('   Selected (English): $englishSelectedPose');
      print('   Detected: $detectedPose');
      print('   Match: $isMatch');

      double accuracy =
          isMatch
              ? _calculateMatchAccuracy(keypoints, englishSelectedPose)
              : _calculateMismatchAccuracy(
                keypoints,
                englishSelectedPose,
                englishDetectedPose,
              );

      final feedback = await _generateAIFeedback(
        englishSelectedPose, // Use English name for feedback
        englishDetectedPose,
        isMatch,
        accuracy,
        keypoints,
      );

      return {
        'poseDetected': detectedPose,
        'selectedPose': selectedPose, // Keep original full name for display
        'accuracy': accuracy.clamp(0, 100),
        'feedback': feedback,
        'isCorrectPose': isMatch && accuracy > 60,
      };
    } catch (e) {
      return {
        'poseDetected': 'Error',
        'selectedPose': selectedPose,
        'accuracy': 0.0,
        'feedback': 'Error: ${e.toString()}',
        'isCorrectPose': false,
      };
    }
  }

  Future<String> _generateAIFeedback(
    String selectedPose,
    String detectedPose,
    bool isMatch,
    double accuracy,
    Map<String, dynamic> keypoints,
  ) async {
    try {
      String prompt;

      if (!isMatch) {
        prompt = '''
You are a professional yoga instructor. A student selected "$selectedPose" but performed "$detectedPose" instead.

Generate a helpful feedback message with:
1. Clear indication that the poses don't match
2. Brief description of how to do "$selectedPose" correctly (3-4 steps)
3. Key differences between "$selectedPose" and "$detectedPose"
4. Encouraging tips to correct the pose

Keep it concise (150-200 words), friendly, and motivating. Use emojis appropriately.
Format with proper line breaks and bullet points.
Start with: "❌ POSE MISMATCH!"
''';
      } else {
        if (accuracy >= 85) {
          prompt = '''
You are a professional yoga instructor. A student performed "$selectedPose" with excellent form (${accuracy.toStringAsFixed(1)}% accuracy).

Generate encouraging feedback that:
1. Celebrates their excellent performance
2. Mentions 2-3 benefits of this pose
3. Gives one advanced tip to perfect it further

Keep it brief (100-120 words), very positive and motivating. Use emojis.
Start with: "🌟 EXCELLENT $selectedPose!"
''';
        } else if (accuracy >= 75) {
          prompt = '''
You are a professional yoga instructor. A student performed "$selectedPose" with good form (${accuracy.toStringAsFixed(1)}% accuracy).

Generate constructive feedback that:
1. Praises their correct execution
2. Suggests 2-3 specific improvements for better alignment
3. Gives practical tips

Keep it concise (120-150 words), supportive and clear. Use emojis.
Start with: "✅ GOOD $selectedPose!"
''';
        } else {
          prompt = '''
You are a professional yoga instructor. A student performed "$selectedPose" with room for improvement (${accuracy.toStringAsFixed(1)}% accuracy).

Generate helpful feedback that:
1. Acknowledges their effort
2. Lists 3-4 specific corrections needed
3. Provides step-by-step tips to improve form

Keep it concise (150-180 words), encouraging and actionable. Use emojis.
Start with: "👍 NEEDS IMPROVEMENT - $selectedPose"
''';
        }
      }

      final feedback = await generateFeedbackWithRetry(prompt);
      return feedback.trim();
    } catch (e) {
      print('AI Error: $e');
      return _getFallbackFeedback(
        selectedPose,
        detectedPose,
        isMatch,
        accuracy,
      );
    }
  }

  Future<String> generateFeedbackWithRetry(
    String prompt, {
    int retries = 3,
  }) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await model.generateContent([Content.text(prompt)]);
        return response.text ?? 'No feedback generated.';
      } catch (e) {
        if (e.toString().contains('overloaded') && i < retries - 1) {
          await Future.delayed(Duration(seconds: 2 * (i + 1)));
          continue;
        }
        rethrow;
      }
    }
    throw Exception('Model overloaded after multiple retries');
  }

  String _getFallbackFeedback(
    String selectedPose,
    String detectedPose,
    bool isMatch,
    double accuracy,
  ) {
    if (!isMatch) {
      return '''❌ POSE MISMATCH!

Selected: $selectedPose
Detected: $detectedPose

Your current pose doesn't match the selected one.

How to do $selectedPose:
${_getPoseInstructions(selectedPose)}

Key Differences:
${_getPoseDifference(selectedPose, detectedPose)}

💡 Tip: Review a reference image or video of $selectedPose before trying again!

Accuracy: ${accuracy.toStringAsFixed(1)}%''';
    }

    if (accuracy >= 85) {
      return '''🌟 EXCELLENT $selectedPose!

✅ Perfect form detected!
✓ Outstanding alignment
✓ All body parts correctly positioned
✓ Great balance and control

${_getPoseBenefits(selectedPose)}

Keep up the excellent work!

Accuracy: ${accuracy.toStringAsFixed(1)}%''';
    } else if (accuracy >= 75) {
      return '''✅ GOOD $selectedPose!

✓ Correct pose detected
✓ Solid form overall

Improvements needed:
→ Engage core muscles more
→ Check shoulder alignment
→ Maintain steady breathing
→ Hold the position longer

Accuracy: ${accuracy.toStringAsFixed(1)}%''';
    } else {
      return '''👍 NEEDS IMPROVEMENT - $selectedPose

✓ Correct pose detected

Work on:
→ Body alignment
→ Proper form
→ Flexibility
→ Balance

${_getPoseInstructions(selectedPose)}

Practice regularly for better results!

Accuracy: ${accuracy.toStringAsFixed(1)}%''';
    }
  }

  String _getPoseInstructions(String pose) {
    final instructions = {
      'Mountain Pose': '''1. Stand with feet together
2. Arms at your sides
3. Shoulders relaxed
4. Core engaged, spine straight''',
      'Tree Pose': '''1. Stand on one leg
2. Place other foot on inner thigh
3. Hands in prayer position
4. Focus on a point for balance''',
      'Warrior Pose': '''1. Step one leg back wide
2. Bend front knee to 90°
3. Extend arms out to sides
4. Look forward, chest open''',
      'Downward Dog': '''1. Start on hands and knees
2. Lift hips up and back
3. Straighten legs (knees soft)
4. Press hands into ground''',
      'Plank Pose': '''1. Hands under shoulders
2. Body in straight line
3. Core engaged tight
4. Hold position steady''',
      'Cobra Pose': '''1. Lie face down
2. Hands under shoulders
3. Lift chest up slowly
4. Keep hips on ground''',
      'Child Pose': '''1. Kneel on the ground
2. Sit back on heels
3. Stretch arms forward
4. Rest forehead down''',
      'Triangle Pose': '''1. Stand with wide stance
2. Turn one foot out
3. Reach hand to ankle
4. Other arm points up''',
      'Lotus Pose': '''1. Sit cross-legged
2. Each foot on opposite thigh
3. Hands on knees
4. Spine straight, relax''',
    };
    return instructions[pose] ?? 'Practice with proper guidance.';
  }

  String _getPoseDifference(String selected, String detected) {
    if (selected == 'Mountain Pose' && detected == 'Tree Pose') {
      return '• Mountain = Both feet on ground\n• Tree = One leg bent up';
    }
    if (selected == 'Warrior Pose' && detected == 'Triangle Pose') {
      return '• Warrior = Knee bent, torso upright\n• Triangle = Legs straight, side bend';
    }
    if (selected == 'Plank Pose' && detected == 'Downward Dog') {
      return '• Plank = Body horizontal\n• Downward Dog = Hips lifted high (inverted V)';
    }
    if (selected == 'Cobra Pose' && detected == 'Plank Pose') {
      return '• Cobra = Lying down, chest lifted\n• Plank = Body elevated and straight';
    }
    return '• $selected requires different body positioning\n• $detected has a different stance/alignment';
  }

  String _getPoseBenefits(String pose) {
    final benefits = {
      'Mountain Pose':
          'Benefits: Improves posture, strengthens legs, increases body awareness.',
      'Tree Pose':
          'Benefits: Enhances balance, strengthens legs, improves focus.',
      'Warrior Pose':
          'Benefits: Builds strength, increases stamina, opens hips.',
      'Downward Dog':
          'Benefits: Stretches hamstrings, strengthens arms, energizes body.',
      'Plank Pose':
          'Benefits: Builds core strength, tones arms, improves posture.',
      'Cobra Pose':
          'Benefits: Strengthens spine, opens chest, relieves stress.',
      'Child Pose': 'Benefits: Relaxes body, stretches back, calms mind.',
      'Triangle Pose':
          'Benefits: Stretches sides, improves balance, aids digestion.',
      'Lotus Pose': 'Benefits: Calms mind, opens hips, improves flexibility.',
    };
    return benefits[pose] ?? 'This pose has numerous health benefits.';
  }

  Map<String, dynamic> _extractKeypoints(List<PoseLandmark> landmarks) {
    try {
      return {
        'nose': (landmarks[0].x, landmarks[0].y),
        'leftShoulder': (landmarks[11].x, landmarks[11].y),
        'rightShoulder': (landmarks[12].x, landmarks[12].y),
        'leftElbow': (landmarks[13].x, landmarks[13].y),
        'rightElbow': (landmarks[14].x, landmarks[14].y),
        'leftWrist': (landmarks[15].x, landmarks[15].y),
        'rightWrist': (landmarks[16].x, landmarks[16].y),
        'leftHip': (landmarks[23].x, landmarks[23].y),
        'rightHip': (landmarks[24].x, landmarks[24].y),
        'leftKnee': (landmarks[25].x, landmarks[25].y),
        'rightKnee': (landmarks[26].x, landmarks[26].y),
        'leftAnkle': (landmarks[27].x, landmarks[27].y),
        'rightAnkle': (landmarks[28].x, landmarks[28].y),
      };
    } catch (e) {
      return {};
    }
  }

  Future<String> _detectPoseML(File imageFile) async {
    final String apiKey = 'AIzaSyBPxz-uyfTd2B9jKbWjqjNui5lETCdQGbk';
    final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

    try {
      final imageBytes = await imageFile.readAsBytes();

      final response = await model.generateContent([
        Content.multi([
          TextPart(
            'Analyze this yoga image and identify which yoga pose it is. '
            'Return only the yoga pose name (e.g., "Tree Pose", "Lotus Pose", "Cobra Pose", etc.). '
            'Do not include any explanation or extra text.',
          ),
          DataPart('image/jpeg', imageBytes),
        ]),
      ]);

      final result = response.text?.trim() ?? 'Unknown Pose';
      print('🧘 Gemini detected pose: $result');
      return result;
    } catch (e) {
      print('❌ Error detecting pose with Gemini: $e');
      return 'Unknown Pose';
    }
  }

  // ✅ UPDATED: Now compares properly regardless of Hindi names
  bool _compareNames(String detected, String selected) {
    final detectedClean = detected.toLowerCase().trim();
    final selectedClean = selected.toLowerCase().trim();

    print('🔍 Comparing: "$detectedClean" vs "$selectedClean"');
    return detectedClean == selectedClean;
  }

  double _calculateMatchAccuracy(
    Map<String, dynamic> keypoints,
    String poseName,
  ) {
    double baseAccuracy = 75.0;
    try {
      final (lsX, lsY) = keypoints['leftShoulder'] as (double, double);
      final (rsX, rsY) = keypoints['rightShoulder'] as (double, double);
      final (lhX, lhY) = keypoints['leftHip'] as (double, double);
      final (rhX, rhY) = keypoints['rightHip'] as (double, double);

      if ((lsY - rsY).abs() < 15) baseAccuracy += 5;
      if ((lhY - rhY).abs() < 15) baseAccuracy += 5;
      if (((lsX + rsX) / 2 - (lhX + rhX) / 2).abs() < 30) baseAccuracy += 5;
    } catch (e) {}

    baseAccuracy += (math.Random().nextDouble() * 12 - 6);
    return baseAccuracy.clamp(70, 95);
  }

  double _calculateMismatchAccuracy(
    Map<String, dynamic> keypoints,
    String selected,
    String detected,
  ) {
    return 25.0 + (math.Random().nextDouble() * 15);
  }

  void dispose() {
    poseDetector.close();
  }
}
// class AIPoweredPoseDetector {
//   final PoseDetector poseDetector = PoseDetector(
//     options: PoseDetectorOptions(
//       mode: PoseDetectionMode.single,
//       model: PoseDetectionModel.accurate,
//     ),
//   );

//   final String geminiApiKey = 'AIzaSyBPxz-uyfTd2B9jKbWjqjNui5lETCdQGbk';
//   late GenerativeModel model;

//   AIPoweredPoseDetector() {
//     model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: geminiApiKey);
//   }

//   Future<Map<String, dynamic>> detectPose(
//     File imageFile,
//     String selectedPose,
//   ) async {
//     try {
//       final inputImage = InputImage.fromFile(imageFile);
//       final poses = await poseDetector.processImage(inputImage);

//       if (poses.isEmpty) {
//         return {
//           'poseDetected': 'No Person',
//           'selectedPose': selectedPose,
//           'accuracy': 0.0,
//           'feedback': '❌ No person detected!\n\nEnsure full body is visible.',
//           'isCorrectPose': false,
//         };
//       }

//       final pose = poses.first;
//       final landmarks = pose.landmarks.values.toList();

//       final keypoints = _extractKeypoints(landmarks);
//       final detectedPose = await _detectPoseML(imageFile);

//       final isMatch = _compareNames(detectedPose, selectedPose);

//       double accuracy =
//           isMatch
//               ? _calculateMatchAccuracy(keypoints, selectedPose)
//               : _calculateMismatchAccuracy(
//                 keypoints,
//                 selectedPose,
//                 detectedPose,
//               );

//       final feedback = await _generateAIFeedback(
//         selectedPose,
//         detectedPose,
//         isMatch,
//         accuracy,
//         keypoints,
//       );

//       return {
//         'poseDetected': detectedPose,
//         'selectedPose': selectedPose,
//         'accuracy': accuracy.clamp(0, 100),
//         'feedback': feedback,
//         'isCorrectPose': isMatch && accuracy > 60,
//       };
//     } catch (e) {
//       return {
//         'poseDetected': 'Error',
//         'selectedPose': selectedPose,
//         'accuracy': 0.0,
//         'feedback': 'Error: ${e.toString()}',
//         'isCorrectPose': false,
//       };
//     }
//   }

//   Future<String> _generateAIFeedback(
//     String selectedPose,
//     String detectedPose,
//     bool isMatch,
//     double accuracy,
//     Map<String, dynamic> keypoints,
//   ) async {
//     try {
//       String prompt;

//       if (!isMatch) {
//         prompt = '''
// You are a professional yoga instructor. A student selected "$selectedPose" but performed "$detectedPose" instead.

// Generate a helpful feedback message with:
// 1. Clear indication that the poses don't match
// 2. Brief description of how to do "$selectedPose" correctly (3-4 steps)
// 3. Key differences between "$selectedPose" and "$detectedPose"
// 4. Encouraging tips to correct the pose

// Keep it concise (150-200 words), friendly, and motivating. Use emojis appropriately.
// Format with proper line breaks and bullet points.
// Start with: "❌ POSE MISMATCH!"
// ''';
//       } else {
//         if (accuracy >= 85) {
//           prompt = '''
// You are a professional yoga instructor. A student performed "$selectedPose" with excellent form (${accuracy.toStringAsFixed(1)}% accuracy).

// Generate encouraging feedback that:
// 1. Celebrates their excellent performance
// 2. Mentions 2-3 benefits of this pose
// 3. Gives one advanced tip to perfect it further

// Keep it brief (100-120 words), very positive and motivating. Use emojis.
// Start with: "🌟 EXCELLENT $selectedPose!"
// ''';
//         } else if (accuracy >= 75) {
//           prompt = '''
// You are a professional yoga instructor. A student performed "$selectedPose" with good form (${accuracy.toStringAsFixed(1)}% accuracy).

// Generate constructive feedback that:
// 1. Praises their correct execution
// 2. Suggests 2-3 specific improvements for better alignment
// 3. Gives practical tips

// Keep it concise (120-150 words), supportive and clear. Use emojis.
// Start with: "✅ GOOD $selectedPose!"
// ''';
//         } else {
//           prompt = '''
// You are a professional yoga instructor. A student performed "$selectedPose" with room for improvement (${accuracy.toStringAsFixed(1)}% accuracy).

// Generate helpful feedback that:
// 1. Acknowledges their effort
// 2. Lists 3-4 specific corrections needed
// 3. Provides step-by-step tips to improve form

// Keep it concise (150-180 words), encouraging and actionable. Use emojis.
// Start with: "👍 NEEDS IMPROVEMENT - $selectedPose"
// ''';
//         }
//       }

//       final feedback = await generateFeedbackWithRetry(prompt);
//       return feedback.trim();
//     } catch (e) {
//       print('AI Error: $e');
//       return _getFallbackFeedback(
//         selectedPose,
//         detectedPose,
//         isMatch,
//         accuracy,
//       );
//     }
//   }

//   Future<String> generateFeedbackWithRetry(
//     String prompt, {
//     int retries = 3,
//   }) async {
//     for (int i = 0; i < retries; i++) {
//       try {
//         final response = await model.generateContent([Content.text(prompt)]);
//         return response.text ?? 'No feedback generated.';
//       } catch (e) {
//         if (e.toString().contains('overloaded') && i < retries - 1) {
//           await Future.delayed(Duration(seconds: 2 * (i + 1)));
//           continue;
//         }
//         rethrow;
//       }
//     }
//     throw Exception('Model overloaded after multiple retries');
//   }

//   String _getFallbackFeedback(
//     String selectedPose,
//     String detectedPose,
//     bool isMatch,
//     double accuracy,
//   ) {
//     if (!isMatch) {
//       return '''❌ POSE MISMATCH!

// Selected: $selectedPose
// Detected: $detectedPose

// Your current pose doesn't match the selected one.

// How to do $selectedPose:
// ${_getPoseInstructions(selectedPose)}

// Key Differences:
// ${_getPoseDifference(selectedPose, detectedPose)}

// 💡 Tip: Review a reference image or video of $selectedPose before trying again!

// Accuracy: ${accuracy.toStringAsFixed(1)}%''';
//     }

//     if (accuracy >= 85) {
//       return '''🌟 EXCELLENT $selectedPose!

// ✅ Perfect form detected!
// ✓ Outstanding alignment
// ✓ All body parts correctly positioned
// ✓ Great balance and control

// ${_getPoseBenefits(selectedPose)}

// Keep up the excellent work!

// Accuracy: ${accuracy.toStringAsFixed(1)}%''';
//     } else if (accuracy >= 75) {
//       return '''✅ GOOD $selectedPose!

// ✓ Correct pose detected
// ✓ Solid form overall

// Improvements needed:
// → Engage core muscles more
// → Check shoulder alignment
// → Maintain steady breathing
// → Hold the position longer

// Accuracy: ${accuracy.toStringAsFixed(1)}%''';
//     } else {
//       return '''👍 NEEDS IMPROVEMENT - $selectedPose

// ✓ Correct pose detected

// Work on:
// → Body alignment
// → Proper form
// → Flexibility
// → Balance

// ${_getPoseInstructions(selectedPose)}

// Practice regularly for better results!

// Accuracy: ${accuracy.toStringAsFixed(1)}%''';
//     }
//   }

//   String _getPoseInstructions(String pose) {
//     final instructions = {
//       'Mountain Pose': '''1. Stand with feet together
// 2. Arms at your sides
// 3. Shoulders relaxed
// 4. Core engaged, spine straight''',
//       'Tree Pose': '''1. Stand on one leg
// 2. Place other foot on inner thigh
// 3. Hands in prayer position
// 4. Focus on a point for balance''',
//       'Warrior Pose': '''1. Step one leg back wide
// 2. Bend front knee to 90°
// 3. Extend arms out to sides
// 4. Look forward, chest open''',
//       'Downward Dog': '''1. Start on hands and knees
// 2. Lift hips up and back
// 3. Straighten legs (knees soft)
// 4. Press hands into ground''',
//       'Plank Pose': '''1. Hands under shoulders
// 2. Body in straight line
// 3. Core engaged tight
// 4. Hold position steady''',
//       'Cobra Pose': '''1. Lie face down
// 2. Hands under shoulders
// 3. Lift chest up slowly
// 4. Keep hips on ground''',
//       'Child Pose': '''1. Kneel on the ground
// 2. Sit back on heels
// 3. Stretch arms forward
// 4. Rest forehead down''',
//       'Triangle Pose': '''1. Stand with wide stance
// 2. Turn one foot out
// 3. Reach hand to ankle
// 4. Other arm points up''',
//       'Lotus Pose': '''1. Sit cross-legged
// 2. Each foot on opposite thigh
// 3. Hands on knees
// 4. Spine straight, relax''',
//     };
//     return instructions[pose] ?? 'Practice with proper guidance.';
//   }

//   String _getPoseDifference(String selected, String detected) {
//     if (selected == 'Mountain Pose' && detected == 'Tree Pose') {
//       return '• Mountain = Both feet on ground\n• Tree = One leg bent up';
//     }
//     if (selected == 'Warrior Pose' && detected == 'Triangle Pose') {
//       return '• Warrior = Knee bent, torso upright\n• Triangle = Legs straight, side bend';
//     }
//     if (selected == 'Plank Pose' && detected == 'Downward Dog') {
//       return '• Plank = Body horizontal\n• Downward Dog = Hips lifted high (inverted V)';
//     }
//     if (selected == 'Cobra Pose' && detected == 'Plank Pose') {
//       return '• Cobra = Lying down, chest lifted\n• Plank = Body elevated and straight';
//     }
//     return '• $selected requires different body positioning\n• $detected has a different stance/alignment';
//   }

//   String _getPoseBenefits(String pose) {
//     final benefits = {
//       'Mountain Pose':
//           'Benefits: Improves posture, strengthens legs, increases body awareness.',
//       'Tree Pose':
//           'Benefits: Enhances balance, strengthens legs, improves focus.',
//       'Warrior Pose':
//           'Benefits: Builds strength, increases stamina, opens hips.',
//       'Downward Dog':
//           'Benefits: Stretches hamstrings, strengthens arms, energizes body.',
//       'Plank Pose':
//           'Benefits: Builds core strength, tones arms, improves posture.',
//       'Cobra Pose':
//           'Benefits: Strengthens spine, opens chest, relieves stress.',
//       'Child Pose': 'Benefits: Relaxes body, stretches back, calms mind.',
//       'Triangle Pose':
//           'Benefits: Stretches sides, improves balance, aids digestion.',
//       'Lotus Pose': 'Benefits: Calms mind, opens hips, improves flexibility.',
//     };
//     return benefits[pose] ?? 'This pose has numerous health benefits.';
//   }

//   Map<String, dynamic> _extractKeypoints(List<PoseLandmark> landmarks) {
//     try {
//       return {
//         'nose': (landmarks[0].x, landmarks[0].y),
//         'leftShoulder': (landmarks[11].x, landmarks[11].y),
//         'rightShoulder': (landmarks[12].x, landmarks[12].y),
//         'leftElbow': (landmarks[13].x, landmarks[13].y),
//         'rightElbow': (landmarks[14].x, landmarks[14].y),
//         'leftWrist': (landmarks[15].x, landmarks[15].y),
//         'rightWrist': (landmarks[16].x, landmarks[16].y),
//         'leftHip': (landmarks[23].x, landmarks[23].y),
//         'rightHip': (landmarks[24].x, landmarks[24].y),
//         'leftKnee': (landmarks[25].x, landmarks[25].y),
//         'rightKnee': (landmarks[26].x, landmarks[26].y),
//         'leftAnkle': (landmarks[27].x, landmarks[27].y),
//         'rightAnkle': (landmarks[28].x, landmarks[28].y),
//       };
//     } catch (e) {
//       return {};
//     }
//   }

//   Future<String> _detectPoseML(File imageFile) async {
//     final String apiKey = 'AIzaSyBPxz-uyfTd2B9jKbWjqjNui5lETCdQGbk';
//     final model = GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);

//     try {
//       final imageBytes = await imageFile.readAsBytes();

//       final response = await model.generateContent([
//         Content.multi([
//           TextPart(
//             'Analyze this yoga image and identify which yoga pose it is. '
//             'Return only the yoga pose name (e.g., "Tree Pose", "Lotus Pose", "Cobra Pose", etc.). '
//             'Do not include any explanation or extra text.',
//           ),
//           DataPart('image/jpeg', imageBytes),
//         ]),
//       ]);

//       final result = response.text?.trim() ?? 'Unknown Pose';
//       print('🧘 Gemini detected pose: $result');
//       return result;
//     } catch (e) {
//       print('❌ Error detecting pose with Gemini: $e');
//       return 'Unknown Pose';
//     }
//   }

//   bool _compareNames(String detected, String selected) {
//     return detected.toLowerCase().trim() == selected.toLowerCase().trim();
//   }

//   double _calculateMatchAccuracy(
//     Map<String, dynamic> keypoints,
//     String poseName,
//   ) {
//     double baseAccuracy = 75.0;
//     try {
//       final (lsX, lsY) = keypoints['leftShoulder'] as (double, double);
//       final (rsX, rsY) = keypoints['rightShoulder'] as (double, double);
//       final (lhX, lhY) = keypoints['leftHip'] as (double, double);
//       final (rhX, rhY) = keypoints['rightHip'] as (double, double);

//       if ((lsY - rsY).abs() < 15) baseAccuracy += 5;
//       if ((lhY - rhY).abs() < 15) baseAccuracy += 5;
//       if (((lsX + rsX) / 2 - (lhX + rhX) / 2).abs() < 30) baseAccuracy += 5;
//     } catch (e) {}

//     baseAccuracy += (math.Random().nextDouble() * 12 - 6);
//     return baseAccuracy.clamp(70, 95);
//   }

//   double _calculateMismatchAccuracy(
//     Map<String, dynamic> keypoints,
//     String selected,
//     String detected,
//   ) {
//     return 25.0 + (math.Random().nextDouble() * 15);
//   }

//   void dispose() {
//     poseDetector.close();
//   }
// }

class MLPoseDetector {
  final PoseDetector _poseDetector = PoseDetector(
    options: PoseDetectorOptions(
      mode: PoseDetectionMode.single,
      model: PoseDetectionModel.accurate,
    ),
  );

  final SupabaseClient _supabase = Supabase.instance.client;
  bool _modelLoaded = false;

  Map<String, Map<String, Map<String, double>>> _poseDefinitions = {};

  Future<void> loadModel() async {
    _modelLoaded = true;
    print('✅ Pose detector initialized...');
    await _loadPosesFromSupabase();
  }

  Future<void> _loadPosesFromSupabase() async {
    print('📥 Fetching poses from Supabase...');
    final poses = await _supabase.from('poses').select();
    final angles = await _supabase.from('pose_angles').select();

    final Map<String, Map<String, Map<String, double>>> temp = {};

    for (var pose in poses) {
      final poseName = pose['pose_name'];
      final relatedAngles = angles.where((a) => a['pose_id'] == pose['id']);
      final angleMap = <String, Map<String, double>>{};

      for (var a in relatedAngles) {
        angleMap[a['joint_name']] = {
          'min': (a['min_angle'] as num).toDouble(),
          'max': (a['max_angle'] as num).toDouble(),
          'ideal': (a['ideal_angle'] as num).toDouble(),
        };
      }

      temp[poseName] = angleMap;
    }

    _poseDefinitions = temp;
    print('✅ Loaded poses: ${_poseDefinitions.keys.toList()}');
    print('🧩 Tree Pose definition: ${_poseDefinitions['Tree Pose']}');
  }

  Future<Map<String, dynamic>> checkPoseMatch(
    File imageFile,
    String selectedPose,
  ) async {
    try {
      if (!_modelLoaded) return _errorResult('Model not loaded', selectedPose);

      // ✅ Verify file exists before processing
      if (!await imageFile.exists()) {
        print('❌ Image file does not exist: ${imageFile.path}');
        return _errorResult('Image file not found', selectedPose);
      }

      print('📸 Processing image: ${imageFile.path}');
      print('📦 File size: ${await imageFile.length()} bytes');

      final inputImage = InputImage.fromFile(imageFile);
      final poses = await _poseDetector.processImage(inputImage);

      if (poses.isEmpty) {
        return _errorResult('No person detected', selectedPose);
      }

      final pose = poses.first;
      final landmarks = pose.landmarks;

      final detectedAngles = calculateAngles(landmarks);

      print('\n🧠 Detected Angles:');
      detectedAngles.forEach(
        (k, v) => print('  $k = ${v.toStringAsFixed(1)}°'),
      );

      final poseDef = _poseDefinitions[selectedPose] ?? {};

      // ✅ Print expected angles for comparison
      print('\n📊 Expected Angles for $selectedPose:');
      poseDef.forEach((joint, ranges) {
        print(
          '  $joint: min=${ranges['min']}, ideal=${ranges['ideal']}, max=${ranges['max']}',
        );
      });

      final accuracy = calculatePoseAccuracy(detectedAngles, poseDef);

      print(
        '🎯 Accuracy for $selectedPose = ${(accuracy * 100).toStringAsFixed(2)}%',
      );

      return {
        'selectedPose': selectedPose,
        'accuracy': accuracy,
        'detectedAngles': detectedAngles,
        'expectedAngles': poseDef, // ✅ Added for debugging
      };
    } catch (e, stackTrace) {
      print('❌ Error in checkPoseMatch: $e');
      print('📋 Stack trace: $stackTrace');
      return _errorResult('Error: $e', selectedPose);
    }
  }

  double calculatePoseAccuracy(
    Map<String, double> detected,
    Map<String, Map<String, double>> expected,
  ) {
    double total = 0;
    int count = 0;

    print('\n🔍 Detailed Scoring Breakdown:');

    for (var joint in expected.keys) {
      if (!detected.containsKey(joint)) {
        print('  ⚠️ $joint: NOT DETECTED → score: 0.05');
        total += 0.05;
        count++;
        continue;
      }

      final detectedAngle = detected[joint]!;
      final minA = expected[joint]!['min']!;
      final maxA = expected[joint]!['max']!;
      final ideal = expected[joint]!['ideal']!;

      double score = 0.0;

      if (detectedAngle >= minA && detectedAngle <= maxA) {
        // ✅ Within acceptable range
        final deviation = (detectedAngle - ideal).abs();
        final allowed = (maxA - minA) / 2;

        final normalized = (1 - (deviation / allowed)).clamp(0.0, 1.0);

        // ✅ Improved scoring: More generous for good poses
        if (deviation <= 5) {
          score = 1.0; // Perfect within 5°
        } else if (deviation <= 10) {
          score = 0.9 + (normalized * 0.1); // 90-100%
        } else {
          score = 0.5 + (normalized * 0.4); // 50-90%
        }

        print(
          '  ✅ $joint: ${detectedAngle.toStringAsFixed(1)}° (ideal: ${ideal.toStringAsFixed(1)}°, range: $minA-$maxA) → score: ${score.toStringAsFixed(3)}',
        );
      } else {
        // ❌ Outside acceptable range
        final dist =
            detectedAngle < minA
                ? (minA - detectedAngle)
                : (detectedAngle - maxA);

        if (dist <= 15) {
          // ✅ Close but outside - more forgiving
          score = 0.3 + (1 - dist / 15) * 0.2; // 30-50%
        } else if (dist <= 30) {
          score = 0.1 + (1 - dist / 30) * 0.2; // 10-30%
        } else {
          score = 0.05; // Very far off
        }

        print(
          '  ❌ $joint: ${detectedAngle.toStringAsFixed(1)}° (expected: $minA-$maxA, off by ${dist.toStringAsFixed(1)}°) → score: ${score.toStringAsFixed(3)}',
        );
      }

      total += score;
      count++;
    }

    if (count == 0) return 0.0;

    final finalScore = (total / count).clamp(0.0, 1.0);
    print(
      '\n📊 Final Score: ${(finalScore * 100).toStringAsFixed(2)}% ($count joints evaluated)',
    );

    return finalScore;
  }

  Map<String, double> calculateAngles(Map<PoseLandmarkType, PoseLandmark> l) {
    double? ang(PoseLandmarkType a, PoseLandmarkType b, PoseLandmarkType c) {
      if (l[a] == null || l[b] == null || l[c] == null) return null;

      final A = l[a]!;
      final B = l[b]!;
      final C = l[c]!;

      final ab = math.sqrt(math.pow(A.x - B.x, 2) + math.pow(A.y - B.y, 2));
      final bc = math.sqrt(math.pow(C.x - B.x, 2) + math.pow(C.y - B.y, 2));
      final ac = math.sqrt(math.pow(A.x - C.x, 2) + math.pow(A.y - C.y, 2));

      final cosA = ((ab * ab) + (bc * bc) - (ac * ac)) / (2 * ab * bc);
      return math.acos(cosA.clamp(-1.0, 1.0)) * (180 / math.pi);
    }

    final angles = <String, double>{};

    angles['left_elbow'] =
        ang(
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.leftWrist,
        ) ??
        0;
    angles['right_elbow'] =
        ang(
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.rightWrist,
        ) ??
        0;

    angles['left_knee'] =
        ang(
          PoseLandmarkType.leftHip,
          PoseLandmarkType.leftKnee,
          PoseLandmarkType.leftAnkle,
        ) ??
        0;
    angles['right_knee'] =
        ang(
          PoseLandmarkType.rightHip,
          PoseLandmarkType.rightKnee,
          PoseLandmarkType.rightAnkle,
        ) ??
        0;

    angles['left_hip'] =
        ang(
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.leftKnee,
        ) ??
        0;
    angles['right_hip'] =
        ang(
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightHip,
          PoseLandmarkType.rightKnee,
        ) ??
        0;

    angles['left_shoulder'] =
        ang(
          PoseLandmarkType.leftElbow,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftHip,
        ) ??
        0;
    angles['right_shoulder'] =
        ang(
          PoseLandmarkType.rightElbow,
          PoseLandmarkType.rightShoulder,
          PoseLandmarkType.rightHip,
        ) ??
        0;

    angles['body_upright'] =
        ang(
          PoseLandmarkType.leftHip,
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.rightShoulder,
        ) ??
        0;
    angles['torso'] =
        ang(
          PoseLandmarkType.leftShoulder,
          PoseLandmarkType.leftHip,
          PoseLandmarkType.rightHip,
        ) ??
        0;

    bool isSideView = false;
    if (angles['torso']! > 140) isSideView = true;

    if (isSideView) {
      angles['left_elbow'] = (180 - angles['left_elbow']!) * 0.8 + 30;
      angles['right_elbow'] = (180 - angles['right_elbow']!) * 0.8 + 30;

      angles['left_shoulder'] = angles['left_shoulder']! + 25;
      angles['right_shoulder'] = angles['right_shoulder']! + 25;

      angles['body_upright'] = (angles['body_upright']! - 60).abs() + 40;
    }

    return angles;
  }

  Map<String, dynamic> _errorResult(String e, String pose) => {
    'isMatch': false,
    'detectedPose': e,
    'selectedPose': pose,
    'confidence': 0.0,
    'message': e,
  };

  List<String> get availablePoses => _poseDefinitions.keys.toList();

  void dispose() => _poseDetector.close();
}

// ============ MAIN SCREEN ============
class AlAnalyzeScreen extends StatefulWidget {
  const AlAnalyzeScreen({Key? key}) : super(key: key);

  @override
  State<AlAnalyzeScreen> createState() => _AlAnalyzeScreenState();
}

class _AlAnalyzeScreenState extends State<AlAnalyzeScreen> {
  final MLPoseDetector _mlDetector = MLPoseDetector();
  final AIPoweredPoseDetector _geminiDetector = AIPoweredPoseDetector();

  String? selectedPose;
  File? selectedImage;
  bool isLoading = false;
  bool isModelLoading = true;
  bool isVideo = false;
  File? extractedFrame;

  @override
  void initState() {
    super.initState();
    _initializeModel();
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

  Future<void> _initializeModel() async {
    if (!mounted) return;

    setState(() => isModelLoading = true);

    try {
      await _mlDetector.loadModel();
      if (mounted) {
        setState(() => isModelLoading = false);
      }
    } catch (e) {
      print('Error initializing model: $e');
      if (mounted) {
        setState(() => isModelLoading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Choose Media Type'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.image, color: Colors.blue),
                  title: const Text('Pick Image'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await picker.pickImage(
                      source: ImageSource.gallery,
                    );
                    if (image != null && mounted) {
                      setState(() {
                        selectedImage = File(image.path);
                        isVideo = false;
                        extractedFrame = null;
                      });
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.videocam, color: Colors.red),
                  title: const Text('Pick Video'),
                  onTap: () async {
                    Navigator.pop(context);
                    final video = await picker.pickVideo(
                      source: ImageSource.gallery,
                    );
                    if (video != null && mounted) {
                      setState(() {
                        selectedImage = File(video.path);
                        isVideo = true;
                        extractedFrame = null;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  // ✅ YE FUNCTION ENGINE SELECTION DIALOG DIKHAYEGA
  Future<void> _showEngineSelectionDialog() async {
    if (selectedImage == null || selectedPose == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select pose and upload image/video'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              const Text(
                'Analyze with',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Engine 1 Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _analyzeWithEngine1();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Engine 1',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Engine 2 Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _analyzeWithEngine2();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: const Text(
                    'Engine 2',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  // ✅ ENGINE 1 - ML POSE DETECTOR
  Future<void> _analyzeWithEngine1() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      File? imageToAnalyze = selectedImage;
      File? displayImage = selectedImage;

      if (isVideo) {
        print('🎬 Starting video frame extraction...');
        print('📹 Video path: ${selectedImage!.path}');

        imageToAnalyze = await VideoProcessor.extractFrameFromVideo(
          selectedImage!,
          atSecond: 5,
        );

        if (imageToAnalyze == null) {
          print('🔄 Primary extraction failed, trying first frame...');
          imageToAnalyze = await VideoProcessor.extractFirstFrame(
            selectedImage!,
          );
        }

        if (imageToAnalyze == null) {
          print('🔄 Trying frame at 0 seconds...');
          imageToAnalyze = await VideoProcessor.extractFrameFromVideo(
            selectedImage!,
            atSecond: 0,
          );
        }

        if (imageToAnalyze == null) {
          throw Exception(
            'Could not extract frame from video. Please try:\n'
            '1. A shorter video\n'
            '2. A different video format\n'
            '3. Using an image instead',
          );
        }

        extractedFrame = imageToAnalyze;
        displayImage = imageToAnalyze;
        print('✅ Frame extraction complete, proceeding to analysis...');
      }

      if (!await imageToAnalyze!.exists()) {
        throw Exception('Image file not found. Please try again.');
      }

      final result = await _mlDetector.checkPoseMatch(
        imageToAnalyze,
        selectedPose!,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => ResultScreen(
                result: result,
                imageFile: displayImage!,
                isFromVideo: isVideo,
              ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error in Engine 1: $e');
      print('📋 Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  // ✅ ENGINE 2 - GEMINI AI DETECTOR
  Future<void> _analyzeWithEngine2() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      File? imageToAnalyze = selectedImage;
      File? displayImage = selectedImage;

      if (isVideo) {
        print('🎬 Starting video frame extraction for Gemini...');

        imageToAnalyze = await VideoProcessor.extractFrameFromVideo(
          selectedImage!,
          atSecond: 5,
        );

        if (imageToAnalyze == null) {
          imageToAnalyze = await VideoProcessor.extractFirstFrame(
            selectedImage!,
          );
        }

        if (imageToAnalyze == null) {
          imageToAnalyze = await VideoProcessor.extractFrameFromVideo(
            selectedImage!,
            atSecond: 0,
          );
        }

        if (imageToAnalyze == null) {
          throw Exception('Could not extract frame from video.');
        }

        extractedFrame = imageToAnalyze;
        displayImage = imageToAnalyze;
      }

      if (!await imageToAnalyze!.exists()) {
        throw Exception('Image file not found. Please try again.');
      }

      final result = await _geminiDetector.detectPose(
        imageToAnalyze,
        selectedPose!,
      );

      if (!mounted) return;
      setState(() => isLoading = false);

      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder:
      //         (_) => AlAnalyzeResponseScreen(
      //           result: result,
      //           imageFile: displayImage!,
      //         ),
      //   ),
      // );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => AlAnalyzeResponseScreen(
                result: result,
                imageFile: displayImage!,
                isFromVideo: isVideo,
              ),
        ),
      );
    } catch (e, stackTrace) {
      print('❌ Error in Engine 2: $e');
      print('📋 Stack trace: $stackTrace');

      if (!mounted) return;
      setState(() => isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Dismiss',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _mlDetector.dispose();
    _geminiDetector.dispose();
    if (extractedFrame != null && extractedFrame!.existsSync()) {
      try {
        extractedFrame!.deleteSync();
      } catch (e) {
        print('Error deleting extracted frame: $e');
      }
    }
    super.dispose();
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.backgroundC,
      endDrawer: ProfileDrawer(),
      body:
          isModelLoading
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('🤖 Loading AI Model...'),
                    SizedBox(height: 10),
                    Text(
                      'Preparing pose detection...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : isLoading
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(
                      isVideo
                          ? '🎬 Extracting video frame...'
                          : '🤖 AI is analyzing your pose...',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Using machine learning...',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.only(right: 0, bottom: 0),
                          child:
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
                        ),
                        // Padding(
                        //   padding: const EdgeInsets.all(8.0),
                        //   child: Row(
                        //     crossAxisAlignment: CrossAxisAlignment.start,
                        //     children: [
                        //       Expanded(
                        //         flex: 2,
                        //         child: Padding(
                        //           padding: const EdgeInsets.only(
                        //             top: 15,
                        //             left: 10,
                        //           ),
                        //           child: Text(
                        //             "Let's Analyze\nYour work!!",
                        //             style: TextStyle(
                        //               fontSize: 20,
                        //               color: Colors.black87,
                        //               height: 1.3,
                        //               fontWeight: FontWeight.bold,
                        //             ),
                        //           ),
                        //         ),
                        //       ),
                        //       Expanded(
                        //         flex: 3,
                        //         child: Image.asset(
                        //           AppAssets.AIScreenImages,
                        //           height: 140,
                        //           fit: BoxFit.contain,
                        //         ),
                        //       ),
                        //     ],
                        //   ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              "Let's Analyze\nYour work!!",
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Image.asset(
                              AppAssets.AIScreenImages,
                              height: 140,
                              width: 180,
                              fit: BoxFit.cover,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Select Yoga Pose',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade400,
                                    width: 1,
                                  ),
                                  color: Colors.white,
                                ),
                                child: DropdownButton<String>(
                                  value: selectedPose,
                                  hint: const Padding(
                                    padding: EdgeInsets.only(left: 16.0),
                                    child: Text('Choose a pose...'),
                                  ),
                                  isExpanded: true,
                                  underline: const SizedBox(),
                                  items:
                                      _mlDetector.availablePoses.map((
                                        String pose,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: pose,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                              left: 16.0,
                                            ),
                                            child: Text(pose),
                                          ),
                                        );
                                      }).toList(),
                                  onChanged: (String? newValue) {
                                    if (mounted) {
                                      setState(() => selectedPose = newValue);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upload your recorded videos or images',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 25),
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  height: 140,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color:
                                          selectedImage != null
                                              ? Colors.blue
                                              : Colors.grey.shade400,
                                      width: 1,
                                    ),
                                  ),
                                  child:
                                      selectedImage == null
                                          ? Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.add,
                                                  size: 40,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Upload Images/Videos',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )
                                          : Stack(
                                            children: [
                                              if (isVideo)
                                                Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.videocam,
                                                        size: 60,
                                                        color:
                                                            Colors
                                                                .grey
                                                                .shade600,
                                                      ),
                                                      SizedBox(height: 8),
                                                      Text(
                                                        'Video Selected',
                                                        style: TextStyle(
                                                          color:
                                                              Colors
                                                                  .grey
                                                                  .shade600,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              else
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  child: Image.file(
                                                    selectedImage!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                                ),
                                              Container(
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  color: Colors.black
                                                      .withOpacity(0.3),
                                                ),
                                              ),
                                              const Center(
                                                child: Icon(
                                                  Icons.check_circle,
                                                  size: 50,
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              CommonButton(
                                text: "Analyze",
                                onTap: _showEngineSelectionDialog,
                              ),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }
}

class ResultScreen extends StatefulWidget {
  final Map<String, dynamic> result;
  final File imageFile;
  final bool isFromVideo; // ✅ Added parameter

  const ResultScreen({
    Key? key,
    required this.result,
    required this.imageFile,
    this.isFromVideo = false, // ✅ Default false for backward compatibility
  }) : super(key: key);

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late Future<String> feedbackFuture;

  @override
  void initState() {
    super.initState();
    feedbackFuture = _getFeedback();
  }

  Future<String> fetchPoseFeedback(String poseName) async {
    final supabase = Supabase.instance.client;

    // Fetch pose instructions
    final poseResponse =
        await supabase
            .from('poses')
            .select('id, instructions')
            .eq('pose_name', poseName)
            .maybeSingle();

    // Fetch correction tips
    final feedbackResponse = await supabase
        .from('pose_feedback')
        .select('correction')
        .eq('pose_id', poseResponse?['id'] ?? 1)
        .limit(3);

    String poseInstructions =
        poseResponse?['instructions'] ??
        'Try maintaining balance, correct alignment, and steady breathing.';

    String corrections =
        feedbackResponse.isNotEmpty
            ? feedbackResponse.map((f) => "• ${f['correction']}").join("\n")
            : "Maintain proper body alignment and breathing.";

    return "✅ How to do ${poseName} correctly:\n\n$poseInstructions\n\nCommon corrections:\n$corrections";
  }

  Future<String> _getFeedback() async {
    final result = widget.result;
    final bool isMatch = result['isMatch'] ?? false;
    final String selectedPose = result['selectedPose'] ?? 'Unknown';
    final String feedback = result['message'] ?? "No feedback available";

    if (isMatch) {
      return "Perfect! You're doing the $selectedPose pose correctly 🎉\n\nKeep your posture steady and breathing relaxed.";
    } else {
      // If incorrect pose → fetch detailed feedback
      return await fetchPoseFeedback(selectedPose);
    }
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
    final result = widget.result;
    final imageFile = widget.imageFile;
    final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

    bool isMatch = result['isMatch'] ?? false;
    double accuracy = ((result['accuracy'] ?? 0.0) * 100);

    String selectedPose = result['selectedPose'] ?? 'Unknown';
    String detectedPose = result['detectedPose'] ?? 'Unknown';

    Color accuracyColor;
    if (accuracy >= 75) {
      accuracyColor = const Color(0xFF4CAF50);
    } else if (accuracy >= 50) {
      accuracyColor = const Color(0xFFFFA726);
    } else {
      accuracyColor = const Color(0xFFEF5350);
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFE9F0EC),
      endDrawer: ProfileDrawer(),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween, // 👈 keeps back icon left, profile icon right
                  children: [
                    // 🔹 Back Icon
                    Padding(
                      padding: const EdgeInsets.only(left: 0, top: 0),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(
                            context,
                          ); // 👈 go back to previous screen
                        },
                        child: Container(
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
                          child: const Center(
                            child: Icon(
                              Icons.arrow_back_ios_new,
                              size: 22,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 🔹 Profile Icon (existing one)
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 5),
                      child: GestureDetector(
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

                      // child: GestureDetector(
                      //   onTap: () {
                      //     _scaffoldKey.currentState?.openEndDrawer();
                      //   },
                      //   child: Container(
                      //     height: 40,
                      //     width: 40,
                      //     decoration: BoxDecoration(
                      //       color: Colors.white,
                      //       borderRadius: BorderRadius.circular(20),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.black.withOpacity(0.1),
                      //           blurRadius: 4,
                      //           offset: const Offset(0, 2),
                      //         ),
                      //       ],
                      //     ),
                      //     child: Center(
                      //       child: Image.asset(
                      //         AppAssets.profileImages,
                      //         height: 28,
                      //         width: 28,
                      //         fit: BoxFit.contain,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                    ),
                  ],
                ),
                // Padding(
                //   padding: const EdgeInsets.all(8.0),
                //   child: Row(
                //     crossAxisAlignment: CrossAxisAlignment.start,
                //     children: [
                //       Expanded(
                //         flex: 2,
                //         child: Padding(
                //           padding: const EdgeInsets.only(top: 15, left: 10),
                //           child: const Text(
                //             "Let's Analyze\nYour work!!",
                //             style: TextStyle(
                //               fontSize: 20,
                //               color: Colors.black87,
                //               height: 1.3,
                //               fontWeight: FontWeight.bold,
                //             ),
                //           ),
                //         ),
                //       ),
                //       Expanded(
                //         flex: 3,
                //         child: Image.asset(
                //           AppAssets.AIScreenImages,
                //           height: 140,
                //           fit: BoxFit.contain,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Text(
                      "Let's Analyze\nYour work!!",
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Image.asset(
                      AppAssets.AIScreenImages,
                      height: 140,
                      width: 180,
                      fit: BoxFit.cover,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ✅ Pose Image with Video/Photo Badge
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      Image.file(
                        imageFile,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.contain,
                      ),
                      // ✅ Video/Photo Badge
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.isFromVideo
                                    ? Colors.red.withOpacity(0.9)
                                    : Colors.blue.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.isFromVideo
                                    ? Icons.videocam
                                    : Icons.image,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                widget.isFromVideo ? 'Video' : 'Photo',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Accurancy",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            accuracy >= 75
                                ? "Excellent! 🎉"
                                : accuracy >= 50
                                ? "Good! Keep practicing 💪"
                                : "Needs improvement 📚",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: accuracy / 100,
                              strokeWidth: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                accuracyColor,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "${accuracy.toStringAsFixed(0)}%",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: accuracyColor,
                                ),
                              ),
                              Text(
                                selectedPose,
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Suggestion",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Feedback FutureBuilder
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: FutureBuilder<String>(
                    future: feedbackFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Text(
                          "Error fetching feedback. Please try again.",
                          style: TextStyle(color: Colors.red.shade700),
                        );
                      } else {
                        return Text(
                          snapshot.data ?? "No feedback available.",
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        );
                      }
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // Retry Button
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFAAD38A),
                        foregroundColor: Colors.black87,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Try Another Pose",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
