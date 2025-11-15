import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/game_service.dart';

enum WaterType {
  clean,
  dirty,
}

class WaterDrop {
  final String id;
  final WaterType type;
  final String emoji;
  Offset position;
  final double speed;
  bool isCaught;

  WaterDrop({
    required this.id,
    required this.type,
    required this.emoji,
    required this.position,
    required this.speed,
    this.isCaught = false,
  });
}

class WaterGameScreen extends StatefulWidget {
  const WaterGameScreen({super.key});

  @override
  State<WaterGameScreen> createState() => _WaterGameScreenState();
}

class _WaterGameScreenState extends State<WaterGameScreen>
    with TickerProviderStateMixin {
  List<WaterDrop> waterDrops = [];
  int score = 0;
  int lives = 3;
  int currentLevel = 1;
  int maxLevel = 5;
  bool gameOver = false;
  bool isPaused = false;
  
  double bucketX = 0.5; // Relative position (0.0 to 1.0)
  final double bucketWidth = 80.0;
  final double bucketHeight = 80.0;
  
  Timer? _gameTimer;
  Timer? _spawnTimer;
  late AnimationController _bucketController;
  late AnimationController _celebrationController;
  late AnimationController _flashController;
  late Animation<double> _bucketAnimation;
  late Animation<double> _flashAnimation;
  
  double _screenWidth = 0;
  double _screenHeight = 0;
  
  int _dropsToNextLevel = 10;
  int _dropsCaughtThisLevel = 0;
  
  // Game tracking
  DateTime? _gameStartTime;
  int _bestScore = 0;
  
  // Flash color - initialize with fully transparent (fixes initial darkness)
  Color _flashColor = Colors.transparent.withOpacity(0.0);

  @override
  void initState() {
    super.initState();
    
    _bucketController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _flashController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _bucketAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _bucketController, curve: Curves.easeOut),
    );
    
    _flashAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
    
    _loadBestScore();
    _initializeGame();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _bucketController.dispose();
    _celebrationController.dispose();
    _flashController.dispose();
    super.dispose();
  }

  Future<void> _loadBestScore() async {
    final scores = await GameService.getHighScores();
    if (scores.isNotEmpty) {
      setState(() {
        _bestScore = scores.first.score;
      });
    }
  }

  void _initializeGame() {
    // Screen dimensions will be set in build method
    // Don't try to access MediaQuery here in initState
    
    _gameStartTime = DateTime.now();
    waterDrops.clear();
    bucketX = 0.5;
    
    _startGameLoop();
    _startSpawning();
  }

  void _startGameLoop() {
    _gameTimer?.cancel();
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!isPaused && !gameOver) {
        _updateGame();
      }
    });
  }

  void _startSpawning() {
    _spawnTimer?.cancel();
    
    // Variable spawn rate - schedule next spawn
    _scheduleNextSpawn();
  }

  void _scheduleNextSpawn() {
    if (gameOver) return;
    
    final random = math.Random();
    
    // Base spawn interval with level difficulty
    final baseInterval = 1000 - (currentLevel * 100);
    final minInterval = 400;
    final maxVariation = 600; // Random variation up to 600ms
    
    // Random spawn interval: base ± variation
    final spawnInterval = math.max(
      minInterval,
      baseInterval + random.nextInt(maxVariation) - (maxVariation ~/ 2),
    );
    
    _spawnTimer = Timer(Duration(milliseconds: spawnInterval), () {
      if (!isPaused && !gameOver) {
        _spawnWaterDrop();
        _scheduleNextSpawn(); // Schedule next spawn with new random interval
      }
    });
  }

  void _spawnWaterDrop() {
    // Don't spawn if screen dimensions not ready yet
    if (_screenWidth == 0 || _screenHeight == 0) return;
    
    final random = math.Random();
    
    // Difficulty: more dirty water at higher levels
    final dirtyChance = 0.2 + (currentLevel * 0.08); // 20% to 60%
    final isDirty = random.nextDouble() < dirtyChance;
    
    final type = isDirty ? WaterType.dirty : WaterType.clean;
    final emoji = isDirty ? '🩸' : '💧';
    
    // VARIABLE SPEED - each drop has random speed
    final baseSpeed = 1.5 + (currentLevel * 0.3);
    final speedVariation = 0.8; // Random variation ±0.8
    final speed = baseSpeed + (random.nextDouble() * speedVariation * 2) - speedVariation;
    final clampedSpeed = speed.clamp(0.8, 4.0); // Keep within reasonable range
    
    // Spawn in middle 80% of screen width
    final spawnAreaWidth = _screenWidth * 0.8;
    final spawnStartX = _screenWidth * 0.1; // Start 10% from left
    final spawnX = spawnStartX + (random.nextDouble() * spawnAreaWidth);
    
    final drop = WaterDrop(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      emoji: emoji,
      position: Offset(spawnX, -50),
      speed: clampedSpeed,
    );
    
    setState(() {
      waterDrops.add(drop);
    });
  }

  void _updateGame() {
    // Screen dimensions are set in build, skip if not ready
    if (_screenHeight == 0 || _screenWidth == 0) return;
    
    setState(() {
      // Update drop positions
      for (var drop in waterDrops) {
        if (!drop.isCaught) {
          drop.position = Offset(
            drop.position.dx,
            drop.position.dy + drop.speed,
          );
          
          // Check collision with bucket
          _checkBucketCollision(drop);
          
          // Remove drops that fell off screen
          if (drop.position.dy > _screenHeight) {
            drop.isCaught = true;
            // Lose a life if clean water was missed
            if (drop.type == WaterType.clean) {
              _missedCleanWater();
            }
          }
        }
      }
      
      // Remove caught drops
      waterDrops.removeWhere((drop) => drop.isCaught);
    });
  }

  void _checkBucketCollision(WaterDrop drop) {
    final bucketLeft = bucketX * _screenWidth - bucketWidth / 2;
    final bucketRight = bucketLeft + bucketWidth;
    final bucketTop = _screenHeight - bucketHeight - 20;
    final bucketBottom = _screenHeight - 20;
    
    if (drop.position.dx >= bucketLeft &&
        drop.position.dx <= bucketRight &&
        drop.position.dy >= bucketTop &&
        drop.position.dy <= bucketBottom) {
      
      drop.isCaught = true;
      
      if (drop.type == WaterType.clean) {
        _catchCleanWater();
      } else {
        _catchDirtyWater();
      }
    }
  }

  void _catchCleanWater() {
    setState(() {
      score += 10;
      _dropsCaughtThisLevel++;
      
      // Check for level up
      if (_dropsCaughtThisLevel >= _dropsToNextLevel && currentLevel < maxLevel) {
        _levelUp();
      }
    });
    
    _bucketController.forward(from: 0);
    _triggerFlash(Colors.green);
  }

  void _catchDirtyWater() {
    setState(() {
      score = math.max(0, score - 5);
      lives--;
      
      if (lives <= 0) {
        _endGame();
      }
    });
    
    _triggerFlash(Colors.red);
  }

  void _triggerFlash(Color color) {
    setState(() {
      _flashColor = color;
    });
    
    // Update animation to start from 0.5 and fade to 0.0
    _flashAnimation = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _flashController, curve: Curves.easeOut),
    );
    
    _flashController.forward(from: 0);
  }

  void _missedCleanWater() {
    // Optional: could lose points or lives for missing clean water
    // For now, just a small penalty
    setState(() {
      score = math.max(0, score - 2);
    });
  }

  void _levelUp() {
    setState(() {
      currentLevel++;
      _dropsCaughtThisLevel = 0;
      _dropsToNextLevel = 10 + (currentLevel * 2); // Progressively harder
    });
    
    // Restart spawning with new difficulty
    _startSpawning();
    
    _celebrationController.forward(from: 0);
  }

  void _endGame() async {
    setState(() {
      gameOver = true;
    });
    
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    
    // Save high score
    if (score > 0) {
      final duration = DateTime.now().difference(_gameStartTime ?? DateTime.now());
      final gameScore = GameScore(
        score: score,
        completionTimeSeconds: duration.inSeconds,
        completedAt: DateTime.now(),
      );
      await GameService.saveWaterGameHighScore(gameScore);
    }
    
    _showGameOverDialog();
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Column(
            children: [
              Text('💧', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text(
                'انتهت اللعبة!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'النتيجة النهائية',
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cairo',
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF27AE60),
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'المستوى: $currentLevel',
                style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
              if (score > _bestScore) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '🏆 رقم قياسي جديد!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text(
                'القائمة الرئيسية',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _restartGame();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF27AE60),
                foregroundColor: Colors.white,
              ),
              child: const Text(
                'العب مرة أخرى',
                style: TextStyle(fontFamily: 'Cairo'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _restartGame() {
    setState(() {
      score = 0;
      lives = 3;
      currentLevel = 1;
      gameOver = false;
      isPaused = false;
      waterDrops.clear();
      _dropsCaughtThisLevel = 0;
      _dropsToNextLevel = 10;
    });
    
    _initializeGame();
  }

  void _togglePause() {
    setState(() {
      isPaused = !isPaused;
    });
    
    // Resume spawning when unpausing
    if (!isPaused && !gameOver) {
      _scheduleNextSpawn();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Set screen dimensions here, after build context is available
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: GestureDetector(
        onHorizontalDragUpdate: (details) {
          if (!isPaused && !gameOver) {
            setState(() {
              bucketX = (details.globalPosition.dx / _screenWidth).clamp(0.1, 0.9);
            });
          }
        },
        onTapDown: (details) {
          if (!isPaused && !gameOver) {
            setState(() {
              bucketX = (details.globalPosition.dx / _screenWidth).clamp(0.1, 0.9);
            });
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF87CEEB), // Sky blue
                const Color(0xFFB0E0E6), // Powder blue
                const Color(0xFFADD8E6), // Light blue
                const Color(0xFF87CEFA), // Light sky blue
              ],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                // Background elements
                _buildBackground(),
                
                // Water drops
                ...waterDrops.map((drop) => _buildWaterDrop(drop)),
                
                // Bucket
                _buildBucket(),
                
                // UI elements
                _buildTopBar(colorScheme),
                
                // Flash overlay
                AnimatedBuilder(
                  animation: _flashAnimation,
                  builder: (context, child) {
                    return IgnorePointer(
                      child: Container(
                        color: _flashColor.withOpacity(_flashAnimation.value),
                      ),
                    );
                  },
                ),
                
                // Pause overlay
                if (isPaused) _buildPauseOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Animated clouds with floating effect
        AnimatedBuilder(
          animation: _bucketAnimation,
          builder: (context, child) {
            return Positioned(
              top: 40 + _bucketAnimation.value * 10,
              left: 50,
              child: Opacity(
                opacity: 0.7,
                child: Text('☁️', style: TextStyle(fontSize: 60)),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _bucketAnimation,
          builder: (context, child) {
            return Positioned(
              top: 80 - _bucketAnimation.value * 8,
              right: 80,
              child: Opacity(
                opacity: 0.6,
                child: Text('☁️', style: TextStyle(fontSize: 50)),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _bucketAnimation,
          builder: (context, child) {
            return Positioned(
              top: 120 + _bucketAnimation.value * 5,
              left: 200,
              child: Opacity(
                opacity: 0.5,
                child: Text('☁️', style: TextStyle(fontSize: 45)),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _bucketAnimation,
          builder: (context, child) {
            return Positioned(
              top: 60 - _bucketAnimation.value * 7,
              right: 200,
              child: Opacity(
                opacity: 0.6,
                child: Text('☁️', style: TextStyle(fontSize: 55)),
              ),
            );
          },
        ),
        
        // Sun in the corner
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.yellow[300]!,
                  Colors.orange[300]!,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.yellow.withOpacity(0.6),
                  blurRadius: 40,
                  spreadRadius: 15,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '☀️',
                style: TextStyle(fontSize: 45),
              ),
            ),
          ),
        ),
        
        // Flying birds
        AnimatedBuilder(
          animation: _bucketAnimation,
          builder: (context, child) {
            return Positioned(
              top: 150 + _bucketAnimation.value * 15,
              left: 100 + _bucketAnimation.value * 30,
              child: Transform.rotate(
                angle: _bucketAnimation.value * 0.2,
                child: Text('🕊️', style: TextStyle(fontSize: 30)),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _bucketAnimation,
          builder: (context, child) {
            return Positioned(
              top: 180 - _bucketAnimation.value * 12,
              right: 120 + _bucketAnimation.value * 25,
              child: Transform.rotate(
                angle: -_bucketAnimation.value * 0.15,
                child: Text('🦅', style: TextStyle(fontSize: 28)),
              ),
            );
          },
        ),
        
        // Water-themed decorations
        Positioned(
          top: 250,
          left: 30,
          child: Opacity(
            opacity: 0.4,
            child: Text('🌊', style: TextStyle(fontSize: 35)),
          ),
        ),
        Positioned(
          top: 280,
          right: 40,
          child: Opacity(
            opacity: 0.4,
            child: Text('💦', style: TextStyle(fontSize: 30)),
          ),
        ),
        
        // Ground with grass texture
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7CB342), // Medium green (grass)
                  const Color(0xFF558B2F), // Darker green
                ],
              ),
            ),
            child: Stack(
              children: [
                // Flowers on grass
                ...List.generate(12, (index) {
                  final random = math.Random(index);
                  return Positioned(
                    left: random.nextDouble() * 400,
                    bottom: random.nextDouble() * 100,
                    child: Text(
                      ['🌼', '🌸', '🌺', '💧'][random.nextInt(4)],
                      style: TextStyle(fontSize: 18 + random.nextDouble() * 12),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        // Trees on sides
        Positioned(
          left: 15,
          bottom: 100,
          child: Text('🌳', style: TextStyle(fontSize: 65)),
        ),
        Positioned(
          right: 20,
          bottom: 100,
          child: Text('🌲', style: TextStyle(fontSize: 60)),
        ),
        
        // Water well/fountain decoration
        Positioned(
          left: 100,
          bottom: 105,
          child: Text('⛲', style: TextStyle(fontSize: 40)),
        ),
        Positioned(
          right: 90,
          bottom: 110,
          child: Text('🚰', style: TextStyle(fontSize: 35)),
        ),
        
        // Rainbow for clean water theme
        if (score > 50)
          Positioned(
            top: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Opacity(
                opacity: 0.3,
                child: Text('🌈', style: TextStyle(fontSize: 80)),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWaterDrop(WaterDrop drop) {
    return Positioned(
      left: drop.position.dx - 20,
      top: drop.position.dy - 20,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.8, end: 1.2),
        duration: const Duration(milliseconds: 500),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: Text(
              drop.emoji,
              style: const TextStyle(fontSize: 40),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBucket() {
    return Positioned(
      left: bucketX * _screenWidth - bucketWidth / 2,
      bottom: 20,
      child: AnimatedBuilder(
        animation: _bucketAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: 1.0 + (_bucketAnimation.value * 0.1),
            child: Container(
              width: bucketWidth,
              height: bucketHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF27AE60).withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF27AE60),
                  width: 3,
                ),
              ),
              child: const Center(
                child: Text(
                  '🪣',
                  style: TextStyle(fontSize: 50),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
          
          // Stats
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Score
                Text(
                  '🏆 $score',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 16),
                // Level
                Text(
                  '📊 $currentLevel',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
                const SizedBox(width: 16),
                // Lives
                Row(
                  children: List.generate(
                    3,
                    (index) => Padding(
                      padding: const EdgeInsets.only(left: 2),
                      child: Text(
                        index < lives ? '❤️' : '🖤',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Pause button
          GestureDetector(
            onTap: _togglePause,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                isPaused ? Icons.play_arrow : Icons.pause,
                color: colorScheme.primary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPauseOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '⏸️',
                style: TextStyle(fontSize: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'اللعبة متوقفة مؤقتاً',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _togglePause,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF27AE60),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  'استئناف',
                  style: TextStyle(
                    fontSize: 18,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
