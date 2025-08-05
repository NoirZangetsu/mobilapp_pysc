import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/learning_provider.dart';
import '../services/settings_service.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';
import 'education_preferences_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceBackground,
        elevation: 0,
        title: Text(
          'Profil',
          style: AppTextStyles.headingMedium,
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.headingText),
      ),
      body: SafeArea(
        child: Consumer3<AuthProvider, ChatProvider, LearningProvider>(
          builder: (context, authProvider, chatProvider, learningProvider, child) {
            final user = authProvider.currentUser;
            final userData = authProvider.userData;
            final userModel = authProvider.userModel;
            
            // E-posta bilgisini farklı kaynaklardan al
            String userEmail = 'kullanici@example.com';
            if (user?.email != null && user!.email!.isNotEmpty) {
              userEmail = user.email!;
            } else if (userModel?.email != null && userModel!.email.isNotEmpty) {
              userEmail = userModel.email;
            } else if (userData != null && userData is Map && userData['email'] != null) {
              userEmail = userData['email'];
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(user, userData, userEmail),
                  const SizedBox(height: 20),
                  
                  // Quick Stats
                  _buildQuickStats(chatProvider, learningProvider),
                  const SizedBox(height: 20),
                  
                  // Education Information Section
                  _buildEducationInfoSection(context, authProvider),
                  const SizedBox(height: 20),
                  
                  // Settings Section
                  _buildSettingsSection(context),
                  const SizedBox(height: 20),
                  
                  // Account Section
                  _buildAccountSection(context, user, userData),
                  const SizedBox(height: 20),
                  
                  // App Info Section
                  _buildAppInfoSection(context),
                  const SizedBox(height: 20),
                  
                  // Logout Button
                  _buildLogoutButton(context, authProvider),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeader(User? user, dynamic userData, String userEmail) {
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
          // Avatar with gradient
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentBlue,
                  AppColors.accentBlue.withValues(alpha: 0.8),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentBlue.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          
          // User Email (Primary Info)
          Text(
            userEmail,
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.headingText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Display Name (Secondary Info)
          if (userData is Map && userData['displayName'] != null)
            Text(
              userData['displayName'],
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          
          // User Email (Above Status)
          Text(
            userEmail,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Status indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accentBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.accentBlue,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Aktif',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.accentBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ChatProvider chatProvider, LearningProvider learningProvider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.analytics,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Öğrenme İstatistikleri',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Sohbetler',
                  '${chatProvider.messages.length}',
                  Icons.chat_bubble_outline,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Bilgi Kartları',
                  '${learningProvider.flashcardDecks.length}',
                  Icons.style_outlined,
                  AppColors.accentBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Podcast\'ler',
                  '${learningProvider.podcasts.length}',
                  Icons.headphones_outlined,
                  AppColors.accentBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            count,
            style: AppTextStyles.headingSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEducationInfoSection(BuildContext context, AuthProvider authProvider) {
    final userModel = authProvider.userModel;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.school_outlined,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Eğitim Bilgileri',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (userModel != null) ...[
            _buildInfoRow('Eğitim Seviyesi', _getEducationLevelDisplay(userModel.educationLevel)),
            _buildInfoRow('Öğrenme Stili', _getLearningStyleDisplay(userModel.learningStyle)),
            _buildInfoRow('Çalışma Ortamı', _getStudyEnvironmentDisplay(userModel.studyEnvironment)),
            _buildInfoRow('Günlük Çalışma', '${userModel.studyTimePerDay} dakika'),
            if (userModel.studySubjects.isNotEmpty)
              _buildInfoRow('Çalışma Konuları', userModel.studySubjects.join(', ')),
            if (userModel.learningGoals.isNotEmpty)
              _buildInfoRow('Öğrenme Hedefleri', userModel.learningGoals.join(', ')),
          ] else ...[
            _buildInfoRow('Eğitim Seviyesi', 'Belirtilmemiş'),
            _buildInfoRow('Öğrenme Stili', 'Belirtilmemiş'),
            _buildInfoRow('Çalışma Ortamı', 'Belirtilmemiş'),
            _buildInfoRow('Günlük Çalışma', 'Belirtilmemiş'),
          ],
          
          const SizedBox(height: 16),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EducationPreferencesScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text('Eğitim Tercihlerini Düzenle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.settings_outlined,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Ayarlar',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildSettingsTile(
            icon: Icons.notifications_outlined,
            title: 'Bildirimler',
            subtitle: 'Bildirim ayarlarını yönet',
            onTap: () => _showNotificationsSettings(context),
          ),
          
          _buildSettingsTile(
            icon: Icons.security_outlined,
            title: 'Güvenlik',
            subtitle: 'Şifre değiştir ve güvenlik ayarları',
            onTap: () => _showSecuritySettings(context),
          ),
          
          _buildSettingsTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Gizlilik',
            subtitle: 'Gizlilik ayarlarını yönet',
            onTap: () => _showPrivacySettings(context),
          ),
          
          _buildSettingsTile(
            icon: Icons.download_outlined,
            title: 'Verileri Dışa Aktar',
            subtitle: 'Kişisel verilerinizi indirin',
            onTap: () => _exportUserData(context),
          ),
          
          _buildSettingsTile(
            icon: Icons.help_outline,
            title: 'Yardım',
            subtitle: 'Kullanım kılavuzu ve destek',
            onTap: () => _showHelpSection(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.accentBlue, size: 20),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.secondaryText,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.secondaryText,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildAccountSection(BuildContext context, User? user, dynamic userData) {
    // E-posta bilgisini farklı kaynaklardan al
    String userEmail = 'kullanici@example.com';
    if (user?.email != null && user!.email!.isNotEmpty) {
      userEmail = user.email!;
    } else if (userData != null && userData is Map && userData['email'] != null) {
      userEmail = userData['email'];
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.account_circle_outlined,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Hesap Bilgileri',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('E-posta', userEmail),
          _buildInfoRow('Kullanıcı ID', user?.uid ?? ''),
          _buildInfoRow('Hesap Oluşturma', _formatDate(user?.metadata.creationTime)),
          _buildInfoRow('Son Giriş', _formatDate(user?.metadata.lastSignInTime)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceBackground,
        borderRadius: BorderRadius.circular(16),
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
              Icon(
                Icons.info_outline,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Uygulama Bilgileri',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildInfoRow('Uygulama Adı', 'Öğrenme Asistanı'),
          _buildInfoRow('Versiyon', '1.0.0'),
          _buildInfoRow('AI Model', 'Gemini 2.0 Flash'),
          _buildInfoRow('Geliştirici', 'AI Agent Team'),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Çıkış Yap'),
              content: const Text('Hesabınızdan çıkış yapmak istediğinizden emin misiniz?'),
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
                  child: const Text('Çıkış Yap'),
                ),
              ],
            ),
          );

          if (confirmed == true) {
            await authProvider.signOut();
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              'Çıkış Yap',
              style: AppTextStyles.buttonLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Bilinmiyor';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _getEducationLevelDisplay(String key) {
    switch (key) {
      case 'primary_school': return 'İlkokul';
      case 'middle_school': return 'Ortaokul';
      case 'high_school': return 'Lise';
      case 'university': return 'Üniversite';
      case 'graduate': return 'Yüksek Lisans';
      case 'phd': return 'Doktora';
      case 'professional': return 'Profesyonel';
      case 'self_study': return 'Kendi Kendine Öğrenme';
      default: return key;
    }
  }

  String _getLearningStyleDisplay(String key) {
    switch (key) {
      case 'visual': return 'Görsel Öğrenme';
      case 'auditory': return 'İşitsel Öğrenme';
      case 'kinesthetic': return 'Kinestetik Öğrenme';
      case 'reading': return 'Okuma/Yazma';
      case 'mixed': return 'Karma Öğrenme';
      default: return key;
    }
  }

  String _getStudyEnvironmentDisplay(String key) {
    switch (key) {
      case 'home': return 'Ev';
      case 'library': return 'Kütüphane';
      case 'cafe': return 'Kafe';
      case 'office': return 'Ofis';
      case 'outdoor': return 'Açık Alan';
      case 'classroom': return 'Sınıf';
      default: return key;
    }
  }

  void _showNotificationsSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return FutureBuilder<Map<String, bool>>(
            future: SettingsService().getNotificationSettings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AlertDialog(
                  title: Text('Bildirim Ayarları'),
                  content: Center(child: CircularProgressIndicator()),
                );
              }

              final settings = snapshot.data ?? {
                'voice_notifications': true,
                'flashcard_reminders': false,
                'podcast_notifications': true,
              };

              return AlertDialog(
                backgroundColor: AppColors.surfaceBackground,
                title: Text(
                  'Bildirim Ayarları',
                  style: AppTextStyles.headingSmall.copyWith(color: AppColors.headingText),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Sesli Bildirimler',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
                      ),
                      subtitle: Text(
                        'Sesli yanıtlar için bildirim al',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                      ),
                      value: settings['voice_notifications'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          settings['voice_notifications'] = value;
                        });
                        _updateNotificationSetting(context, 'voice_notifications', value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        'Flashcard Hatırlatıcıları',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
                      ),
                      subtitle: Text(
                        'Günlük çalışma hatırlatıcıları',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                      ),
                      value: settings['flashcard_reminders'] ?? false,
                      onChanged: (value) {
                        setState(() {
                          settings['flashcard_reminders'] = value;
                        });
                        _updateNotificationSetting(context, 'flashcard_reminders', value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        'Podcast Bildirimleri',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
                      ),
                      subtitle: Text(
                        'Yeni podcast oluşturulduğunda bildir',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                      ),
                      value: settings['podcast_notifications'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          settings['podcast_notifications'] = value;
                        });
                        _updateNotificationSetting(context, 'podcast_notifications', value);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Kapat',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _updateNotificationSetting(BuildContext context, String setting, bool value) async {
    try {
      final settingsService = SettingsService();
      await settingsService.updateNotificationSetting(setting, value);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bildirim ayarı güncellendi'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showSecuritySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceBackground,
        title: Text(
          'Güvenlik Ayarları',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.headingText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.lock, color: AppColors.accentBlue),
              title: Text(
                'Şifre Değiştir',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
              ),
              subtitle: Text(
                'Hesap şifrenizi güncelleyin',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showChangePasswordDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fingerprint, color: AppColors.accentBlue),
              title: Text(
                'Biometrik Giriş',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
              ),
              subtitle: Text(
                'Parmak izi ile giriş yap',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBiometricSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices, color: AppColors.accentBlue),
              title: Text(
                'Cihaz Yönetimi',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
              ),
              subtitle: Text(
                'Aktif oturumları görüntüle',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeviceManagement(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showPrivacySettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return FutureBuilder<Map<String, bool>>(
            future: SettingsService().getPrivacySettings(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const AlertDialog(
                  title: Text('Gizlilik Ayarları'),
                  content: Center(child: CircularProgressIndicator()),
                );
              }

              final settings = snapshot.data ?? {
                'data_collection': true,
                'analytics': false,
                'personalization': true,
              };

              return AlertDialog(
                backgroundColor: AppColors.surfaceBackground,
                title: Text(
                  'Gizlilik Ayarları',
                  style: AppTextStyles.headingSmall.copyWith(color: AppColors.headingText),
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      title: Text(
                        'Veri Toplama',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
                      ),
                      subtitle: Text(
                        'Kullanım verilerini topla',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                      ),
                      value: settings['data_collection'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          settings['data_collection'] = value;
                        });
                        _updatePrivacySetting(context, 'data_collection', value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        'Analitik',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
                      ),
                      subtitle: Text(
                        'Uygulama performansını analiz et',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                      ),
                      value: settings['analytics'] ?? false,
                      onChanged: (value) {
                        setState(() {
                          settings['analytics'] = value;
                        });
                        _updatePrivacySetting(context, 'analytics', value);
                      },
                    ),
                    SwitchListTile(
                      title: Text(
                        'Kişiselleştirme',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
                      ),
                      subtitle: Text(
                        'Kişiselleştirilmiş içerik göster',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
                      ),
                      value: settings['personalization'] ?? true,
                      onChanged: (value) {
                        setState(() {
                          settings['personalization'] = value;
                        });
                        _updatePrivacySetting(context, 'personalization', value);
                      },
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Kapat',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _updatePrivacySetting(BuildContext context, String setting, bool value) async {
    try {
      final settingsService = SettingsService();
      await settingsService.updatePrivacySetting(setting, value);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gizlilik ayarı güncellendi'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _showHelpSection(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceBackground,
        title: Text(
          'Yardım ve Destek',
          style: AppTextStyles.headingSmall.copyWith(color: AppColors.headingText),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.book, color: AppColors.accentBlue),
              title: Text(
                'Kullanım Kılavuzu',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
              ),
              subtitle: Text(
                'Uygulama kullanım rehberi',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showUserGuide(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.question_answer, color: AppColors.accentBlue),
              title: Text(
                'Sık Sorulan Sorular',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
              ),
              subtitle: Text(
                'Yaygın sorular ve cevaplar',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showFAQ(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.contact_support, color: AppColors.accentBlue),
              title: Text(
                'Destek Ekibi',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
              ),
              subtitle: Text(
                'Teknik destek ile iletişim',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showContactSupport(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bug_report, color: AppColors.accentBlue),
              title: Text(
                'Hata Bildir',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.headingText),
              ),
              subtitle: Text(
                'Sorun bildir ve geri bildirim ver',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.secondaryText),
              ),
              onTap: () {
                Navigator.pop(context);
                _showBugReport(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Kapat',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.accentBlue),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Şifre Değiştir'),
        content: const Text('Bu özellik yakında eklenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showBiometricSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Biometrik Giriş'),
        content: const Text('Bu özellik yakında eklenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showDeviceManagement(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cihaz Yönetimi'),
        content: const Text('Bu özellik yakında eklenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showUserGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanım Kılavuzu'),
        content: const Text('Bu özellik yakında eklenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showFAQ(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sık Sorulan Sorular'),
        content: const Text('Bu özellik yakında eklenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showContactSupport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Destek Ekibi'),
        content: const Text('Bu özellik yakında eklenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _showBugReport(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hata Bildir'),
        content: const Text('Bu özellik yakında eklenecektir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  void _exportUserData(BuildContext context) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          title: Text('Veriler Dışa Aktarılıyor'),
          content: Center(child: CircularProgressIndicator()),
        ),
      );

      final settingsService = SettingsService();
      final userData = await settingsService.exportUserData();
      
      // Close loading dialog
      Navigator.pop(context);
      
      // Show success dialog with data summary
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Veriler Dışa Aktarıldı'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Podcast Sayısı: ${userData['podcasts']?.length ?? 0}'),
              Text('Bilgi Kartı Sayısı: ${userData['flashcardDecks']?.length ?? 0}'),
              Text('Doküman Sayısı: ${userData['documents']?.length ?? 0}'),
              const SizedBox(height: 12),
              const Text(
                'Verileriniz başarıyla dışa aktarıldı. Bu verileri güvenli bir yerde saklayın.',
                style: TextStyle(fontSize: 12),
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
    } catch (e) {
      // Close loading dialog
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }
} 