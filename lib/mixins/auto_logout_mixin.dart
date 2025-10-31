import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gastos_app/auth/auth_service.dart';

mixin AutoLogoutMixin<T extends StatefulWidget> on State<T> {
  Timer? _inactivityTimer;
  static const Duration _inactivityDuration = Duration(
    minutes: 1,
  ); // 1 minutos de inactividad

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
  }

  @override
  void dispose() {
    _cancelInactivityTimer();
    super.dispose();
  }

  void _startInactivityTimer() {
    _cancelInactivityTimer();
    _inactivityTimer = Timer(_inactivityDuration, () {
      _handleInactivityLogout();
    });
  }

  void _cancelInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = null;
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  Future<void> _handleInactivityLogout() async {
    if (!mounted) return;

    try {
      // Mostrar diálogo de advertencia antes de cerrar sesión
      final shouldLogout = await _showInactivityDialog();

      if (shouldLogout && mounted) {
        await Provider.of<AuthService>(context, listen: false).logout();
        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        }
      } else {
        // Si el usuario cancela, reiniciar el timer
        _resetInactivityTimer();
      }
    } catch (e) {
      print('Error durante logout automático: $e');
    }
  }

  Future<bool> _showInactivityDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return _CountdownDialog();
          },
        ) ??
        true; // Por defecto cerrar sesión si se cierra el diálogo
  }

  // Widget wrapper que detecta interacciones del usuario
  Widget buildWithActivityDetection({required Widget child}) {
    return Listener(
      onPointerDown: (_) => _resetInactivityTimer(),
      onPointerMove: (_) => _resetInactivityTimer(),
      onPointerUp: (_) => _resetInactivityTimer(),
      child: GestureDetector(
        onTap: () => _resetInactivityTimer(),
        onPanUpdate: (_) => _resetInactivityTimer(),
        behavior: HitTestBehavior.translucent,
        child: child,
      ),
    );
  }
}

// Diálogo con countdown para logout automático
class _CountdownDialog extends StatefulWidget {
  @override
  _CountdownDialogState createState() => _CountdownDialogState();
}

class _CountdownDialogState extends State<_CountdownDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  Timer? _countdownTimer;
  int _secondsRemaining = 30;

  @override
  void initState() {
    super.initState();

    // Configurar animación circular
    _animationController = AnimationController(
      duration: const Duration(seconds: 30),
      vsync: this,
    );

    _animation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_animationController);

    // Iniciar countdown
    _startCountdown();
    _animationController.forward();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        timer.cancel();
        // Forzar logout automáticamente
        Navigator.of(context).pop(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Icon(
            Icons.access_time_rounded,
            color: Colors.orange.shade600,
            size: 24,
          ),
          const SizedBox(width: 8),
          const Text(
            'Sesión por expirar',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Tu sesión ha estado inactiva por mucho tiempo.',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Text(
            '¿Deseas continuar o cerrar sesión por seguridad?',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          // Contador circular
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return CircularProgressIndicator(
                      value: _animation.value,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _secondsRemaining > 10
                            ? Colors.orange.shade600
                            : Colors.red.shade600,
                      ),
                    );
                  },
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$_secondsRemaining',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _secondsRemaining > 10
                          ? Colors.orange.shade600
                          : Colors.red.shade600,
                    ),
                  ),
                  Text(
                    'segundos',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'La sesión se cerrará automáticamente al finalizar el contador',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            _countdownTimer?.cancel();
            _animationController.stop();
            Navigator.of(context).pop(false);
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(
            'Continuar',
            style: TextStyle(
              color: Colors.green.shade600,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            _countdownTimer?.cancel();
            _animationController.stop();
            Navigator.of(context).pop(true);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.logout, size: 16),
              const SizedBox(width: 4),
              const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
    );
  }
}
