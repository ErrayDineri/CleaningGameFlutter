import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:async';
import '../services/game_service.dart';
import '../services/user_service.dart';

enum AnimalType {
  turtle,
  bird,
  fish,
  dolphin,
  seal,
}

enum TrashType {
  plasticRing,
  can,
  bottle,
  bag,
  net,
}

class TrappedAnimal {
  final String id;
  final AnimalType type;
  final TrashType trashType;
  final String animalEmoji;
  final String trashEmoji;
  final Offset position;
  bool isFreed;
  bool isRescuing;

  TrappedAnimal({
    required this.id,
    required this.type,
    required this.trashType,
    required this.animalEmoji,
    required this.trashEmoji,
    required this.position,
    this.isFreed = false,
    this.isRescuing = false,
  });

  TrappedAnimal copyWith({
    bool? isFreed,
    bool? isRescuing,
    Offset? position,
  }) {
    return TrappedAnimal(
      id: id,
      type: type,
      trashType: trashType,
      animalEmoji: animalEmoji,
      trashEmoji: trashEmoji,
      position: position ?? this.position,
      isFreed: isFreed ?? this.isFreed,
      isRescuing: isRescuing ?? this.isRescuing,
    );
  }
}

class SaveAnimalsGameScreen extends StatefulWidget {
  const SaveAnimalsGameScreen({super.key});

  @override
  State<SaveAnimalsGameScreen> createState() => _SaveAnimalsGameScreenState();
}

class _SaveAnimalsGameScreenState extends State<SaveAnimalsGameScreen>
    with TickerProviderStateMixin {
  List<TrappedAnimal> animals = [];
  int score = 0;
  int currentLevel = 1;
  int maxLevel = 5;
  bool gameComplete = false;
  bool levelComplete = false;
  
  late AnimationController _celebrationController;
  late AnimationController _waveController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _waveAnimation;
  
  // Timer variables
  Timer? _gameTimer;
  int _timeRemaining = 15; // 15 seconds per level
  
  // Game tracking
  DateTime? _gameStartTime;
  int _animalsFreedThisLevel = 0;
  
  // Screen dimensions
  double _screenWidth = 0;
  double _screenHeight = 0;
  
  // Rescue animation controllers
  Map<String, AnimationController> _rescueControllers = {};

  @override
  void initState() {
    super.initState();
    
    _celebrationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _waveController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _celebrationAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _celebrationController, curve: Curves.elasticOut),
    );
    
    _waveAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _waveController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    _waveController.dispose();
    _gameTimer?.cancel();
    for (var controller in _rescueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _initializeGame() {
    if (context.mounted) {
      _screenWidth = MediaQuery.of(context).size.width;
      _screenHeight = MediaQuery.of(context).size.height;
    }
    
    if (currentLevel == 1) {
      _gameStartTime = DateTime.now();
    }
    
    animals = _generateAnimalsForLevel(currentLevel);
    levelComplete = false;
    _animalsFreedThisLevel = 0;
    
    _startTimer();
  }

  void _startTimer() {
    _timeRemaining = 90;
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

  List<TrappedAnimal> _generateAnimalsForLevel(int level) {
    List<TrappedAnimal> animalsList = [];
    
    // Define animals and their trash for each level
    List<Map<String, dynamic>> levelAnimals;
    
    switch (level) {
      case 1:
        levelAnimals = [
          {'animal': AnimalType.turtle, 'emoji': '🐢', 'trash': TrashType.plasticRing, 'trashEmoji': '⭕'},
          {'animal': AnimalType.bird, 'emoji': '🐦', 'trash': TrashType.can, 'trashEmoji': '🥫'},
          {'animal': AnimalType.fish, 'emoji': '🐟', 'trash': TrashType.bag, 'trashEmoji': '🛍️'},
        ];
        break;
      case 2:
        levelAnimals = [
          {'animal': AnimalType.turtle, 'emoji': '🐢', 'trash': TrashType.plasticRing, 'trashEmoji': '⭕'},
          {'animal': AnimalType.bird, 'emoji': '🦜', 'trash': TrashType.can, 'trashEmoji': '🥫'},
          {'animal': AnimalType.fish, 'emoji': '🐠', 'trash': TrashType.bottle, 'trashEmoji': '🍼'},
          {'animal': AnimalType.dolphin, 'emoji': '🐬', 'trash': TrashType.net, 'trashEmoji': '🎣'},
        ];
        break;
      case 3:
        levelAnimals = [
          {'animal': AnimalType.turtle, 'emoji': '🐢', 'trash': TrashType.plasticRing, 'trashEmoji': '⭕'},
          {'animal': AnimalType.bird, 'emoji': '🦅', 'trash': TrashType.can, 'trashEmoji': '🥫'},
          {'animal': AnimalType.fish, 'emoji': '🐡', 'trash': TrashType.bag, 'trashEmoji': '🛍️'},
          {'animal': AnimalType.dolphin, 'emoji': '🐬', 'trash': TrashType.net, 'trashEmoji': '🎣'},
          {'animal': AnimalType.seal, 'emoji': '🦭', 'trash': TrashType.bottle, 'trashEmoji': '🍼'},
        ];
        break;
      case 4:
        levelAnimals = [
          {'animal': AnimalType.turtle, 'emoji': '🐢', 'trash': TrashType.plasticRing, 'trashEmoji': '⭕'},
          {'animal': AnimalType.turtle, 'emoji': '🐢', 'trash': TrashType.bag, 'trashEmoji': '🛍️'},
          {'animal': AnimalType.bird, 'emoji': '🦆', 'trash': TrashType.can, 'trashEmoji': '🥫'},
          {'animal': AnimalType.fish, 'emoji': '🐟', 'trash': TrashType.bottle, 'trashEmoji': '🍼'},
          {'animal': AnimalType.dolphin, 'emoji': '🐬', 'trash': TrashType.net, 'trashEmoji': '🎣'},
          {'animal': AnimalType.seal, 'emoji': '🦭', 'trash': TrashType.plasticRing, 'trashEmoji': '⭕'},
        ];
        break;
      default: // Level 5
        levelAnimals = [
          {'animal': AnimalType.turtle, 'emoji': '🐢', 'trash': TrashType.plasticRing, 'trashEmoji': '⭕'},
          {'animal': AnimalType.turtle, 'emoji': '🐢', 'trash': TrashType.bag, 'trashEmoji': '🛍️'},
          {'animal': AnimalType.bird, 'emoji': '🦜', 'trash': TrashType.can, 'trashEmoji': '🥫'},
          {'animal': AnimalType.bird, 'emoji': '🦅', 'trash': TrashType.bottle, 'trashEmoji': '🍼'},
          {'animal': AnimalType.fish, 'emoji': '🐠', 'trash': TrashType.bag, 'trashEmoji': '🛍️'},
          {'animal': AnimalType.dolphin, 'emoji': '🐬', 'trash': TrashType.net, 'trashEmoji': '🎣'},
          {'animal': AnimalType.seal, 'emoji': '🦭', 'trash': TrashType.plasticRing, 'trashEmoji': '⭕'},
        ];
        break;
    }
    
    for (int i = 0; i < levelAnimals.length; i++) {
      final template = levelAnimals[i];
      animalsList.add(TrappedAnimal(
        id: '${template['animal'].toString()}_$i',
        type: template['animal'],
        trashType: template['trash'],
        animalEmoji: template['emoji'],
        trashEmoji: template['trashEmoji'],
        position: _getRandomPosition(),
      ));
    }
    
    return animalsList;
  }

  Offset _getRandomPosition() {
    final random = math.Random();
    final playAreaWidth = _screenWidth * 0.8;
    final playAreaHeight = _screenHeight * 0.5;
    final startX = _screenWidth * 0.1;
    final startY = _screenHeight * 0.2;
    
    return Offset(
      startX + random.nextDouble() * playAreaWidth,
      startY + random.nextDouble() * playAreaHeight,
    );
  }

  void _rescueAnimal(TrappedAnimal animal) async {
    if (animal.isFreed || animal.isRescuing) return;
    
    // Create rescue animation
    final controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _rescueControllers[animal.id] = controller;
    
    setState(() {
      final index = animals.indexWhere((a) => a.id == animal.id);
      if (index != -1) {
        animals[index] = animal.copyWith(isRescuing: true);
      }
    });
    
    // Animate rescue
    await controller.forward();
    
    setState(() {
      final index = animals.indexWhere((a) => a.id == animal.id);
      if (index != -1) {
        animals[index] = animal.copyWith(isFreed: true, isRescuing: false);
        score += 15; // 15 points per rescued animal
        _animalsFreedThisLevel++;
      }
    });
    
    // Show success message
    _showRescueMessage(animal);
    
    // Check if level complete
    _checkGameComplete();
  }

  void _showRescueMessage(TrappedAnimal animal) {
    final messages = {
      AnimalType.turtle: 'أحسنت! أنقذت السلحفاة 🐢',
      AnimalType.bird: 'رائع! أنقذت الطائر 🐦',
      AnimalType.fish: 'ممتاز! أنقذت السمكة 🐟',
      AnimalType.dolphin: 'عظيم! أنقذت الدلفين 🐬',
      AnimalType.seal: 'مذهل! أنقذت الفقمة 🦭',
    };
    
    // Clear any existing snackbar before showing new one
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          messages[animal.type] ?? 'أحسنت! أنقذت الحيوان',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF27AE60),
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _checkGameComplete() {
    if (animals.every((animal) => animal.isFreed)) {
      setState(() {
        levelComplete = true;
      });
      
      _gameTimer?.cancel();
      
      if (currentLevel < maxLevel) {
        _showLevelCompleteDialog();
      } else {
        _saveHighScore();
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
    final completionTime = _gameStartTime != null 
        ? DateTime.now().difference(_gameStartTime!).inSeconds 
        : 0;
    
    final gameScore = GameScore(
      score: score,
      completionTimeSeconds: completionTime,
      completedAt: DateTime.now(),
    );
    
    await GameService.saveAnimalsGameHighScore(gameScore);
    
    // Award XP: 15 per level + 75 bonus for completing all 5 levels
    final xpEarned = (currentLevel * 15) + 75;
    final leveledUp = await UserService.addXp(xpEarned);
    
    if (leveledUp && mounted) {
      _showLevelUpDialog(xpEarned);
    }
  }

  void _showLevelUpDialog(int xpEarned) async {
    final profile = await UserService.getUserProfile();
    final newLevel = profile['level'] as int;
    
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Text('⭐', style: TextStyle(fontSize: 60)),
            SizedBox(height: 8),
            Text(
              'تهانينا!',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'لقد ارتقيت إلى مستوى أعلى!',
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE67E22).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: [
                  Text(
                    'المستوى $newLevel',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFE67E22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '+$xpEarned XP',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE67E22),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'رائع!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
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
              Text(
                'أنقذت $_animalsFreedThisLevel حيوان في هذا المستوى',
                style: const TextStyle(fontSize: 16),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  currentLevel = 1;
                  score = 0;
                  gameComplete = false;
                  levelComplete = false;
                  _gameStartTime = DateTime.now();
                  _initializeGame();
                });
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
                  color: Color(0xFF27AE60),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'أنقذت $_animalsFreedThisLevel حيوان!',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'النقاط: $score',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
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
                      backgroundColor: const Color(0xFF27AE60),
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_screenWidth == 0 && _screenHeight == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _initializeGame();
        });
      });
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF4A90E2), // Ocean blue
              Color(0xFF5BA3D0),
              Color(0xFF6CB5DE),
              Color(0xFF7DC8EC),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Background
              _buildBackground(),
              
              // Animals
              ...animals
                  .where((animal) => !animal.isFreed)
                  .map((animal) => _buildTrappedAnimal(animal)),
              
              // Top bar
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
        // Multiple wave layers for depth
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 80 + _waveAnimation.value,
              left: -20,
              right: -20,
              child: Opacity(
                opacity: 0.4,
                child: Text(
                  '🌊' * 12,
                  style: const TextStyle(fontSize: 45),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 130 - _waveAnimation.value * 0.7,
              left: -20,
              right: -20,
              child: Opacity(
                opacity: 0.3,
                child: Text(
                  '🌊' * 12,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              bottom: 180 + _waveAnimation.value * 0.5,
              left: -20,
              right: -20,
              child: Opacity(
                opacity: 0.2,
                child: Text(
                  '🌊' * 12,
                  style: const TextStyle(fontSize: 35),
                ),
              ),
            );
          },
        ),
        
        // Glowing sun with rays
        Positioned(
          top: 30,
          right: 30,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Sun glow
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.yellow.withOpacity(0.6),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
              // Sun emoji
              const Text('☀️', style: TextStyle(fontSize: 55)),
            ],
          ),
        ),
        
        // Animated clouds with different speeds
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              top: 60 + _waveAnimation.value * 0.6,
              left: 50 + _waveAnimation.value * 0.3,
              child: const Opacity(
                opacity: 0.8,
                child: Text('☁️', style: TextStyle(fontSize: 55)),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              top: 100 - _waveAnimation.value * 0.4,
              right: 80 - _waveAnimation.value * 0.2,
              child: const Opacity(
                opacity: 0.7,
                child: Text('☁️', style: TextStyle(fontSize: 50)),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              top: 140 + _waveAnimation.value * 0.5,
              left: 200 - _waveAnimation.value * 0.25,
              child: const Opacity(
                opacity: 0.6,
                child: Text('☁️', style: TextStyle(fontSize: 48)),
              ),
            );
          },
        ),
        
        // Flying birds
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              top: 180 + math.sin(_waveAnimation.value * 0.5) * 20,
              left: 100 + _waveAnimation.value * 2,
              child: Transform.rotate(
                angle: math.sin(_waveAnimation.value * 0.5) * 0.2,
                child: const Text('🕊️', style: TextStyle(fontSize: 32)),
              ),
            );
          },
        ),
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              top: 150 - math.sin(_waveAnimation.value * 0.3) * 15,
              right: 150 + _waveAnimation.value * 1.5,
              child: Transform.rotate(
                angle: -math.sin(_waveAnimation.value * 0.3) * 0.15,
                child: const Text('🦅', style: TextStyle(fontSize: 30)),
              ),
            );
          },
        ),
        
        // Floating jellyfish
        AnimatedBuilder(
          animation: _waveAnimation,
          builder: (context, child) {
            return Positioned(
              top: 300 + _waveAnimation.value * 2,
              left: 80,
              child: Opacity(
                opacity: 0.5,
                child: Text('🪼', style: TextStyle(fontSize: 35)),
              ),
            );
          },
        ),
        
        // Sea floor with enhanced details
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 120,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF8B7355),
                  Color(0xFF6B5345),
                  Color(0xFF5A4436),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Coral and seaweed with shadows
                Positioned(
                  left: 30,
                  bottom: 20,
                  child: Stack(
                    children: [
                      Positioned(
                        left: 2,
                        top: 2,
                        child: Text('🪸', style: TextStyle(fontSize: 45, color: Colors.black.withOpacity(0.3))),
                      ),
                      const Text('🪸', style: TextStyle(fontSize: 45)),
                    ],
                  ),
                ),
                Positioned(
                  right: 50,
                  bottom: 15,
                  child: const Text('🌿', style: TextStyle(fontSize: 50)),
                ),
                Positioned(
                  left: 150,
                  bottom: 25,
                  child: const Text('🪨', style: TextStyle(fontSize: 38)),
                ),
                Positioned(
                  right: 200,
                  bottom: 20,
                  child: const Text('🐚', style: TextStyle(fontSize: 32)),
                ),
                Positioned(
                  left: 250,
                  bottom: 18,
                  child: const Text('⭐', style: TextStyle(fontSize: 28)),
                ),
                Positioned(
                  right: 120,
                  bottom: 22,
                  child: const Text('🪸', style: TextStyle(fontSize: 42)),
                ),
                // Bubbles rising
                AnimatedBuilder(
                  animation: _waveAnimation,
                  builder: (context, child) {
                    return Positioned(
                      left: 180,
                      bottom: 30 + (_waveAnimation.value * 3),
                      child: Opacity(
                        opacity: 0.6 - (_waveAnimation.value / 30),
                        child: const Text('💧', style: TextStyle(fontSize: 20)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
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
                      '🐢 أنقذ الحيوانات',
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
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _timeRemaining <= 15 && _timeRemaining > 0
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

  Widget _buildTrappedAnimal(TrappedAnimal animal) {
    final controller = _rescueControllers[animal.id];
    
    return Positioned(
      left: animal.position.dx,
      top: animal.position.dy,
      child: GestureDetector(
        onTap: () => _rescueAnimal(animal),
        child: AnimatedBuilder(
          animation: controller ?? _waveController,
          builder: (context, child) {
            final scale = animal.isRescuing && controller != null
                ? 1.0 + (controller.value * 0.5)
                : 1.0 + (math.sin(_waveController.value * math.pi / 7.5) * 0.05);
            final opacity = animal.isRescuing && controller != null
                ? 1.0 - controller.value
                : 1.0;
            
            return Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: animal.isRescuing
                          ? [
                              Colors.white,
                              const Color(0xFFE8F5E9),
                            ]
                          : [
                              Colors.white,
                              const Color(0xFFFFEBEE),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: animal.isRescuing
                          ? const Color(0xFF27AE60)
                          : Colors.red.withOpacity(0.6),
                      width: 4,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: animal.isRescuing
                            ? const Color(0xFF27AE60).withOpacity(0.5)
                            : Colors.red.withOpacity(0.3),
                        blurRadius: animal.isRescuing ? 20 : 15,
                        spreadRadius: animal.isRescuing ? 5 : 2,
                        offset: const Offset(0, 5),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animal with subtle bounce
                          Transform.translate(
                            offset: Offset(0, animal.isRescuing ? -controller!.value * 30 : 0),
                            child: Text(
                              animal.animalEmoji,
                              style: const TextStyle(fontSize: 55),
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Trash overlay
                          if (!animal.isRescuing)
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                animal.trashEmoji,
                                style: const TextStyle(fontSize: 42),
                              ),
                            ),
                          if (!animal.isRescuing)
                            const SizedBox(height: 6),
                          if (!animal.isRescuing)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27AE60).withOpacity(0.9),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF27AE60).withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'اضغط للإنقاذ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      // Rescue sparkle effect
                      if (animal.isRescuing)
                        Positioned.fill(
                          child: Center(
                            child: Transform.scale(
                              scale: controller!.value * 2,
                              child: Opacity(
                                opacity: 1.0 - controller.value,
                                child: Text(
                                  '✨🌟✨',
                                  style: TextStyle(
                                    fontSize: 50,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      // Pulsing glow ring for urgent rescue
                      if (!animal.isRescuing)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.amber.withOpacity(0.3 + math.sin(_waveController.value * math.pi) * 0.2),
                                width: 2,
                              ),
                            ),
                          ),
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
                      'مبروك! بطل!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF27AE60),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'أنقذت جميع الحيوانات!',
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
                    const SizedBox(height: 24),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          onPressed: _resetGame,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF27AE60),
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
