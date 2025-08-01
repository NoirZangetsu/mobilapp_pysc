import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import '../widgets/message_bubble.dart';
import '../widgets/voice_button.dart';
import 'debug/firestore_test_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        title: Text(
          'Dinleyen Zeka',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.headingText),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: AppColors.secondaryText),
            onPressed: () {
              _showInfoDialog();
            },
          ),
          IconButton(
            icon: const Icon(Icons.bug_report, color: AppColors.secondaryText),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FirestoreTestScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.secondaryText),
            onPressed: () {
              _showLogoutDialog();
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Column(
            children: [
              // Messages area
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
              
              // Voice control area
              _buildVoiceControlArea(chatProvider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWelcomeMessage() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.accentBlue,
                borderRadius: BorderRadius.circular(60),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentBlue.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                size: 60,
                color: AppColors.headingText,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Merhaba!',
              style: AppTextStyles.displaySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Ben Dinleyen Zeka. Aklından geçenleri sesli olarak paylaşmak için aşağıdaki mikrofona dokunman yeterli. Seni dinlemek için buradayım.',
              style: AppTextStyles.welcomeSubtitle,
              textAlign: TextAlign.center,
            ),
          ],
        ),
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
          const Icon(
            Icons.mic,
            color: AppColors.accentBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              partialText,
              style: AppTextStyles.statusText.copyWith(
                color: AppColors.accentBlue,
                fontStyle: FontStyle.italic,
              ),
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
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              error,
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.error, size: 20),
            onPressed: () {
              context.read<ChatProvider>().clearError();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceControlArea(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (chatProvider.isListening)
                _buildStatusIndicator('Dinleniyor...', AppColors.listeningIndicator),
              if (chatProvider.isProcessing)
                _buildStatusIndicator('İşleniyor...', AppColors.processingIndicator),
              if (chatProvider.isSpeaking)
                _buildStatusIndicator('Konuşuyor...', AppColors.speakingIndicator),
            ],
          ),
          const SizedBox(height: 24),
          
          // Voice button
          VoiceButton(
            isListening: chatProvider.isListening,
            isProcessing: chatProvider.isProcessing,
            isSpeaking: chatProvider.isSpeaking,
            onTap: () async {
              if (chatProvider.isListening) {
                await chatProvider.stopListening();
              } else if (!chatProvider.isProcessing && !chatProvider.isSpeaking) {
                await chatProvider.startListening();
                _scrollToBottom();
              }
            },
          ),
          
          const SizedBox(height: 16),
          
          // Instructions
          Text(
            chatProvider.isListening
                ? 'Konuşmayı bitirmek için tekrar basın'
                : 'Konuşmaya başlamak için basın',
            style: AppTextStyles.statusText,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String text, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: AppTextStyles.statusText.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceBackground,
        title: Text(
          'Dinleyen Zeka Hakkında',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'Bu uygulama, sesli etkileşimli bir kişisel danışman uygulamasıdır. '
          'Gemini 2.0 Flash yapay zeka modeli kullanılarak geliştirilmiştir.\n\n'
          'Önemli Not: Bu uygulama profesyonel bir terapi veya tıbbi danışmanlık '
          'hizmeti sunmamaktadır. Ciddi konular için mutlaka bir sağlık '
          'profesyoneli ile görüşünüz.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Anladım',
              style: AppTextStyles.linkMedium,
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceBackground,
        title: Text(
          'Çıkış Yap',
          style: AppTextStyles.headingSmall,
        ),
        content: Text(
          'Uygulamadan çıkış yapmak istediğinize emin misiniz?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'İptal',
              style: AppTextStyles.linkMedium,
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<AuthProvider>().signOut();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text(
              'Çıkış Yap',
              style: AppTextStyles.linkMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
} 