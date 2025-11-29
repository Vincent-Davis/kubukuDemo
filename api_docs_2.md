# API Documentation — `amartha_rag` & `analytics` modules

Dokumentasi API untuk dua modul utama: **amartha_rag** (sistem RAG untuk customer service Amartha) dan **analytics** (analisis finansial dan manajemen data Amartha).

---

## 1. Module `amartha_rag`

### Overview
Module ini menyediakan sistem RAG (Retrieval-Augmented Generation) untuk customer service Amartha yang menggunakan Pinecone untuk vector storage, Gemini untuk LLM, dan LangChain untuk orchestration.

**Key Files**: 
- `amartha_rag/views.py` — ChatRAGAPIView
- `amartha_rag/rag_service.py` — AmarthaRAGService, OutputCleaner
- `amartha_rag/urls.py` — routing

### Endpoints

#### **Chat RAG API**
- **Base paths**: 
  - `GET/POST /amartha_rag/chat/`
  - `GET/POST /amartha_rag/chat/<session_id>/`

**Authentication**: `AllowAny` (tapi menggunakan `request.user` untuk session management)

---

#### **GET Chat Session**
- **Purpose**: Retrieve chat session dan riwayat messages
- **Method**: `GET`
- **URLs**:
  - `/amartha_rag/chat/` — get/create session terbaru untuk user
  - `/amartha_rag/chat/<session_id>/` — get specific session

**Parameters**:
- `session_id` (path, optional): UUID session untuk retrieve specific chat

**Response**: 200
```json
{
  "status": "success",
  "session": {
    "session_id": "uuid-string",
    "title": "New Chat",
    "created_at": "2025-11-29T10:00:00Z",
    "updated_at": "2025-11-29T10:00:00Z"
  },
  "messages": [
    {
      "id": 1,
      "sender": "user",
      "message": "Bagaimana cara mengajukan pinjaman?",
      "timestamp": "2025-11-29T10:01:00Z"
    },
    {
      "id": 2,
      "sender": "bot",
      "message": "Untuk mengajukan pinjaman di Amartha...",
      "timestamp": "2025-11-29T10:01:05Z"
    }
  ]
}
```

**Behavior**:
- Jika `session_id` tidak ada, buat session baru untuk user
- Jika user anonymous, gunakan `"anonymous"` sebagai user_id
- Return semua messages dalam session, ordered by timestamp

**Errors**:
- 404 jika session tidak ditemukan atau bukan milik user

---

#### **POST Chat Query**
- **Purpose**: Kirim query ke RAG system, dapat jawaban, simpan ke database
- **Method**: `POST`
- **URLs**: sama seperti GET

**Payload** (JSON):
```json
{
  "query": "Berapa bunga pinjaman untuk UMKM?"
}
```

**Response**: 200
```json
{
  "status": "success",
  "session": {
    "session_id": "uuid-string",
    "title": "New Chat",
    "created_at": "2025-11-29T10:00:00Z",
    "updated_at": "2025-11-29T10:05:00Z"
  },
  "new_messages": [
    {
      "id": 3,
      "sender": "user",
      "message": "Berapa bunga pinjaman untuk UMKM?",
      "timestamp": "2025-11-29T10:05:00Z"
    },
    {
      "id": 4,
      "sender": "bot", 
      "message": "Bunga pinjaman UMKM di Amartha berkisar 2-3% per bulan...",
      "timestamp": "2025-11-29T10:05:02Z"
    }
  ],
  "all_messages": [
    // semua messages di session, include yang baru
  ]
}
```

**RAG Processing Flow**:
1. Ambil history chat dari session
2. Kirim query + history ke `rag_answer()` function
3. RAG service:
   - Retrieve dokumen dari Pinecone (hybrid search: vector + BM25)
   - Format context dari dokumen
   - Generate response dengan Gemini
   - Clean output (remove markdown, fix formatting)
4. Simpan user message dan bot response ke database
5. Update session timestamp

**Errors**:
- 400: jika query kosong
- 404: jika session_id specified tapi tidak ditemukan
- 500: jika RAG processing error

---

### RAG Service Details

#### **AmarthaRAGService Class**
- **Embeddings**: Google text-embedding-004
- **LLM**: Gemini 2.0 Flash (temperature 0.3, max tokens 1024)
- **Vector DB**: Pinecone index `amartha-rag-hybrid`, namespace `amartha-docs`
- **Search**: Hybrid search (vector + BM25, alpha=0.7, top_k=8)

#### **OutputCleaner Class**
Membersihkan response dari:
- Markdown formatting (```, **, *, etc.)
- Multiple spaces dan newlines
- Unwanted prefixes ("Jawaban:", "Berikut", dll.)
- Indonesian text encoding issues

#### **Error Handling**
- Jika Pinecone/retriever error: return fallback message
- Jika no documents found: return "hubungi tim Amartha" message
- Jika invalid output: return "sistem error" message

---

## 2. Module `analytics`

### Overview
Module ini menyediakan analytics dan dashboard untuk data finansial user serta manajemen data Amartha (customers, loans, bills, tasks). Menggunakan DRF ViewSets dan custom AI agent untuk financial analysis.

**Key Files**:
- `analytics/views.py` — ViewSets dan Analytics views
- `analytics/models.py` — Customer, LoanSnapshot, Bill, Task, TaskParticipant
- `analytics/agent.py` — Financial agent with LangGraph
- `analytics/tools.py` — Financial analysis tools

### Models Summary

**Customer**: Profile pelanggan Amartha
- `user` (OneToOne ke User)
- `customer_number` (unique, hashed ID)
- `date_of_birth`, `marital_status`, `religion`, `purpose`

**LoanSnapshot**: Data pinjaman
- `customer` (FK), `loan_id` (PK)
- `principal_amount`, `outstanding_amount`, `dpd` (days past due)

**Bill**: Tagihan cicilan
- `bill_id` (PK), `loan` (FK)
- `bill_scheduled_date`, `bill_paid_date`, `amount`, `paid_amount`

**Task**: Aktivitas operasional lapangan
- `task_id` (PK), `task_type`, `task_status`
- `start_datetime`, `end_datetime`, `actual_datetime`
- `latitude`, `longitude`, `branch_id`

**TaskParticipant**: Peserta task
- `task` (FK), `participant_type`, `participant_id`
- `is_face_matched`, `is_qr_matched`, `payment_amount`

---

### Endpoints

#### **Customer Management** 
**Base**: `/analytics/customers/`

**Standard ViewSet Actions**:
- `GET /analytics/customers/` — list semua customers
- `GET /analytics/customers/{id}/` — detail customer
- `GET /analytics/customers/?marital_status=single` — filter by fields
- `GET /analytics/customers/?search=12345` — search by customer_number/username

**Custom Actions**:
- `GET /analytics/customers/{id}/loans/` — get loans untuk customer
- `GET /analytics/customers/{id}/summary/` — summary stats customer
- `GET /analytics/customers/scrape_data/?threshold=100` — scrape customer data dengan limit

**Response Example** (`/customers/1/summary/`):
```json
{
  "customer_number": "CUST001",
  "total_loans": 2,
  "total_principal": 50000000.00,
  "total_outstanding": 25000000.00,
  "loans_with_dpd": 0,
  "max_dpd": 0
}
```

---

#### **Loan Management**
**Base**: `/analytics/loans/`

**Standard Actions**:
- `GET /analytics/loans/` — list loans
- `GET /analytics/loans/{loan_id}/` — detail loan
- `GET /analytics/loans/?customer__customer_number=CUST001` — filter by customer

**Custom Actions**:
- `GET /analytics/loans/{loan_id}/bills/` — bills untuk loan
- `GET /analytics/loans/overdue/` — loans dengan DPD > 0
- `GET /analytics/loans/scrape_data/?threshold=100` — scrape loan data

---

#### **Bill Management**
**Base**: `/analytics/bills/`

**Custom Actions**:
- `GET /analytics/bills/unpaid/` — tagihan belum dibayar
- `GET /analytics/bills/paid/` — tagihan sudah dibayar  
- `GET /analytics/bills/overdue/` — tagihan terlambat (past due date + unpaid)

---

#### **Task Management**
**Base**: `/analytics/tasks/`

**Custom Actions**:
- `GET /analytics/tasks/{task_id}/participants/` — participants task
- `GET /analytics/tasks/by_status/` — count by task status
- `GET /analytics/tasks/by_type/` — count by task type

**Response Example** (`/tasks/by_status/`):
```json
[
  {"task_status": "COMPLETED", "count": 45},
  {"task_status": "IN_PROGRESS", "count": 12},
  {"task_status": "PENDING", "count": 8}
]
```

---

#### **Task Participant Management**
**Base**: `/analytics/task-participants/`

**Custom Actions**:
- `GET /analytics/task-participants/with_payments/` — participants dengan payment_amount

---

### Analytics Views

#### **Dashboard View**
- **URL**: `GET /analytics/dashboard/`
- **Purpose**: Render dashboard template (HTML view)
- **Template**: `analytics/dashboard.html`

#### **Financial Chatbot** 
- **URL**: `POST /analytics/chat/`
- **Authentication**: `IsAuthenticated` required
- **Purpose**: AI-powered financial analysis chat

**Payload** (JSON):
```json
{
  "message": "Berapa total penjualan saya minggu ini?"
}
```

**Response**: 200
```json
{
  "reply": "Total penjualan Anda minggu ini adalah IDR 2,500,000. Terdiri dari 15 transaksi dengan rata-rata nilai IDR 166,667 per transaksi.",
  "user_message": "Berapa total penjualan saya minggu ini?"
}
```

**AI Agent Features**:
- Menggunakan LangGraph + Gemini 2.5 Flash
- Tools tersedia: transaction stats, credit health analysis, inventory status, top selling products
- Output cleaning untuk remove markdown formatting
- Error handling untuk tool access issues

#### **Cashflow Trend**
- **URL**: `GET /analytics/cashflow-trend/`
- **Authentication**: `IsAuthenticated` required
- **Purpose**: Data untuk chart income vs expense per bulan

**Response**: 200
```json
{
  "labels": ["2025-10", "2025-11"],
  "datasets": [
    {
      "label": "Income",
      "data": [15000000, 18000000],
      "color": "green"
    },
    {
      "label": "Expense", 
      "data": [8000000, 12000000],
      "color": "red"
    }
  ]
}
```

**Logic**:
- Ambil Transaction data user, group by month
- Map `sell` transaction → Income
- Map `buy` transaction → Expense
- Return format chart-ready

---

### Financial Tools (Agent Tools)

#### **get_transaction_stats**
- **Function**: Hitung total transaksi per periode & tipe
- **Parameters**: `period` (today/this_week/this_month), `transaction_type` (income/expense)
- **Return**: String dengan total amount formatted

#### **analyze_credit_health** 
- **Function**: Analisis risiko kredit berdasarkan surplus, bills, DPD
- **Logic**:
  1. Hitung weekly surplus (income - expense)
  2. Ambil next unpaid bill
  3. Check max DPD dari loans
  4. Determine status: SAFE/WARNING/CRITICAL
- **Return**: Formatted credit health report

#### **get_inventory_status**
- **Function**: Status inventory dan total value
- **Return**: List produk dengan stock level, low stock alerts

#### **get_top_selling_products**
- **Function**: Top selling products by revenue
- **Parameters**: `limit` (default 5), `period` (today/this_week/this_month/all_time)
- **Return**: Ranked list dengan quantity sold dan revenue

---

### Authentication & Permissions

**amartha_rag**: `AllowAny` tapi menggunakan `request.user` untuk session management
**analytics**: 
- ViewSets: `AllowAny` 
- FinancialChatBotView & CashflowTrendView: `IsAuthenticated`
- Dashboard: template view (likely requires login depending on middleware)

### Common Query Parameters

**Filtering**: Django Filter Backend aktif di ViewSets
```
/analytics/customers/?marital_status=married&religion=1
/analytics/tasks/?task_type=COLLECTION&task_status=COMPLETED
```

**Search**: Search backend aktif
```
/analytics/customers/?search=CUST001
```

**Ordering**: Order backend aktif
```
/analytics/loans/?ordering=-principal_amount
/analytics/bills/?ordering=bill_scheduled_date
```

**Scraping**: Semua ViewSet punya `scrape_data` action dengan `threshold` param
```
/analytics/customers/scrape_data/?threshold=50
```

---

### Error Handling

**amartha_rag**:
- RAG errors return fallback messages instead of 500s
- Session not found returns 404
- Invalid query returns 400

**analytics**:
- Financial agent tool errors mengembalikan "ACCESS DENIED" message
- Chart data errors return 500 dengan error message
- ViewSet errors mengikuti DRF standard error format

---

### Dependencies & Configuration

**Environment Variables**:
- `GEMINI_API_KEY` — untuk RAG service dan financial agent
- Pinecone API key hardcoded di rag_service.py (production should use env var)

**Key Libraries**:
- LangChain + LangGraph untuk RAG dan agent
- Pinecone untuk vector storage
- Google Generative AI untuk embeddings dan chat
- Django REST Framework untuk APIs
- django-filter untuk filtering

**Database Relations**:
- Customer ↔ User (OneToOne)
- Customer → LoanSnapshot (ForeignKey)  
- LoanSnapshot → Bill (ForeignKey)
- Task → TaskParticipant (ForeignKey)
- ChatSession ← Transaction (optional link untuk tracking)

---

## Contoh Usage

**RAG Chat**:
```bash
# Start new chat session
curl -X POST "http://localhost:8000/amartha_rag/chat/" \
  -H "Content-Type: application/json" \
  -d '{"query": "Bagaimana cara mengajukan pinjaman?"}'

# Continue existing session  
curl -X POST "http://localhost:8000/amartha_rag/chat/uuid-session-id/" \
  -H "Content-Type: application/json" \
  -d '{"query": "Berapa lama proses persetujuan?"}'
```

**Financial Analysis**:
```bash
# AI financial chat
curl -X POST "http://localhost:8000/analytics/chat/" \
  -H "Authorization: Bearer <token>" \
  -H "Content-Type: application/json" \
  -d '{"message": "Analisis kesehatan kredit saya"}'

# Cashflow trend
curl "http://localhost:8000/analytics/cashflow-trend/" \
  -H "Authorization: Bearer <token>"
```

**Data Management**:
```bash
# Get customer loans
curl "http://localhost:8000/analytics/customers/1/loans/"

# Get overdue bills
curl "http://localhost:8000/analytics/bills/overdue/"

# Scrape customer data
curl "http://localhost:8000/analytics/customers/scrape_data/?threshold=100"
```

---

File dibuat: `api_docs_2.md`