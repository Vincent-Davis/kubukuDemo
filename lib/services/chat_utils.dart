import 'package:flutter/material.dart';

class ChatUtils {
  static void showApiKeyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('API Configuration'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Untuk menggunakan AI yang sesungguhnya, Anda perlu mengonfigurasi API key:',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
            Text(
              '1. Buka file ai_chat_service.dart\n'
              '2. Ganti YOUR_API_KEY_HERE dengan API key Anda\n'
              '3. Uncomment kode OpenAI API\n'
              '4. Comment kode mock response',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 16),
            Text(
              'Saat ini menggunakan response mock untuk demo.',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showVoicePermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: Colors.red),
            SizedBox(width: 8),
            Text('Izin Mikrofon'),
          ],
        ),
        content: const Text(
          'Aplikasi memerlukan izin mikrofon untuk fitur voice input. '
          'Silakan berikan izin di pengaturan aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  static List<String> getSuggestedQuestions() {
    return [
      "Berapa keuntungan hari ini?",
      "Produk apa yang paling laris?",
      "Stok apa yang hampir habis?",
      "Berikan rekomendasi bisnis",
      "Siapa pelanggan setia saya?",
    ];
  }
}
