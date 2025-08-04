import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../providers/learning_provider.dart';
import '../providers/auth_provider.dart';
import '../models/podcast.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'podcast_player_screen.dart';

class PodcastsScreen extends StatefulWidget {
  const PodcastsScreen({super.key});

  @override
  State<PodcastsScreen> createState() => _PodcastsScreenState();
}

class _PodcastsScreenState extends State<PodcastsScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  bool _isProcessingPDF = false;
  bool _isProcessingImage = false;
  bool _isTyping = false;
  bool _isCreatingPodcast = false; // Yeni loading state
  
  // Enhanced podcast creation options
  String _selectedVoiceStyle = 'professional';
  String _selectedContentLength = 'detailed'; // 'summary', 'detailed', 'comprehensive'
  String _selectedLanguage = 'tr-TR';

  // Content length options with descriptions
  static const Map<String, Map<String, String>> _contentLengthOptions = {
    'summary': {
      'name': 'Özet',
      'description': 'Kısa ve öz içerik (2-3 dakika)',
      'icon': '📝',
    },
    'detailed': {
      'name': 'Detaylı',
      'description': 'Kapsamlı açıklama (5-7 dakika)',
      'icon': '📚',
    },
    'comprehensive': {
      'name': 'Bütün Konu',
      'description': 'Tam kapsamlı içerik (10-15 dakika)',
      'icon': '🎓',
    },
    'extended': {
      'name': 'Genişletilmiş',
      'description': 'Derinlemesine analiz (15-20 dakika)',
      'icon': '🔬',
    },
  };

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
                  if (learningProvider.podcasts.isNotEmpty)
                    _buildPodcastsList(learningProvider)
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
        'Podcast\'ler',
        style: AppTextStyles.headingMedium,
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: AppColors.headingText),
    );
  }

  Future<void> _pickAndProcessPDF() async {
    try {
      setState(() {
        _isProcessingPDF = true;
      });

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
            _textController.text = 'Bu PDF\'den podcast oluştur';
            _textFocusNode.requestFocus();
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('PDF işleme hatası: $e')),
      );
    } finally {
      setState(() {
        _isProcessingPDF = false;
      });
    }
  }

  Future<void> _pickAndProcessImage() async {
    try {
      setState(() {
        _isProcessingImage = true;
      });

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
            _textController.text = 'Bu görüntüden podcast oluştur';
            _textFocusNode.requestFocus();
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görüntü işleme hatası: $e')),
      );
    } finally {
      setState(() {
        _isProcessingImage = false;
      });
    }
  }

  Future<void> _sendTextMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // Set loading state
    setState(() {
      _isCreatingPodcast = true;
    });

    try {
      _textController.clear();
      _textFocusNode.unfocus();
      
      final learningProvider = context.read<LearningProvider>();
      final authProvider = context.read<AuthProvider>();
      if (authProvider.currentUser != null) {
        // Enhanced podcast creation with selected options
        await learningProvider.processPodcastRequest(
          text, 
          authProvider.currentUser!.uid,
          voiceStyle: _selectedVoiceStyle,
          contentLength: _selectedContentLength, // Changed to content length
          language: _selectedLanguage,
        );
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Podcast başarıyla oluşturuldu!'),
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
            content: Text('Podcast oluşturma hatası: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _isCreatingPodcast = false;
        });
      }
    }
  }

  Widget _buildAIAssistantSection(BuildContext context, LearningProvider learningProvider) {
    return Container(
      margin: const EdgeInsets.all(12), // Reduced margin
      padding: const EdgeInsets.all(12), // Reduced padding
      decoration: BoxDecoration(
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4), // Reduced padding
                decoration: BoxDecoration(
                  color: AppColors.accentBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6), // Reduced radius
                ),
                child: Icon(Icons.psychology, color: AppColors.accentBlue, size: 14), // Reduced size
              ),
              const SizedBox(width: 6), // Reduced spacing
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Podcast Asistanı',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.accentBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13, // Reduced font size
                      ),
                    ),
                    Text(
                      'Sesli içerik oluşturmak için AI\'ya sorular sorun',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 10, // Reduced font size
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8), // Reduced spacing
          
          // Podcast creation options
          _buildPodcastOptions(),
          const SizedBox(height: 8), // Reduced spacing
          
          // Text input area
          Container(
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _isCreatingPodcast 
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
                    enabled: !_isCreatingPodcast, // Disable during creation
                    decoration: InputDecoration(
                      hintText: _isCreatingPodcast 
                          ? 'Podcast oluşturuluyor...' 
                          : 'AI asistanına sorun...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: _isCreatingPodcast 
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
                    onChanged: (value) {
                      setState(() {
                        _isTyping = value.isNotEmpty;
                      });
                    },
                  ),
                ),
                // Loading indicator or send button
                Container(
                  margin: const EdgeInsets.only(right: 4),
                  child: _isCreatingPodcast
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
                              icon: const Icon(Icons.send, color: AppColors.accentBlue, size: 18),
                              onPressed: _sendTextMessage,
                              tooltip: 'Gönder',
                            )
                          : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6), // Reduced spacing
          
          // Enhanced quick actions
          Wrap(
            spacing: 6, // Reduced spacing
            runSpacing: 6, // Reduced spacing
            children: [
              _buildQuickActionButton(
                icon: Icons.image,
                label: 'Görüntü',
                onTap: _pickAndProcessImage,
                isLoading: _isProcessingImage,
              ),
              _buildQuickActionButton(
                icon: Icons.upload_file,
                label: 'PDF',
                onTap: _pickAndProcessPDF,
                isLoading: _isProcessingPDF,
              ),
              _buildQuickActionButton(
                icon: Icons.auto_awesome,
                label: 'Otomatik',
                onTap: () {
                  final contentName = _contentLengthOptions[_selectedContentLength]!['name']!;
                  _textController.text = 'Bu konu için $contentName podcast oluştur';
                  _sendTextMessage();
                },
                isLoading: false,
              ),
              _buildQuickActionButton(
                icon: Icons.mic,
                label: 'Eğitim',
                onTap: () {
                  final contentName = _contentLengthOptions[_selectedContentLength]!['name']!;
                  _textController.text = 'Eğitim amaçlı $contentName podcast oluştur';
                  _sendTextMessage();
                },
                isLoading: false,
              ),
              _buildQuickActionButton(
                icon: Icons.record_voice_over,
                label: 'Sesli',
                onTap: () {
                  final contentName = _contentLengthOptions[_selectedContentLength]!['name']!;
                  _textController.text = '$_selectedVoiceStyle ses tonuyla $contentName podcast yap';
                  _sendTextMessage();
                },
                isLoading: false,
              ),
            ],
          ),
          const SizedBox(height: 6), // Reduced spacing
          _buildExamplePrompts(),
        ],
      ),
    );
  }

  Widget _buildPodcastOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Podcast Ayarları',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.headingText, // Changed to white
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedVoiceStyle,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                dropdownColor: AppColors.surfaceBackground, // Added dropdown color
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.headingText, // White text color
                ),
                items: const [
                  DropdownMenuItem(value: 'professional', child: Text('Profesyonel', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'friendly', child: Text('Arkadaşça', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'casual', child: Text('Seyirciye Uygun', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedVoiceStyle = value;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedContentLength,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                dropdownColor: AppColors.surfaceBackground, // Added dropdown color
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.headingText, // White text color
                ),
                items: _contentLengthOptions.entries.map((entry) {
                  final option = entry.value;
                  return DropdownMenuItem(
                    value: entry.key,
                    child: Text(
                      '${option['icon']!} ${option['name']!}',
                      style: const TextStyle(color: Colors.white),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedContentLength = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Content length description
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.accentBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.accentBlue,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _contentLengthOptions[_selectedContentLength]!['description']!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), // Reduced padding
        decoration: BoxDecoration(
          color: isLoading 
              ? AppColors.accentBlue.withValues(alpha: 0.3)
              : AppColors.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12), // Reduced border radius
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
                width: 10, // Reduced size
                height: 10, // Reduced size
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
                ),
              )
            else
              Icon(icon, size: 12, color: AppColors.accentBlue), // Reduced icon size
            const SizedBox(width: 3), // Reduced spacing
            Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
                fontSize: 10, // Reduced font size
              ),
            ),
          ],
        ),
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
                size: 12, // Reduced size
                color: AppColors.accentBlue,
              ),
              const SizedBox(width: 4), // Reduced spacing
              Text(
                'Örnek Sorular:',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.accentBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 11, // Reduced font size
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Reduced spacing
          _buildExampleQuestion('"Matematik konuları için ${_contentLengthOptions[_selectedContentLength]!['name']} podcast oluştur"'),
          _buildExampleQuestion('"Tarih dersleri için $_selectedVoiceStyle ses tonuyla eğitim podcast\'i yap"'),
          _buildExampleQuestion('"Bu PDF\'den ${_contentLengthOptions[_selectedContentLength]!['name']} podcast oluştur"'),
          _buildExampleQuestion('"Bilim konuları için $_selectedVoiceStyle ses tonuyla ${_contentLengthOptions[_selectedContentLength]!['name']} podcast yap"'),
        ],
      ),
    );
  }

  Widget _buildExampleQuestion(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2), // Reduced padding
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 10, // Reduced size
            color: AppColors.accentBlue.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4), // Reduced spacing
          Expanded(
            child: Text(
              question,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
                fontStyle: FontStyle.italic,
                fontSize: 10, // Reduced font size
              ),
            ),
          ),
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
                Icons.headphones_outlined,
                size: 50,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz podcast oluşturmadınız',
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
                  _buildEmptyFeatureItem(Icons.headphones, 'Sesli içerik oluşturun'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Yukarıdaki AI asistanını kullanarak podcast oluşturmaya başlayın!',
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

  Widget _buildPodcastsList(LearningProvider provider) {
    return ListView.builder(
      shrinkWrap: true, // Added shrinkWrap: true to allow ListView to be inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Disable ListView's own scrolling
      padding: const EdgeInsets.all(16),
      itemCount: provider.podcasts.length,
      itemBuilder: (context, index) {
        final podcast = provider.podcasts[index];
        return Dismissible(
          key: Key(podcast.id),
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
            return await _showDeleteConfirmation(context, podcast, provider);
          },
          onDismissed: (direction) async {
            final authProvider = context.read<AuthProvider>();
            if (authProvider.currentUser != null) {
              await provider.deletePodcast(
                authProvider.currentUser!.uid,
                podcast.id,
              );
            }
          },
          child: _buildPodcastCard(podcast, provider, context),
        );
      },
    );
  }

  Widget _buildPodcastCard(Podcast podcast, LearningProvider provider, BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PodcastPlayerScreen(podcast: podcast),
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
                    Icons.headphones,
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
                        podcast.title,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (podcast.description != null)
                        Text(
                          podcast.description!,
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
            // Simplified metadata row
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(podcast.createdAt),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.timer,
                  size: 14,
                  color: AppColors.secondaryText,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(podcast.duration),
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
                    'Dinle',
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<bool?> _showDeleteConfirmation(BuildContext context, Podcast podcast, LearningProvider provider) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Podcast\'i Sil'),
        content: Text('"${podcast.title}" başlıklı podcast\'i silmek istediğinizden emin misiniz?'),
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