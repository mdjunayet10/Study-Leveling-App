import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_formatters.dart';
import 'primary_button.dart';
import 'surface_card.dart';

class CountdownTimerCard extends StatefulWidget {
  const CountdownTimerCard({super.key, required this.minutes, this.onFinished});

  final int minutes;
  final VoidCallback? onFinished;

  @override
  State<CountdownTimerCard> createState() => _CountdownTimerCardState();
}

class _CountdownTimerCardState extends State<CountdownTimerCard> {
  Timer? _timer;
  late int _remainingSeconds;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.minutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() => _running = true);
  }

  void _tick() {
    if (_remainingSeconds <= 1) {
      _timer?.cancel();
      setState(() {
        _remainingSeconds = 0;
        _running = false;
      });

      widget.onFinished?.call();
      return;
    }

    setState(() => _remainingSeconds--);
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = widget.minutes * 60;
      _running = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final pulse = _running && _remainingSeconds < 60;
    final color = _remainingSeconds == 0
        ? AppColors.error
        : _remainingSeconds < widget.minutes * 60 * 0.25
        ? AppColors.error
        : _remainingSeconds < widget.minutes * 60 * 0.5
        ? AppColors.warning
        : pulse
        ? AppColors.accentBright
        : AppColors.textPrimary;

    return SurfaceCard(
      child: Column(
        children: <Widget>[
          Text(
            'COMPETITION TIMER',
            style: AppTextStyles.subheader.copyWith(color: AppColors.accent),
          ),
          const SizedBox(height: 14),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: AppTextStyles.timerLarge.copyWith(color: color),
            child: Text(
              AppFormatters.formatCountdown(
                Duration(seconds: _remainingSeconds),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _running ? 'RUNNING' : 'READY',
            style: AppTextStyles.body.copyWith(
              color: _running ? AppColors.accent : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: PrimaryButton(
                  label: _running ? 'PAUSE' : 'START',
                  onPressed: _toggle,
                  backgroundColor: AppColors.success,
                  hoverColor: AppColors.success,
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'RESET',
                  onPressed: _reset,
                  backgroundColor: AppColors.primary,
                  hoverColor: AppColors.primaryLight,
                  isExpanded: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
