# API Documentation — `api` app

Ringkasan singkat: API ini menyediakan endpoint untuk parsing transaksi via Gemini, manajemen transaksi, produk, dan voice transcription. Tidak ada autentikasi token built-in di view; ownership/divider dikendalikan oleh `user_id` yang harus disediakan oleh klien.

**Lokasi file**: `api/views.py`, `api/urls.py`, `api/models.py`

**Umum**:
- Base path: endpoints disajikan relatif ke `api/` (sesuai `urls.py`).
- Content-Type: kebanyakan endpoint menerima `application/json` (POST) kecuali endpoint file (multipart/form-data) seperti `voice/transcription/` dan `gemini/parse-transaction/` ketika mengirim gambar.
- Ownership: banyak operasi (create/update/delete/list/detail) membutuhkan `user_id` baik sebagai query param (`GET`) atau di body JSON (POST) untuk validasi kepemilikan.

**Model ringkas (dari `api/models.py`)**:
- Product:
  - `id` (int, auto)
  - `user_id` (str)
  - `name` (str)
  - `base_price` (decimal)
  - `default_sell_price` (decimal)
  - `unit` (str)
  - `current_stock` (int)

- Transaction:
  - `id` (int, auto)
  - `user_id` (str)
  - `transaction_type` (`buy` | `sell`)
  - `session` (nullable FK ke ChatSession)
  - `timestamp` (datetime)
  - `total_amount` (decimal)
  - `original_text` (text)

- TransactionItem:
  - `transaction` (FK)
  - `product` (FK)
  - `product_name_snapshot` (str)
  - `quantity` (decimal)
  - `actual_price_per_unit` (decimal)
  - `subtotal` (decimal)


**Endpoints**

- **Ping**: `GET /api/ping/`
  - Purpose: healthcheck
  - Request: GET
  - Response: 200
    {
      "status": "ok",
      "message": "pong5"
    }

- **Gemini Chat**: `POST /api/gemini/chat/`
  - Purpose: kirim teks ke Gemini untuk parsing transaksi (menggunakan `GEMINI_API_KEY` environment variable).
  - Payload (JSON):
    {
      "message": "beli apel merah, 2 pcs, harga 7000"
    }
  - Response: 200 (contoh)
    {
      "status": "ok",
      "model": "gemini-2.0-flash",
      "user_input": "...",
      "raw_text": "...",
      "cleaned": "...",
      "structured": { ... }  // parsed JSON jika berhasil
    }
  - Errors: 400 jika body invalid atau `message` kosong; 500 jika GEMINI_API_KEY tidak diset atau error provider.

- **Gemini Transaction Parser**: `POST /api/gemini/parse-transaction/`
  - Purpose: parse message atau image menjadi struktur transaksi via Gemini.
  - Accepts:
    - `Content-Type: application/json` with body {"user_id":..., "message":...}
    - or `multipart/form-data` with fields: `user_id` (optional), `message` (optional), `image` (file)
  - Validation: harus ada `message` atau `image`.
  - Response: 200
    {
      "status": "ok",
      "model": "gemini-2.0-flash",
      "user_input": "...",
      "has_image": true|false,
      "product_context_count": 10,
      "structured_response": { ... JSON parsed ... }
    }
  - Errors: 400 jika tidak ada message & image; 500 on provider error.

- **Create Transaction**: `POST /api/transaction/create/`
  - Payload (JSON):
    {
      "user_id": "user_123",
      "type": "sell"|"buy",
      "items": [
        {"product_id": 1, "product_name": "Apel", "quantity": 2, "price_per_unit": 7000, "unit": "pcs"},
        ...
      ],
      "original_text": "...",
      "session_id": "optional-session-id"
    }
  - Behavior:
    - Validates `user_id` dan `items`.
    - Untuk tiap item: jika `product_id` ada, gunakan produk; jika tidak, auto-create `Product` baru.
    - Update stok: `sell` => stock -= qty, `buy` => stock += qty.
    - Menyimpan Transaction dan TransactionItem; menghitung `total_amount`.
  - Response: 200
    {
      "status": "success",
      "transaction_id": 123,
      "total_amount": 14000
    }
  - Errors: 400 jika data incomplete; 500 on exception.

- **Update Transaction**: `POST /api/transaction/update/<transaction_id>/`
  - Payload (JSON): { user_id, type (optional), items: [...] }
  - Behavior:
    - Revert stok dari item lama berdasarkan `transaction_type` lama.
    - Hapus old items.
    - Insert new items & update stok sesuai tipe baru (atau lama jika tidak diubah).
  - Response: 200
    {"status":"success","message":"Transaction updated","transaction_id":...,"new_total": ...}
  - Errors: 405 for non-POST; 404 if not found; 500 on failure.

- **Delete Transaction**: `DELETE or POST /api/transaction/delete/<transaction_id>/`
  - Payload (JSON): { "user_id": "..." }
  - Behavior:
    - Validasi `user_id`.
    - Revert stok (kebalikan create), lalu hapus transaksi.
  - Response: 200
    {"status":"success","message":"Transaction <id> deleted and stock reverted."}

- **List Transactions**: `GET /api/transaction/list/?user_id=<user_id>`
  - Query params: `user_id` (required)
  - Response: 200
    {
      "status": "success",
      "count": N,
      "data": [
        {"id": ..., "timestamp": "...", "type": "sell|buy", "total_amount": 123.45, "original_text": "...", "item_count": 3},
        ...
      ]
    }

- **Get Transaction Detail**: `GET /api/transaction/detail/<transaction_id>/?user_id=<user_id>`
  - Response: 200
    {
      "status": "success",
      "data": {
        "id": ..., "timestamp": "...", "type": "sell|buy", "total_amount": ..., "original_text": "...",
        "session_id": "...",
        "items": [ {"product_id":..., "product_name":"...", "quantity":..., "unit":"...", "price_per_unit":..., "subtotal":...}, ... ]
      }
    }

- **Voice Transcription**: `POST /api/voice/transcription/`
  - Form-data fields:
    - `file` (audio file, required) — field name must be `file`.
    - `user_id` (optional)
  - Behavior:
    - Upload file to Gemini Files API, request transcription.
    - Then parse transcript via `_parse_transaction_text_with_gemini` to structured JSON.
  - Response: 200
    {
      "status": "success",
      "model": "gemini-2.0-flash",
      "transcript": "...",
      "user_id": "...",
      "product_context_count": 10,
      "structured_response": { ... }
    }

- **List Products**: `GET /api/product/list/?user_id=<user_id>`
  - Response: 200
    {
      "status": "success",
      "count": N,
      "data": [ {"id":..., "name":"...", "unit":"pcs", "base_price": 10000.0, "default_sell_price": 12000.0, "current_stock": 5}, ... ]
    }

- **Create Product**: `POST /api/product/create/`
  - Payload (JSON): { "user_id": "...", "name": "...", "unit": "pcs", "base_price": 10000, "sell_price": 12000, "stock": 5 }
  - Response: 200
    {"status":"success","message":"Product created","data":{"id":...,"name":"..."}}
  - Errors: 400 if missing `user_id` or `name`, or duplicate product name for same user.

- **Update Product**: `POST /api/product/update/<product_id>/`
  - Payload (JSON): must include `user_id` and any fields to update: `name`, `unit`, `base_price`, `sell_price`, `stock`.
  - Response: 200
    {"status":"success","message":"Product updated","data": {"id":...,"name":"...","current_stock":...,"price": ...}}

- **Delete Product**: `DELETE or POST /api/product/delete/<product_id>/`
  - Payload (JSON): { "user_id": "..." }
  - Response: 200
    {"status":"success","message":"Product '<name>' deleted successfully"}


**Notes & Caveats**
- Auth: Saat ini views menggunakan `user_id` string passed from client for authorization checks. Jika aplikasi produksi, sebaiknya ganti dengan autentikasi token/session dan gunakan `request.user` untuk validasi kepemilikan.
- GEMINI_API_KEY diperlukan untuk fitur `gemini_*` dan `voice_transcription`. Pastikan env var `GEMINI_API_KEY` ada.
- Error handling: beberapa endpoint mengembalikan 500 dengan pesan exception; tangani ini di client atau perbaiki di server untuk payload yang lebih jelas.
- Tipe data numerik: model memakai `DecimalField` untuk harga; responses convert ke `float` di beberapa endpoint.
- File uploads: `voice_transcription` expects form-data `file` and uses temp file.


**Contoh singkat curl**
- Create product

```bash
curl -X POST "http://localhost:8000/api/product/create/" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"u1","name":"Apel Merah","unit":"kg","base_price":7000,"sell_price":8000,"stock":10}'
```

- Create transaction

```bash
curl -X POST "http://localhost:8000/api/transaction/create/" \
  -H "Content-Type: application/json" \
  -d '{"user_id":"u1","type":"sell","items":[{"product_name":"Apel Merah","quantity":2,"price_per_unit":7000}],"original_text":"jual 2 kg apel"}'
```

- List products

```bash
curl "http://localhost:8000/api/product/list/?user_id=u1"
```


---
Jika mau, saya bisa:
- Tambahkan contoh respons penuh untuk tiap endpoint.
- Tambahkan Postman collection atau OpenAPI (Swagger) file.
- Ganti `user_id` checks dengan decorator autentikasi dan dokumentasikan header Authorization.

File yang dibuat: `api_documentations.md`.
