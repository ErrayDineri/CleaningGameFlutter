import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/vision_api_service.dart';
import '../services/user_service.dart';

class PollutionDetectorScreen extends StatefulWidget {
  const PollutionDetectorScreen({super.key});

  @override
  State<PollutionDetectorScreen> createState() =>
      _PollutionDetectorScreenState();
}

class _PollutionDetectorScreenState extends State<PollutionDetectorScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _capturedImage;
  String? _analysisResult;
  bool _isAnalyzing = false;
  bool? _isPolluted;
  Uint8List? _imageBytes;

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = Uint8List.fromList(await photo.readAsBytes());
        setState(() {
          _capturedImage = photo;
          _imageBytes = bytes;
          _analysisResult = null;
          _isPolluted = null;
        });

        // Automatically analyze the photo
        await _analyzePhoto();
      }
    } catch (e) {
      _showError('فشل التقاط الصورة: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (photo != null) {
        final bytes = Uint8List.fromList(await photo.readAsBytes());
        setState(() {
          _capturedImage = photo;
          _imageBytes = bytes;
          _analysisResult = null;
          _isPolluted = null;
        });

        // Automatically analyze the photo
        await _analyzePhoto();
      }
    } catch (e) {
      _showError('فشل اختيار الصورة: $e');
    }
  }

  Future<void> _analyzePhoto() async {
    if (_capturedImage == null) return;

    setState(() {
      _isAnalyzing = true;
      _analysisResult = null;
    });

    try {
      print('📸 Starting photo analysis...');
      // Convert image to base64
      final bytes = await _capturedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      print('📦 Image size: ${bytes.length} bytes, Base64 length: ${base64Image.length}');

      // Analyze with vision API
      print('🚀 Calling Vision API...');
      final result = await VisionApiService.analyzePollution(base64Image);
      print('✅ Got analysis result: "$result"');
      
      final isPolluted = VisionApiService.isPolluted(result);
      print('🎯 isPolluted: $isPolluted');

      setState(() {
        _analysisResult = result;
        _isPolluted = isPolluted;
        _isAnalyzing = false;
      });

      // Award XP and save detection count
      if (isPolluted) {
        print('💰 Awarding 50 XP for pollution detection...');
        final gained = await UserService.addXp(50);
        print('💰 XP gained: $gained');
        
        // Increment pollution detection count
        await _incrementDetectionCount();
        
        if (gained && mounted) {
          _showLevelUpDialog(50);
        }
      } else {
        print('✨ Clean location detected, awarding 25 XP...');
        await UserService.addXp(25);
        await _incrementDetectionCount();
      }
    } catch (e) {
      print('❌ Error analyzing photo: $e');
      setState(() {
        _isAnalyzing = false;
      });
      _showError('فشل تحليل الصورة: $e');
    }
  }

  Future<void> _incrementDetectionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt('pollution_detections') ?? 0;
    await prefs.setInt('pollution_detections', currentCount + 1);
    print('📊 Total detections: ${currentCount + 1}');
  }

  Future<int> _getDetectionCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('pollution_detections') ?? 0;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLevelUpDialog(int xpEarned) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          '🎉 مستوى جديد!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars, size: 80, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'لقد حصلت على $xpEarned نقطة خبرة!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text(
                'رائع!',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('كاشف التلوث 🔍'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Info card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        size: 40, color: Colors.blue.shade700),
                    const SizedBox(height: 8),
                    Text(
                      'التقط صورة لمكان ما وسيخبرك الذكاء الاصطناعي إذا كان ملوثاً أم لا!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _capturePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('التقط صورة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isAnalyzing ? null : _pickFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('اختر صورة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Image preview
            if (_capturedImage != null && _imageBytes != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Image.memory(
                  _imageBytes!,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Analysis status
            if (_isAnalyzing)
              Card(
                color: Colors.orange.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        'جارٍ تحليل الصورة...',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.orange.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Analysis result
            if (_analysisResult != null && !_isAnalyzing) ...[
              Card(
                color: _isPolluted == true
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        _isPolluted == true
                            ? Icons.warning_amber_rounded
                            : Icons.check_circle_outline,
                        size: 60,
                        color: _isPolluted == true
                            ? Colors.red.shade700
                            : Colors.green.shade700,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _isPolluted == true ? 'مكان ملوث! ⚠️' : 'مكان نظيف! ✅',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: _isPolluted == true
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        _analysisResult!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.5,
                          color: _isPolluted == true
                              ? Colors.red.shade900
                              : Colors.green.shade900,
                        ),
                      ),
                      if (_isPolluted == true) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.amber.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'حصلت على 50 نقطة خبرة!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.eco, color: Colors.green.shade700),
                              const SizedBox(width: 8),
                              Text(
                                'حصلت على 25 نقطة خبرة!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            // Statistics card
            FutureBuilder<int>(
              future: _getDetectionCount(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == 0) {
                  return const SizedBox.shrink();
                }
                return Card(
                  color: Colors.purple.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics, color: Colors.purple.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'عدد الفحوصات: ${snapshot.data}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Educational tip
            if (_analysisResult == null && _capturedImage == null)
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.lightbulb_outline,
                          size: 40, color: Colors.green.shade700),
                      const SizedBox(height: 8),
                      Text(
                        '💡 نصيحة: التقط صوراً لأماكن مختلفة لتتعلم كيفية التعرف على التلوث البيئي',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
