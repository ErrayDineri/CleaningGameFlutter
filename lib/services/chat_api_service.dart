import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatApiService {
  // Update this URL to your actual API endpoint
  static const String baseUrl = 'http://localhost:8000'; // Change to your API URL
  
  /// Stream chat responses from the API
  /// Returns a stream of text chunks as they arrive
  static Stream<String> streamChat({
    required List<Map<String, String>> messages,
    Map<String, dynamic>? config,
  }) async* {
    final url = Uri.parse('$baseUrl/chat/regular/stream');
    
    print('Streaming chat to: $url');
    print('Messages count: ${messages.length}');
    
    try {
      final request = http.Request('POST', url);
      request.headers['Content-Type'] = 'application/json';
      
      final body = {
        'messages': messages,
        if (config != null) 'config': config,
      };
      
      request.body = json.encode(body);
      
      print('Sending request...');
      final streamedResponse = await request.send();
      
      print('Response status: ${streamedResponse.statusCode}');
      print('Response headers: ${streamedResponse.headers}');
      
      if (streamedResponse.statusCode == 200) {
        var lineCount = 0;
        // Process NDJSON (newline-delimited JSON) response
        await for (var chunk in streamedResponse.stream.transform(utf8.decoder).transform(const LineSplitter())) {
          lineCount++;
          final trimmedChunk = chunk.trim();
          
          print('Line $lineCount: $trimmedChunk');
          
          if (trimmedChunk.isEmpty) continue;
          
          try {
            final jsonData = json.decode(trimmedChunk);
            print('Parsed JSON: $jsonData');
            
            // Handle fragment type (contains content to stream)
            if (jsonData is Map && jsonData['type'] == 'fragment') {
              final content = jsonData['content'];
              print('Fragment content: $content');
              if (content != null && content.toString().isNotEmpty) {
                yield content.toString();
              }
            }
            // Handle done type (end of stream)
            else if (jsonData is Map && jsonData['type'] == 'done') {
              print('Stream done');
              // Stream complete, no more content
              break;
            }
          } catch (e) {
            print('Error parsing line: $e');
            // Skip malformed JSON lines
            continue;
          }
        }
        print('Total lines processed: $lineCount');
      } else {
        throw Exception('API Error: ${streamedResponse.statusCode}');
      }
    } catch (e) {
      print('Stream error: $e');
      throw Exception('Network Error: $e');
    }
  }
  
  /// Non-streaming chat (fallback)
  static Future<String> chat({
    required List<Map<String, String>> messages,
    Map<String, dynamic>? config,
  }) async {
    final url = Uri.parse('$baseUrl/chat/regular');
    
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'messages': messages,
          if (config != null) 'config': config,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract message content from response
        if (data is Map && data.containsKey('choices')) {
          return data['choices'][0]['message']['content'];
        } else if (data is Map && data.containsKey('content')) {
          return data['content'];
        } else if (data is Map && data.containsKey('message')) {
          return data['message'];
        }
        
        return data.toString();
      } else {
        throw Exception('API Error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network Error: $e');
    }
  }
  
  /// Check API health
  static Future<bool> checkHealth() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
