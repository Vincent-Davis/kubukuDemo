import 'package:flutter/material.dart';
import '../models/business_insight.dart';
import '../services/dummy_data_service.dart';

class OpportunitiesScreen extends StatefulWidget {
  final List<BusinessInsight> insights;

  const OpportunitiesScreen({super.key, required this.insights});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInsightsHeader(),
          const SizedBox(height: 20),
          _buildBusinessInsights(),
          const SizedBox(height: 20),
          _buildAmarthaOpportunities(),
        ],
      ),
    );
  }

  Widget _buildInsightsHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFF7931E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.white, size: 28),
              SizedBox(width: 12),
              Text(
                'Peluang Bisnis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            'Temukan peluang untuk mengembangkan usaha Anda',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insight Bisnis Anda',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.insights.length,
          itemBuilder: (context, index) {
            final insight = widget.insights[index];
            return _buildInsightItem(insight);
          },
        ),
      ],
    );
  }

  Widget _buildInsightItem(BusinessInsight insight) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getInsightColor(insight.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getInsightIcon(insight.type),
                  color: _getInsightColor(insight.type),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  insight.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.description,
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          if (insight.type == InsightType.recommendation)
            Container(
              margin: const EdgeInsets.only(top: 12),
              child: ElevatedButton(
                onPressed: () => _handleRecommendationAction(insight),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5c2d91),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Pelajari Lebih Lanjut'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmarthaOpportunities() {
    final recommendations = DummyDataService.getAmarthaRecommendations();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Peluang dari Amartha',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recommendations.length,
          itemBuilder: (context, index) {
            final recommendation = recommendations[index];
            return _buildAmarthaOpportunityItem(recommendation, index);
          },
        ),
      ],
    );
  }

  Widget _buildAmarthaOpportunityItem(String recommendation, int index) {
    final icons = [
      Icons.account_balance,
      Icons.savings,
      Icons.bolt,
      Icons.group,
    ];
    final colors = [Colors.green, Colors.blue, Colors.orange, Colors.purple];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [
            colors[index].withOpacity(0.1),
            colors[index].withOpacity(0.05),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border.all(color: colors[index].withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icons[index], color: Colors.white, size: 24),
        ),
        title: Text(
          recommendation.split(':')[0],
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Text(
          recommendation.split(':')[1].trim(),
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors[index],
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Text(
            'COBA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        onTap: () => _handleAmarthaOpportunityTap(index),
      ),
    );
  }

  IconData _getInsightIcon(InsightType type) {
    switch (type) {
      case InsightType.bestSelling:
        return Icons.trending_up;
      case InsightType.lowStock:
        return Icons.warning;
      case InsightType.profitAnalysis:
        return Icons.account_balance_wallet;
      case InsightType.salesTrend:
        return Icons.show_chart;
      case InsightType.recommendation:
        return Icons.lightbulb;
    }
  }

  Color _getInsightColor(InsightType type) {
    switch (type) {
      case InsightType.bestSelling:
        return Colors.green;
      case InsightType.lowStock:
        return Colors.red;
      case InsightType.profitAnalysis:
        return const Color(0xFF5c2d91);
      case InsightType.salesTrend:
        return Colors.blue;
      case InsightType.recommendation:
        return Colors.orange;
    }
  }

  void _handleRecommendationAction(BusinessInsight insight) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(insight.title),
        content: Text(
          'Rekomendasi: ${insight.description}\n\nFitur ini akan segera hadir!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _handleAmarthaOpportunityTap(int index) {
    final titles = [
      'Modal Usaha',
      'Celengan Digital',
      'Agen Listrik',
      'AmarthaLink',
    ];
    final messages = [
      'Dapatkan modal usaha dengan bunga rendah untuk mengembangkan bisnis Anda.',
      'Mulai menabung keuntungan harian Anda dengan Celengan Digital Amartha.',
      'Jadikan toko Anda sebagai agen pembayaran listrik untuk income tambahan.',
      'Bergabung dengan komunitas UMKM Amartha untuk berbagi tips dan pengalaman.',
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titles[index]),
        content: Text(
          '${messages[index]}\n\nHubungi tim Amartha untuk informasi lebih lanjut.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nanti'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showContactDialog();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5c2d91),
              foregroundColor: Colors.white,
            ),
            child: const Text('Hubungi Sekarang'),
          ),
        ],
      ),
    );
  }

  void _showContactDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hubungi Amartha'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.phone, color: Color(0xFF5c2d91)),
              title: Text('Call Center'),
              subtitle: Text('1500-878'),
            ),
            ListTile(
              leading: Icon(Icons.message, color: Color(0xFF5c2d91)),
              title: Text('WhatsApp'),
              subtitle: Text('0812-3456-7890'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }
}
