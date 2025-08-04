import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_button.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _isProcessingPDF = false;
  bool _isProcessingImage = false;
  bool _isTyping = false;
  bool _isKeyboardVisible = false;
  File? _selectedImageFile;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
    
    // Add keyboard listener to scroll to bottom when keyboard appears
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        if (keyboardHeight > 0) {
          _scrollToBottom();
        }
      }
    });
    
    // Add focus listener to scroll when text field is focused
    _textFocusNode.addListener(() {
      if (_textFocusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _scrollToBottom();
          }
        });
      }
    });
    
    // Add keyboard visibility listener
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
        setState(() {
          _isKeyboardVisible = keyboardHeight > 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickAndProcessPDF() async {
    try {
      setState(() => _isProcessingPDF = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentUser != null) {
          await context.read<ChatProvider>().processPDFFile(
            result.files.single.path!,
          );
          
          _textController.text = 'Bu PDF hakkında ne sormak istiyorsun?';
          _textFocusNode.requestFocus();
        }
      }
    } catch (e) {
      _showErrorSnackBar('PDF işleme hatası: $e');
    } finally {
      setState(() => _isProcessingPDF = false);
    }
  }

  Future<void> _pickAndProcessImage() async {
    try {
      setState(() => _isProcessingImage = true);
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
      );

      if (result != null) {
        final authProvider = context.read<AuthProvider>();
        if (authProvider.currentUser != null) {
          final imageFile = File(result.files.single.path!);
          
          _textController.text = 'Bu görüntü hakkında ne sormak istiyorsun?';
          _textFocusNode.requestFocus();
          _selectedImageFile = imageFile;
        }
      }
    } catch (e) {
      _showErrorSnackBar('Görüntü işleme hatası: $e');
    } finally {
      setState(() => _isProcessingImage = false);
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    _textFocusNode.unfocus();
    
    final chatProvider = context.read<ChatProvider>();
    
    if (_selectedImageFile != null) {
      await chatProvider.processImageWithQuestion(text, _selectedImageFile!);
      _selectedImageFile = null;
    } else {
      await chatProvider.sendTextMessage(text);
    }
    
    _scrollToBottom();
  }

  bool get _isSmallScreen => MediaQuery.of(context).size.height < 600;
  bool get _isVerySmallScreen => MediaQuery.of(context).size.height < 500;

  void _updateKeyboardVisibility() {
    if (mounted) {
      final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
      final newKeyboardVisible = keyboardHeight > 0;
      if (_isKeyboardVisible != newKeyboardVisible) {
        setState(() {
          _isKeyboardVisible = newKeyboardVisible;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Update keyboard visibility
    _updateKeyboardVisibility();
    
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        title: Text(
          'Öğrenme Asistanı',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.headingText),
        actions: [
          // New conversation button
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.accentBlue),
            onPressed: () {
              _showNewConversationDialog();
            },
            tooltip: 'Yeni Sohbet',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.secondaryText),
            onPressed: () {
              _showInfoDialog();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    // Document context indicator
                    if (chatProvider.currentDocument != null)
                      _buildDocumentContextIndicator(chatProvider),
                    
                    // Messages area - wrapped in Expanded to handle overflow properly
                    Expanded(
                      child: chatProvider.messages.isEmpty
                          ? _buildWelcomeMessage()
                          : _buildMessagesList(chatProvider),
                    ),
                    
                    // Partial text indicator
                    if (chatProvider.partialText.isNotEmpty)
                      _buildPartialTextIndicator(chatProvider.partialText),
                    
                    // Error display
                    if (chatProvider.error != null)
                      _buildErrorDisplay(chatProvider.error!),
                    
                    // Input area - wrapped in Container with proper constraints
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: _isKeyboardVisible 
                            ? (_isVerySmallScreen ? 80.0 : 120.0) // Very compact for small screens
                            : (_isSmallScreen ? 120.0 : 150.0), // Compact for small screens
                      ),
                      child: _buildInputArea(chatProvider),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon container
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentBlue.withValues(alpha: 0.2),
                  AppColors.accentBlue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(60),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 60,
              color: AppColors.accentBlue,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Merhaba! Ben senin öğrenme asistanın.',
            style: AppTextStyles.headingSmall.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.borderLight,
              ),
            ),
            child: Column(
              children: [
                _buildFeatureItem(Icons.edit, 'Metin yazarak sorular sor'),
                const SizedBox(height: 8),
                _buildFeatureItem(Icons.mic, 'Sesli konuşma yap'),
                const SizedBox(height: 8),
                _buildFeatureItem(Icons.upload_file, 'PDF ve görüntü yükle'),
                const SizedBox(height: 8),
                _buildFeatureItem(Icons.auto_awesome, 'AI ile öğrenme içeriği oluştur'),
                const SizedBox(height: 8),
                _buildFeatureItem(Icons.visibility, 'Görsel analiz yap'),
                const SizedBox(height: 8),
                _buildFeatureItem(Icons.description, 'Belge içeriklerini analiz et'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Herhangi bir konuda soru sorabilirsin!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.accentBlue,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.headingText,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentContextIndicator(ChatProvider chatProvider) {
    final document = chatProvider.currentDocument!;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accentBlue.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.description, color: AppColors.accentBlue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktif Doküman',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentBlue,
                  ),
                ),
                Text(
                  document.fileName ?? 'Doküman',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () {
              chatProvider.setCurrentDocument(null);
            },
            color: AppColors.accentBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildMessagesList(ChatProvider chatProvider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: chatProvider.messages.length,
      itemBuilder: (context, index) {
        final message = chatProvider.messages[index];
        return MessageBubble(message: message);
      },
    );
  }

  Widget _buildPartialTextIndicator(String partialText) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.mic,
              color: AppColors.accentBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dinleniyor...',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  partialText,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentBlue,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorDisplay(String error) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hata',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  error,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.error, size: 16),
            onPressed: () {
              context.read<ChatProvider>().clearError();
            },
            tooltip: 'Kapat',
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).viewInsets.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        border: Border(
          top: BorderSide(
            color: AppColors.borderLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Text input area
          Row(
            children: [
              Expanded(
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 44,
                    maxHeight: _isKeyboardVisible 
                        ? (_isVerySmallScreen ? 50 : 60) // Very compact for small screens
                        : (_isSmallScreen ? 60 : 80), // Compact for small screens
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: AppColors.inputBorder,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          focusNode: _textFocusNode,
                          style: AppTextStyles.bodyMedium,
                          decoration: InputDecoration(
                            hintText: 'Mesajınızı yazın...',
                            hintStyle: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.inputLabel,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          maxLines: null,
                          minLines: 1,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendTextMessage(),
                          onChanged: (value) {
                            setState(() {
                              _isTyping = value.isNotEmpty;
                            });
                          },
                        ),
                      ),
                      // Send button
                      if (_isTyping)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          child: IconButton(
                            icon: const Icon(Icons.send, color: AppColors.accentBlue),
                            onPressed: _sendTextMessage,
                            tooltip: 'Gönder',
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Voice button
              Container(
                width: 44,
                height: 44,
                child: VoiceButton(
                  isListening: chatProvider.isListening,
                  isProcessing: chatProvider.isProcessing,
                  isSpeaking: chatProvider.isSpeaking,
                  onTap: () {
                    if (chatProvider.isListening) {
                      chatProvider.stopListening();
                    } else {
                      chatProvider.startListening();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Quick action buttons - only show when keyboard is not visible and there's enough space
          if (!_isKeyboardVisible && !_isVerySmallScreen)
            Container(
              height: _isSmallScreen ? 32 : 40, // Smaller height for small screens
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickActionButton(
                          icon: Icons.image,
                          label: 'Görüntü',
                          onTap: _pickAndProcessImage,
                          isLoading: _isProcessingImage,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionButton(
                          icon: Icons.upload_file,
                          label: 'PDF',
                          onTap: _pickAndProcessPDF,
                          isLoading: _isProcessingPDF,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionButton(
                          icon: Icons.mic,
                          label: 'Sesli',
                          onTap: () {
                            if (chatProvider.isListening) {
                              chatProvider.stopListening();
                            } else {
                              chatProvider.startListening();
                            }
                          },
                          isLoading: chatProvider.isListening,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionButton(
                          icon: Icons.auto_awesome,
                          label: 'AI Yardım',
                          onTap: () {
                            _textController.text = 'Merhaba, bana yardım edebilir misin?';
                            _sendTextMessage();
                          },
                          isLoading: false,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionButton(
                          icon: Icons.school,
                          label: 'Flashcard',
                          onTap: () {
                            _showEducationalContentDialog('flashcard');
                          },
                          isLoading: false,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionButton(
                          icon: Icons.mic,
                          label: 'Podcast',
                          onTap: () {
                            _showEducationalContentDialog('podcast');
                          },
                          isLoading: false,
                        ),
                        const SizedBox(width: 6),
                        _buildQuickActionButton(
                          icon: Icons.summarize,
                          label: 'Özet',
                          onTap: () {
                            _showEducationalContentDialog('summary');
                          },
                          isLoading: false,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: _isVerySmallScreen ? 6 : (MediaQuery.of(context).size.width < 400 ? 8 : 12), // More compact on very small screens
          vertical: _isSmallScreen ? 6 : 8, // Smaller vertical padding for small screens
        ),
        decoration: BoxDecoration(
          color: isLoading 
              ? AppColors.accentBlue.withValues(alpha: 0.3)
              : AppColors.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.3),
          ),
          boxShadow: isLoading ? [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                ),
              )
            else
              Icon(icon, size: _isVerySmallScreen ? 14 : 16, color: AppColors.accentBlue),
            const SizedBox(width: 6),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
                fontSize: _isVerySmallScreen ? 10 : 12, // Smaller font for very small screens
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Öğrenme Asistanı Hakkında'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bu uygulama ile:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Metin yazarak sorular sorabilirsiniz'),
            Text('• Sesli konuşma yapabilirsiniz'),
            Text('• PDF dosyaları yükleyebilirsiniz'),
            Text('• Görüntüler yükleyebilirsiniz'),
            Text('• Bilgi kartları oluşturabilirsiniz'),
            Text('• Podcast\'ler oluşturabilirsiniz'),
            SizedBox(height: 16),
            Text(
              'Tüm içerikleriniz güvenle saklanır ve istediğiniz zaman erişebilirsiniz.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showNewConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Sohbet Başlat'),
        content: const Text('Bu sohbeti başlatmak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatProvider>().clearMessages();
              _textController.clear();
              _textFocusNode.unfocus();
              _selectedImageFile = null;
            },
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
  }

  void _showEducationalContentDialog(String type) {
    final chatProvider = context.read<ChatProvider>();
    
    if (chatProvider.currentDocument == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Önce bir doküman yüklemelisiniz.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    String title;
    String content;
    IconData icon;

    switch (type) {
      case 'flashcard':
        title = 'Flashcard Oluştur';
        content = 'Mevcut dokümandan eğitimsel flashcard\'lar oluşturulacak. Bu işlem biraz zaman alabilir.';
        icon = Icons.school;
        break;
      case 'podcast':
        title = 'Podcast Oluştur';
        content = 'Mevcut dokümandan eğitimsel podcast içeriği oluşturulacak. Bu işlem biraz zaman alabilir.';
        icon = Icons.mic;
        break;
      case 'summary':
        title = 'Özet Oluştur';
        content = 'Mevcut dokümandan eğitimsel özet oluşturulacak. Bu işlem biraz zaman alabilir.';
        icon = Icons.summarize;
        break;
      default:
        title = 'İçerik Oluştur';
        content = 'Eğitimsel içerik oluşturulacak.';
        icon = Icons.auto_awesome;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: AppColors.accentBlue),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            const SizedBox(height: 16),
            Text(
              'Doküman: ${chatProvider.currentDocument!.fileName ?? 'Bilinmeyen'}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _generateEducationalContent(type);
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateEducationalContent(String type) async {
    final chatProvider = context.read<ChatProvider>();
    
    try {
      String result;
      switch (type) {
        case 'flashcard':
          result = await chatProvider.generateEducationalContentFromDocument('flashcard');
          break;
        case 'podcast':
          result = await chatProvider.generateEducationalContentFromDocument('podcast');
          break;
        case 'summary':
          result = await chatProvider.generateEducationalContentFromDocument('summary');
          break;
        default:
          throw Exception('Geçersiz içerik türü');
      }

      // Show result in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(
                type == 'flashcard' ? Icons.school : 
                type == 'podcast' ? Icons.mic : Icons.summarize,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 8),
              Text('${type.toUpperCase()} Oluşturuldu'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'İçerik başarıyla oluşturuldu:',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Text(
                    result,
                    style: AppTextStyles.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Copy to clipboard or save
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('İçerik kopyalandı'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              child: const Text('Kopyala'),
            ),
          ],
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
} 