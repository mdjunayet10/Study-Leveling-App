import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/app_formatters.dart';
import 'primary_button.dart';
import 'surface_card.dart';

class PomodoroTimerCard extends StatefulWidget {
  const PomodoroTimerCard({super.key});

  @override
  State<PomodoroTimerCard> createState() => _PomodoroTimerCardState();
}

class _PomodoroTimerCardState extends State<PomodoroTimerCard> {
  static const int _defaultStudyMinutes = 25;
  static const int _defaultBreakMinutes = 5;
  static const int _defaultLongBreakMinutes = 15;

  Timer? _timer;
  int _studyMinutes = _defaultStudyMinutes;
  int _breakMinutes = _defaultBreakMinutes;
  int _longBreakMinutes = _defaultLongBreakMinutes;
  int _secondsLeft = _defaultStudyMinutes * 60;
  bool _isRunning = false;
  bool _isStudySession = true;
  int _pomodoroCount = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
      setState(() => _isRunning = false);
      return;
    }

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    setState(() => _isRunning = true);
  }

  void _tick() {
    if (_secondsLeft <= 1) {
      _timer?.cancel();
      setState(() {
        _isRunning = false;
        if (_isStudySession) {
          _pomodoroCount++;
        }
        _isStudySession = !_isStudySession;
        _secondsLeft = _isStudySession
            ? _studyMinutes * 60
            : (_pomodoroCount > 0 && _pomodoroCount % 4 == 0
                  ? _longBreakMinutes * 60
                  : _breakMinutes * 60);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isStudySession
                ? 'Break finished. Ready for another study session?'
                : 'Study session complete. Take a break.',
          ),
        ),
      );
      return;
    }

    setState(() => _secondsLeft--);
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isStudySession = true;
      _secondsLeft = _studyMinutes * 60;
    });
  }

  void _skipSession() {
    _timer?.cancel();
    setState(() {
      if (_isStudySession) {
        _pomodoroCount++;
      }
      _isStudySession = !_isStudySession;
      _secondsLeft = _isStudySession
          ? _studyMinutes * 60
          : (_pomodoroCount > 0 && _pomodoroCount % 4 == 0
                ? _longBreakMinutes * 60
                : _breakMinutes * 60);
      _isRunning = false;
    });
  }

  Future<void> _openSettings() async {
    final studyController = TextEditingController(
      text: _studyMinutes.toString(),
    );
    final breakController = TextEditingController(
      text: _breakMinutes.toString(),
    );
    final longBreakController = TextEditingController(
      text: _longBreakMinutes.toString(),
    );

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Pomodoro Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: studyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Study minutes'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: breakController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Break minutes'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: longBreakController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Long break minutes',
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('CANCEL'),
            ),
            PrimaryButton(
              label: 'SAVE',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newStudy = int.tryParse(studyController.text) ?? _studyMinutes;
      final newBreak = int.tryParse(breakController.text) ?? _breakMinutes;
      final newLongBreak =
          int.tryParse(longBreakController.text) ?? _longBreakMinutes;

      setState(() {
        _studyMinutes = newStudy.clamp(1, 120);
        _breakMinutes = newBreak.clamp(1, 60);
        _longBreakMinutes = newLongBreak.clamp(1, 120);
      });
      _resetTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final timeColor = !_isRunning && !_isStudySession
        ? AppColors.accent
        : (_isStudySession ? AppColors.success : AppColors.info);

    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'POMODORO TIMER',
                  style: AppTextStyles.subheader.copyWith(
                    color: AppColors.accent,
                  ),
                ),
              ),
              IconButton(
                onPressed: _openSettings,
                icon: const Icon(
                  Icons.settings,
                  color: AppColors.textSecondary,
                ),
                tooltip: 'Customize Timer Settings',
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                _isStudySession ? 'STUDY SESSION' : 'BREAK SESSION',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                'CYCLE: $_pomodoroCount',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: AppTextStyles.timerLarge.copyWith(color: timeColor),
              child: Text(
                AppFormatters.formatCountdown(Duration(seconds: _secondsLeft)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Center(
            child: Text(
              _isRunning ? 'RUNNING' : 'READY',
              style: AppTextStyles.body.copyWith(
                color: _isStudySession ? AppColors.accent : AppColors.info,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: PrimaryButton(
                  label: _isRunning ? 'PAUSE' : 'START',
                  onPressed: _toggleTimer,
                  backgroundColor: AppColors.success,
                  hoverColor: AppColors.success,
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'RESET',
                  onPressed: _resetTimer,
                  backgroundColor: AppColors.primary,
                  hoverColor: AppColors.primaryLight,
                  isExpanded: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: PrimaryButton(
                  label: 'SKIP',
                  onPressed: _skipSession,
                  backgroundColor: AppColors.warning,
                  hoverColor: AppColors.warning,
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
