import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _showShop = true;

  void _startGame(LevelType levelType) {
    setState(() {
      _showShop = false;
      _game = MyPhysicsGame(
        shopManager: _shopManager,
        levelType: levelType,
      );
    });
  }

  void _returnToShop() {
    // Resetear items comprados para el siguiente turno
    _shopManager.resetItemsForNewTurn();
    setState(() {
      _showShop = true;
      _game = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showShop) {
      return ShopScreen(
        shopManager: _shopManager,
        onStartGame: _startGame,
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
                  );
                },
                'inventory': (context, game) {
                  return _InventoryOverlay(
                    game: game as MyPhysicsGame,
                  );
                },
              },
            ),
            // Botón de inventario flotante
            Positioned(
              top: 10,
              left: 10,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    _game?.overlays.add('inventory');
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade700,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.inventory_2, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'INVENTARIO',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
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

class _SaveScoreDialog extends StatefulWidget {
  const _SaveScoreDialog({
    required this.game,
    this.onReturnToShop,
  });

  final MyPhysicsGame game;
  final VoidCallback? onReturnToShop;

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
    
    // Colores neón de los 90s
    final neonBlue = Color(0xFF00FFFF);
    final neonBlueGlow = Color(0xFF00FFFF).withOpacity(0.6);

    return Container(
      color: Colors.black87,
      child: Center(
        child: Container(
          width: 600,
          constraints: BoxConstraints(maxHeight: 500),
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: neonBlue, width: 3),
            boxShadow: [
              BoxShadow(
                color: neonBlueGlow,
                blurRadius: 20,
                spreadRadius: 3,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: neonBlue, width: 2),
                            color: Colors.black,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: neonBlueGlow,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(Icons.inventory_2, color: neonBlue, size: 28),
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
                            'INVENTARIO',
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
                                Shadow(
                                  blurRadius: 20,
                                  color: neonBlue,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: neonBlue),
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
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: neonBlue.withOpacity(0.5),
                                  width: 2,
                                ),
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 64,
                                color: neonBlue.withOpacity(0.6),
                              ),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No tienes items en el inventario',
                              style: TextStyle(
                                fontSize: 18,
                                color: neonBlue.withOpacity(0.8),
                                letterSpacing: 1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Compra items en la tienda antes de jugar',
                              style: TextStyle(
                                fontSize: 14,
                                color: neonBlue.withOpacity(0.6),
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
    final neonBlue = Color(0xFF00FFFF);
    final neonBlueGlow = Color(0xFF00FFFF).withOpacity(0.5);
    final neonGreen = Color(0xFF00FF00);
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: neonBlue,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: neonBlueGlow,
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              // Icono
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: neonBlue,
                    width: 2,
                  ),
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: neonBlueGlow,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(
                  item.icon,
                  color: neonBlue,
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
                        color: neonBlue,
                        letterSpacing: 1,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: neonBlue,
                            offset: Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      item.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: neonBlue.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: neonGreen,
                          width: 1,
                        ),
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: neonGreen.withOpacity(0.5),
                            blurRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        'Cantidad: ${item.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: neonGreen,
                          shadows: [
                            Shadow(
                              blurRadius: 3,
                              color: neonGreen,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Botón usar
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: item.quantity > 0 ? onUse : null,
                icon: Icon(Icons.play_arrow, color: neonGreen),
                label: Text(
                  'USAR',
                  style: TextStyle(
                    color: neonGreen,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                    shadows: [
                      Shadow(
                        blurRadius: 5,
                        color: neonGreen,
                        offset: Offset(0, 0),
                      ),
                    ],
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  side: BorderSide(
                    color: item.quantity > 0 ? neonGreen : Colors.grey.shade700,
                    width: 2,
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
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