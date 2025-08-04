import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../providers/auth_provider.dart';
import '../models/flashcard.dart';
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
  bool _isCreatingFlashcards = false; // Yeni loading state
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
        child: SingleChildScrollView(
          child: Consumer<LearningProvider>(
            builder: (context, learningProvider, child) {
              return Column(
                children: [
                  _buildAIAssistantSection(context, learningProvider),
                  if (learningProvider.flashcardDecks.isNotEmpty)
                    _buildFlashcardsList(learningProvider)
                  else
                    _buildEmptyState(),
                ],
              );
            },
          ),
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

    // Set loading state
    setState(() {
      _isCreatingFlashcards = true;
    });

    try {
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
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Bilgi kartları başarıyla oluşturuldu!'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bilgi kartları oluşturma hatası: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _isCreatingFlashcards = false;
        });
      }
    }
  }

  Widget _buildAIAssistantSection(BuildContext context, LearningProvider learningProvider) {
    return Container(
      margin: const EdgeInsets.all(12), // Reduced margin
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: _buildSectionDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIHeader(),
          const SizedBox(height: 8), // Reduced spacing
          _buildCardCountSelector(),
          const SizedBox(height: 6), // Reduced spacing
          _buildCardCountSlider(),
          const SizedBox(height: 8), // Reduced spacing
          _buildTextInputArea(),
          const SizedBox(height: 6), // Reduced spacing
          _buildQuickActionButtons(),
          const SizedBox(height: 6), // Reduced spacing
          _buildExamplePrompts(),
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
          color: _isCreatingFlashcards 
              ? AppColors.accentBlue 
              : AppColors.inputBorder,
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
              enabled: !_isCreatingFlashcards, // Disable during creation
              decoration: InputDecoration(
                hintText: _isCreatingFlashcards 
                    ? 'Bilgi kartları oluşturuluyor...' 
                    : 'AI asistanına sorun...',
                hintStyle: AppTextStyles.bodyMedium.copyWith(
                  color: _isCreatingFlashcards 
                      ? AppColors.accentBlue 
                      : AppColors.inputLabel,
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
          // Loading indicator or send button
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: _isCreatingFlashcards
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                    ),
                  )
                : _isTyping
                    ? IconButton(
                        icon: const Icon(Icons.send, color: AppColors.accentBlue, size: 20),
                        onPressed: _sendTextMessage,
                        tooltip: 'Gönder',
                      )
                    : const SizedBox.shrink(),
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

  Widget _buildExamplePrompts() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accentBlue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.accentBlue.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 14,
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 6),
              Text(
                'Örnek Sorular:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildExampleQuestion('"Matematik için $_selectedCardCount bilgi kartı oluştur"'),
          _buildExampleQuestion('"Tarih konularından $_selectedCardCount kart yap"'),
          _buildExampleQuestion('"Bu PDF\'den $_selectedCardCount soru kartı oluştur"'),
          _buildExampleQuestion('"Bilim konuları için $_selectedCardCount öğrenme kartı yap"'),
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
      shrinkWrap: true, // Added shrinkWrap: true to allow ListView to be inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
      padding: const EdgeInsets.all(16),
      itemCount: provider.flashcardDecks.length,
      itemBuilder: (context, index) {
        final deck = provider.flashcardDecks[index];
        return Dismissible(
          key: Key(deck.id),
          direction: DismissDirection.endToStart,
          background: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.delete,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sil',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          confirmDismiss: (direction) async {
            return await _showDeleteConfirmation(context, deck, provider);
          },
          onDismissed: (direction) async {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.currentUser != null) {
              await provider.deleteFlashcardDeck(
                authProvider.currentUser!.uid,
                deck.id,
              );
            }
          },
          child: _buildFlashcardDeckCard(deck, provider, context),
        );
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

  Future<bool?> _showDeleteConfirmation(BuildContext context, FlashcardDeck deck, LearningProvider provider) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bilgi Kartı Sil'),
        content: Text('"${deck.title}" başlıklı bilgi kartını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
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