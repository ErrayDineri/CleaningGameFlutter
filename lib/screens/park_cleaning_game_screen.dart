import 'package:flutter/material.dart';
import 'dart:math' as math;

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
  late List<TrashItem> trashItems;
  late List<RecyclingBin> recyclingBins;
  int score = 0;
  int currentLevel = 1;
  int maxLevel = 5;
  bool gameComplete = false;
  bool levelComplete = false;
  late AnimationController _celebrationController;
  late AnimationController _birdController;
  late Animation<double> _celebrationAnimation;
  late Animation<double> _birdAnimation;

  @override
  void initState() {
    super.initState();
    _initializeGame();
    
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
    super.dispose();
  }

  void _initializeGame() {
    // Initialize recycling bins
    recyclingBins = [
      RecyclingBin(
        type: TrashType.plastic,
        emoji: '♻️',
        label: 'البلاستيك',
        color: Colors.blue,
        position: const Offset(50, 500),
      ),
      RecyclingBin(
        type: TrashType.paper,
        emoji: '📄',
        label: 'الورق',
        color: Colors.green,
        position: const Offset(150, 500),
      ),
      RecyclingBin(
        type: TrashType.metal,
        emoji: '🗂️',
        label: 'المعدن',
        color: Colors.grey,
        position: const Offset(250, 500),
      ),
    ];

    // Initialize trash items based on current level
    trashItems = _generateTrashForLevel(currentLevel);
    levelComplete = false;
  }

  List<TrashItem> _generateTrashForLevel(int level) {
    List<TrashItem> items = [];
    
    // Base trash items
    List<Map<String, dynamic>> trashTemplates = [
      {'type': TrashType.plastic, 'emoji': '🥤'},
      {'type': TrashType.plastic, 'emoji': '🍼'},
      {'type': TrashType.paper, 'emoji': '📄'},
      {'type': TrashType.paper, 'emoji': '🗞️'},
      {'type': TrashType.metal, 'emoji': '🥫'},
      {'type': TrashType.metal, 'emoji': '⚙️'},
    ];

    // Additional items for higher levels
    List<Map<String, dynamic>> advancedTrash = [
      {'type': TrashType.plastic, 'emoji': '🧴'},
      {'type': TrashType.plastic, 'emoji': '🥛'},
      {'type': TrashType.paper, 'emoji': '📰'},
      {'type': TrashType.paper, 'emoji': '📋'},
      {'type': TrashType.metal, 'emoji': '�'},
      {'type': TrashType.metal, 'emoji': '📎'},
    ];

    // Level 1-2: Base items (6 items)
    int itemCount = 6;
    List<Map<String, dynamic>> availableTrash = [...trashTemplates];

    // Level 3-4: Add more items (8-10 items)
    if (level >= 3) {
      itemCount = 8 + (level - 3);
      availableTrash.addAll(advancedTrash);
    }

    // Level 5: Maximum challenge (12 items)
    if (level >= 5) {
      itemCount = 12;
    }

    // Generate items
    for (int i = 0; i < itemCount; i++) {
      final template = availableTrash[i % availableTrash.length];
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
    return Offset(
      50 + random.nextDouble() * 250, // x: 50-300
      150 + random.nextDouble() * 200, // y: 150-350
    );
  }

  void _checkGameComplete() {
    if (trashItems.every((item) => item.isCollected)) {
      setState(() {
        levelComplete = true;
      });
      
      if (currentLevel < maxLevel) {
        // Level complete, show next level option
        _showLevelCompleteDialog();
      } else {
        // All levels complete
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
      _initializeGame();
    });
    _celebrationController.reset();
  }

  void _dismissCurrentSnackBar() {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.lightBlue[100]!,
              Colors.green[100]!,
            ],
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
        // Grass
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.lightBlue[200]!,
                  Colors.green[200]!,
                ],
              ),
            ),
          ),
        ),
        
        // Trees
        const Positioned(
          top: 80,
          left: 20,
          child: Text('🌳', style: TextStyle(fontSize: 60)),
        ),
        const Positioned(
          top: 100,
          right: 30,
          child: Text('🌲', style: TextStyle(fontSize: 50)),
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'المستوى $currentLevel',
                  style: TextStyle(
                    color: colorScheme.primary.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          
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
        ],
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
            // Show error feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  '❌ حاول مرة أخرى! ضع القمامة في السلة المناسبة',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.orange,
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