import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/auth_provider.dart';
import '../providers/learning_provider.dart';
import '../models/flashcard.dart';
import '../models/document.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'flashcard_study_screen.dart';

class FlashcardsScreen extends StatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  State<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends State<FlashcardsScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _isProcessingPDF = false;
  bool _isProcessingImage = false;
  bool _isTyping = false;
  int _selectedCardCount = 10;

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Consumer<LearningProvider>(
          builder: (context, learningProvider, child) {
            return Column(
              children: [
                _buildAIAssistantSection(context, learningProvider),
                Expanded(
                  child: learningProvider.flashcardDecks.isEmpty
                      ? _buildEmptyState()
                      : _buildFlashcardsList(learningProvider),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surfaceBackground,
      elevation: 0,
      title: Text(
        'Bilgi Kartları',
        style: AppTextStyles.headingMedium,
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.headingText),
      actions: [
        _buildUploadButton(
          icon: Icons.image,
          isLoading: _isProcessingImage,
          onPressed: _pickAndProcessImage,
          tooltip: 'Görüntü Yükle',
        ),
        _buildUploadButton(
          icon: Icons.upload_file,
          isLoading: _isProcessingPDF,
          onPressed: _pickAndProcessPDF,
          tooltip: 'PDF Yükle',
        ),
        IconButton(
          icon: const Icon(Icons.add, color: AppColors.secondaryText),
          onPressed: () => _showCreateFlashcardDialog(context),
        ),
      ],
    );
  }

  Widget _buildUploadButton({
    required IconData icon,
    required bool isLoading,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return IconButton(
      icon: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              ),
            )
          : Icon(icon, color: AppColors.accentBlue),
      onPressed: isLoading ? null : onPressed,
      tooltip: tooltip,
    );
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
          final document = await context.read<LearningProvider>().processPDFFile(
            result.files.single.path!,
            authProvider.currentUser!.uid,
          );
          
          if (document != null) {
            _textController.text = 'Bu PDF\'den bilgi kartları oluştur';
            _textFocusNode.requestFocus();
          }
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
          final document = await context.read<LearningProvider>().processImageFile(
            result.files.single.path!,
            authProvider.currentUser!.uid,
          );
          
          if (document != null) {
            _textController.text = 'Bu görüntüden bilgi kartları oluştur';
            _textFocusNode.requestFocus();
          }
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
    
    final learningProvider = context.read<LearningProvider>();
    final authProvider = context.read<AuthProvider>();
    
    if (authProvider.currentUser != null) {
      await learningProvider.processFlashcardRequest(
        text, 
        authProvider.currentUser!.uid,
        cardCount: _selectedCardCount,
      );
    }
  }

  Widget _buildAIAssistantSection(BuildContext context, LearningProvider learningProvider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: _buildSectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIHeader(),
          const SizedBox(height: 12),
          _buildCardCountSelector(),
          const SizedBox(height: 8),
          _buildCardCountSlider(),
          const SizedBox(height: 12),
          _buildTextInputArea(),
          const SizedBox(height: 8),
          _buildQuickActionButtons(),
        ],
      ),
    );
  }

  BoxDecoration _buildSectionDecoration() {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.surfaceBackground,
          AppColors.surfaceBackground.withValues(alpha: 0.8),
        ],
      ),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: AppColors.accentBlue.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.accentBlue.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildAIHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.psychology, color: AppColors.accentBlue, size: 16),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Asistan',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Bilgi kartları oluşturmak için AI\'ya sorular sorun',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardCountSelector() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.style, size: 14, color: AppColors.accentBlue),
          const SizedBox(width: 6),
          Text(
            'Kart Sayısı:',
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.accentBlue,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$_selectedCardCount',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardCountSlider() {
    return Slider(
      value: _selectedCardCount.toDouble(),
      min: 5,
      max: 50,
      divisions: 9,
      activeColor: AppColors.accentBlue,
      inactiveColor: AppColors.accentBlue.withValues(alpha: 0.2),
      onChanged: (value) => setState(() => _selectedCardCount = value.round()),
    );
  }

  Widget _buildTextInputArea() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(12),
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
                hintText: 'AI asistanına sorun...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.inputLabel,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              maxLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendTextMessage(),
              onChanged: (value) => setState(() => _isTyping = value.isNotEmpty),
            ),
          ),
          if (_isTyping)
            Container(
              margin: const EdgeInsets.only(right: 4),
              child: IconButton(
                icon: const Icon(Icons.send, color: AppColors.accentBlue, size: 20),
                onPressed: _sendTextMessage,
                tooltip: 'Gönder',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons() {
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
            icon: Icons.auto_awesome,
            label: 'Otomatik',
            onTap: () {
              _textController.text = 'Bu konu için $_selectedCardCount bilgi kartı oluştur';
              _sendTextMessage();
            },
            isLoading: false,
          ),
          const SizedBox(width: 6),
          _buildQuickActionButton(
            icon: Icons.school,
            label: 'Öğrenme',
            onTap: () {
              _textController.text = 'Öğrenme teknikleri için $_selectedCardCount kart yap';
              _sendTextMessage();
            },
            isLoading: false,
          ),
        ],
      ),
    );
  }

  Widget _buildExampleQuestion(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 12,
            color: AppColors.accentBlue.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              question,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isLoading 
              ? AppColors.accentBlue.withValues(alpha: 0.3)
              : AppColors.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.accentBlue.withValues(alpha: 0.3),
          ),
          boxShadow: isLoading ? [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                ),
              )
            else
              Icon(icon, size: 14, color: AppColors.accentBlue),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateSection(BuildContext context, LearningProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yeni Bilgi Kartları Oluştur',
            style: AppTextStyles.headingSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Konu veya dokümanlardan otomatik olarak bilgi kartları oluşturun',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isCreatingFlashcards
                      ? null
                      : () => _showCreateFromTopicDialog(context, provider),
                  icon: provider.isCreatingFlashcards
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.topic),
                  label: const Text('Konudan Oluştur'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: provider.isCreatingFlashcards || provider.documents.isEmpty
                      ? null
                      : () => _showCreateFromDocumentDialog(context, provider),
                  icon: const Icon(Icons.description),
                  label: const Text('Dokümandan Oluştur'),
                ),
              ),
            ],
          ),
          if (provider.flashcardError != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                provider.flashcardError!,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accentBlue.withValues(alpha: 0.2),
                    AppColors.accentBlue.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(50),
                border: Border.all(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.style_outlined,
                size: 50,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz bilgi kartı oluşturmadınız',
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
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
                  _buildEmptyFeatureItem(Icons.psychology, 'AI asistanına sorular sorun'),
                  const SizedBox(height: 8),
                  _buildEmptyFeatureItem(Icons.upload_file, 'PDF veya görüntü yükleyin'),
                  const SizedBox(height: 8),
                  _buildEmptyFeatureItem(Icons.auto_awesome, 'Otomatik kart oluşturun'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Yukarıdaki AI asistanını kullanarak bilgi kartları oluşturmaya başlayın!',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeatureItem(IconData icon, String text) {
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

  Widget _buildFlashcardsList(LearningProvider provider) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: provider.flashcardDecks.length,
      itemBuilder: (context, index) {
        final deck = provider.flashcardDecks[index];
        return _buildFlashcardDeckCard(deck, provider, context);
      },
    );
  }

  Widget _buildFlashcardDeckCard(FlashcardDeck deck, LearningProvider provider, BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Direct access to study screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FlashcardStudyScreen(deck: deck),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentBlue.withValues(alpha: 0.05),
              blurRadius: 8,
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
                    color: AppColors.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.style,
                    color: AppColors.accentBlue,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deck.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (deck.description != null)
                        Text(
                          deck.description!,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.secondaryText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.secondaryText,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(deck.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.style,
                  size: 16,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  '${deck.cardCount} kart',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Çalış',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showCreateFlashcardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bilgi Kartları Oluştur'),
        content: const Text('Konu veya doküman seçerek bilgi kartları oluşturun.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCreateFromTopicDialog(context, context.read<LearningProvider>());
            },
            child: const Text('Konudan Oluştur'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCreateFromDocumentDialog(context, context.read<LearningProvider>());
            },
            child: const Text('Dokümandan Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showCreateFromTopicDialog(BuildContext context, LearningProvider provider) {
    final topicController = TextEditingController();
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konudan Bilgi Kartları Oluştur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: topicController,
              decoration: const InputDecoration(
                labelText: 'Konu',
                hintText: 'Örn: Matematik, Tarih, Bilim...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Başlık',
                hintText: 'Örn: Matematik Kartları',
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
              if (topicController.text.isNotEmpty && titleController.text.isNotEmpty) {
                Navigator.pop(context);
                final authProvider = context.read<AuthProvider>();
                if (authProvider.currentUser != null) {
                  await provider.createFlashcardsFromTopic(
                    authProvider.currentUser!.uid,
                    topicController.text,
                    titleController.text,
                  );
                }
              }
            },
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  void _showCreateFromDocumentDialog(BuildContext context, LearningProvider provider, [Document? document]) {
    final titleController = TextEditingController();
    Document? selectedDocument = document;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Dokümandan Bilgi Kartları Oluştur'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (document == null) ...[
                DropdownButtonFormField<Document>(
                  value: selectedDocument,
                  decoration: const InputDecoration(
                    labelText: 'Doküman Seç',
                  ),
                  items: provider.documents
                      .where((doc) => doc.status == 'completed')
                      .map((doc) => DropdownMenuItem(
                            value: doc,
                            child: Text(doc.fileName),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedDocument = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.description, color: AppColors.accentBlue, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          document.fileName,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accentBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Başlık',
                  hintText: 'Örn: Doküman Kartları',
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
              onPressed: selectedDocument != null && titleController.text.isNotEmpty
                  ? () async {
                      Navigator.pop(context);
                      final authProvider = context.read<AuthProvider>();
                      if (authProvider.currentUser != null) {
                        await provider.createFlashcardsFromDocument(
                          authProvider.currentUser!.uid,
                          selectedDocument!,
                          titleController.text,
                        );
                      }
                    }
                  : null,
              child: const Text('Oluştur'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, FlashcardDeck deck, LearningProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bilgi Kartlarını Sil'),
        content: Text('"${deck.title}" başlıklı bilgi kartlarını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = context.read<AuthProvider>();
              if (authProvider.currentUser != null) {
                await provider.deleteFlashcardDeck(
                  authProvider.currentUser!.uid,
                  deck.id,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
} 