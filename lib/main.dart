import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'services/ip_fetcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const WhatsMyIpApp());
}

class WhatsMyIpApp extends StatelessWidget {
  const WhatsMyIpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WhatsMyIP',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const NotificationDialogScreen(),
    );
  }
}

class NotificationDialogScreen extends StatefulWidget {
  final bool autoFetch;
  final IpResult? initialResult;

  const NotificationDialogScreen({
    super.key,
    this.autoFetch = true,
    this.initialResult,
  });

  @override
  State<NotificationDialogScreen> createState() => _NotificationDialogScreenState();
}

class _NotificationDialogScreenState extends State<NotificationDialogScreen> {
  IpResult? _result;
  bool _isLoading = true;
  bool _copied = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialResult != null) {
      _result = widget.initialResult;
      _isLoading = false;
      _copied = true;
    }
    if (widget.autoFetch) {
      _startFetchAndCopy();
    } else {
      _isLoading = false;
    }
  }

  Future<void> _startFetchAndCopy() async {
    // 1. Mostrar la ultima IP guardada de inmediato si existe
    final cached = await IpFetcher.getCachedIp();
    if (cached != null && mounted) {
      setState(() {
        _result = cached;
        _copied = true;
      });
    }

    // 2. Consultar en vivo GitHub y copiar al portapapeles
    final fresh = await IpFetcher.fetchAndCopyIp();
    if (mounted) {
      setState(() {
        _result = fresh;
        _isLoading = false;
        _copied = fresh.isSuccess;
      });
    }
  }

  void _copyAgain() async {
    if (_result != null && _result!.ip.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: _result!.ip));
      try {
        await HapticFeedback.mediumImpact();
      } catch (_) {}
      if (mounted) {
        setState(() => _copied = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('IP ${_result!.ip} copiada'),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _closeApp() {
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    // Fondo transparente con detector de toques para cerrar al tocar fuera
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _closeApp,
        child: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: GestureDetector(
              onTap: () {}, // Evitar que toques dentro de la tarjeta la cierren
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: const Color(0xFF06B6D4).withOpacity(0.45),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 26,
                      offset: const Offset(0, 10),
                    ),
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cabecera tipo Notificacion Android
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.language_rounded,
                            color: Color(0xFF06B6D4),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'WhatsMyIP',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (_copied)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF10B981).withOpacity(0.4),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF10B981),
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Copiada',
                                  style: TextStyle(
                                    color: Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_isLoading) ...[
                          const SizedBox(width: 8),
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF06B6D4)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tarjeta de la IP con toque para copiar
                    InkWell(
                      onTap: _copyAgain,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFF334155),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: SelectableText(
                                _result?.ip ?? 'Obteniendo IP...',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: _result?.isSuccess == false
                                      ? const Color(0xFFF43F5E)
                                      : const Color(0xFF06B6D4),
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Copiar de nuevo',
                              icon: const Icon(
                                Icons.copy_rounded,
                                color: Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: _copyAgain,
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_result != null && _result!.updatedAt.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            size: 12,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Actualizado: ${_result!.updatedAt}',
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 11,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Boton Aceptar que cierra el dialogo y la app
                    SizedBox(
                      height: 44,
                      child: ElevatedButton(
                        key: const Key('btn_aceptar'),
                        onPressed: _closeApp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF06B6D4),
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Aceptar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(
                  begin: -0.6,
                  end: 0,
                  duration: 260.ms,
                  curve: Curves.easeOutCubic,
                ).fadeIn(duration: 220.ms),
          ),
        ),
      ),
    );
  }
}
