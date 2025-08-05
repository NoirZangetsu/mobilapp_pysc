import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class MessageBubble extends StatelessWidget {
  final ConversationMessage message;

  const MessageBubble({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: message.isUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            _buildAvatar(),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.userMessageBackground
                    : AppColors.aiMessageBackground,
                borderRadius: BorderRadius.circular(18).copyWith(
                  bottomLeft: message.isUser 
                      ? const Radius.circular(18)
                      : const Radius.circular(4),
                  bottomRight: message.isUser 
                      ? const Radius.circular(4)
                      : const Radius.circular(18),
                ),
                border: Border.all(
                  color: message.isUser
                      ? AppColors.accentBlue.withValues(alpha: 0.3)
                      : AppColors.borderLight.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: message.isUser 
                          ? AppColors.userMessageText
                          : AppColors.aiMessageText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: message.isUser 
                              ? AppColors.userMessageText.withValues(alpha: 0.7)
                              : AppColors.aiMessageText.withValues(alpha: 0.5),
                        ),
                      ),
                      if (!message.isUser) ...[
                        const SizedBox(width: 8),
                        Icon(
                          Icons.smart_toy,
                          size: 12,
                          color: AppColors.aiMessageText.withValues(alpha: 0.5),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            _buildAvatar(),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isUser
            ? AppColors.userMessageBackground
            : AppColors.accentBlue,
        shape: BoxShape.circle,
        border: Border.all(
          color: message.isUser
              ? AppColors.accentBlue.withValues(alpha: 0.3)
              : AppColors.accentBlue.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Icon(
        message.isUser ? Icons.person : Icons.smart_toy,
        size: 18,
        color: Colors.white,
      ),
    );
  }
} 