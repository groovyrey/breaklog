import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../components/index.dart';
import '../../theme/app_theme.dart';
import '../top_actions.dart';

const double _tileWidth = 52;
const double _tileGap = 8;
const double _stripPadding = 20;

/// Home. The current month with a horizontal strip of its days, today marked.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DateTime _today = DateTime.now();
  late final List<DateTime> _days;
  ScrollController? _scroll;

  @override
  void initState() {
    super.initState();
    final count = DateTime(_today.year, _today.month + 1, 0).day;
    _days = List<DateTime>.generate(
      count,
      (i) => DateTime(_today.year, _today.month, i + 1),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scroll ??= ScrollController(
      initialScrollOffset: _offsetForToday(MediaQuery.of(context).size.width),
    );
  }

  double _offsetForToday(double screenWidth) {
    final content = _stripPadding * 2 +
        _days.length * _tileWidth +
        (_days.length - 1) * _tileGap;
    final target = _stripPadding +
        (_today.day - 1) * (_tileWidth + _tileGap) -
        (screenWidth - _tileWidth) / 2;
    final maxExtent = (content - screenWidth).clamp(0.0, double.infinity);
    return target.clamp(0.0, maxExtent).toDouble();
  }

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const BrkHeader(
              title: 'Home',
              mark: BrkBrandMark(),
              actions: [TopBarActions()],
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.only(bottom: brkFloatingBarInset(context)),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      DateFormat.yMMMM().format(_today),
                      style: context.appTextTheme.titleMedium
                          ?.copyWith(color: AppColors.onSurface),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 70,
                    child: ListView.separated(
                      controller: _scroll,
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: _stripPadding),
                      itemCount: _days.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: _tileGap),
                      itemBuilder: (_, i) {
                        final date = _days[i];
                        return _DayTile(
                          date: date,
                          isToday: date.day == _today.day,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  const _DayTile({required this.date, required this.isToday});

  final DateTime date;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final color =
        isToday ? AppColors.accent : AppColors.onSurfaceVariant;
    return Container(
      width: _tileWidth,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isToday ? AppColors.accentSoft : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.control),
        border: Border.all(
          color: isToday ? AppColors.accent : AppColors.outline,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat.E().format(date).toUpperCase(),
            style: context.appTextTheme.labelSmall
                ?.copyWith(color: color, fontSize: 10),
          ),
          const SizedBox(height: 4),
          Text(
            '${date.day}',
            style: context.appTextTheme.titleMedium?.copyWith(
              color: isToday ? AppColors.accent : AppColors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
