import 'package:flutter/material.dart';
import '../l10n/app_strings.dart';

/// Özel loading overlay widget'ı
/// Analiz yapılırken gösterilecek animasyonlu loading ekranı
/// [steps] ile adım listesi, [currentStep] ile aktif adım,
/// [onCancel] ile iptal butonu desteklenir.
class LoadingOverlay extends StatelessWidget {
  final String message;
  final bool isLoading;
  final VoidCallback? onCancel;
  final List<String>? steps;
  final int currentStep;

  const LoadingOverlay({
    super.key,
    this.message = 'Analiz yapılıyor...',
    required this.isLoading,
    this.onCancel,
    this.steps,
    this.currentStep = 0,
  });

  Widget _buildStepItem(int index, String stepText) {
    final isDone = index < currentStep;
    final isActive = index == currentStep;

    Widget icon;
    if (isDone) {
      icon = Icon(Icons.check_circle_rounded, color: Colors.green[600], size: 20);
    } else if (isActive) {
      icon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
        ),
      );
    } else {
      icon = Icon(Icons.radio_button_unchecked, color: Colors.grey[400], size: 20);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              stepText,
              style: TextStyle(
                fontSize: 13,
                color: isDone
                    ? Colors.grey[500]
                    : isActive
                        ? Colors.black87
                        : Colors.grey[400],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                decoration: isDone ? TextDecoration.lineThrough : null,
                decorationColor: Colors.grey[400],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoading) return const SizedBox.shrink();

    return ValueListenableBuilder<String>(
      valueListenable: languageNotifier,
      builder: (context, _, __) => Container(
        color: Colors.black.withOpacity(0.7),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 32, 32, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animasyonlu loading indicator
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Dış daire (dönen)
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            strokeWidth: 4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.orange[600]!,
                            ),
                            backgroundColor: Colors.orange[100],
                          ),
                        ),
                        // İç ikon
                        Icon(
                          Icons.architecture,
                          size: 40,
                          color: Colors.orange[600],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Ana mesaj
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t('loading_please_wait'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // ── Adım göstergeleri ──────────────────────────────────
                  if (steps != null && steps!.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Divider(color: Colors.grey[200], height: 1),
                    const SizedBox(height: 12),
                    ...steps!.asMap().entries.map(
                          (e) => _buildStepItem(e.key, e.value),
                        ),
                  ],
                  // ── İptal butonu ────────────────────────────────────────
                  if (onCancel != null) ...[
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[200], height: 1),
                    const SizedBox(height: 4),
                    TextButton.icon(
                      onPressed: onCancel,
                      icon: const Icon(Icons.cancel_outlined, size: 18),
                      label: Text(t('cancel_analysis')),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[700],
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated loading button widget
/// Analiz butonunda kullanılacak animasyonlu loading göstergesi
class AnimatedLoadingButton extends StatefulWidget {
  final bool isLoading;
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const AnimatedLoadingButton({
    super.key,
    required this.isLoading,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  State<AnimatedLoadingButton> createState() => _AnimatedLoadingButtonState();
}

class _AnimatedLoadingButtonState extends State<AnimatedLoadingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.isLoading ? null : widget.onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: widget.backgroundColor ?? Colors.orange[600],
        foregroundColor: widget.foregroundColor ?? Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: widget.isLoading
          ? AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          widget.foregroundColor ?? Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Opacity(
                      opacity: 0.7 + (_animation.value * 0.3),
                      child: Text(
                        t('loading_step_ai'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                );
              },
            )
          : Text(
              widget.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
