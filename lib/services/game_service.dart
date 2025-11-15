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
  static const String _currentLevelKey = 'park_cleaning_current_level';
  static const String _highScoresKey = 'park_cleaning_high_scores';
  static const String _gameStartTimeKey = 'park_cleaning_game_start_time';

  // Save current level
  static Future<void> saveCurrentLevel(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_currentLevelKey, level);
  }

  // Get current level (default to 1)
  static Future<int> getCurrentLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_currentLevelKey) ?? 1;
  }

  // Save game start time
  static Future<void> saveGameStartTime(DateTime startTime) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_gameStartTimeKey, startTime.toIso8601String());
  }

  // Get game start time
  static Future<DateTime?> getGameStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timeString = prefs.getString(_gameStartTimeKey);
    if (timeString != null) {
      return DateTime.parse(timeString);
    }
    return null;
  }

  // Clear game start time
  static Future<void> clearGameStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_gameStartTimeKey);
  }

  // Save high score
  static Future<void> saveHighScore(GameScore score) async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getStringList(_highScoresKey) ?? [];
    
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
    await prefs.setStringList(_highScoresKey, updatedScoresJson);
  }

  // Get high scores
  static Future<List<GameScore>> getHighScores() async {
    final prefs = await SharedPreferences.getInstance();
    final scoresJson = prefs.getStringList(_highScoresKey) ?? [];
    
    return scoresJson
        .map((scoreJson) => GameScore.fromJson(json.decode(scoreJson)))
        .toList();
  }

  // Get best completion time (fastest time among high scores)
  static Future<int?> getBestCompletionTime() async {
    final scores = await getHighScores();
    if (scores.isNotEmpty) {
      return scores
          .map((score) => score.completionTimeSeconds)
          .reduce((a, b) => a < b ? a : b);
    }
    return null;
  }

  // Reset current level to 1
  static Future<void> resetCurrentLevel() async {
    await saveCurrentLevel(1);
  }

  // Format time in MM:SS format
  static String formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}