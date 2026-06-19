// lib/services/update_service.dart
// GitHub-based update checker and installer — translated from UpdateService.swift

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

// ─── Version ──────────────────────────────────────────────────────────────────

class AppVersion implements Comparable<AppVersion> {
  final int major, minor, patch;
  AppVersion(this.major, this.minor, this.patch);

  static AppVersion? parse(String s) {
    final clean = s.replaceAll(RegExp(r'^v'), '');
    final parts = clean.split('.').map(int.tryParse).toList();
    if (parts.length != 3 || parts.any((p) => p == null)) return null;
    return AppVersion(parts[0]!, parts[1]!, parts[2]!);
  }

  @override
  int compareTo(AppVersion other) {
    if (major != other.major) return major.compareTo(other.major);
    if (minor != other.minor) return minor.compareTo(other.minor);
    return patch.compareTo(other.patch);
  }

  bool operator >(AppVersion other) => compareTo(other) > 0;
  @override
  String toString() => '$major.$minor.$patch';
}

// ─── Manifest ─────────────────────────────────────────────────────────────────

class VersionManifest {
  final String version;
  final String url;
  final String notes;
  VersionManifest(
      {required this.version, required this.url, required this.notes});

  factory VersionManifest.fromJson(Map<String, dynamic> j) => VersionManifest(
        version: j['version'] as String,
        url: j['url'] as String,
        notes: j['notes'] as String? ?? '',
      );
}

// ─── Update state ─────────────────────────────────────────────────────────────

enum UpdateStateKind {
  idle,
  checking,
  upToDate,
  available,
  downloading,
  readyToInstall,
  error
}

class UpdateState {
  final UpdateStateKind kind;
  final VersionManifest? manifest;
  final double downloadProgress;
  final String? zipPath;
  final String? errorMessage;

  const UpdateState._({
    required this.kind,
    this.manifest,
    this.downloadProgress = 0,
    this.zipPath,
    this.errorMessage,
  });

  static const idle = UpdateState._(kind: UpdateStateKind.idle);
  static const checking = UpdateState._(kind: UpdateStateKind.checking);
  static const upToDate = UpdateState._(kind: UpdateStateKind.upToDate);

  static UpdateState available(VersionManifest m) =>
      UpdateState._(kind: UpdateStateKind.available, manifest: m);

  static UpdateState downloading(double p) =>
      UpdateState._(kind: UpdateStateKind.downloading, downloadProgress: p);

  static UpdateState readyToInstall(String path) =>
      UpdateState._(kind: UpdateStateKind.readyToInstall, zipPath: path);

  static UpdateState error(String msg) =>
      UpdateState._(kind: UpdateStateKind.error, errorMessage: msg);
}

// ─── Service ──────────────────────────────────────────────────────────────────

class UpdateService extends ChangeNotifier {
  static const manifestUrl =
      'https://raw.githubusercontent.com/vibeproductions/GoalKeeper/main/version_flutter.json';

  UpdateState state = UpdateState.idle;

  String get currentVersion {
    // In a real app, read from pubspec or a generated file.
    // For now, hardcode and update with each release.
    return '1.1.5';
  }

  // ── Check for updates ──────────────────────────────────────────────────────
  Future<void> checkForUpdates() async {
    state = UpdateState.checking;
    notifyListeners();
    try {
      final response = await http
          .get(Uri.parse(manifestUrl))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        state = UpdateState.error(
            'Could not reach update server (${response.statusCode})');
        notifyListeners();
        return;
      }
      final manifest = VersionManifest.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>);
      final remote = AppVersion.parse(manifest.version);
      final local = AppVersion.parse(currentVersion);
      if (remote == null || local == null) {
        state = UpdateState.error('Could not parse version numbers.');
        notifyListeners();
        return;
      }
      state = remote > local
          ? UpdateState.available(manifest)
          : UpdateState.upToDate;
    } catch (e) {
      state = UpdateState.error(e.toString());
    }
    notifyListeners();
  }

  // ── Download ───────────────────────────────────────────────────────────────
  Future<void> downloadUpdate(String url) async {
    state = UpdateState.downloading(0);
    notifyListeners();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await request.send();

      if (response.statusCode != 200) {
        state = UpdateState.error('Download failed (${response.statusCode})');
        notifyListeners();
        return;
      }

      final tmp = await getTemporaryDirectory();
      final zipPath = p.join(tmp.path, 'GoalKeeper_update.zip');
      final file = File(zipPath);
      final sink = file.openWrite();
      final total = response.contentLength ?? 0;
      var received = 0;

      await response.stream.forEach((chunk) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) {
          state = UpdateState.downloading(received / total);
          notifyListeners();
        }
      });

      await sink.close();
      state = UpdateState.readyToInstall(zipPath);
    } catch (e) {
      state = UpdateState.error(e.toString());
    }
    notifyListeners();
  }

  // ── Install ────────────────────────────────────────────────────────────────
  Future<void> installUpdate(String zipPath) async {
    try {
      final tmp = await getTemporaryDirectory();
      final extractDir = Directory(p.join(tmp.path, 'GoalKeeper_extracted'));
      if (await extractDir.exists()) await extractDir.delete(recursive: true);
      await extractDir.create(recursive: true);

      // Unzip
      final result =
          await Process.run('unzip', ['-q', zipPath, '-d', extractDir.path]);
      if (result.exitCode != 0) {
        throw Exception('Unzip failed: ${result.stderr}');
      }

      // Find the .app (macOS) or .exe (Windows)
      final appPath = await _findApp(extractDir);
      if (appPath == null) throw Exception('Could not find app inside ZIP.');

      // Current app location
      final currentApp = File(Platform.resolvedExecutable).parent.parent.path;

      // Replace
      if (Platform.isMacOS) {
        await Process.run('cp', ['-R', appPath, currentApp]);
      } else if (Platform.isWindows) {
        // On Windows, copy alongside and run installer
        await Process.run('xcopy', [appPath, currentApp, '/E', '/Y']);
      }

      // Clean up
      await File(zipPath).delete();
      await extractDir.delete(recursive: true);

      // Relaunch
      await Future.delayed(const Duration(seconds: 1));
      await Process.start(Platform.resolvedExecutable, []);
      exit(0);
    } catch (e) {
      state = UpdateState.error('Install failed: $e');
      notifyListeners();
    }
  }

  Future<String?> _findApp(Directory dir) async {
    await for (final entity in dir.list(recursive: true)) {
      if (Platform.isMacOS && entity.path.endsWith('.app')) return entity.path;
      if (Platform.isWindows && entity.path.endsWith('goalkeeper.exe')) {
        return entity.path;
      }
    }
    return null;
  }

  void cancelDownload() {
    state = UpdateState.idle;
    notifyListeners();
  }
}
