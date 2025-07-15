import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/note.dart';

class DBHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    return openDatabase(
      join(dbPath, 'smart_daily.db'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            description TEXT,
            category TEXT,
            date TEXT,
            time TEXT,
            isCompleted INTEGER,
            reminder INTEGER
          )
        ''');
        await db.execute('''
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT,
            content TEXT,
            dateCreated TEXT
          )
        ''');
      },
      version: 1,
    );
  }

  // Task CRUD
  static Future<int> insertTask(Task task) async {
    final db = await database;
    return db.insert('tasks', {
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'date': task.date.toIso8601String(),
      'time': '${task.time.hour}:${task.time.minute}',
      'isCompleted': task.isCompleted ? 1 : 0,
      'reminder': task.reminder ? 1 : 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getTasks() async {
    final db = await database;
    return db.query('tasks');
  }

  static Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update('tasks', {
      'title': task.title,
      'description': task.description,
      'category': task.category,
      'date': task.date.toIso8601String(),
      'time': '${task.time.hour}:${task.time.minute}',
      'isCompleted': task.isCompleted ? 1 : 0,
      'reminder': task.reminder ? 1 : 0,
    }, where: 'id = ?', whereArgs: [task.id]);
  }

  static Future<int> deleteTask(int id) async {
    final db = await database;
    return db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Note CRUD
  static Future<int> insertNote(Note note) async {
    final db = await database;
    return db.insert('notes', {
      'title': note.title,
      'content': note.content,
      'dateCreated': note.dateCreated.toIso8601String(),
    });
  }

  static Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    return db.query('notes');
  }

  static Future<int> updateNote(Note note) async {
    final db = await database;
    return db.update('notes', {
      'title': note.title,
      'content': note.content,
      'dateCreated': note.dateCreated.toIso8601String(),
    }, where: 'id = ?', whereArgs: [note.id]);
  }

  static Future<int> deleteNote(int id) async {
    final db = await database;
    return db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
} 