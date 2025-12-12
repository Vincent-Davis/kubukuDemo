import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'dart:typed_data';
import '../services/chat_service.dart';
import '../models/chat_session.dart';
import '../models/parsed_transaction.dart';
import '../widgets/transaction_validation_dialog.dart';

enum ChatMode {
  transaction,
  amarthaRag,
  analytics,
}

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];

  // Chat mode
  ChatMode _currentMode = ChatMode.transaction;

  // Chat session
  ChatSession? _currentSession;

  // Voice recording for transcription
  late FlutterSoundRecorder _audioRecorder;
  bool _isRecording = false;
  String? _currentRecordingPath;
  bool _isLoading = false;

  // Image attachment (max 1)
  XFile? _attachedImage;

  @override
  void initState() {
    super.initState();
    _audioRecorder = FlutterSoundRecorder();
    _initializeRecorder();
    _initializeChat();
  }

  Future<void> _initializeRecorder() async {
    await _audioRecorder.openRecorder();
  }

  void _initializeChat() async {
    try {
      // Skip session creation for now since endpoint doesn't exist
      // _currentSession = await ChatService.createChatSession();
      
      // Add welcome message based on current mode
      _addWelcomeMessage();
    } catch (e) {
      _addBotMessage('Maaf, terjadi kesalahan saat menginisialisasi chat. Silakan coba lagi.');
    }
  }

  void _addWelcomeMessage() {
    String welcomeMessage;
    switch (_currentMode) {
      case ChatMode.transaction:
        welcomeMessage = 'Halo! Mode Transaksi aktif. Anda bisa:\n\n• Catat transaksi: "jual 5 telur seharga 10rb"\n• Tanya stok: "cek stok beras"\n• Gunakan suara atau foto untuk input';
        break;
      case ChatMode.amarthaRag:
        welcomeMessage = 'Halo! Mode Amartha Customer Service aktif. Anda bisa tanya tentang:\n\n• Produk pinjaman Amartha\n• Cara mengajukan pinjaman\n• Syarat dan ketentuan\n• Proses persetujuan';
        break;
      case ChatMode.analytics:
        welcomeMessage = 'Halo! Mode Analisis Bisnis aktif. Anda bisa tanya:\n\n• "Berapa total penjualan minggu ini?"\n• "Analisis kesehatan kredit saya"\n• "Produk apa yang paling laris?"\n• "Bagaimana tren cashflow saya?"';
        break;
    }
    _addBotMessage(welcomeMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Asisten AI KuBuku',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF5c2d91),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          PopupMenuButton<ChatMode>(
            icon: const Icon(Icons.settings, color: Colors.white),
            onSelected: (ChatMode mode) {
              setState(() {
                _currentMode = mode;
                _messages.clear(); // Clear existing messages
                _addWelcomeMessage(); // Add welcome message for new mode
              });
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<ChatMode>(
                value: ChatMode.transaction,
                child: Row(
                  children: [
                    Icon(
                      Icons.receipt_long,
                      color: _currentMode == ChatMode.transaction 
                          ? const Color(0xFF5c2d91) 
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transaksi',
                      style: TextStyle(
                        fontWeight: _currentMode == ChatMode.transaction
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<ChatMode>(
                value: ChatMode.amarthaRag,
                child: Row(
                  children: [
                    Icon(
                      Icons.help_center,
                      color: _currentMode == ChatMode.amarthaRag
                          ? const Color(0xFF5c2d91)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Amartha CS',
                      style: TextStyle(
                        fontWeight: _currentMode == ChatMode.amarthaRag
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<ChatMode>(
                value: ChatMode.analytics,
                child: Row(
                  children: [
                    Icon(
                      Icons.analytics,
                      color: _currentMode == ChatMode.analytics
                          ? const Color(0xFF5c2d91)
                          : Colors.grey,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Analisis',
                      style: TextStyle(
                        fontWeight: _currentMode == ChatMode.analytics
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Mode indicator
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _getModeColor().withOpacity(0.1),
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getModeIcon(),
                  color: _getModeColor(),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  'Mode: ${_getModeDisplayName()}',
                  style: TextStyle(
                    color: _getModeColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  'Tap ⚙️ untuk ganti mode',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isLoading) {
                        return _buildTypingIndicator();
                      }
                      final message = _messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                ),
                if (_messages.length <= 1) _buildSuggestionChips(),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Color _getModeColor() {
    switch (_currentMode) {
      case ChatMode.transaction:
        return const Color(0xFF5c2d91);
      case ChatMode.amarthaRag:
        return Colors.blue;
      case ChatMode.analytics:
        return Colors.green;
    }
  }

  IconData _getModeIcon() {
    switch (_currentMode) {
      case ChatMode.transaction:
        return Icons.receipt_long;
      case ChatMode.amarthaRag:
        return Icons.help_center;
      case ChatMode.analytics:
        return Icons.analytics;
    }
  }

  String _getModeDisplayName() {
    switch (_currentMode) {
      case ChatMode.transaction:
        return 'Transaksi';
      case ChatMode.amarthaRag:
        return 'Amartha Customer Service';
      case ChatMode.analytics:
        return 'Analisis Bisnis';
    }
  }

  String _getInputHintText() {
    if (_attachedImage != null) {
      return 'Tambah keterangan untuk gambar (opsional)...';
    }
    
    switch (_currentMode) {
      case ChatMode.transaction:
        return 'Catat transaksi atau tanya stok...';
      case ChatMode.amarthaRag:
        return 'Tanya tentang Amartha...';
      case ChatMode.analytics:
        return 'Tanya analisis bisnis Anda...';
    }
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5c2d91), Color(0xFF7b4397)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: EdgeInsets.only(
                left: isUser ? 40 : 0,
                right: isUser ? 0 : 40,
              ),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF5c2d91) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.imagePath != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: kIsWeb
                            ? FutureBuilder<Uint8List>(
                                future: () async {
                                  // For web, imagePath contains the bytes as base64 or direct bytes
                                  // We'll store the bytes directly in the message
                                  return Uint8List(0); // Placeholder - we'll fix this separately
                                }(),
                                builder: (context, snapshot) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  );
                                },
                              )
                            : FutureBuilder<Uint8List>(
                                future: () async {
                                  // For mobile, we'll also use bytes for consistency
                                  return Uint8List(0); // Placeholder
                                }(),
                                builder: (context, snapshot) {
                                  return Container(
                                    width: 200,
                                    height: 200,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[300],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.image,
                                      color: Colors.grey,
                                      size: 40,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: Colors.grey[600], size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5c2d91), Color(0xFF7b4397)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(right: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0),
                const SizedBox(width: 4),
                _buildTypingDot(200),
                const SizedBox(width: 4),
                _buildTypingDot(400),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot(int delay) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.5 + (0.5 * value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Image attachment preview
            if (_attachedImage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? FutureBuilder<Uint8List>(
                              future: _attachedImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  );
                                } else {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  );
                                }
                              },
                            )
                          : FutureBuilder<Uint8List>(
                              future: _attachedImage!.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  );
                                } else {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[300],
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  );
                                }
                              },
                            ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Gambar siap dikirim',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF5c2d91),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _attachedImage = null;
                        });
                      },
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            // Input row
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: _getInputHintText(),
                        hintStyle: const TextStyle(color: Colors.grey),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onSubmitted: (text) => _sendMessage(),
                      onChanged: (text) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Camera button (only in transaction mode)
                if (_currentMode == ChatMode.transaction)
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF5c2d91).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _attachedImage == null ? _showImageSourceDialog : null,
                      icon: Icon(
                        Icons.camera_alt, 
                        color: _attachedImage == null 
                            ? const Color(0xFF5c2d91) 
                            : Colors.grey,
                      ),
                    ),
                  ),
                if (_currentMode == ChatMode.transaction)
                  const SizedBox(width: 8),
                // Voice recording button (only in transaction mode)
                if (_currentMode == ChatMode.transaction)
                  InkWell(
                    onTap: () {
                      // Toggle recording on/off
                      if (!_isLoading) {
                        if (_isRecording) {
                          _stopVoiceRecording();
                        } else {
                          _startVoiceRecording();
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isRecording
                            ? Colors.red
                            : const Color(0xFF5c2d91).withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: _isRecording 
                            ? Border.all(color: Colors.red.shade300, width: 2)
                            : null,
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        color: _isRecording ? Colors.white : const Color(0xFF5c2d91),
                        size: 24,
                      ),
                    ),
                  ),
                if (_currentMode == ChatMode.transaction)
                  const SizedBox(width: 8),
                // Send button
                Container(
                  decoration: BoxDecoration(
                    gradient: (_messageController.text.trim().isNotEmpty || _attachedImage != null)
                        ? const LinearGradient(
                            colors: [Color(0xFF5c2d91), Color(0xFF7b4397)],
                          )
                        : null,
                    color: (_messageController.text.trim().isEmpty && _attachedImage == null)
                        ? Colors.grey[300]
                        : null,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed:
                        (_messageController.text.trim().isNotEmpty || _attachedImage != null) && !_isLoading
                        ? _sendMessage
                        : null,
                    icon: Icon(
                      Icons.send,
                      color: (_messageController.text.trim().isNotEmpty || _attachedImage != null)
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    final attachedImage = _attachedImage;
    
    // Must have either text or image
    if (text.isEmpty && attachedImage == null) return;
    if (_isLoading) return;

    // Clear input and attachment
    _messageController.clear();
    setState(() {
      _attachedImage = null;
    });

    // Send message based on type
    if (attachedImage != null) {
      // Send image with optional text
      _sendImageMessage(attachedImage, additionalText: text.isEmpty ? null : text);
    } else {
      // Send text only
      _sendTextMessage(text);
    }
  }

  void _sendTextMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    // Call AI service
    _handleAIResponse(text);
  }

  void _handleAIResponse(String userMessage) async {
    try {
      // Route based on current chat mode
      switch (_currentMode) {
        case ChatMode.transaction:
          await _handleTransactionMode(userMessage);
          break;
        case ChatMode.amarthaRag:
          await _handleAmarthaRagMode(userMessage);
          break;
        case ChatMode.analytics:
          await _handleAnalyticsMode(userMessage);
          break;
      }
    } catch (e) {
      _addBotMessage('Maaf, terjadi kesalahan. Silakan coba lagi.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleTransactionMode(String userMessage) async {
    try {
      // For simple greetings and casual chat, use direct chat endpoint
      final lowerMessage = userMessage.toLowerCase().trim();
      if (_isSimpleGreetingOrChat(lowerMessage)) {
        final response = await ChatService.sendChatMessage(userMessage);
        _addBotMessage(response);
        return;
      }
      
      // For potential transactions, try parsing first
      final parsedTransaction = await ChatService.parseTransaction(
        userMessage, 
        sessionId: _currentSession?.sessionId
      );
      
      // Handle different types of responses
      if (parsedTransaction.isStockTransaction) {
        // Show transaction validation dialog
        _showTransactionValidationDialog(parsedTransaction, userMessage);
      } else if (parsedTransaction.isStockQuery) {
        // Handle stock queries
        _handleStockQuery(parsedTransaction);
      } else if (parsedTransaction.isAmarthaRelated) {
        // Redirect to Amartha mode suggestion
        _addBotMessage('Sepertinya ini pertanyaan tentang Amartha. Coba ganti ke mode "Amartha CS" di menu ⚙️ untuk mendapat jawaban yang lebih akurat!');
      } else {
        // Handle general queries with chat endpoint
        final response = await ChatService.sendChatMessage(userMessage);
        _addBotMessage(response);
      }
    } catch (e) {
      // If transaction parsing fails, fallback to regular chat
      try {
        final response = await ChatService.sendChatMessage(userMessage);
        _addBotMessage(response);
      } catch (chatError) {
        throw Exception('Failed to get response');
      }
    }
  }

  Future<void> _handleAmarthaRagMode(String userMessage) async {
    try {
      final response = await ChatService.sendAmarthaRagMessage(
        userMessage,
        sessionId: _currentSession?.sessionId,
      );
      _addBotMessage(response);
    } catch (e) {
      print('Amartha RAG Error: $e');
      _addBotMessage('Maaf, sistem Amartha Customer Service sedang mengalami gangguan. Silakan coba lagi atau hubungi customer service langsung.\n\nError: $e');
    }
  }

  Future<void> _handleAnalyticsMode(String userMessage) async {
    try {
      final response = await ChatService.sendAnalyticsMessage(userMessage);
      _addBotMessage(response);
    } catch (e) {
      print('Analytics Error: $e');
      _addBotMessage('Maaf, sistem analisis bisnis sedang mengalami gangguan. Silakan coba lagi nanti.\n\nError: $e');
    }
  }

  bool _isSimpleGreetingOrChat(String message) {
    final greetings = [
      'halo', 'hai', 'hi', 'hello', 'hey', 'hoi',
      'selamat pagi', 'selamat siang', 'selamat sore', 'selamat malam',
      'apa kabar', 'gimana', 'bagaimana',
      'terima kasih', 'thanks', 'makasih',
      'ok', 'oke', 'baik', 'siap'
    ];
    
    // Check if message is just a greeting
    for (String greeting in greetings) {
      if (message == greeting || message.startsWith('$greeting ')) {
        return true;
      }
    }
    
    // Check if message is very short and doesn't contain transaction keywords
    if (message.length <= 10 && !_containsTransactionKeywords(message)) {
      return true;
    }
    
    return false;
  }
  
  bool _containsTransactionKeywords(String message) {
    final transactionKeywords = [
      'jual', 'beli', 'kulakan', 'stok', 'harga', 'rp', 'rupiah',
      'pcs', 'kg', 'gram', 'liter', 'dus', 'karung', 'ekor',
      'transaksi', 'pembayaran', 'bayar'
    ];
    
    for (String keyword in transactionKeywords) {
      if (message.contains(keyword)) {
        return true;
      }
    }
    
    return false;
  }

  void _showTransactionValidationDialog(ParsedTransaction parsedTransaction, String userMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TransactionValidationDialog(
        parsedTransaction: parsedTransaction,
        originalMessage: userMessage,
      ),
    ).then((result) {
      if (result == true) {
        _addBotMessage('Transaksi berhasil disimpan! Ada lagi yang mau dicatat?');
      } else {
        _addBotMessage('Transaksi dibatalkan. Ada yang bisa saya bantu lagi?');
      }
    });
  }

  void _handleStockQuery(ParsedTransaction parsedTransaction) {
    // For now, show a simple response. This can be enhanced later.
    final items = parsedTransaction.items;
    if (items.isNotEmpty) {
      final productNames = items.map((item) => item.productName).join(', ');
      _addBotMessage('Informasi stok untuk $productNames sedang diproses. Fitur ini akan segera tersedia.');
    } else {
      _addBotMessage('Mohon sebutkan produk yang ingin dicek stoknya.');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addBotMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: false));
    });
  }

  Widget _buildSuggestionChips() {
    List<String> suggestions;
    
    switch (_currentMode) {
      case ChatMode.transaction:
        suggestions = [
          'jual 5 telur seharga 10rb',
          'beli beras 2 karung',
          'cek stok minyak goreng',
          'tambah stok gula',
          'berapa keuntungan hari ini?',
        ];
        break;
      case ChatMode.amarthaRag:
        suggestions = [
          'Bagaimana cara mengajukan pinjaman?',
          'Berapa bunga pinjaman UMKM?',
          'Syarat pinjaman Amartha',
          'Proses persetujuan berapa lama?',
          'Cara pembayaran cicilan',
        ];
        break;
      case ChatMode.analytics:
        suggestions = [
          'Berapa total penjualan minggu ini?',
          'Analisis kesehatan kredit saya',
          'Produk apa yang paling laris?',
          'Bagaimana tren cashflow saya?',
          'Berapa keuntungan bulan ini?',
        ];
        break;
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Coba tanyakan (${_getModeDisplayName()}):',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: _getModeColor(),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              return GestureDetector(
                onTap: () {
                  _messageController.text = suggestion;
                  _sendMessage();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _getModeColor().withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    suggestion,
                    style: const TextStyle(
                      color: Color(0xFF5c2d91),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Voice recording methods
  Future<void> _startVoiceRecording() async {
    try {
      // Request permissions
      if (await Permission.microphone.request() != PermissionStatus.granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Izin mikrofon diperlukan untuk merekam suara'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Create audio file path using timestamp
      final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
      final tempDir = Directory.systemTemp;
      final path = '${tempDir.path}/$fileName';

      // Start recording
      await _audioRecorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
      );

      setState(() {
        _isRecording = true;
        _currentRecordingPath = path;
      });

      // Show recording indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.mic, color: Colors.white),
              SizedBox(width: 8),
              Expanded(child: Text('🎤 Merekam... Lepas untuk mengirim')),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 60), // Long duration
          behavior: SnackBarBehavior.floating,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error memulai rekaman: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopVoiceRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      
      setState(() {
        _isRecording = false;
      });

      // Hide recording snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (path != null && _currentRecordingPath != null) {
        // Process the recorded audio
        _processVoiceRecording(_currentRecordingPath!);
      }
      
      _currentRecordingPath = null;
      
    } catch (e) {
      setState(() {
        _isRecording = false;
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error menghentikan rekaman: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _processVoiceRecording(String audioPath) async {
    setState(() {
      _messages.add(
        ChatMessage(
          text: 'Memproses suara...',
          isUser: true,
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      String transcript;
      
      // Only use voice transcription endpoint for transaction mode
      if (_currentMode == ChatMode.transaction) {
        // Call backend voice transcription + parsing service
        final response = await ChatService.transcribeAndParseVoice(
          audioPath,
          sessionId: _currentSession?.sessionId,
        );

        transcript = response['transcript'] as String? ?? '';
        final structuredResponse = response['structured_response'] as Map<String, dynamic>?;

        if (transcript.isEmpty) {
          throw Exception('Tidak ada teks yang terdeteksi dari suara');
        }

        // Update user message with transcript
        setState(() {
          _messages.removeLast(); // Remove "processing" message
          _messages.add(
            ChatMessage(
              text: '🎤 "$transcript"',
              isUser: true,
            ),
          );
          _isLoading = false;
        });

        // Check if it's a transaction (category = "stock")
        if (structuredResponse != null && 
            structuredResponse['category'] == 'stock' &&
            structuredResponse['action'] == 'create') {
          
          // Parse as transaction and show validation dialog
          try {
            final parsedTransaction = ParsedTransaction.fromJson(structuredResponse);
            
            final shouldSave = await showDialog<bool>(
              context: context,
              barrierDismissible: false,
              builder: (context) => TransactionValidationDialog(
                originalMessage: transcript,
                parsedTransaction: parsedTransaction,
              ),
            );

            if (shouldSave == true) {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text: 'Transaksi berhasil disimpan! ✅',
                    isUser: false,
                  ),
                );
              });
            } else {
              setState(() {
                _messages.add(
                  ChatMessage(
                    text: 'Transaksi dibatalkan.',
                    isUser: false,
                  ),
                );
              });
            }
          } catch (e) {
            // If parsing fails, treat as regular chat
            _handleRegularVoiceChatResponse(transcript, structuredResponse);
          }
        } else {
          // Handle as regular chat - use transcript as the response
          _handleRegularVoiceChatResponse(transcript, structuredResponse);
        }
      } else {
        // For non-transaction modes, we need a simple transcription
        // Since we don't have a simple transcription endpoint, we'll use the transaction one
        // but ignore the structured response and just use the transcript
        final response = await ChatService.transcribeAndParseVoice(
          audioPath,
          sessionId: _currentSession?.sessionId,
        );

        transcript = response['transcript'] as String? ?? '';

        if (transcript.isEmpty) {
          throw Exception('Tidak ada teks yang terdeteksi dari suara');
        }

        // Update user message with transcript
        setState(() {
          _messages.removeLast(); // Remove "processing" message
          _messages.add(
            ChatMessage(
              text: '🎤 "$transcript"',
              isUser: true,
            ),
          );
        });

        // Process transcript through the appropriate mode
        _handleAIResponse(transcript);
      }

    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.removeLast(); // Remove "processing" message
        _messages.add(
          ChatMessage(
            text: 'Error memproses suara: $e',
            isUser: false,
          ),
        );
      });
    } finally {
      // Clean up audio file
      try {
        final file = File(audioPath);
        if (file.existsSync()) {
          await file.delete();
        }
      } catch (e) {
        print('Error deleting audio file: $e');
      }
    }
  }

  void _handleRegularVoiceChatResponse(String transcript, Map<String, dynamic>? structuredResponse) {
    setState(() {
      _isLoading = false;
      _messages.add(
        ChatMessage(
          text: transcript, // Just echo back the transcript
          isUser: false,
        ),
      );
    });
    
    _scrollToBottom();
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Pilih Sumber Gambar',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5c2d91),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF5c2d91)),
                title: const Text('Kamera'),
                subtitle: const Text('Ambil foto langsung'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageForAttachment(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF5c2d91),
                ),
                title: const Text('Galeri'),
                subtitle: const Text('Pilih dari galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageForAttachment(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel, color: Colors.grey),
                title: const Text('Batal'),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageForAttachment(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _attachedImage = image;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error mengambil gambar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }



  void _sendImageMessage(XFile image, {String? additionalText}) async {
    // Add user message with image
    final displayText = additionalText?.isNotEmpty == true 
        ? '$additionalText' 
        : 'Gambar dikirim untuk analisis';
    
    setState(() {
      _messages.add(
        ChatMessage(
          text: displayText,
          isUser: true,
          imagePath: image.path,
        ),
      );
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // Try to parse transaction using OCR + text
      final parsedTransaction = await ChatService.parseTransactionWithImage(
        imageFile: image, // Pass XFile directly
        message: additionalText?.isNotEmpty == true ? additionalText : null,
        sessionId: _currentSession?.sessionId,
        onMimeInfo: (String info) {
          // Show MIME info in placeholder text
          if (mounted) {
            setState(() {
              _messageController.text = info;
            });
            // Clear after 3 seconds
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted && _messageController.text == info) {
                setState(() {
                  _messageController.clear();
                });
              }
            });
          }
        },
      );

      // Show validation dialog
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        final shouldSave = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => TransactionValidationDialog(
            originalMessage: displayText,
            parsedTransaction: parsedTransaction,
          ),
        );

        if (shouldSave == true) {
          _addBotMessage('✅ Transaksi berhasil disimpan!');
        } else {
          _addBotMessage('ℹ️ Transaksi dibatalkan.');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        String errorMessage;
        if (e.toString().contains('category":"other"') || 
            e.toString().contains('category":"amartha"')) {
          // Handle non-transaction messages
          try {
            final aiResponse = await ChatService.sendChatMessage(
              additionalText?.isNotEmpty == true 
                ? 'Gambar dengan pesan: $additionalText' 
                : 'Analisis gambar ini'
            );
            _addBotMessage(aiResponse);
            return;
          } catch (chatError) {
            errorMessage = 'Maaf, saya tidak bisa memproses gambar ini. Pastikan gambar berisi struk belanja atau informasi transaksi yang jelas.';
          }
        } else {
          errorMessage = 'Error memproses gambar: ${e.toString()}';
        }
        
        _addBotMessage('❌ $errorMessage');
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.closeRecorder();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final String? imagePath;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
    this.imagePath,
  }) : timestamp = timestamp ?? DateTime.now();
}
