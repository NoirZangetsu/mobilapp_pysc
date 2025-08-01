import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../providers/learning_provider.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: AppColors.secondaryText),
            onPressed: () {
              _showSettingsDialog(context);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer3<AuthProvider, ChatProvider, LearningProvider>(
          builder: (context, authProvider, chatProvider, learningProvider, child) {
            final user = authProvider.currentUser;
            final userData = authProvider.userData;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  _buildProfileHeader(user, userData),
                  const SizedBox(height: 20),
                  
                  // Quick Stats
                  _buildQuickStats(chatProvider, learningProvider),
                  const SizedBox(height: 20),
                  
                  // Features Section
                  _buildFeaturesSection(context),
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

  Widget _buildProfileHeader(User? user, dynamic userData) {
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
          
          // User Name
          Text(
            userData?.displayName ?? user?.displayName ?? 'Öğrenme Asistanı Kullanıcısı',
            style: AppTextStyles.headingMedium.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          
          // Email
          Text(
            user?.email ?? 'kullanici@example.com',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          
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

  Widget _buildFeaturesSection(BuildContext context) {
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
                Icons.auto_awesome,
                color: AppColors.accentBlue,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Özellikler',
                style: AppTextStyles.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          _buildFeatureTile(
            icon: Icons.chat_bubble_outline,
            title: 'AI Sohbet',
            subtitle: 'Gemini 2.0 Flash ile akıllı sohbet',
            color: AppColors.accentBlue,
            onTap: () {
              // Navigate to chat
            },
          ),
          
          _buildFeatureTile(
            icon: Icons.style_outlined,
            title: 'Bilgi Kartları',
            subtitle: 'AI ile otomatik kart oluşturma',
            color: AppColors.accentBlue,
            onTap: () {
              // Navigate to flashcards
            },
          ),
          
          _buildFeatureTile(
            icon: Icons.headphones_outlined,
            title: 'Podcast\'ler',
            subtitle: 'Sesli öğrenme içerikleri',
            color: AppColors.accentBlue,
            onTap: () {
              // Navigate to podcasts
            },
          ),
          
          _buildFeatureTile(
            icon: Icons.upload_file_outlined,
            title: 'Multimodal',
            subtitle: 'PDF ve görsel analizi',
            color: AppColors.accentBlue,
            onTap: () {
              // Show multimodal info
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
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
          
          _buildInfoRow('E-posta', user?.email ?? ''),
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

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ayarlar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.notifications, color: AppColors.accentBlue),
              title: const Text('Bildirimler'),
              subtitle: const Text('Bildirim ayarlarını yönet'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement notifications settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.security, color: AppColors.accentBlue),
              title: const Text('Güvenlik'),
              subtitle: const Text('Şifre değiştir ve güvenlik ayarları'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement security settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip, color: AppColors.accentBlue),
              title: const Text('Gizlilik'),
              subtitle: const Text('Gizlilik ayarlarını yönet'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement privacy settings
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppColors.accentBlue),
              title: const Text('Yardım'),
              subtitle: const Text('Kullanım kılavuzu ve destek'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement help section
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
} 