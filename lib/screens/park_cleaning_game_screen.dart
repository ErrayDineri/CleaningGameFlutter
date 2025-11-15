import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/game_service.dart';

enum TrashType {
  plastic,
  paper,
  metal,
}

class TrashItem {
  final String id;
  final TrashType type;
  final String emoji;
  final Offset position;
  bool isDragging;
  bool isCollected;

  TrashItem({
    required this.id,
    required this.type,
    required this.emoji,
    required this.position,
    this.isDragging = false,
    this.isCollected = false,
  });

  TrashItem copyWith({
    Offset? position,
    bool? isDragging,
    bool? isCollected,
  }) {
    return TrashItem(
      id: id,
      type: type,
      emoji: emoji,
      position: position ?? this.position,
      isDragging: isDragging ?? this.isDragging,
      isCollected: isCollected ?? this.isCollected,
    );
  }
}

class RecyclingBin {
  final TrashType type;
  final String emoji;
  final String label;
  final Color color;
  final Offset position;

  RecyclingBin({
    required this.type,
    required this.emoji,
    required this.label,
    required this.color,
    required this.position,
  });
}

class ParkCleaningGameScreen extends StatefulWidget {
  const ParkCleaningGameScreen({super.key});

  @override
  State<ParkCleaningGameScreen> createState() => _ParkCleaningGameScreenState();
}

class _ParkCleaningGameScreenState extends State<ParkCleaningGameScreen>
    with TickerProviderStateMixin {
  List<TrashItem> trashItems = [];
  List<RecyclingBin> recyclingBins = [];
  int score = 0;
  int currentLevel = 1;
  int maxLevel = 5;
  bool gameComplete = false;
  bool levelComplete = false;
  late AnimationController _celebrationController;
  late AnimationController _birdController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _birdAnimation;
  
  // Timer variables
  Timer? _gameTimer;
  int _timeRemaining = 60; // 60 seconds per level
  
  // Game tracking variables
  DateTime? _gameStartTime;
  
  // Screen dimensions for relative positioning
  double _screenWidth = 0;
  double _screenHeight = 0;

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _birdController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    
    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    
    _birdAnimation = Tween<double>(begin: 0, end: 20).animate(
      CurvedAnimation(parent: _birdController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _birdController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }



  void _initializeGame() {
    // Get screen dimensions if available
    if (context.mounted) {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
    }
    
    // Record game start time for first level
    if (currentLevel == 1) {
      _gameStartTime = DateTime.now();
    }
    
    // Initialize recycling bins based on level - centered at bottom (relative positioning)
    final binY = _screenHeight * 0.80; // 80% down the screen
    final binSpacing = _screenWidth * 0.25; // 25% of screen width spacing
    final startX = (_screenWidth - (binSpacing * (currentLevel >= 2 ? 2 : 1))) / 2; // Center the bins
    
    recyclingBins = [
      RecyclingBin(
        type: TrashType.plastic,
        emoji: '♻️',
        label: 'البلاستيك',
        color: Colors.blue,
        position: Offset(startX, binY),
      ),
      RecyclingBin(
        type: TrashType.paper,
        emoji: '📄',
        label: 'الورق',
        color: Colors.green,
        position: Offset(startX + binSpacing, binY),
      ),
    ];
    
    // Add metal bin only from level 2 onwards
    if (currentLevel >= 2) {
      recyclingBins.add(RecyclingBin(
        type: TrashType.metal,
        emoji: '🗂️',
        label: 'المعدن',
        color: Colors.grey,
        position: Offset(startX + binSpacing * 2, binY),
      ));
    }

    // Initialize trash items based on current level
    trashItems = _generateTrashForLevel(currentLevel);
    levelComplete = false;
    
    // Start level timer
    _startTimer();
  }

  void _startTimer() {
    _timeRemaining = 60; // 60 seconds per level
    _gameTimer?.cancel();
    
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0 && !levelComplete && !gameComplete) {
          _timeRemaining--;
        } else if (_timeRemaining <= 0) {
          timer.cancel();
          _handleTimeUp();
        }
      });
    });
  }

  void _handleTimeUp() {
    _gameTimer?.cancel();
    if (!levelComplete) {
      _showGameOverDialog();
    }
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
              Text('⏰', style: TextStyle(fontSize: 48)),
              SizedBox(height: 8),
              Text(
                'انتهى الوقت!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'للأسف، لم تكمل المستوى في الوقت المحدد',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'النقاط: $score',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              Text(
                'المستوى: $currentLevel',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetGameAfterTimeUp();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ابدأ من جديد',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'العودة للقائمة',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceEvenly,
        );
      },
    );
  }

  Future<void> _resetGameAfterTimeUp() async {
    setState(() {
      currentLevel = 1;
      score = 0;
      gameComplete = false;
      levelComplete = false;
      _gameStartTime = DateTime.now();
    });
    
    setState(() {
      _initializeGame();
    });
  }

  List<TrashItem> _generateTrashForLevel(int level) {
    List<TrashItem> items = [];
    
    // Progressive level system: Each level increases difficulty
    int itemCount;
    List<Map<String, dynamic>> levelTrash;
    
    switch (level) {
      case 1:
        itemCount = 4;
        levelTrash = [
          {'type': TrashType.plastic, 'emoji': '🥤'},
          {'type': TrashType.plastic, 'emoji': '🍼'},
          {'type': TrashType.paper, 'emoji': '📄'},
          {'type': TrashType.paper, 'emoji': '🗞️'},
        ];
        break;
      case 2:
        itemCount = 6;
        levelTrash = [
          {'type': TrashType.plastic, 'emoji': '🥤'},
          {'type': TrashType.plastic, 'emoji': '🍼'},
          {'type': TrashType.paper, 'emoji': '📄'},
          {'type': TrashType.paper, 'emoji': '🗞️'},
          {'type': TrashType.metal, 'emoji': '🥫'},
          {'type': TrashType.metal, 'emoji': '⚙️'},
        ];
        break;
      case 3:
        itemCount = 8;
        levelTrash = [
          {'type': TrashType.plastic, 'emoji': '🥤'},
          {'type': TrashType.plastic, 'emoji': '🍼'},
          {'type': TrashType.plastic, 'emoji': '🧴'},
          {'type': TrashType.paper, 'emoji': '📄'},
          {'type': TrashType.paper, 'emoji': '🎫'},
          {'type': TrashType.paper, 'emoji': '📃'},
          {'type': TrashType.metal, 'emoji': '🥫'},
          {'type': TrashType.metal, 'emoji': '⚙️'},
        ];
        break;
      case 4:
        itemCount = 10;
        levelTrash = [
          {'type': TrashType.plastic, 'emoji': '🥤'},
          {'type': TrashType.plastic, 'emoji': '🍼'},
          {'type': TrashType.plastic, 'emoji': '🧴'},
          {'type': TrashType.plastic, 'emoji': '🥛'},
          {'type': TrashType.paper, 'emoji': '📄'},
          {'type': TrashType.paper, 'emoji': '🗞️'},
          {'type': TrashType.paper, 'emoji': '📰'},
          {'type': TrashType.paper, 'emoji': '📋'},
          {'type': TrashType.metal, 'emoji': '🥫'},
          {'type': TrashType.metal, 'emoji': '⚙️'},
        ];
        break;
      default: // Level 5 and beyond
        itemCount = 12;
        levelTrash = [
          {'type': TrashType.plastic, 'emoji': '🥤'},
          {'type': TrashType.plastic, 'emoji': '🍼'},
          {'type': TrashType.plastic, 'emoji': '🧴'},
          {'type': TrashType.plastic, 'emoji': '🥛'},
          {'type': TrashType.paper, 'emoji': '📄'},
          {'type': TrashType.paper, 'emoji': '🗞️'},
          {'type': TrashType.paper, 'emoji': '📰'},
          {'type': TrashType.paper, 'emoji': '📋'},
          {'type': TrashType.metal, 'emoji': '🥫'},
          {'type': TrashType.metal, 'emoji': '⚙️'},
          {'type': TrashType.metal, 'emoji': '🔧'},
          {'type': TrashType.metal, 'emoji': '📎'},
        ];
        break;
    }

    // Generate items using level-specific trash
    for (int i = 0; i < itemCount; i++) {
      final template = levelTrash[i % levelTrash.length];
      items.add(TrashItem(
        id: '${template['type'].toString()}_${i}',
        type: template['type'],
        emoji: template['emoji'],
        position: _getRandomPosition(),
      ));
    }

    return items;
  }

  Offset _getRandomPosition() {
    final random = math.Random();
    
    // Use relative positioning based on screen size
    final playAreaWidth = _screenWidth * 0.7; // 70% of screen width
    final playAreaHeight = _screenHeight * 0.5; // 50% of screen height
    final startX = _screenWidth * 0.15; // Start 15% from left (centers the play area)
    final startY = _screenHeight * 0.2; // Start 20% from top
    
    return Offset(
      startX + random.nextDouble() * playAreaWidth,
      startY + random.nextDouble() * playAreaHeight,
    );
  }

  void _checkGameComplete() async {
    if (trashItems.every((item) => item.isCollected)) {
      setState(() {
        levelComplete = true;
      });
      
      // Stop timer when level is complete
      _gameTimer?.cancel();
      
      if (currentLevel < maxLevel) {
        // Level complete, show next level option
        _showLevelCompleteDialog();
      } else {
        // All levels complete - save high score only when finishing all 5 levels
        await _saveHighScore();
        setState(() {
          gameComplete = true;
        });
        _celebrationController.forward();
      }
    }
  }

  void _nextLevel() {
    setState(() {
      currentLevel++;
      _initializeGame();
    });
  }

  void _resetGame() {
    setState(() {
      score = 0;
      currentLevel = 1;
      gameComplete = false;
      levelComplete = false;
      _gameStartTime = DateTime.now();
      _initializeGame();
    });
    _celebrationController.reset();
  }

  Future<void> _saveHighScore() async {
    // Calculate time from start to current level completion
    final completionTime = _gameStartTime != null 
        ? DateTime.now().difference(_gameStartTime!).inSeconds 
        : 0;
    
    final gameScore = GameScore(
      score: score,
      completionTimeSeconds: completionTime,
      completedAt: DateTime.now(),
    );
    
    await GameService.saveParkGameHighScore(gameScore);
  }

  void _dismissCurrentSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Initialize game on first build when screen dimensions are available
    if (_screenWidth == 0 && _screenHeight == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _initializeGame();
        });
      });
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF87CEEB), // Sky blue
              const Color(0xFFB0E0E6), // Powder blue
              const Color(0xFFC1E1C1), // Light mint green
              const Color(0xFF90EE90), // Light green
            ],
            stops: const [0.0, 0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background elements
              _buildBackground(),
              
              // Game elements
              ...trashItems
                  .where((item) => !item.isCollected)
                  .map((item) => _buildTrashItem(item)),
              
              // Recycling bins
              ...recyclingBins.map((bin) => _buildRecyclingBin(bin)),
              
              // UI elements
              _buildTopBar(colorScheme),
              
              // Celebration overlay
              if (gameComplete) _buildCelebrationOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        // Animated clouds
        Positioned(
          top: 40,
          left: 50,
          child: AnimatedBuilder(
            animation: _birdAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_birdAnimation.value, 0),
                child: Opacity(
                  opacity: 0.7,
                  child: Text(
                    '☁️',
                    style: TextStyle(fontSize: 50),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 80,
          right: 80,
          child: AnimatedBuilder(
            animation: _birdAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(-_birdAnimation.value * 0.7, 0),
                child: Opacity(
                  opacity: 0.6,
                  child: Text(
                    '☁️',
                    style: TextStyle(fontSize: 40),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 120,
          left: 150,
          child: AnimatedBuilder(
            animation: _birdAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_birdAnimation.value * 0.5, 0),
                child: Opacity(
                  opacity: 0.5,
                  child: Text(
                    '☁️',
                    style: TextStyle(fontSize: 35),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Sun
        Positioned(
          top: 30,
          right: 30,
          child: Container(
            width: 60,
            height: 60,
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
                  color: Colors.yellow.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '☀️',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
        
        // Ground/Grass layer with texture
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 150,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF7CB342), // Medium green
                  const Color(0xFF558B2F), // Darker green
                ],
              ),
            ),
            child: Stack(
              children: [
                // Grass texture with small flowers
                ...List.generate(15, (index) {
                  final random = math.Random(index);
                  return Positioned(
                    left: random.nextDouble() * 400,
                    bottom: random.nextDouble() * 120,
                    child: Text(
                      ['🌼', '🌸', '🌺', '🌻'][random.nextInt(4)],
                      style: TextStyle(fontSize: 20 + random.nextDouble() * 15),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        
        // Trees and bushes
        Positioned(
          left: 20,
          bottom: 120,
          child: Text('🌳', style: TextStyle(fontSize: 70)),
        ),
        Positioned(
          right: 30,
          bottom: 120,
          child: Text('🌲', style: TextStyle(fontSize: 65)),
        ),
        Positioned(
          left: 120,
          bottom: 130,
          child: Text('🌳', style: TextStyle(fontSize: 60)),
        ),
        Positioned(
          right: 150,
          bottom: 125,
          child: Text('🌲', style: TextStyle(fontSize: 55)),
        ),
        
        // Bushes
        Positioned(
          left: 80,
          bottom: 110,
          child: Text('🌿', style: TextStyle(fontSize: 40)),
        ),
        Positioned(
          right: 100,
          bottom: 105,
          child: Text('🌿', style: TextStyle(fontSize: 35)),
        ),
        
        // Flying birds (animated)
        AnimatedBuilder(
          animation: _birdAnimation,
          builder: (context, child) {
            return Positioned(
              top: 150 + _birdAnimation.value * 0.3,
              left: 200 + _birdAnimation.value * 2,
              child: Transform.rotate(
                angle: math.sin(_birdAnimation.value / 10) * 0.1,
                child: Text('🦅', style: TextStyle(fontSize: 30)),
              ),
            );
          },
        ),
        
        // Flowers (appear when game is complete)
        if (gameComplete) ...[
          const Positioned(
            top: 200,
            left: 100,
            child: Text('🌸', style: TextStyle(fontSize: 30)),
          ),
          const Positioned(
            top: 180,
            right: 80,
            child: Text('🌻', style: TextStyle(fontSize: 35)),
          ),
          const Positioned(
            top: 220,
            left: 200,
            child: Text('🌺', style: TextStyle(fontSize: 25)),
          ),
        ],
        
        // Birds (animated when game is complete)
        if (gameComplete)
          AnimatedBuilder(
            animation: _birdAnimation,
            builder: (context, child) {
              return Positioned(
                top: 60 + _birdAnimation.value,
                right: 100,
                child: const Text('🐦', style: TextStyle(fontSize: 25)),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTopBar(ColorScheme colorScheme) {
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: SafeArea(
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
          
          // Title and Level
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🧹 نظّف الحديقة',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'المستوى $currentLevel',
                    style: TextStyle(
                      color: colorScheme.primary.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.9),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'النقاط: $score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _timeRemaining <= 10 && _timeRemaining > 0
                  ? Colors.red.withOpacity(0.9)
                  : Colors.orange.withOpacity(0.9),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_timeRemaining}s',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
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

  Widget _buildTrashItem(TrashItem item) {
    return Positioned(
      left: item.position.dx,
      top: item.position.dy,
      child: Draggable<TrashItem>(
        data: item,
        onDragStarted: () {
          // Dismiss any current snackbars when starting to drag
          _dismissCurrentSnackBar();
        },
        feedback: Material(
          color: Colors.transparent,
          child: Transform.scale(
            scale: 1.2,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                item.emoji,
                style: const TextStyle(fontSize: 40),
              ),
            ),
          ),
        ),
        childWhenDragging: Container(),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.brown.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Text(
            item.emoji,
            style: const TextStyle(fontSize: 35),
          ),
        ),
      ),
    );
  }

  Widget _buildRecyclingBin(RecyclingBin bin) {
    return Positioned(
      left: bin.position.dx,
      top: bin.position.dy,
      child: DragTarget<TrashItem>(
        onAcceptWithDetails: (details) {
          final item = details.data;
          if (item.type == bin.type) {
            setState(() {
              final index = trashItems.indexWhere((t) => t.id == item.id);
              if (index != -1) {
                trashItems[index] = item.copyWith(isCollected: true);
                score += 10;
              }
            });
            
            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '🎉 أحسنت! وضعت القمامة في المكان الصحيح',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: '✕',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
            
            _checkGameComplete();
          } else {
            // Decrease timer by 5 seconds for wrong placement
            setState(() {
              _timeRemaining = math.max(0, _timeRemaining - 5);
            });
            
            // Check if time is up due to penalty
            if (_timeRemaining <= 0) {
              _gameTimer?.cancel();
              _handleTimeUp();
              return;
            }
            
            // Show error feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '❌ خطأ! -5 ثوان • ضع القمامة في السلة المناسبة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                behavior: SnackBarBehavior.floating,
                action: SnackBarAction(
                  label: '✕',
                  textColor: Colors.white,
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        },
        builder: (context, candidateItems, rejectedItems) {
          final isHighlighted = candidateItems.isNotEmpty;
          return Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: isHighlighted 
                  ? bin.color.withOpacity(0.8)
                  : bin.color.withOpacity(0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isHighlighted 
                    ? Colors.white
                    : bin.color.withOpacity(0.8),
                width: isHighlighted ? 3 : 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  bin.emoji,
                  style: const TextStyle(fontSize: 30),
                ),
                const SizedBox(height: 4),
                Text(
                  bin.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '🌟',
                style: TextStyle(fontSize: 60),
              ),
              const SizedBox(height: 16),
              Text(
                'أكملت المستوى $currentLevel!',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'النقاط: $score',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _nextLevel();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'المستوى ${currentLevel + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'العودة',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCelebrationOverlay() {
    return AnimatedBuilder(
      animation: _celebrationAnimation,
      builder: (context, child) {
        return Container(
          color: Colors.black.withOpacity(0.3),
          child: Center(
            child: Transform.scale(
              scale: _celebrationAnimation.value,
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      '🎉',
                      style: TextStyle(fontSize: 60),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'مبروك!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أكملت جميع المستويات!',
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'النقاط النهائية: $score',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    if (_gameStartTime != null)
                      Text(
                        'الوقت: ${GameService.formatTime(DateTime.now().difference(_gameStartTime!).inSeconds)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                    const SizedBox(height: 16),
                    // High Scores Section
                    FutureBuilder<List<GameScore>>(
                      future: GameService.getParkGameHighScores(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final scores = snapshot.data!.take(5).toList();
                          return Container(
                            constraints: const BoxConstraints(maxHeight: 200, maxWidth: 300),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🏆 أفضل النتائج',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Flexible(
                                  child: SingleChildScrollView(
                                    child: Column(
                                      children: scores.asMap().entries.map((entry) {
                                        final index = entry.key;
                                        final score = entry.value;
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 2),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '${index + 1}.',
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                '${score.score} نقطة',
                                                style: const TextStyle(fontSize: 12),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                GameService.formatTime(score.completionTimeSeconds),
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _resetGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'العب مرة أخرى',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'العودة للقائمة',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}