// import 'dart:convert';
// import 'package:http/http.dart' as http;

class AIChatService {
  // Replace with your actual API endpoint when ready
  // static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';
  // static const String _apiKey = 'YOUR_API_KEY_HERE';

  static Future<String> sendMessage(String message) async {
    try {
      // Simulate API delay
      await Future.delayed(const Duration(milliseconds: 1500));
      return _getMockResponse(message);
    } catch (e) {
      return 'Maaf, terjadi kesalahan saat menghubungi AI. Silakan coba lagi.';
    }
  }

  static String _getMockResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('laris') ||
        lowerMessage.contains('terlaris') ||
        lowerMessage.contains('paling laku')) {
      return 'Berdasarkan data minggu ini, produk terlaris Anda adalah:\n\n1. 🥇 Beras Premium (15 terjual, Rp 75.000)\n2. 🥈 Telur Ayam (6 terjual, Rp 120.000)\n3. 🥉 Minyak Goreng (8 terjual, Rp 60.000)\n\nBeras Premium paling diminati pelanggan!';
    }

    if (lowerMessage.contains('keuntungan') ||
        lowerMessage.contains('profit') ||
        lowerMessage.contains('untung')) {
      if (lowerMessage.contains('hari ini')) {
        return 'Alhamdulillah! Keuntungan hari ini Rp 87.000 dari 12 transaksi.\n\n📊 Breakdown:\n• Pemasukan: Rp 134.000\n• Modal: Rp 47.000\n• Keuntungan: Rp 87.000 (65% margin)\n\nLuar biasa!';
      } else {
        return 'Keuntungan minggu ini Rp 520.000 dengan margin 65%.\n\n📈 Tren bagus! Keuntungan naik 15% dari minggu lalu.';
      }
    }

    if (lowerMessage.contains('stok') ||
        lowerMessage.contains('habis') ||
        lowerMessage.contains('kosong')) {
      return 'Ada beberapa produk yang stoknya menipis:\n\n⚠️ Sabun Cuci Rinso (3 pcs tersisa)\n⚠️ Gula Pasir (8 kg tersisa)\n\n💡 Rekomendasi: Segera restock Sabun Cuci karena sering laku dan margin bagus!';
    }

    if (lowerMessage.contains('pelanggan') ||
        lowerMessage.contains('pembeli')) {
      return 'Hari ini sudah 8 pelanggan yang belanja.\n\n👥 Pelanggan setia:\n• Ibu Ani (3x minggu ini)\n• Pak Budi (2x minggu ini)\n• Ibu Sari (2x minggu ini)\n\nMereka suka beli beras dan minyak goreng!';
    }

    if (lowerMessage.contains('rekomendasi') ||
        lowerMessage.contains('saran') ||
        lowerMessage.contains('advice')) {
      return 'Berdasarkan pola penjualan, saya sarankan:\n\n💡 Tambah stok beras premium (laris terus!)\n💡 Promo bundling: beras + minyak goreng\n💡 Jual telur ayam lebih agresif (margin tinggi)\n💡 Pertimbangkan jual online via AmarthaLink\n\nMau saya jelaskan detail salah satunya?';
    }

    // Greetings
    if (lowerMessage.contains('halo') ||
        lowerMessage.contains('hai') ||
        lowerMessage.contains('selamat')) {
      return 'Halo! Senang bisa bantu analisa bisnis Anda hari ini. Ada yang mau ditanyakan tentang penjualan atau stok? 😊';
    }

    if (lowerMessage.contains('terima kasih') ||
        lowerMessage.contains('makasih')) {
      return 'Sama-sama! Senang bisa membantu. Jangan ragu tanya lagi kalau butuh analisa bisnis ya! 🙏';
    }

    // Default response
    return 'Maaf, saya belum sepenuhnya memahami pertanyaan Anda. Coba tanya seperti ini:\n\n• "Berapa keuntungan hari ini?"\n• "Produk apa yang paling laris?"\n• "Stok apa yang hampir habis?"\n• "Berikan saran untuk bisnis saya"\n\nAtau tanya hal lain tentang penjualan Anda! 🤔';
  }
}
