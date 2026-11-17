import 'dart:math';
import 'package:flutter/material.dart';

class PieChartItem {
  final String label;
  final double value;
  final Color color;

  PieChartItem({
    required this.label,
    required this.value,
    required this.color,
  });
}

class CircularPieChart extends StatelessWidget {
  final List<PieChartItem> items;
  final String centerTitle;
  final String centerSubtitle;
  final double chartRadius;
  final double strokeWidth;

  const CircularPieChart({
    super.key,
    required this.items,
    this.centerTitle = '',
    this.centerSubtitle = '',
    this.chartRadius = 75,
    this.strokeWidth = 20,
  });

  @override
  Widget build(BuildContext context) {
    final total = items.fold<double>(0, (sum, item) => sum + item.value);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;

        return isNarrow
            ? Column(
                children: [
                  _buildChart(total),
                  const SizedBox(height: 16),
                  _buildLegend(total),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildChart(total),
                  const SizedBox(width: 24),
                  Expanded(child: _buildLegend(total)),
                ],
              );
      },
    );
  }

  Widget _buildChart(double total) {
    return SizedBox(
      width: chartRadius * 2,
      height: chartRadius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(chartRadius * 2, chartRadius * 2),
            painter: _PieChartPainter(
              items: items,
              total: total > 0 ? total : 1,
              strokeWidth: strokeWidth,
            ),
          ),
          if (centerTitle.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  centerTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0C0C0E),
                  ),
                ),
                if (centerSubtitle.isNotEmpty)
                  Text(
                    centerSubtitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildLegend(double total) {
    if (total == 0) {
      return const Text(
        'Aucune mission à afficher.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        final percent = total > 0 ? (item.value / total * 100) : 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: item.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0C0C0E),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${percent.toStringAsFixed(0)}% (${item.value.toInt()})',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PieChartItem> items;
  final double total;
  final double strokeWidth;

  _PieChartPainter({
    required this.items,
    required this.total,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    if (total <= 0) {
      final basePaint = Paint()
        ..color = Colors.grey.shade200
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth;
      canvas.drawCircle(center, radius, basePaint);
      return;
    }

    double startAngle = -pi / 2;

    for (final item in items) {
      if (item.value <= 0) continue;
      final sweepAngle = (item.value / total) * 2 * pi;

      final paint = Paint()
        ..color = item.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _PieChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.items != items;
  }
}
