import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class FlashcardStudyScreen extends StatefulWidget {
  final FlashcardDeck deck;

  const FlashcardStudyScreen({
    super.key,
    required this.deck,
  });

  @override
  State<FlashcardStudyScreen> createState() => _FlashcardStudyScreenState();
}

class _FlashcardStudyScreenState extends State<FlashcardStudyScreen> {
  int _currentCardIndex = 0;
  bool _showAnswer = false;
  int _correctAnswers = 0;
  int _totalAnswered = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        title: Text(
          'Çalışma: ${widget.deck.title}',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.headingText),
        actions: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              '${_currentCardIndex + 1}/${widget.deck.cards.length}',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.accentBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress bar
            Container(
              height: 4,
              child: LinearProgressIndicator(
                value: widget.deck.cards.isNotEmpty 
                    ? (_currentCardIndex + 1) / widget.deck.cards.length 
                    : 0,
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentBlue),
              ),
            ),
            
            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Doğru', _correctAnswers, AppColors.success),
                  _buildStatCard('Toplam', _totalAnswered, AppColors.accentBlue),
                  _buildStatCard('Kalan', widget.deck.cards.length - _totalAnswered, AppColors.warning),
                ],
              ),
            ),
            
            // Flashcard
            Expanded(
              child: widget.deck.cards.isEmpty
                  ? _buildEmptyState()
                  : _buildFlashcard(),
            ),
            
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            value.toString(),
            style: AppTextStyles.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
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
                Icons.style_outlined,
                size: 50,
                color: AppColors.accentBlue,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bu kart setinde kart bulunmuyor',
              style: AppTextStyles.headingSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Yeni kartlar oluşturmak için ana sayfaya dönün',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Ana Sayfaya Dön'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlashcard() {
    final card = widget.deck.cards[_currentCardIndex];
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Card(
          elevation: 8,
          shadowColor: AppColors.accentBlue.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.surfaceBackground,
                  AppColors.surfaceBackground.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Card type indicator
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _showAnswer 
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.accentBlue.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _showAnswer ? 'CEVAP' : 'SORU',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: _showAnswer ? AppColors.success : AppColors.accentBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Card content
                Expanded(
                  child: Center(
                    child: Text(
                      _showAnswer ? card.answer : card.question,
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                // Flip button
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAnswer = !_showAnswer;
                      });
                    },
                    icon: Icon(_showAnswer ? Icons.question_mark : Icons.lightbulb),
                    label: Text(_showAnswer ? 'Soruyu Göster' : 'Cevabı Göster'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Tap hint
                Text(
                  'Kartı çevirmek için dokunun',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.secondaryText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentCardIndex > 0
                  ? () {
                      setState(() {
                        _currentCardIndex--;
                        _showAnswer = false;
                      });
                    }
                  : null,
              icon: const Icon(Icons.arrow_back),
              label: const Text('Önceki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceBackground,
                foregroundColor: AppColors.headingText,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: AppColors.borderLight,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Answer buttons
          if (_showAnswer) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _correctAnswers++;
                    _totalAnswered++;
                    if (_currentCardIndex < widget.deck.cards.length - 1) {
                      _currentCardIndex++;
                      _showAnswer = false;
                    }
                  });
                },
                icon: const Icon(Icons.check),
                label: const Text('Doğru'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _totalAnswered++;
                    if (_currentCardIndex < widget.deck.cards.length - 1) {
                      _currentCardIndex++;
                      _showAnswer = false;
                    }
                  });
                },
                icon: const Icon(Icons.close),
                label: const Text('Yanlış'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          
          // Next button
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _currentCardIndex < widget.deck.cards.length - 1
                  ? () {
                      setState(() {
                        _currentCardIndex++;
                        _showAnswer = false;
                      });
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Sonraki'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 