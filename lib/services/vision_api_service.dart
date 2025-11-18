import 'dart:convert';
import 'package:http/http.dart' as http;

class VisionApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  /// Analyzes an image to detect pollution using the vision API
  /// Returns the full analysis text from the model
  static Future<String> analyzePollution(String base64Image) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/vision/stream'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': [
            {
              'role': 'system',
              'content': 'You are an environmental expert. Your ONLY task is to determine if a place in an image is POLLUTED or CLEAN. '
                  'Output ONLY one word in English: either "dirty" or "clean". '
                  'Do NOT add any description, explanation, or additional text. JUST ONE WORD.'
            },
            {
              'role': 'user',
              'content': 'Look at this image. Answer with ONLY ONE WORD in English: "dirty" or "clean". Nothing else.',
              'images': [
                {
                  'data_base64': base64Image,
                  'mime_type': 'image/jpeg',
                }
              ]
            }
          ],
          'config': {
            'temperature': 0.1,
            'maxTokens': 10,
          }
        }),
      );

      if (response.statusCode == 200) {
        // Parse NDJSON response
        final lines = response.body.split('\n');
        final buffer = StringBuffer();

        print('🔍 Vision API Response (${lines.length} lines):');
        for (final line in lines) {
          if (line.trim().isNotEmpty) {
            print('  Line: $line');
            try {
              final json = jsonDecode(line);
              print('  Parsed JSON: $json');
              if (json['type'] == 'fragment') {
                buffer.write(json['content']);
                print('  Fragment content: ${json['content']}');
              } else if (json['type'] == 'done') {
                print('  Done - Model: ${json['model']}, Tokens: ${json['predicted_tokens']}');
              }
            } catch (e) {
              print('  ⚠️ Failed to parse line: $e');
              // Skip invalid JSON lines
              continue;
            }
          }
        }

        final result = buffer.toString().trim();
        print('📝 Final analysis result: $result');
        
        // Check if the model refused or couldn't see the image
        if (result.isEmpty) {
          throw Exception('لم يتم استلام رد من النموذج');
        }
        
        final lowerResult = result.toLowerCase();
        if (lowerResult.contains('cannot see') || 
            lowerResult.contains("can't see") ||
            lowerResult.contains('unable to see') ||
            lowerResult.contains('لا أستطيع رؤية') ||
            lowerResult.contains('لا يمكنني')) {
          throw Exception('النموذج لم يتمكن من رؤية الصورة أو تحليلها');
        }
        
        return result;
      } else {
        throw Exception('فشل تحليل الصورة: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال بالخادم: $e');
    }
  }

  /// Checks if the response indicates pollution
  static bool isPolluted(String analysisText) {
    print('🔬 Analyzing text for pollution: "$analysisText"');
    final text = analysisText.toLowerCase().trim();
    print('🔬 Lowercase text: "$text"');
    
    // Check for dirty/polluted
    if (text.contains('dirty') || text.contains('polluted')) {
      print('🎯 Result: POLLUTED (dirty)');
      return true;
    }
    
    // Check for clean
    if (text.contains('clean')) {
      print('🎯 Result: CLEAN');
      return false;
    }
    
    // Default to clean if unclear
    print('⚠️ Unclear result, defaulting to CLEAN');
    return false;
  }
}
