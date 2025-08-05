import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/education_preferences.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class EducationPreferencesScreen extends StatefulWidget {
  const EducationPreferencesScreen({super.key});

  @override
  State<EducationPreferencesScreen> createState() => _EducationPreferencesScreenState();
}

class _EducationPreferencesScreenState extends State<EducationPreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  String _selectedEducationLevel = 'high_school';
  String _selectedLearningStyle = 'visual';
  String _selectedStudyEnvironment = 'home';
  String _selectedVoiceStyle = 'professional';
  int _studyTimePerDay = 60;
  
  // Multi-select lists
  List<String> _selectedSubjects = [];
  List<String> _selectedLearningGoals = [];
  List<String> _selectedWeakAreas = [];
  List<String> _selectedStrongAreas = [];

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() {
    final authProvider = context.read<AuthProvider>();
    final userModel = authProvider.userModel;
    
    if (userModel != null) {
      setState(() {
        _selectedEducationLevel = userModel.educationLevel;
        _selectedLearningStyle = userModel.learningStyle;
        _selectedStudyEnvironment = userModel.studyEnvironment;
        _selectedVoiceStyle = userModel.preferredVoiceStyle;
        _studyTimePerDay = userModel.studyTimePerDay;
        _selectedSubjects = List.from(userModel.studySubjects);
        _selectedLearningGoals = List.from(userModel.learningGoals);
        _selectedWeakAreas = List.from(userModel.weakAreas);
        _selectedStrongAreas = List.from(userModel.strongAreas);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Eğitim Tercihleri',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.headingText,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.headingText),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeaderSection(),
              const SizedBox(height: 24),
              
              // Education Level Section
              _buildSectionCard(
                title: 'Eğitim Seviyesi',
                icon: Icons.school_outlined,
                child: _buildEducationLevelSelector(),
              ),
              const SizedBox(height: 16),
              
              // Learning Style Section
              _buildSectionCard(
                title: 'Öğrenme Stili',
                icon: Icons.psychology_outlined,
                child: _buildLearningStyleSelector(),
              ),
              const SizedBox(height: 16),
              
              // Study Subjects Section
              _buildSectionCard(
                title: 'Çalışma Konuları',
                icon: Icons.book_outlined,
                child: _buildMultiSelectChips(
                  EducationPreferences.commonSubjects,
                  _selectedSubjects,
                  (value) => setState(() {
                    if (_selectedSubjects.contains(value)) {
                      _selectedSubjects.remove(value);
                    } else {
                      _selectedSubjects.add(value);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 16),
              
              // Learning Goals Section
              _buildSectionCard(
                title: 'Öğrenme Hedefleri',
                icon: Icons.flag_outlined,
                child: _buildMultiSelectChips(
                  EducationPreferences.commonLearningGoals,
                  _selectedLearningGoals,
                  (value) => setState(() {
                    if (_selectedLearningGoals.contains(value)) {
                      _selectedLearningGoals.remove(value);
                    } else {
                      _selectedLearningGoals.add(value);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 16),
              
              // Strong Areas Section
              _buildSectionCard(
                title: 'Güçlü Alanlar',
                icon: Icons.trending_up_outlined,
                child: _buildMultiSelectChips(
                  EducationPreferences.commonStrongAreas,
                  _selectedStrongAreas,
                  (value) => setState(() {
                    if (_selectedStrongAreas.contains(value)) {
                      _selectedStrongAreas.remove(value);
                    } else {
                      _selectedStrongAreas.add(value);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 16),
              
              // Weak Areas Section
              _buildSectionCard(
                title: 'Geliştirilmesi Gereken Alanlar',
                icon: Icons.construction_outlined,
                child: _buildMultiSelectChips(
                  EducationPreferences.commonWeakAreas,
                  _selectedWeakAreas,
                  (value) => setState(() {
                    if (_selectedWeakAreas.contains(value)) {
                      _selectedWeakAreas.remove(value);
                    } else {
                      _selectedWeakAreas.add(value);
                    }
                  }),
                ),
              ),
              const SizedBox(height: 16),
              
              // Study Time Section
              _buildSectionCard(
                title: 'Günlük Çalışma Süresi',
                icon: Icons.access_time_outlined,
                child: _buildStudyTimeSlider(),
              ),
              const SizedBox(height: 16),
              
              // Study Environment Section
              _buildSectionCard(
                title: 'Çalışma Ortamı',
                icon: Icons.home_outlined,
                child: _buildStudyEnvironmentSelector(),
              ),
              const SizedBox(height: 16),
              
              // Voice Style Section
              _buildSectionCard(
                title: 'Ses Stili',
                icon: Icons.record_voice_over_outlined,
                child: _buildVoiceStyleSelector(),
              ),
              const SizedBox(height: 16),
              
              // Save Button
              _buildSaveButton(),
              const SizedBox(height: 100), // Bottom padding for bottom navigation
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.settings_applications,
            size: 48,
            color: AppColors.accentBlue,
          ),
          const SizedBox(height: 16),
          Text(
            'Kişiselleştirilmiş Öğrenme',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.headingText,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Eğitim tercihlerinizi belirleyerek daha iyi bir öğrenme deneyimi yaşayın',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.borderLight,
          width: 1,
        ),
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
              Icon(
                icon,
                color: AppColors.accentBlue,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.headingText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEducationLevelSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedEducationLevel,
      decoration: InputDecoration(
        labelText: 'Eğitim Seviyesi',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inputLabel,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 2),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.inputText,
      ),
      dropdownColor: AppColors.surfaceBackground,
      items: EducationPreferences.educationLevels.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.headingText,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedEducationLevel = value!;
        });
      },
    );
  }

  Widget _buildLearningStyleSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedLearningStyle,
      decoration: InputDecoration(
        labelText: 'Öğrenme Stili',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inputLabel,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 2),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.inputText,
      ),
      dropdownColor: AppColors.surfaceBackground,
      items: EducationPreferences.learningStyles.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.headingText,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedLearningStyle = value!;
        });
      },
    );
  }

  Widget _buildStudyEnvironmentSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedStudyEnvironment,
      decoration: InputDecoration(
        labelText: 'Çalışma Ortamı',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inputLabel,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 2),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.inputText,
      ),
      dropdownColor: AppColors.surfaceBackground,
      items: EducationPreferences.studyEnvironments.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.headingText,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedStudyEnvironment = value!;
        });
      },
    );
  }

  Widget _buildVoiceStyleSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedVoiceStyle,
      decoration: InputDecoration(
        labelText: 'Tercih Edilen Ses Stili',
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.inputLabel,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.inputFocusedBorder, width: 2),
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: AppTextStyles.bodyMedium.copyWith(
        color: AppColors.inputText,
      ),
      dropdownColor: AppColors.surfaceBackground,
      items: EducationPreferences.voiceStyles.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(
            entry.value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.headingText,
            ),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedVoiceStyle = value!;
        });
      },
    );
  }

  Widget _buildStudyTimeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${_studyTimePerDay} dakika/gün',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.headingText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primaryButton,
            inactiveTrackColor: AppColors.borderLight,
            thumbColor: AppColors.primaryButton,
            overlayColor: AppColors.primaryButton.withValues(alpha: 0.2),
            valueIndicatorColor: AppColors.primaryButton,
            valueIndicatorTextStyle: AppTextStyles.bodySmall.copyWith(
              color: AppColors.headingText,
            ),
          ),
          child: Slider(
            value: _studyTimePerDay.toDouble(),
            min: 15,
            max: 480,
            divisions: 31,
            onChanged: (value) {
              setState(() {
                _studyTimePerDay = value.round();
              });
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '15 dk',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
            Text(
              '8 saat',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMultiSelectChips(
    List<String> options,
    List<String> selectedItems,
    Function(String) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((option) {
        final isSelected = selectedItems.contains(option);
        return FilterChip(
          label: Text(
            option,
            style: AppTextStyles.bodySmall.copyWith(
              color: isSelected ? AppColors.headingText : AppColors.secondaryText,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) => onChanged(option),
          selectedColor: AppColors.primaryButton.withValues(alpha: 0.2),
          checkmarkColor: AppColors.primaryButton,
          backgroundColor: AppColors.inputBackground,
          side: BorderSide(
            color: isSelected ? AppColors.primaryButton : AppColors.borderLight,
            width: 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          pressElevation: 2,
        );
      }).toList(),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryButton.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _savePreferences,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryButton,
          foregroundColor: AppColors.headingText,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.save_outlined, size: 20),
            const SizedBox(width: 8),
            Text(
              'Tercihleri Kaydet',
              style: AppTextStyles.buttonLarge.copyWith(
                color: AppColors.headingText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    try {
      final success = await authProvider.updateEducationPreferences(
        studySubjects: _selectedSubjects,
        educationLevel: _selectedEducationLevel,
        learningStyle: _selectedLearningStyle,
        learningGoals: _selectedLearningGoals,
        studyTimePerDay: _studyTimePerDay,
        weakAreas: _selectedWeakAreas,
        strongAreas: _selectedStrongAreas,
        studyEnvironment: _selectedStudyEnvironment,
        preferredVoiceStyle: _selectedVoiceStyle,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Eğitim tercihleriniz başarıyla kaydedildi!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                const Text('Tercihler kaydedilirken bir hata oluştu.'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Text('Hata: $e'),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }
} 