import 'package:flutter/material.dart';
import 'package:roadlink/core/utils/size_utils.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_images.dart';
import '../../../core/shared/app_button.dart';
import '../../../core/shared/app_text.dart';

class ChatDetailView extends StatelessWidget {
  final String userName;
  final bool isOnline;
  final bool isRequest; // Whether this is a chat request

  const ChatDetailView({
    super.key,
    this.userName = 'John Ham',
    this.isOnline = true,
    this.isRequest = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            /// 🔹 HEADER
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  /// Back Button
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      size: 24.fSize,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  Gap.h(12),

                  /// Profile Picture
                  Container(
                    width: 40.adaptSize,
                    height: 40.adaptSize,
                    decoration: BoxDecoration(shape: BoxShape.circle),
                    child: ClipOval(
                      child: Image.asset(
                        AppImages.userAvatar,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: AppColors.cardBackground,
                            child: Icon(
                              Icons.person,
                              color: AppColors.textSecondary,
                              size: 24.fSize,
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  Gap.h(12),

                  /// Name and Online Status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          userName,
                          size: 16.fSize,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        if (isOnline) ...[
                          Gap.v(2),
                          Row(
                            children: [
                              Container(
                                width: 8.adaptSize,
                                height: 8.adaptSize,
                                decoration: BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Gap.h(6),
                              AppText(
                                'Online',
                                size: 12.fSize,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  /// Phone Icon
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.phone,
                      size: 24.fSize,
                      color: AppColors.textPrimary,
                    ),
                  ),

                  /// More Options Icon
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.more_vert,
                      size: 24.fSize,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            /// 🔹 CHAT MESSAGES AREA
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 16.v),
                child: Column(
                  children: [
                    /// Received Message Bubble
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.h,
                          vertical: 12.v,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBackground,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(16.adaptSize),
                            topRight: Radius.circular(16.adaptSize),
                            bottomRight: Radius.circular(16.adaptSize),
                            bottomLeft: Radius.circular(4.adaptSize),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppText(
                              'Hey! I saw your Tesla at the downtown garage yesterday. Those wheels look amazing!',
                              size: 14.fSize,
                              color: AppColors.textPrimary,
                            ),
                            Gap.v(6),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AppText(
                                  '10:24 AM',
                                  size: 11.fSize,
                                  color: AppColors.textSecondary,
                                ),
                                Gap.h(4),
                                Icon(
                                  Icons.check,
                                  size: 14.fSize,
                                  color: AppColors.primaryBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 🔹 ACTION BUTTONS (Only for chat requests)
            if (isRequest) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.h, vertical: 16.v),
                child: Row(
                  children: [
                    /// Reject Button
                    Expanded(
                      child: CustomButton(
                        text: 'Reject Request',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        backgroundColor: AppColors.cardBackground,
                        textColor: AppColors.textPrimary,
                        borderRadius: 10.adaptSize,
                        height: 50.v,
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.w500,
                        borderColor: AppColors.border,
                      ),
                    ),

                    Gap.h(16),

                    /// Accept Button
                    Expanded(
                      child: CustomButton(
                        text: 'Accept Request',
                        onPressed: () {
                          // Accept request logic
                        },
                        backgroundColor: AppColors.primaryBlue,
                        textColor: AppColors.white,
                        borderRadius: 10.adaptSize,
                        height: 50.v,
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            /// 🔹 MESSAGE INPUT BAR
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 12.v),
              decoration: BoxDecoration(
                color: AppColors.scaffoldBackground,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
                ),
              ),
              child: Row(
                children: [
                  /// Attach Button
                  Container(
                    width: 40.adaptSize,
                    height: 40.adaptSize,
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.add,
                        size: 24.fSize,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  Gap.h(12),

                  /// Message Input Field
                  Expanded(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.h),
                      decoration: BoxDecoration(
                        color: AppColors.textFieldFillColor,
                        borderRadius: BorderRadius.circular(24.adaptSize),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14.fSize,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12.v),
                        ),
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.fSize,
                        ),
                      ),
                    ),
                  ),

                  Gap.h(12),

                  /// Send Button
                  Container(
                    width: 40.adaptSize,
                    height: 40.adaptSize,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.send,
                        size: 20.fSize,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
