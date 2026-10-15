import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class IpResult {
  final String ip;
  final String updatedAt;
  final bool isSuccess;
  final String? errorMessage;
  final bool isCached;

  const IpResult({
    required this.ip,
    required this.updatedAt,
    this.isSuccess = true,
    this.errorMessage,
    this.isCached = false,
  });
}

class IpFetcher {
  static const String _repo = 'JulioGL98/current_IP';
  static const String _file = 'IP.txt';

  static const String _cachedIpKey = 'cached_ip';
  static const String _cachedDateKey = 'cached_date';

  /// Carga el token de GitHub desde variables de entorno o assets/config.json
  static Future<String> _getToken() async {
    const fromEnv = String.fromEnvironment('GITHUB_TOKEN');
    if (fromEnv.isNotEmpty) return fromEnv;

    try {
      final content = await rootBundle.loadString('assets/config.json');
      final json = jsonDecode(content) as Map<String, dynamic>;
      return json['github_token'] as String? ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Obtiene la ultima IP guardada en cache local de inmediato
  static Future<IpResult?> getCachedIp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ip = prefs.getString(_cachedIpKey);
      final date = prefs.getString(_cachedDateKey) ?? '';
      if (ip != null && ip.isNotEmpty) {
        return IpResult(ip: ip, updatedAt: date, isCached: true);
      }
    } catch (_) {}
    return null;
  }

  /// Consulta GitHub, copia al portapapeles y vibra
  static Future<IpResult> fetchAndCopyIp({http.Client? client}) async {
    final httpClient = client ?? http.Client();
    final token = await _getToken();

    String? ip;
    String updatedAt = '';

    // 1. Intentar desde GitHub API
    try {
      final uri = Uri.parse('https://api.github.com/repos/$_repo/contents/$_file');
      final headers = <String, String>{
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'WhatsMyIP-App',
        if (token.isNotEmpty) 'Authorization': 'token $token',
      };

      final res = await httpClient.get(uri, headers: headers).timeout(
        const Duration(seconds: 6),
      );

      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final rawContent = json['content'] as String? ?? '';
        final encoding = json['encoding'] as String? ?? '';

        String decodedText = '';
        if (encoding == 'base64' && rawContent.isNotEmpty) {
          final clean = rawContent.replaceAll(RegExp(r'\s+'), '');
          decodedText = utf8.decode(base64.decode(clean));
        }

        if (decodedText.isNotEmpty) {
          final parsed = _parseContent(decodedText);
          ip = parsed.ip;
          updatedAt = parsed.updatedAt;
        }
      }
    } catch (_) {}

    // 2. Fallback publico si GitHub no responde
    if (ip == null || ip.isEmpty) {
      try {
        final res = await httpClient.get(
          Uri.parse('https://api.ipify.org?format=json'),
        ).timeout(const Duration(seconds: 4));

        if (res.statusCode == 200) {
          final json = jsonDecode(res.body) as Map<String, dynamic>;
          ip = json['ip'] as String?;
          updatedAt = DateTime.now().toString().substring(0, 19);
        }
      } catch (_) {}
    }

    if (ip != null && ip.isNotEmpty) {
      // Guardar en cache local
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_cachedIpKey, ip);
        await prefs.setString(_cachedDateKey, updatedAt);
      } catch (_) {}

      // Copiar al portapapeles y dar respuesta haptica
      await Clipboard.setData(ClipboardData(text: ip));
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}

      return IpResult(ip: ip, updatedAt: updatedAt, isSuccess: true);
    }

    // 3. Si fallo la red, usar la ultima conocida
    final cached = await getCachedIp();
    if (cached != null) {
      await Clipboard.setData(ClipboardData(text: cached.ip));
      try {
        await HapticFeedback.lightImpact();
      } catch (_) {}
      return cached;
    }

    return const IpResult(
      ip: 'Sin conexión',
      updatedAt: '',
      isSuccess: false,
      errorMessage: 'No se pudo obtener la IP de GitHub.',
    );
  }

  static ({String ip, String updatedAt}) _parseContent(String text) {
    String foundIp = '';
    String foundDate = '';

    for (final line in text.split('\n')) {
      final t = line.trim();
      if (t.startsWith('IP:')) {
        foundIp = t.substring(3).trim();
      } else if (t.startsWith('Última actualización:') || t.startsWith('Ultima actualizacion:')) {
        final idx = t.indexOf(':');
        if (idx != -1) {
          foundDate = t.substring(idx + 1).trim();
        }
      }
    }

    if (foundIp.isEmpty) {
      final m = RegExp(r'\b(?:\d{1,3}\.){3}\d{1,3}\b').firstMatch(text);
      if (m != null) foundIp = m.group(0)!;
    }

    return (ip: foundIp, updatedAt: foundDate);
  }
}
