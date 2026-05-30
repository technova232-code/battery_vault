import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;

class VaultItem {
  final int? id;
  final String type; // 'photo', 'video', 'file', 'note'
  final String name;
  final String path; // encrypted file path or note content
  final DateTime createdAt;
  final int size;

  VaultItem({
    this.id,
    required this.type,
    required this.name,
    required this.path,
    required this.createdAt,
    this.size = 0,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'name': name,
        'path': path,
        'created_at': createdAt.millisecondsSinceEpoch,
        'size': size,
      };

  factory VaultItem.fromMap(Map<String, dynamic> map) => VaultItem(
        id: map['id'],
        type: map['type'],
        name: map['name'],
        path: map['path'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
        size: map['size'] ?? 0,
      );
}

class VaultService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  static Database? _db;
  static const String _pinKey = 'vault_pin_hash';
  static const String _vaultSetKey = 'vault_is_set';

  // Initialize database
  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  static Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, '.vault', 'vault.db');
    await Directory(p.dirname(path)).create(recursive: true);
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE vault_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            type TEXT NOT NULL,
            name TEXT NOT NULL,
            path TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            size INTEGER DEFAULT 0
          )
        ''');
      },
    );
  }

  // PIN Management
  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin + 'battery_vault_salt_2024');
    return sha256.convert(bytes).toString();
  }

  static Future<bool> isPinSet() async {
    final val = await _secureStorage.read(key: _vaultSetKey);
    return val == 'true';
  }

  static Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _secureStorage.write(key: _pinKey, value: hash);
    await _secureStorage.write(key: _vaultSetKey, value: 'true');
  }

  static Future<bool> verifyPin(String pin) async {
    final storedHash = await _secureStorage.read(key: _pinKey);
    if (storedHash == null) return false;
    return storedHash == _hashPin(pin);
  }

  static Future<bool> changePin(String oldPin, String newPin) async {
    if (!await verifyPin(oldPin)) return false;
    await setPin(newPin);
    return true;
  }

  // Vault directory
  static Future<Directory> get _vaultDir async {
    final dir = await getApplicationDocumentsDirectory();
    final vaultPath = p.join(dir.path, '.vault', 'files');
    final vaultDir = Directory(vaultPath);
    if (!await vaultDir.exists()) {
      await vaultDir.create(recursive: true);
    }
    return vaultDir;
  }

  // Add file to vault (copy & hide)
  static Future<VaultItem?> addFile(File sourceFile, String type) async {
    try {
      final dir = await _vaultDir;
      final ext = p.extension(sourceFile.path);
      final newName = '${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(dir.path, newName);
      await sourceFile.copy(destPath);
      final size = await sourceFile.length();
      final item = VaultItem(
        type: type,
        name: p.basename(sourceFile.path),
        path: destPath,
        createdAt: DateTime.now(),
        size: size,
      );
      final db = await database;
      final id = await db.insert('vault_items', item.toMap());
      return VaultItem(
        id: id,
        type: item.type,
        name: item.name,
        path: item.path,
        createdAt: item.createdAt,
        size: item.size,
      );
    } catch (e) {
      debugPrint('VaultService addFile error: $e');
      return null;
    }
  }

  // Add note
  static Future<VaultItem?> addNote(String title, String content) async {
    try {
      final dir = await _vaultDir;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.txt';
      final file = File(p.join(dir.path, fileName));
      await file.writeAsString(content);
      final item = VaultItem(
        type: 'note',
        name: title.isEmpty ? 'Note' : title,
        path: file.path,
        createdAt: DateTime.now(),
        size: content.length,
      );
      final db = await database;
      final id = await db.insert('vault_items', item.toMap());
      return VaultItem(
        id: id,
        type: item.type,
        name: item.name,
        path: item.path,
        createdAt: item.createdAt,
        size: item.size,
      );
    } catch (e) {
      debugPrint('VaultService addNote error: $e');
      return null;
    }
  }

  // Get all items
  static Future<List<VaultItem>> getAllItems({String? type}) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = type != null
        ? await db.query('vault_items',
            where: 'type = ?', whereArgs: [type], orderBy: 'created_at DESC')
        : await db.query('vault_items', orderBy: 'created_at DESC');
    return maps.map((m) => VaultItem.fromMap(m)).toList();
  }

  // Delete item
  static Future<void> deleteItem(VaultItem item) async {
    final db = await database;
    await db.delete('vault_items', where: 'id = ?', whereArgs: [item.id]);
    final file = File(item.path);
    if (await file.exists()) await file.delete();
  }

  // Get note content
  static Future<String> readNote(String path) async {
    final file = File(path);
    if (await file.exists()) return await file.readAsString();
    return '';
  }

  // Get vault stats
  static Future<Map<String, int>> getStats() async {
    final db = await database;
    final photos =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM vault_items WHERE type='photo'")) ?? 0;
    final videos =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM vault_items WHERE type='video'")) ?? 0;
    final files =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM vault_items WHERE type='file'")) ?? 0;
    final notes =
        Sqflite.firstIntValue(await db.rawQuery("SELECT COUNT(*) FROM vault_items WHERE type='note'")) ?? 0;
    return {
      'photos': photos,
      'videos': videos,
      'files': files,
      'notes': notes,
      'total': photos + videos + files + notes,
    };
  }

  // Get file bytes for display
  static Future<Uint8List?> getFileBytes(String path) async {
    final file = File(path);
    if (await file.exists()) return await file.readAsBytes();
    return null;
  }
}
