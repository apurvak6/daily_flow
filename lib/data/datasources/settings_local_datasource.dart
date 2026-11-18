import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/utils/app_logger.dart';

/// Contract for persistent settings data access using SQLite.
abstract class SettingsLocalDataSource {
  Future<String?> getSetting(String key);
  Future<void> setSetting(String key, String value);
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
}

/// Implementation of [SettingsLocalDataSource] backed by the SQLite `app_settings` table.
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final DatabaseHelper _dbHelper;

  SettingsLocalDataSourceImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<String?> getSetting(String key) async {
    try {
      final db = await _dbHelper.database;
      final results = await db.query(
        DbConstants.tableAppSettings,
        columns: [DbConstants.colSettingValue],
        where: '${DbConstants.colSettingKey} = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (results.isNotEmpty) {
        return results.first[DbConstants.colSettingValue] as String?;
      }
      return null;
    } catch (e, stack) {
      AppLogger.error(
        'Error fetching setting $key',
        e,
        stack,
        'SettingsLocalDataSource',
      );
      return null;
    }
  }

  @override
  Future<void> setSetting(String key, String value) async {
    try {
      final db = await _dbHelper.database;
      await db.insert(DbConstants.tableAppSettings, {
        DbConstants.colSettingKey: key,
        DbConstants.colSettingValue: value,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e, stack) {
      AppLogger.error(
        'Error setting $key to $value',
        e,
        stack,
        'SettingsLocalDataSource',
      );
      rethrow;
    }
  }

  @override
  Future<ThemeMode> getThemeMode() async {
    final value = await getSetting(DbConstants.prefThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  @override
  Future<void> setThemeMode(ThemeMode mode) async {
    await setSetting(DbConstants.prefThemeMode, mode.name);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    final value = await getSetting(DbConstants.prefNotifications);
    if (value == null) return true;
    return value == '1' || value == 'true';
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await setSetting(DbConstants.prefNotifications, enabled ? '1' : '0');
  }
}
