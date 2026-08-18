import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/athlete.dart';
import 'database_service.dart';

class PhotoSyncService {
  static const String _supabaseUrl = 'https://lptfwohfngjrondbzmjj.supabase.co';
  static const String _supabaseKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxwdGZ3b2hmbmdqcm9uZGJ6bWpqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTY1NjM3NTIsImV4cCI6MjA3MjEzOTc1Mn0.q6BA8hNrgxZDuCzox8dy_j_MUstrtkJexLs59Fbon5g';

  final DatabaseService _db = DatabaseService();

  /// Fetch photos from Supabase and save to local storage.
  /// Matches athletes by name (case-insensitive).
  /// Only fetches for athletes that don't already have a local photo.
  Future<int> syncPhotos() async {
    try {
      // 1. Get local athletes without photos
      final localAthletes = await _db.getAllAthletes();
      final needPhoto = localAthletes.where((a) =>
        a.photoPath == null || a.photoPath!.isEmpty
      ).toList();

      if (needPhoto.isEmpty) return 0;

      // 2. Fetch profiles from Supabase (without avatar to keep response small)
      final profiles = await _fetchProfileNames();
      if (profiles.isEmpty) return 0;

      // 3. Build name lookup: normalized name -> profile
      final profileMap = <String, Map<String, dynamic>>{};
      for (final p in profiles) {
        final name = _buildName(p['first_name'], p['last_name']);
        profileMap[name] = p;
      }

      // 4. Match and download
      final photosDir = await _getPhotosDir();
      int synced = 0;

      for (final athlete in needPhoto) {
        final normalizedName = _normalizeName(athlete.name);
        final match = profileMap[normalizedName];
        if (match == null) continue;

        // Fetch avatar for this profile
        final avatarData = await _fetchAvatar(match['id']);
        if (avatarData == null || avatarData.isEmpty) continue;

        // Decode and save
        final bytes = await _decodeBase64Image(avatarData);
        if (bytes == null || bytes.isEmpty) continue;

        final filename = 'athlete_${athlete.id}_${_safeFilename(athlete.name)}.jpg';
        final file = File(p.join(photosDir.path, filename));
        await file.writeAsBytes(bytes);

        // Update local DB
        await _db.updateAthletePhoto(athlete.id!, file.path);
        synced++;
      }

      return synced;
    } catch (e) {
      return 0;
    }
  }

  // ─── Supabase REST API calls ────────────────────────────────

  Future<List<Map<String, dynamic>>> _fetchProfileNames() async {
    final url = '$_supabaseUrl/rest/v1/profiles?select=id,first_name,last_name';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      },
    );

    if (response.statusCode != 200) return [];
    final List data = jsonDecode(response.body);
    return data.cast<Map<String, dynamic>>();
  }

  Future<String?> _fetchAvatar(String profileId) async {
    final url = '$_supabaseUrl/rest/v1/profiles?id=eq.$profileId&select=avatar_url';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'apikey': _supabaseKey,
        'Authorization': 'Bearer $_supabaseKey',
      },
    );

    if (response.statusCode != 200) return null;
    final List data = jsonDecode(response.body);
    if (data.isEmpty) return null;

    final avatar = data[0]['avatar_url'] as String?;
    if (avatar == null || avatar.isEmpty) return null;
    return avatar;
  }

  // ─── Helpers ─────────────────────────────────────────────────

  String _buildName(String? first, String? last) {
    return _normalizeName('${first ?? ''} ${last ?? ''}'.trim());
  }

  String _normalizeName(String name) {
    return name
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _safeFilename(String name) {
    return name.replaceAll(RegExp(r'[^\w]'), '_');
  }

  Future<Directory> _getPhotosDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final photosDir = Directory(p.join(dir.path, 'photos'));
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    return photosDir;
  }

  /// Decode base64 data URI, skipping the header.
  /// Supports both "data:image/...;base64,..." and raw base64.
  Uint8List? _decodeBase64Image(String data) {
    try {
      String base64Str = data;

      // Strip data URI header if present
      final commaIndex = data.indexOf(',');
      if (commaIndex != -1 && data.startsWith('data:')) {
        base64Str = data.substring(commaIndex + 1);
      }

      return base64Decode(base64Str);
    } catch (_) {
      return null;
    }
  }
}
