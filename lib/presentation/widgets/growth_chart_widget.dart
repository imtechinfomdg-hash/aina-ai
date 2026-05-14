import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../data/models/constante_model.dart';
import 'package:intl/intl.dart';

enum ChartViewMode {
  poidsTaille,
  temperature,
  perimetreBrachial,
}

class GrowthChartWidget extends StatefulWidget {
  final List<ConstanteModel> constantes;

  const GrowthChartWidget({
    Key? key,
    required this.constantes,
  }) : super(key: key);

  @override
  State<GrowthChartWidget> createState() => _GrowthChartWidgetState();
}

class _GrowthChartWidgetState extends State<GrowthChartWidget> {
  ChartViewMode _currentMode = ChartViewMode.poidsTaille;
  bool _showWeight = true; // Sub-toggle for View A

  @override
  Widget build(BuildContext context) {
    if (widget.constantes.isEmpty) {
      return const Center(child: Text("Aucune donnée enregistrée.", style: TextStyle(color: Colors.grey)));
    }

    // Sort ascending
    final sortedData = List<ConstanteModel>.from(widget.constantes)
      ..sort((a, b) => a.date.compareTo(b.date));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode switch
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Center(
            child: SegmentedButton<ChartViewMode>(
              segments: const [
                ButtonSegment(value: ChartViewMode.poidsTaille, label: Text("Poids/Taille", style: TextStyle(fontSize: 12))),
                ButtonSegment(value: ChartViewMode.temperature, label: Text("Température", style: TextStyle(fontSize: 12))),
                ButtonSegment(value: ChartViewMode.perimetreBrachial, label: Text("PB", style: TextStyle(fontSize: 12))),
              ],
              selected: {_currentMode},
              onSelectionChanged: (Set<ChartViewMode> newSelection) {
                setState(() {
                  _currentMode = newSelection.first;
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_currentMode == ChartViewMode.poidsTaille) ...[
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Taille"),
                Switch(
                  value: _showWeight,
                  onChanged: (val) => setState(() => _showWeight = val),
                  activeColor: Colors.blueAccent,
                  inactiveThumbColor: Colors.orangeAccent,
                ),
                const Text("Poids"),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildPoidsTailleChart(sortedData)),
        ] else if (_currentMode == ChartViewMode.temperature) ...[
          Expanded(child: _buildTemperatureChart(sortedData)),
        ] else ...[
          Expanded(child: _buildPerimetreBrachialGauge(sortedData)),
        ]
      ],
    );
  }

  Widget _buildPoidsTailleChart(List<ConstanteModel> validConstantes) {
    var data = validConstantes.where((c) => _showWeight ? c.poids != null : c.taille != null).toList();
    if (data.isEmpty) return const Center(child: Text("Données insuffisantes."));

    final minDate = data.first.date.millisecondsSinceEpoch.toDouble();
    final List<FlSpot> spots = data.map((c) {
      final x = (c.date.millisecondsSinceEpoch - minDate) / (1000 * 3600 * 24);
      final y = _showWeight ? c.poids! : c.taille!;
      return FlSpot(x, y);
    }).toList();

    double minY = spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) * 0.9;
    double maxY = spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) * 1.1;
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
         titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                final date = DateTime.fromMillisecondsSinceEpoch((minDate + value * 1000 * 3600 * 24).toInt());
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 10)),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _showWeight ? Colors.blueAccent : Colors.orangeAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: (_showWeight ? Colors.blueAccent : Colors.orangeAccent).withOpacity(0.1)),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureChart(List<ConstanteModel> validConstantes) {
    var data = validConstantes.where((c) => c.temperature != null).toList();
    if (data.isEmpty) return const Center(child: Text("Aucune donnée de température."));

    final minDate = data.first.date.millisecondsSinceEpoch.toDouble();
    final List<FlSpot> tempSpots = [];

    for (var c in data) {
      final x = (c.date.millisecondsSinceEpoch - minDate) / (1000 * 3600 * 24);
      if (c.temperature != null) tempSpots.add(FlSpot(x, c.temperature!));
    }

    double minY = tempSpots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 0.5;
    double maxY = tempSpots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 0.5;
    if (minY < 35.0) minY = 35.0;
    if (maxY > 41.0) maxY = 41.0;

    return Column(
      children: [
        const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, color: Colors.redAccent, size: 12), SizedBox(width: 4), Text("Température (°C)", style: TextStyle(fontSize: 12)),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: LineChart(
            LineChartData(
              minY: minY,
              maxY: maxY,
              gridData: const FlGridData(show: true, drawVerticalLine: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      final date = DateTime.fromMillisecondsSinceEpoch((minDate + value * 1000 * 3600 * 24).toInt());
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(DateFormat('dd MMM').format(date), style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) => Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 10)),
                  ),
                ),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(show: true, border: Border.all(color: Colors.grey.withOpacity(0.3))),
              extraLinesData: ExtraLinesData(
                horizontalLines: [
                  HorizontalLine(
                    y: 38.0, // Fievre
                    color: Colors.red.withOpacity(0.5),
                    strokeWidth: 2,
                    dashArray: [5, 5],
                    label: HorizontalLineLabel(
                      show: true,
                      alignment: Alignment.topRight,
                      padding: const EdgeInsets.only(right: 5, bottom: 5),
                      style: const TextStyle(fontSize: 9, color: Colors.deepOrange),
                      labelResolver: (_) => "Fièvre (>38°C)",
                    ),
                  ),
                ],
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: tempSpots,
                  isCurved: true,
                  color: Colors.redAccent,
                  barWidth: 3,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(show: true, color: Colors.redAccent.withOpacity(0.1)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerimetreBrachialGauge(List<ConstanteModel> validConstantes) {
    final pbData = validConstantes.where((c) => c.perimetreBrachial != null).toList();
    if (pbData.isEmpty) {
      return const Center(child: Text("Aucune donnée de Périmètre Brachial.", textAlign: TextAlign.center));
    }

    final latestPB = pbData.last.perimetreBrachial!;
    
    // Code couleur OMS: Rouge < 115mm, Jaune 115-125mm, Vert > 125mm
    Color pbColor;
    String statusStr;
    if (latestPB < 115) {
      pbColor = Colors.red;
      statusStr = "Malnutrition aiguë sévère";
    } else if (latestPB <= 125) {
      pbColor = Colors.orange;
      statusStr = "Malnutrition aiguë modérée";
    } else {
      pbColor = Colors.green;
      statusStr = "Normal";
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          "Dernière mesure du Périmètre Brachial",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          DateFormat('dd/MM/yyyy').format(pbData.last.date),
          style: const TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 32),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              height: 150,
              width: 150,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 20,
                color: Colors.grey.shade200,
              ),
            ),
            SizedBox(
              height: 150,
              width: 150,
              child: CircularProgressIndicator(
                value: latestPB / 160.0, // Normalize arbitrarily for display (~160 max)
                strokeWidth: 20,
                color: pbColor,
                backgroundColor: Colors.transparent,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "${latestPB.toStringAsFixed(0)} mm",
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: pbColor),
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: pbColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: pbColor),
          ),
          child: Text(
            statusStr,
            style: TextStyle(color: pbColor, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
