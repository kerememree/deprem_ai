import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/risk_analizi.dart';
import '../models/tespit.dart';

class RiskGrafikleri extends StatelessWidget {
  final RiskAnalizi analiz;

  const RiskGrafikleri({super.key, required this.analiz});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Risk Skoru Gauge Chart (Modern)
        _buildRiskGauge(),
        const SizedBox(height: 24),
        
        // Önem Seviyesi Pie Chart (YENİ)
        _buildOnemSeviyesiPieChart(),
        const SizedBox(height: 24),
        
        // Tespitler Kategorileri Pie Chart
        _buildTespitKategorileriPieChart(),
      ],
    );
  }

  /// Risk Skoru Gauge Chart (Modern - fl_chart PieChart kullanarak)
  Widget _buildRiskGauge() {
    final percentage = analiz.riskSkoru / 10.0;
    final riskRengi = analiz.riskRengi;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          const Text(
            'Risk Skoru Dağılımı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 70,
                sections: [
                  PieChartSectionData(
                    value: analiz.riskSkoru,
                    color: riskRengi,
                    title: '${analiz.riskSkoru.toStringAsFixed(1)}',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: 10 - analiz.riskSkoru,
                    color: Colors.grey[300],
                    title: '',
                    radius: 50,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Risk Seviyesi Göstergesi
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // FIX: sınırlar RiskAnalizi.riskSeviyesi ile aynı: <=3 Düşük, <=6 Orta, <=8 Yüksek, >8 ÇokYüksek
              _buildRiskLevelIndicator('Düşük', Colors.green, 0, 3),
              _buildRiskLevelIndicator('Orta', Colors.orange, 3, 6),
              _buildRiskLevelIndicator('Yüksek', Colors.deepOrange, 6, 8),
              _buildRiskLevelIndicator('Çok Yüksek', Colors.red, 8, 10),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRiskLevelIndicator(String label, Color color, double min, double max) {
    // FIX: RiskAnalizi.riskSeviyesi ile tutarlı sınır: min <= skor < max
    // Özel durum: son aralık (8,10) için skoru = 10 dahil et
    final isActive = analiz.riskSkoru > min && analiz.riskSkoru <= max;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 8,
            decoration: BoxDecoration(
              color: isActive ? color : Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? color : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  /// Önem Seviyesi Pie Chart (YENİ)
  Widget _buildOnemSeviyesiPieChart() {
    // Önem seviyelerine göre tespitleri grupla
    final onemMap = <String, int>{};
    for (var tespit in analiz.tespitler) {
      final onem = tespit.onem;
      onemMap[onem] = (onemMap[onem] ?? 0) + 1;
    }

    if (onemMap.isEmpty) {
      return const SizedBox.shrink();
    }

    // Pie chart için veri hazırla
    final pieData = <PieChartSectionData>[];
    final colors = <Color>[];
    final labels = <String>[];

    onemMap.forEach((onem, count) {
      final color = _getOnemRengi(onem);
      colors.add(color);
      labels.add(onem);
      
      final percentage = (count / analiz.tespitler.length) * 100;
      pieData.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: color,
          title: '$count\n(${percentage.toStringAsFixed(0)}%)',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Önem Seviyesi Dağılımı',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: pieData,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: labels.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors[entry.key],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              entry.value,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getOnemRengi(String onem) {
    switch (onem.toLowerCase()) {
      case 'düşük':
      case 'dusuk':
        return Colors.blue;
      case 'orta':
        return Colors.orange;
      case 'yüksek':
      case 'yuksek':
        return Colors.deepOrange;
      case 'kritik':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /// Tespitler Kategorileri Pie Chart
  Widget _buildTespitKategorileriPieChart() {
    // Kategorilere göre tespitleri grupla
    final kategoriMap = <String, int>{};
    for (var tespit in analiz.tespitler) {
      kategoriMap[tespit.kategori] = (kategoriMap[tespit.kategori] ?? 0) + 1;
    }

    if (kategoriMap.isEmpty) {
      return const SizedBox.shrink();
    }

    // Pie chart için veri hazırla
    final pieData = <PieChartSectionData>[];
    final colors = <Color>[];
    final labels = <String>[];

    kategoriMap.forEach((kategori, count) {
      final color = _getKategoriRengi(kategori);
      colors.add(color);
      labels.add(kategori);
      
      final percentage = (count / analiz.tespitler.length) * 100;
      pieData.add(
        PieChartSectionData(
          value: count.toDouble(),
          color: color,
          title: '$count\n(${percentage.toStringAsFixed(0)}%)',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );
    });

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tespitler Kategorileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: pieData,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: labels.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: colors[entry.key],
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                entry.value,
                                style: const TextStyle(fontSize: 11),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getKategoriRengi(String kategori) {
    // Kategoriye göre renk döndür
    if (kategori.toLowerCase().contains('çatlak')) {
      return Colors.red;
    } else if (kategori.toLowerCase().contains('korozyon')) {
      return Colors.orange;
    } else if (kategori.toLowerCase().contains('yumuşak')) {
      return Colors.deepOrange;
    } else if (kategori.toLowerCase().contains('kısa')) {
      return Colors.amber;
    }
    return Colors.blue;
  }
}
