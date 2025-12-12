# OCR Features Documentation

## Overview
KuBuku sekarang mendukung OCR (Optical Character Recognition) untuk menganalisis gambar transaksi menggunakan Gemini AI. Fitur ini memungkinkan pengguna untuk memfoto struk belanja atau dokumen transaksi dan secara otomatis mengekstrak informasi produk, harga, dan jumlah.

## Fitur OCR yang Tersedia

### 1. **Gambar Saja (Image-Only)**
- Ambil foto struk belanja atau dokumen transaksi
- AI akan menganalisis gambar dan mengekstrak informasi transaksi
- Mendukung sumber: Kamera dan Galeri

### 2. **Gambar + Teks (Image + Text)**
- Kirim gambar bersama dengan keterangan tambahan
- Berguna untuk memberikan konteks atau koreksi pada AI
- Contoh: "ini struk belanja hari ini" atau "cek harga produk ini"

### 3. **Integrasi dengan Validasi Transaksi**
- Hasil OCR akan ditampilkan dalam dialog validasi
- User dapat mengedit dan memverifikasi setiap field yang terdeteksi:
  - Nama produk
  - Jumlah (quantity)
  - Satuan (unit)
  - Harga per unit
- Kalkulasi otomatis subtotal dan total

## Cara Menggunakan

### Melalui Chatbot AI:

1. **Buka AI Chat Screen**
2. **Pilih input gambar**:
   - Tap ikon kamera di area input
   - Pilih salah satu opsi:
     - **"Kamera"** - Ambil foto langsung
     - **"Galeri"** - Pilih dari galeri
     - **"Gambar + Teks"** - Gambar dengan keterangan

3. **Untuk Gambar + Teks**:
   - Pilih sumber gambar (kamera/galeri)
   - Tambahkan keterangan teks (opsional)
   - Kirim

4. **Verifikasi Hasil**:
   - Dialog validasi akan muncul
   - Review dan edit data yang terdeteksi
   - Semua field bisa diedit (nama produk, jumlah, satuan, harga)
   - Konfirmasi untuk menyimpan transaksi

## Implementasi Teknis

### Backend API
- **Endpoint**: `/api/gemini/parse-transaction/`
- **Method**: POST (multipart/form-data)
- **Fields**:
  - `user_id` (string)
  - `message` (optional string) - Teks keterangan
  - `image` (file) - File gambar
  - `session_id` (optional) - ID sesi chat

### Frontend Implementation
- **ChatService**: Method `parseTransactionWithImage()`
- **AI Chat Screen**: UI untuk image picker dan text input
- **Transaction Validation Dialog**: Form untuk edit hasil OCR

### Supported Image Formats
- JPEG
- PNG
- Kualitas gambar dioptimasi otomatis (max 800x800, quality 85%)

## Error Handling

### Kasus yang Ditangani:
1. **Gambar tidak bisa diproses** - Menampilkan pesan error
2. **Tidak ada transaksi terdeteksi** - Fallback ke chat biasa
3. **Network error** - Pesan error koneksi
4. **Format gambar tidak didukung** - Pesan error format

### Fallback Behavior:
- Jika OCR gagal parsing transaksi, sistem akan mencoba menggunakan regular chat
- User tetap mendapat respons dari AI meskipun OCR tidak berhasil

## Tips Penggunaan

### Untuk Hasil OCR Terbaik:
1. **Foto yang jelas** - Pastikan struk/dokumen terlihat jelas
2. **Pencahayaan yang baik** - Hindari bayangan atau refleksi
3. **Teks lengkap** - Tambahkan keterangan jika gambar kurang jelas
4. **Format standar** - Struk belanja atau dokumen transaksi formal

### Contoh Keterangan Teks yang Efektif:
- "Ini struk belanja dari toko sayur kemarin"
- "Cek harga produk dalam foto ini"
- "Rekap transaksi hari ini dari kasir"
- "Nota kulakan beras dan minyak"

## Batasan Current

1. **Session Persistence**: Chat session creation sementara dinonaktifkan karena endpoint backend belum tersedia
2. **Image Storage**: Gambar hanya disimpan sementara untuk processing
3. **Language**: Optimized untuk Bahasa Indonesia
4. **File Size**: Dibatasi untuk performa optimal

## Future Enhancements

1. **Batch OCR**: Proses multiple images sekaligus
2. **History Management**: Simpan riwayat OCR results
3. **Template Recognition**: Deteksi format struk specific stores
4. **Voice + Image**: Kombinasi voice input dengan OCR
5. **Offline OCR**: Basic OCR tanpa internet connection

## Troubleshooting

### OCR Tidak Bekerja:
1. Check koneksi internet
2. Pastikan gambar format yang didukung
3. Coba dengan gambar yang lebih jelas
4. Restart aplikasi jika perlu

### Hasil Parsing Tidak Akurat:
1. Tambahkan keterangan teks untuk konteks
2. Edit manual di dialog validasi
3. Gunakan foto dengan pencahayaan yang lebih baik

---

**Note**: Fitur OCR ini menggunakan Google Gemini AI untuk processing, sehingga memerlukan koneksi internet yang stabil.