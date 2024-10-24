import 'dart:math';

import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Babs Aquarium',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Babs Aquarium'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required String title});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class Fish {
  Color color;
  double speed;

  Fish({required this.color, required this.speed});
}

class _MyHomePageState extends State<MyHomePage> {
List<Fish> fishList = [];
Color selectedColor = Colors.blue;
double selectedSpeed = 1.0;
Database? database;

@override
  void initState() {
    super.initState();
    initDatabase();
  }

  Future<void> initDatabase() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'aquarium.db'),
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE settings(id INTEGER PRIMARY KEY, fishCount INTEGER, speed REAL, color TEXT)",
        );
      },
      version: 1,
    );
    loadSettings();
  }

   Future<void> loadSettings() async {
    final List<Map<String, dynamic>> maps = await database!.query('settings');
    if (maps.isNotEmpty) {
      var savedSettings = maps[0];
      setState(() {
        fishList = List.generate(savedSettings['fishCount'], (_) => Fish(color: selectedColor, speed: selectedSpeed));
        selectedSpeed = savedSettings['speed'];
        selectedColor = Color(int.parse(savedSettings['color']));
      });
    }
  }

 Future<void> saveSettings() async {
    await database!.insert(
      'settings',
      {
        'fishCount': fishList.length,
        'speed': selectedSpeed,
        'color': selectedColor.value.toString(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  void addFish() {
    if (fishList.length < 10) {
      setState(() {
        fishList.add(Fish(color: selectedColor, speed: selectedSpeed));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
             Container(
              width: 300,
              height: 300,
               decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('underthesea.jpg'),
                  fit: BoxFit.cover,
                ),
               ),
               child: Stack(
                children: fishList.map((fish) => FishWidget(fish: fish)).toList(),
              ),
             ),
              Row(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   ElevatedButton(
                  onPressed: addFish,
                  child: const Text("Add Fish"),
                      ),
                   ElevatedButton(
                  onPressed: saveSettings,
                  child: const Text("Save Settings"),
                      ),
                  ],
              ),
              Slider(
                value: selectedSpeed,
                min: 0.5,
                max: 3.0,
                divisions: 5,
                label: selectedSpeed.toString(),
                onChanged: (value) {
                setState(() {
                  selectedSpeed = value;
                });
              },
            ),
             DropdownButton<Color>(
              value: selectedColor,
              items: <Color>[Colors.blue, Colors.red, Colors.green, Colors.yellow]
                  .map<DropdownMenuItem<Color>>((Color value) {
                return DropdownMenuItem<Color>(
                  value: value,
                  child: Container(
                    width: 24,
                    height: 24,
                    color: value,
                  ),
                );
              }).toList(),
              onChanged: (Color? newValue) {
                setState(() {
                  selectedColor = newValue!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
class FishWidget extends StatefulWidget {
  final Fish fish;

  const FishWidget({super.key, required this.fish});

  @override
  _FishWidgetState createState() => _FishWidgetState();
}

class _FishWidgetState extends State<FishWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: (4 / widget.fish.speed).round()),
      vsync: this,
    );

    final random = Random();
    _animation = Tween<Offset>(
      begin: Offset(random.nextDouble(), random.nextDouble()),
      end: Offset(random.nextDouble(), random.nextDouble()),
    ).animate(_controller);

    _controller.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          left: _animation.value.dx * 300,
          top: _animation.value.dy * 300,
          child: Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.fish.color,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}