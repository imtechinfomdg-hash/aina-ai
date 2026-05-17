import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/child_model.dart';
import '../models/constante_model.dart';
import '../models/vaccine_model.dart';
import '../models/medication_reminder_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;
  
  // Mocks en mémoire pour le Web
  final List<ChildModel> _mockChildren = [];
  final List<ConstanteModel> _mockConstantes = [];
  final List<VaccineModel> _mockVaccines = [];
  final List<MedicationReminderModel> _mockReminders = [];
  int _mockIdCounter = 1;

  DatabaseHelper._init() {
    if (kIsWeb) {
      _seedMockData();
    }
  }

  void _seedMockData() {
    final now = DateTime.now();
    
    // Baby 1: Koto
    final koto = ChildModel(
      id: _mockIdCounter++,
      firstName: 'Koto',
      birthDate: now.subtract(const Duration(days: 180)).toIso8601String(),
      gender: 'Garçon',
      weight: 7.5,
      height: 68.0,
    );
    _mockChildren.add(koto);
    _mockConstantes.add(ConstanteModel(
      id: _mockIdCounter++,
      enfantId: koto.id!,
      date: now.toIso8601String(),
      poids: 7.5,
      taille: 68.0,
      temperature: 37.1,
      perimetreBrachial: 14.5,
    ));

    // Baby 2: Soa
    final soa = ChildModel(
      id: _mockIdCounter++,
      firstName: 'Soa',
      birthDate: now.subtract(const Duration(days: 540)).toIso8601String(),
      gender: 'Fille',
      weight: 10.2,
      height: 82.0,
    );
    _mockChildren.add(soa);
    _mockConstantes.add(ConstanteModel(
      id: _mockIdCounter++,
      enfantId: soa.id!,
      date: now.subtract(const Duration(days: 1)).toIso8601String(),
      poids: 10.2,
      taille: 82.0,
      temperature: 38.5,
      perimetreBrachial: 15.0,
    ));
    _mockReminders.add(MedicationReminderModel(
      id: _mockIdCounter++,
      enfantId: soa.id!,
      medName: 'Paracétamol',
      dosage: '10 ml',
      time: '08:00',
      isActive: true,
    ));

    // Baby 3: Rina
    final rina = ChildModel(
      id: _mockIdCounter++,
      firstName: 'Rina',
      birthDate: now.subtract(const Duration(days: 730)).toIso8601String(),
      gender: 'Garçon',
      weight: 9.0,
      height: 85.0,
      temperature: 36.8,
    );
    _mockChildren.add(rina);
    _mockConstantes.add(ConstanteModel(
      id: _mockIdCounter++,
      enfantId: rina.id!,
      date: now.subtract(const Duration(days: 30)).toIso8601String(),
      poids: 8.8,
      taille: 84.5,
      temperature: 36.8,
      perimetreBrachial: 11.5,
    ));
    _mockConstantes.add(ConstanteModel(
      id: _mockIdCounter++,
      enfantId: rina.id!,
      date: now.toIso8601String(),
      poids: 9.0,
      taille: 85.0,
      temperature: 36.9,
      perimetreBrachial: 12.0,
    ));
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('aina_local.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const textNullType = 'TEXT';
    const realType = 'REAL';
    const integerType = 'INTEGER NOT NULL';
    const integerNullType = 'INTEGER';
    const boolType = 'INTEGER NOT NULL';

    // Table pour la fratrie
    await db.execute('''
CREATE TABLE children (
  id $idType,
  firstName $textType,
  birthDate $textType,
  gender $textType,
  weight $realType,
  height $realType
)
''');

    // Table pour les constantes de santé
    await db.execute('''
CREATE TABLE constantes (
  id $idType,
  enfantId $integerType,
  date $textType,
  poids $realType,
  taille $realType,
  temperature $realType,
  perimetre_brachial $realType,
  FOREIGN KEY (enfantId) REFERENCES children (id) ON DELETE CASCADE
)
''');

    // Table pour le suivi des vaccins
    await db.execute('''
CREATE TABLE vaccines (
  id $idType,
  enfantId $integerType,
  vaccineKey $textType,
  vaccineName $textType,
  datePlanned $textType,
  dateAdministered $textNullType,
  isCompleted $boolType,
  FOREIGN KEY (enfantId) REFERENCES children (id) ON DELETE CASCADE
)
''');

    // Table pour les rappels de médicaments
    await db.execute('''
CREATE TABLE rappels_medicaments (
  id $idType,
  enfantId $integerType,
  medName $textType,
  dosage $textType,
  time $textType,
  isActive $boolType,
  FOREIGN KEY (enfantId) REFERENCES children (id) ON DELETE CASCADE
)
''');

    // Seeding with default data
    await _seedInitialData(db);
  }

  Future<void> _seedInitialData(Database db) async {
    final now = DateTime.now();
    
    // Baby 1: Koto (Garçon, 6 mois)
    final kotoId = await db.insert('children', {
      'firstName': 'Koto',
      'birthDate': now.subtract(const Duration(days: 180)).toIso8601String(),
      'gender': 'Garçon',
      'weight': 7.5,
      'height': 68.0,
    });
    await db.insert('constantes', {
      'enfantId': kotoId,
      'date': now.toIso8601String(),
      'poids': 7.5,
      'taille': 68.0,
      'temperature': 37.1,
      'perimetre_brachial': 14.5,
    });
    
    // Baby 2: Soa (Fille, 18 mois, fièvre hier)
    final soaId = await db.insert('children', {
      'firstName': 'Soa',
      'birthDate': now.subtract(const Duration(days: 540)).toIso8601String(),
      'gender': 'Fille',
      'weight': 10.2,
      'height': 82.0,
    });
    await db.insert('constantes', {
      'enfantId': soaId,
      'date': now.subtract(const Duration(days: 1)).toIso8601String(),
      'poids': 10.2,
      'taille': 82.0,
      'temperature': 38.5,
      'perimetre_brachial': 15.0,
    });
    await db.insert('rappels_medicaments', {
      'enfantId': soaId,
      'medName': 'Paracétamol',
      'dosage': '10 ml',
      'time': '08:00',
      'isActive': 1,
    });
    
    // Baby 3: Rina (Garçon, 2 ans, suivi malnutrition)
    final rinaId = await db.insert('children', {
      'firstName': 'Rina',
      'birthDate': now.subtract(const Duration(days: 730)).toIso8601String(),
      'gender': 'Garçon',
      'weight': 9.0, // Faible
      'height': 85.0,
      'temperature': 36.8,
    });
    await db.insert('constantes', {
      'enfantId': rinaId,
      'date': now.subtract(const Duration(days: 30)).toIso8601String(),
      'poids': 8.8,
      'taille': 84.5,
      'temperature': 36.8,
      'perimetre_brachial': 11.5, // Rouge (malnutrition sévère)
    });
    await db.insert('constantes', {
      'enfantId': rinaId,
      'date': now.toIso8601String(),
      'poids': 9.0,
      'taille': 85.0,
      'temperature': 36.9,
      'perimetre_brachial': 12.0, // Jaune (malnutrition modérée)
    });
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const realType = 'REAL';
      const integerType = 'INTEGER NOT NULL';
      
      await db.execute('''
CREATE TABLE constantes (
  id $idType,
  enfantId $integerType,
  date $textType,
  poids $realType,
  taille $realType,
  temperature $realType,
  FOREIGN KEY (enfantId) REFERENCES children (id) ON DELETE CASCADE
)
''');
    }
    if (oldVersion < 3) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const textNullType = 'TEXT';
      const integerType = 'INTEGER NOT NULL';
      const boolType = 'INTEGER NOT NULL';
      
      await db.execute('''
CREATE TABLE vaccines (
  id $idType,
  enfantId $integerType,
  vaccineKey $textType,
  vaccineName $textType,
  datePlanned $textType,
  dateAdministered $textNullType,
  isCompleted $boolType,
  FOREIGN KEY (enfantId) REFERENCES children (id) ON DELETE CASCADE
)
''');
    }
    if (oldVersion < 4) {
      const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
      const textType = 'TEXT NOT NULL';
      const integerType = 'INTEGER NOT NULL';
      const boolType = 'INTEGER NOT NULL';
      
      await db.execute('''
CREATE TABLE rappels_medicaments (
  id $idType,
  enfantId $integerType,
  medName $textType,
  dosage $textType,
  time $textType,
  isActive $boolType,
  FOREIGN KEY (enfantId) REFERENCES children (id) ON DELETE CASCADE
)
''');
    }
    if (oldVersion < 6) {
      await db.execute('ALTER TABLE constantes ADD COLUMN perimetre_brachial REAL;');
    }
  }

  // === Méthodes CRUD pour ChildModel ===

  Future<int> createChild(ChildModel child) async {
    if (kIsWeb) {
      final newChild = ChildModel(id: _mockIdCounter++, firstName: child.firstName, birthDate: child.birthDate, gender: child.gender, weight: child.weight, height: child.height);
      _mockChildren.add(newChild);
      return newChild.id!;
    }
    final db = await instance.database;
    return await db.insert('children', child.toMap());
  }

  Future<List<ChildModel>> readAllChildren() async {
    if (kIsWeb) return _mockChildren;
    final db = await instance.database;
    final result = await db.query('children', orderBy: 'firstName ASC');
    return result.map((json) => ChildModel.fromMap(json)).toList();
  }

  Future<ChildModel?> getChild(int id) async {
    if (kIsWeb) {
      try {
        return _mockChildren.firstWhere((c) => c.id == id);
      } catch (e) {
        return null;
      }
    }
    final db = await instance.database;
    final maps = await db.query(
      'children',
      columns: null,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return ChildModel.fromMap(maps.first);
    } else {
      return null;
    }
  }

  Future<int> updateChild(ChildModel child) async {
    if (kIsWeb) {
      final index = _mockChildren.indexWhere((c) => c.id == child.id);
      if (index != -1) _mockChildren[index] = child;
      return 1;
    }
    final db = await instance.database;
    return db.update(
      'children',
      child.toMap(),
      where: 'id = ?',
      whereArgs: [child.id],
    );
  }

  Future<int> deleteChild(int id) async {
    if (kIsWeb) {
      _mockChildren.removeWhere((c) => c.id == id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'children',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Méthodes CRUD pour ConstanteModel ===

  Future<int> addConstante(ConstanteModel constante) async {
    if (kIsWeb) {
      final newConst = ConstanteModel(
        id: _mockIdCounter++, 
        enfantId: constante.enfantId, 
        date: constante.date, 
        poids: constante.poids, 
        taille: constante.taille, 
        temperature: constante.temperature,
        perimetreBrachial: constante.perimetreBrachial,
      );
      _mockConstantes.add(newConst);
      return newConst.id!;
    }
    final db = await instance.database;
    return await db.insert('constantes', constante.toMap());
  }

  Future<List<ConstanteModel>> getConstantesForChild(int enfantId) async {
    if (kIsWeb) {
      final list = _mockConstantes.where((c) => c.enfantId == enfantId).toList();
      list.sort((a, b) => a.date.compareTo(b.date));
      return list;
    }
    final db = await instance.database;
    final result = await db.query(
      'constantes',
      where: 'enfantId = ?',
      whereArgs: [enfantId],
      orderBy: 'date ASC',
    );
    return result.map((json) => ConstanteModel.fromMap(json)).toList();
  }

  Future<int> deleteConstante(int id) async {
    if (kIsWeb) {
      _mockConstantes.removeWhere((c) => c.id == id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'constantes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // === Méthodes CRUD pour VaccineModel ===

  Future<int> addVaccine(VaccineModel vaccine) async {
    if (kIsWeb) {
      final newVac = VaccineModel(id: _mockIdCounter++, enfantId: vaccine.enfantId, vaccineKey: vaccine.vaccineKey, vaccineName: vaccine.vaccineName, datePlanned: vaccine.datePlanned, dateAdministered: vaccine.dateAdministered, isCompleted: vaccine.isCompleted);
      _mockVaccines.add(newVac);
      return newVac.id!;
    }
    final db = await instance.database;
    return await db.insert('vaccines', vaccine.toMap());
  }

  Future<List<VaccineModel>> getVaccinesForChild(int enfantId) async {
    if (kIsWeb) {
      final list = _mockVaccines.where((v) => v.enfantId == enfantId).toList();
      list.sort((a, b) => a.datePlanned.compareTo(b.datePlanned));
      return list;
    }
    final db = await instance.database;
    final result = await db.query(
      'vaccines',
      where: 'enfantId = ?',
      whereArgs: [enfantId],
      orderBy: 'datePlanned ASC',
    );
    return result.map((json) => VaccineModel.fromMap(json)).toList();
  }

  Future<int> updateVaccine(VaccineModel vaccine) async {
    if (kIsWeb) {
      final index = _mockVaccines.indexWhere((v) => v.id == vaccine.id);
      if (index != -1) _mockVaccines[index] = vaccine;
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'vaccines',
      vaccine.toMap(),
      where: 'id = ?',
      whereArgs: [vaccine.id],
    );
  }

  // === Méthodes CRUD pour MedicationReminderModel ===

  Future<int> addReminder(MedicationReminderModel reminder) async {
    if (kIsWeb) {
      final newRem = reminder.copyWith(id: _mockIdCounter++);
      _mockReminders.add(newRem);
      return newRem.id!;
    }
    final db = await instance.database;
    return await db.insert('rappels_medicaments', reminder.toMap());
  }

  Future<List<MedicationReminderModel>> getRemindersForChild(int enfantId) async {
    if (kIsWeb) {
      final list = _mockReminders.where((r) => r.enfantId == enfantId).toList();
      list.sort((a, b) => a.time.compareTo(b.time));
      return list;
    }
    final db = await instance.database;
    final result = await db.query(
      'rappels_medicaments',
      where: 'enfantId = ?',
      whereArgs: [enfantId],
      orderBy: 'time ASC',
    );
    return result.map((json) => MedicationReminderModel.fromMap(json)).toList();
  }

  Future<int> updateReminder(MedicationReminderModel reminder) async {
    if (kIsWeb) {
      final index = _mockReminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) _mockReminders[index] = reminder;
      return 1;
    }
    final db = await instance.database;
    return await db.update(
      'rappels_medicaments',
      reminder.toMap(),
      where: 'id = ?',
      whereArgs: [reminder.id],
    );
  }

  Future<int> deleteReminder(int id) async {
    if (kIsWeb) {
      _mockReminders.removeWhere((r) => r.id == id);
      return 1;
    }
    final db = await instance.database;
    return await db.delete(
      'rappels_medicaments',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    if (kIsWeb) return;
    final db = await instance.database;
    db.close();
  }
}
