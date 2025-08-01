import 'package:flutter/material.dart';
import '../../services/firestore_test_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';

class FirestoreTestScreen extends StatefulWidget {
  const FirestoreTestScreen({super.key});

  @override
  State<FirestoreTestScreen> createState() => _FirestoreTestScreenState();
}

class _FirestoreTestScreenState extends State<FirestoreTestScreen> {
  final FirestoreTestService _testService = FirestoreTestService();
  bool _isRunning = false;
  String _testResults = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text('Firestore Test', style: AppTextStyles.headingMedium),
        backgroundColor: AppColors.surfaceBackground,
        iconTheme: const IconThemeData(color: AppColors.headingText),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Buttons
            ElevatedButton(
              onPressed: _isRunning ? null : _runAllTests,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryButton,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isRunning
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.headingText),
                      ),
                    )
                  : Text(
                      'Tüm Testleri Çalıştır',
                      style: AppTextStyles.buttonLarge,
                    ),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: _isRunning ? null : _cleanupTestData,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryButton,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Test Verilerini Temizle',
                style: AppTextStyles.buttonLarge,
              ),
            ),
            const SizedBox(height: 24),

            // Test Results
            Expanded(
              child: Container(
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
                      'Test Sonuçları:',
                      style: AppTextStyles.headingSmall,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Text(
                          _testResults.isEmpty ? 'Henüz test çalıştırılmadı.' : _testResults,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _runAllTests() async {
    setState(() {
      _isRunning = true;
      _testResults = '';
    });

    try {
      // Capture console output
      StringBuffer results = StringBuffer();
      
      // Run tests
      await _testService.runAllTests();
      
      setState(() {
        _testResults = results.toString();
      });
    } catch (e) {
      setState(() {
        _testResults = 'Test çalıştırılırken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  void _cleanupTestData() async {
    setState(() {
      _isRunning = true;
    });

    try {
      await _testService.cleanupTestData();
      setState(() {
        _testResults = 'Test verileri başarıyla temizlendi!';
      });
    } catch (e) {
      setState(() {
        _testResults = 'Test verileri temizlenirken hata oluştu: $e';
      });
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }
} 