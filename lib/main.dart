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
  const MyHomePage({super.key});

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
          ],
        ),
      ),
    );
  }
}
