import 'package:flutter/material.dart';
import 'package:dailynest/weather_service.dart';

class TenDayForecastList extends StatelessWidget {
  final List<DailyForecast> forecasts;

  const TenDayForecastList({super.key, required this.forecasts});

  @override
  Widget build(BuildContext context) {
    if (forecasts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '10-DAY FORECAST',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          ...forecasts.asMap().entries.map((entry) {
            final index = entry.key;
            final forecast = entry.value;
            final isLast = index == forecasts.length - 1;
            
            return Column(
              children: [
                DailyForecastRow(
                  forecast: forecast,
                  isToday: index == 0,
                ),
                if (!isLast) ...[
                  const SizedBox(height: 12),
                  Divider(
                    height: 1,
                    color: Colors.black.withOpacity(0.1),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class DailyForecastRow extends StatelessWidget {
  final DailyForecast forecast;
  final bool isToday;

  const DailyForecastRow({
    super.key,
    required this.forecast,
    required this.isToday,
  });

  String _formatDay(DateTime date, bool isToday) {
    if (isToday) return 'Today';
    
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dayLabel = _formatDay(forecast.date, isToday);

    return Row(
      children: [
        SizedBox(
          width: 50,
          child: Text(
            dayLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            forecast.description,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 16),
        Row(
          children: [
            Text(
              '${forecast.minTemp.toStringAsFixed(0)}°',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${forecast.maxTemp.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
