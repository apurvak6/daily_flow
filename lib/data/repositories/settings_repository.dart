import 'package:flutter/material.dart';
import '../datasources/settings_local_datasource.dart';

/// Repository interface governing application settings and preferences.
abstract class SettingsRepository {
  Future<ThemeMode> getThemeMode();
  Future<void> setThemeMode(ThemeMode mode);
  Future<bool> areNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
}

/// Implementation of [SettingsRepository] bridging ViewModels to [SettingsLocalDataSource].
class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _dataSource;

  SettingsRepositoryImpl({SettingsLocalDataSource? dataSource})
    : _dataSource = dataSource ?? SettingsLocalDataSourceImpl();

  @override
  Future<ThemeMode> getThemeMode() => _dataSource.getThemeMode();

  @override
  Future<void> setThemeMode(ThemeMode mode) => _dataSource.setThemeMode(mode);

  @override
  Future<bool> areNotificationsEnabled() =>
      _dataSource.getNotificationsEnabled();

  @override
  Future<void> setNotificationsEnabled(bool enabled) =>
      _dataSource.setNotificationsEnabled(enabled);
}
