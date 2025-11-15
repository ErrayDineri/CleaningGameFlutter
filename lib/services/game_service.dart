import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GameScore {
  final int score;
  final int completionTimeSeconds;
  final DateTime completedAt;

  GameScore({
    required this.score,
    required this.completionTimeSeconds,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'completionTimeSeconds': completionTimeSeconds,
      'completedAt': completedAt.toIso8601String(),
    };
  }

  factory GameScore.fromJson(Map<String, dynamic> json) {
    return GameScore(
      score: json['score'],
      completionTimeSeconds: json['completionTimeSeconds'],
      completedAt: DateTime.parse(json['completedAt']),
    );
  }
}

class GameService {
  // Separate storage keys for each game
  static const String _parkGameHighScoresKey = 'park_cleaning_high_scores';
  static const String _waterGameHighScoresKey = 'water_game_high_scores';

  // Save high score for Park Cleaning Game
  static Future<void> saveParkGameHighScore(GameScore score) async {
    await _saveHighScore(score, _parkGameHighScoresKey);
  }

  // Save high score for Water Game
  static Future<void> saveWaterGameHighScore(GameScore score) async {
    await _saveHighScore(score, _waterGameHighScoresKey);
  }

  // Internal method to save high score
  static Future<void> _saveHighScore(GameScore score, String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getStringList(storageKey) ?? [];
    
    // Convert to GameScore objects
    List<GameScore> scores = scoresJson
        .map((scoreJson) => GameScore.fromJson(json.decode(scoreJson)))
        .toList();
    
    // Add new score
    scores.add(score);
    
    // Sort by score (descending), then by time (ascending)
    scores.sort((a, b) {
      if (a.score != b.score) {
        return b.score.compareTo(a.score); // Higher score first
      }
      return a.completionTimeSeconds.compareTo(b.completionTimeSeconds); // Faster time first
    });
    
    // Keep only top 10
    if (scores.length > 10) {
      scores = scores.take(10).toList();
    }
    
    // Convert back to JSON strings and save
    final updatedScoresJson = scores
        .map((score) => json.encode(score.toJson()))
        .toList();
    await prefs.setStringList(storageKey, updatedScoresJson);
  }

  // Get high scores for Park Cleaning Game
  static Future<List<GameScore>> getParkGameHighScores() async {
    return _getHighScores(_parkGameHighScoresKey);
  }

  // Get high scores for Water Game
  static Future<List<GameScore>> getWaterGameHighScores() async {
    return _getHighScores(_waterGameHighScoresKey);
  }

  // Internal method to get high scores
  static Future<List<GameScore>> _getHighScores(String storageKey) async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getStringList(storageKey) ?? [];
    
    return scoresJson
        .map((scoreJson) => GameScore.fromJson(json.decode(scoreJson)))
        .toList();
  }

  // Get best completion time for Park Cleaning Game (fastest time among high scores)
  static Future<int?> getParkGameBestCompletionTime() async {
    final scores = await getParkGameHighScores();
    if (scores.isNotEmpty) {
      return scores
          .map((score) => score.completionTimeSeconds)
          .reduce((a, b) => a < b ? a : b);
    }
    return null;
  }

  // Get highest score for Park Cleaning Game
  static Future<int?> getParkGameHighestScore() async {
    final scores = await getParkGameHighScores();
    if (scores.isNotEmpty) {
      return scores.first.score; // Already sorted by score descending
    }
    return null;
  }

  // Get highest score for Water Game
  static Future<int?> getWaterGameHighestScore() async {
    final scores = await getWaterGameHighScores();
    if (scores.isNotEmpty) {
      return scores.first.score; // Already sorted by score descending
    }
    return null;
  }

  // Format time in MM:SS format
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Deprecated - kept for backward compatibility, redirects to park game
  @deprecated
  static Future<void> saveHighScore(GameScore score) async {
    await saveParkGameHighScore(score);
  }

  // Deprecated - kept for backward compatibility, redirects to park game
  @deprecated
  static Future<List<GameScore>> getHighScores() async {
    return getParkGameHighScores();
  }

  // Deprecated - kept for backward compatibility, redirects to park game
  @deprecated
  static Future<int?> getBestCompletionTime() async {
    return getParkGameBestCompletionTime();
  }
}