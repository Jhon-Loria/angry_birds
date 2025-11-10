import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart';

import 'components/game.dart';
import 'components/shop.dart';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

  await Supabase.initialize(
    url: 'https://fhqkawzltegysrfcnbrt.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZocWthd3psdGVneXNyZmNuYnJ0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjE3MDQ0MzQsImV4cCI6MjA3NzI4MDQzNH0.lO84El-97OrKojA38G0Fldp-lSzxShVzXZTQGZ5ldZs',
  );

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: _GameWrapper(),
    ),
  );
}

class _GameWrapper extends StatefulWidget {
  @override
  State<_GameWrapper> createState() => _GameWrapperState();
}

class _GameWrapperState extends State<_GameWrapper> {
  final ShopManager _shopManager = ShopManager();
  MyPhysicsGame? _game;
  String _currentScreen = 'menu'; // 'menu', 'shop', 'game'
  late AudioPlayer _menuMusicPlayer;

  @override
  void initState() {
    super.initState();
    _menuMusicPlayer = AudioPlayer();
    _startMenuMusic();
  }

  @override
  void dispose() {
    _menuMusicPlayer.dispose();
    super.dispose();
  }

  Future<void> _startMenuMusic() async {
    await _menuMusicPlayer.setReleaseMode(ReleaseMode.loop);
    await _menuMusicPlayer.play(AssetSource('audio/fondo.mp3'));
  }

  void _startGame(LevelType levelType) {
    _menuMusicPlayer.stop();
    setState(() {
      _currentScreen = 'game';
      _game = MyPhysicsGame(
        shopManager: _shopManager,
        levelType: levelType,
      );
    });
  }

  void _openShop() {
    _menuMusicPlayer.stop();
    setState(() {
      _currentScreen = 'shop';
    });
  }

  void _openScores() {
    _menuMusicPlayer.stop();
    setState(() {
      _currentScreen = 'scores';
    });
  }

  void _returnToMenu() {
    _startMenuMusic();
    setState(() {
      _currentScreen = 'menu';
      _game = null;
    });
  }

  void _returnToShop() {
    // Resetear items comprados para el siguiente turno
    _shopManager.resetItemsForNewTurn();
    setState(() {
      _currentScreen = 'shop';
      _game = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentScreen == 'menu') {
      return MainMenu(
        onStartGame: _startGame,
        onOpenShop: _openShop,
        onOpenScores: _openScores,
      );
    }
    
    if (_currentScreen == 'shop') {
      return ShopScreen(
        shopManager: _shopManager,
        onStartGame: _startGame,
        onReturnToMenu: _returnToMenu,
      );
    }
    
    if (_currentScreen == 'scores') {
      return ScoresScreen(
        onReturnToMenu: _returnToMenu,
      );
    }

    return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            GameWidget.controlled(
              gameFactory: () => _game!,
              overlayBuilderMap: {
                'dialog': (context, game) {
                  return _SaveScoreDialog(
                    game: game as MyPhysicsGame,
                    onReturnToShop: _returnToShop,
                    onReturnToMenu: _returnToMenu,
                  );
                },
                'inventory': (context, game) {
                  return _InventoryOverlay(
                    game: game as MyPhysicsGame,
                  );
                },
              },
            ),
            // Botón de habilidades (rayo) flotante
            Positioned(
              top: 10,
              left: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _game?.overlays.add('inventory');
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color(0xFFFFD700), // Dorado/Amarillo neón
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFFD700).withOpacity(0.6),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 8,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.bolt,
                      color: Color(0xFFFFD700), // Dorado/Amarillo neón
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
  }
}

// Widget del menú principal
class MainMenu extends StatelessWidget {
  final Function(LevelType) onStartGame;
  final VoidCallback onOpenShop;
  final VoidCallback onOpenScores;

  const MainMenu({
    Key? key,
    required this.onStartGame,
    required this.onOpenShop,
    required this.onOpenScores,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Colores neón de los 90s
    final neonBlue = Color(0xFF00FFFF);
    final neonBlueGlow = Color(0xFF00FFFF).withOpacity(0.6);
    final darkBlue = Color(0xFF001122);
    final neonGreen = Color(0xFF00FF00);
    final neonPink = Color(0xFFFF0080);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkBlue,
              Colors.black,
              darkBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              ),
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Título del juego
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: neonBlue,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: neonBlueGlow,
                              blurRadius: 20,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: Text(
                          'ANGRY BIRDS',
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: neonBlue,
                            letterSpacing: 5,
                            shadows: [
                              Shadow(
                                blurRadius: 15,
                                color: neonBlue,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 30,
                                color: neonBlue,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 60),
                      
                      // Botones del menú
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Column(
                          children: [
                            // Botón Normal
                            SizedBox(
                              width: double.infinity,
                              height: 70,
                              child: ElevatedButton(
                                onPressed: () {
                                  onStartGame(LevelType.normal);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  side: BorderSide(
                                    color: neonGreen,
                                    width: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: neonGreen.withOpacity(0.6),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'NORMAL',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: neonGreen,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: neonGreen,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Botón Jefe Final
                            SizedBox(
                              width: double.infinity,
                              height: 70,
                              child: ElevatedButton(
                                onPressed: () {
                                  onStartGame(LevelType.bigBoss);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  side: BorderSide(
                                    color: neonPink,
                                    width: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: neonPink.withOpacity(0.6),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'JEFE FINAL',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: neonPink,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: neonPink,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Botón Tienda
                            SizedBox(
                              width: double.infinity,
                              height: 70,
                              child: ElevatedButton(
                                onPressed: onOpenShop,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  side: BorderSide(
                                    color: neonBlue,
                                    width: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: neonBlueGlow,
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'TIENDA',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: neonBlue,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: neonBlue,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                            
                            // Botón Scores
                            SizedBox(
                              width: double.infinity,
                              height: 70,
                              child: ElevatedButton(
                                onPressed: onOpenScores,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  side: BorderSide(
                                    color: Colors.amber,
                                    width: 3,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  elevation: 0,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withOpacity(0.6),
                                        blurRadius: 15,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'SCORES',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                      letterSpacing: 3,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 10,
                                          color: Colors.amber,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Widget para mostrar los scores
class ScoresScreen extends StatefulWidget {
  final VoidCallback onReturnToMenu;

  const ScoresScreen({
    Key? key,
    required this.onReturnToMenu,
  }) : super(key: key);

  @override
  State<ScoresScreen> createState() => _ScoresScreenState();
}

class _ScoresScreenState extends State<ScoresScreen> {
  List<Map<String, dynamic>> _scores = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadScores();
  }

  Future<void> _loadScores() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('scores_puntuaje')
          .select()
          .order('score', ascending: false)
          .limit(100);

      setState(() {
        _scores = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error al cargar scores: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colores neón de los 90s
    final neonBlue = Color(0xFF00FFFF);
    final darkBlue = Color(0xFF001122);
    final neonYellow = Colors.amber;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkBlue,
              Colors.black,
              darkBlue,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: neonBlue, width: 2),
                  ),
                  color: Colors.black,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: neonBlue),
                      onPressed: widget.onReturnToMenu,
                    ),
                    SizedBox(width: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: neonBlue, width: 2),
                        ),
                      ),
                      child: Text(
                        'SCORES',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: neonBlue,
                          letterSpacing: 3,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: neonBlue,
                              offset: Offset(0, 0),
                            ),
                            Shadow(
                              blurRadius: 20,
                              color: neonBlue,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.refresh, color: neonBlue),
                      onPressed: _loadScores,
                    ),
                  ],
                ),
              ),
              
              // Contenido
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(neonBlue),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 64,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    _error!,
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(height: 24),
                                  ElevatedButton(
                                    onPressed: _loadScores,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black,
                                      side: BorderSide(color: neonBlue, width: 2),
                                    ),
                                    child: Text(
                                      'REINTENTAR',
                                      style: TextStyle(color: neonBlue),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : _scores.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.emoji_events_outlined,
                                      color: neonBlue.withOpacity(0.5),
                                      size: 64,
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No hay scores guardados',
                                      style: TextStyle(
                                        color: neonBlue.withOpacity(0.8),
                                        fontSize: 18,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.all(16),
                                itemCount: _scores.length,
                                itemBuilder: (context, index) {
                                  final score = _scores[index];
                                  final position = index + 1;
                                  final isTopThree = position <= 3;
                                  
                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      border: Border.all(
                                        color: isTopThree ? neonYellow : neonBlue,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isTopThree ? neonYellow : neonBlue).withOpacity(0.3),
                                          blurRadius: 8,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: isTopThree ? neonYellow : neonBlue,
                                            width: 2,
                                          ),
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            '#$position',
                                            style: TextStyle(
                                              color: isTopThree ? neonYellow : neonBlue,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        score['player_name'] ?? 'Sin nombre',
                                        style: TextStyle(
                                          color: neonBlue,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: neonYellow,
                                            width: 1,
                                          ),
                                          color: Colors.black,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(Icons.star, color: neonYellow, size: 20),
                                            SizedBox(width: 4),
                                            Text(
                                              '${score['score'] ?? 0}',
                                              style: TextStyle(
                                                color: neonYellow,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveScoreDialog extends StatefulWidget {
  const _SaveScoreDialog({
    required this.game,
    this.onReturnToShop,
    this.onReturnToMenu,
  });

  final MyPhysicsGame game;
  final VoidCallback? onReturnToShop;
  final VoidCallback? onReturnToMenu;

  @override
  State<_SaveScoreDialog> createState() => _SaveScoreDialogState();
}

class _SaveScoreDialogState extends State<_SaveScoreDialog> {
  final _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final won = widget.game.playerWon;
    final score = widget.game.score;
    
    // Colores neón de los 90s
    final neonBlue = Color(0xFF00FFFF);
    final neonBlueGlow = Color(0xFF00FFFF).withOpacity(0.6);
    final darkBlue = Color(0xFF001122);
    final neonGreen = Color(0xFF00FF00);
    final neonPink = Color(0xFFFF0080);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
        padding: EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(
            color: neonBlue,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: neonBlueGlow,
              blurRadius: 20,
              spreadRadius: 3,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icono de resultado
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: won ? neonGreen : neonPink,
                    width: 3,
                  ),
                  color: Colors.black,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (won ? neonGreen : neonPink).withOpacity(0.6),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  won ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 64,
                  color: won ? neonGreen : neonPink,
                ),
              ),
              SizedBox(height: 16),
              
              // Mensaje principal
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: neonBlue, width: 2),
                  ),
                ),
                child: Text(
                  won ? '¡Victoria!' : '¡Juego Terminado!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: neonBlue,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: neonBlue,
                        offset: Offset(0, 0),
                      ),
                      Shadow(
                        blurRadius: 20,
                        color: neonBlue,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              
              // Score
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: neonBlue,
                    width: 2,
                  ),
                  color: darkBlue,
                  boxShadow: [
                    BoxShadow(
                      color: neonBlueGlow,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Tu Score: $score',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: neonBlue,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: neonBlue,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              
              // Instrucción
              Text(
                'Ingresa tu nombre para guardar tu score',
                style: TextStyle(
                  fontSize: 14,
                  color: neonBlue.withOpacity(0.8),
                  letterSpacing: 1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              
              // Campo de texto
              TextField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Nombre del jugador',
                  labelStyle: TextStyle(color: neonBlue.withOpacity(0.8)),
                  prefixIcon: Icon(Icons.person, color: neonBlue),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: neonBlue, width: 2),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: neonBlue.withOpacity(0.6), width: 2),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(2),
                    borderSide: BorderSide(color: neonBlue, width: 2),
                  ),
                  filled: true,
                  fillColor: darkBlue,
                ),
                style: TextStyle(color: neonBlue, letterSpacing: 1),
              ),
              SizedBox(height: 24),
              
              // Botones de acción
              Column(
                children: [
                  // Guardar Score
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (_textController.text.isNotEmpty) {
                          try {
                            await widget.game.saveScore(_textController.text);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Score guardado exitosamente'),
                                  backgroundColor: neonBlue,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error al guardar score: $e'),
                                  backgroundColor: neonPink,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Por favor ingresa tu nombre'),
                              backgroundColor: Colors.amber,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                      icon: Icon(Icons.save, color: neonGreen),
                      label: Text(
                        'Guardar Score',
                        style: TextStyle(
                          color: neonGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: neonGreen,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(
                          color: neonGreen,
                          width: 2,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Nueva Ronda
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        widget.game.overlays.remove('dialog');
                        await widget.game.reset();
                      },
                      icon: Icon(Icons.refresh, color: neonBlue),
                      label: Text(
                        'Nueva Ronda',
                        style: TextStyle(
                          color: neonBlue,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          shadows: [
                            Shadow(
                              blurRadius: 8,
                              color: neonBlue,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        side: BorderSide(
                          color: neonBlue,
                          width: 2,
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Volver a Tienda
                  if (widget.onReturnToShop != null)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          widget.game.overlays.remove('dialog');
                          widget.onReturnToShop!();
                        },
                        icon: Icon(Icons.shopping_cart, color: neonBlue),
                        label: Text(
                          'Volver a Tienda',
                          style: TextStyle(
                            color: neonBlue,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            shadows: [
                              Shadow(
                                blurRadius: 8,
                                color: neonBlue,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          side: BorderSide(
                            color: neonBlue,
                            width: 2,
                          ),
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(2),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Widget del inventario durante el juego
class _InventoryOverlay extends StatefulWidget {
  final MyPhysicsGame game;

  const _InventoryOverlay({
    required this.game,
  });

  @override
  State<_InventoryOverlay> createState() => _InventoryOverlayState();
}

class _InventoryOverlayState extends State<_InventoryOverlay> {
  @override
  Widget build(BuildContext context) {
    final shopManager = widget.game.shopManager;
    if (shopManager == null) {
      return SizedBox.shrink();
    }

    final inventoryItems = shopManager.getInventoryItems();
    
    // Colores para habilidades (diferente estilo - dorado/amarillo neón)
    final neonYellow = Color(0xFFFFD700);
    final neonYellowGlow = Color(0xFFFFD700).withOpacity(0.6);
    final darkBlue = Color(0xFF001122);
    
    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: neonYellow, width: 3),
            boxShadow: [
              BoxShadow(
                color: neonYellowGlow,
                blurRadius: 25,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con estilo diferente
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      darkBlue,
                      Colors.black,
                    ],
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(9),
                    topRight: Radius.circular(9),
                  ),
                  border: Border(
                    bottom: BorderSide(color: neonYellow, width: 3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: neonYellow, width: 3),
                            color: Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: neonYellowGlow,
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(Icons.bolt, color: neonYellow, size: 32),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'HABILIDADES',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: neonYellow,
                            letterSpacing: 4,
                            shadows: [
                              Shadow(
                                blurRadius: 12,
                                color: neonYellow,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                blurRadius: 24,
                                color: neonYellow,
                                offset: Offset(0, 0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: neonYellow, size: 28),
                      onPressed: () {
                        widget.game.overlays.remove('inventory');
                      },
                    ),
                  ],
                ),
              ),
              
              // Lista de items
              Flexible(
                child: inventoryItems.isEmpty
                    ? Padding(
                        padding: EdgeInsets.all(40),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: neonYellow.withOpacity(0.5),
                                  width: 3,
                                ),
                                color: Colors.black,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: neonYellowGlow,
                                    blurRadius: 15,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.bolt_outlined,
                                size: 64,
                                color: neonYellow.withOpacity(0.7),
                              ),
                            ),
                            SizedBox(height: 20),
                            Text(
                              'No tienes habilidades disponibles',
                              style: TextStyle(
                                fontSize: 18,
                                color: neonYellow.withOpacity(0.9),
                                letterSpacing: 2,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Compra habilidades en la tienda',
                              style: TextStyle(
                                fontSize: 14,
                                color: neonYellow.withOpacity(0.7),
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(16),
                        shrinkWrap: true,
                        itemCount: inventoryItems.length,
                        itemBuilder: (context, index) {
                          final item = inventoryItems[index];
                          return _InventoryItemCard(
                            item: item,
                            onUse: () {
                              if (widget.game.useItem(item.id)) {
                                setState(() {});
                                widget.game.overlays.remove('inventory');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${item.name} usado'),
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InventoryItemCard extends StatelessWidget {
  final ShopItem item;
  final VoidCallback onUse;

  const _InventoryItemCard({
    required this.item,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final neonYellow = Color(0xFFFFD700);
    final neonYellowGlow = Color(0xFFFFD700).withOpacity(0.5);
    final neonOrange = Color(0xFFFF6600);
    final darkBlue = Color(0xFF001122);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              darkBlue,
              Colors.black,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: neonYellow,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: neonYellowGlow,
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono con estilo diferente
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: neonYellow,
                    width: 3,
                  ),
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: neonYellowGlow,
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: neonYellow,
                  size: 32,
                ),
              ),
              SizedBox(width: 16),
              
              // Información
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: neonYellow,
                        letterSpacing: 2,
                        shadows: [
                          Shadow(
                            blurRadius: 8,
                            color: neonYellow,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: neonYellow.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: neonOrange,
                          width: 2,
                        ),
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: neonOrange.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: neonOrange, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'x${item.quantity}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: neonOrange,
                              shadows: [
                                Shadow(
                                  blurRadius: 4,
                                  color: neonOrange,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botón usar con estilo diferente
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: item.quantity > 0 ? onUse : null,
                icon: Icon(Icons.bolt, color: neonYellow, size: 20),
                label: Text(
                  'ACTIVAR',
                  style: TextStyle(
                    color: neonYellow,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    shadows: [
                      Shadow(
                        blurRadius: 6,
                        color: neonYellow,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  side: BorderSide(
                    color: item.quantity > 0 ? neonYellow : Colors.grey.shade700,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}