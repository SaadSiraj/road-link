import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final bool showBackButton;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Color? titleColor;
  final Color? iconColor;
  final double elevation;
  final bool centerTitle;

  const CustomAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.showBackButton = true,
    this.leading,
    this.actions,
    this.backgroundColor,
    this.titleColor,
    this.iconColor,
    this.elevation = 0,
    this.centerTitle = false,
  }) : assert(
         title != null || titleWidget != null,
         'Either title or titleWidget must be provided',
       );

  @override
  Widget build(BuildContext context) {
    return AppBar(
      forceMaterialTransparency: true,
      backgroundColor: backgroundColor ?? Colors.transparent,
      elevation: elevation,
      centerTitle: centerTitle,
      automaticallyImplyLeading: false,
      leading:
          leading ??
          (showBackButton
              ? IconButton(
                icon: const Icon(Icons.arrow_back),
                color: iconColor ?? AppColors.primaryBlue,
                onPressed: () => Navigator.of(context).pop(),
              )
              : null),
      title:
          titleWidget ??
          (title != null
              ? Text(
                title!,
                style: TextStyle(
                  color: titleColor ?? AppColors.primaryBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              )
              : null),
      actions: actions,
      iconTheme: IconThemeData(color: iconColor ?? AppColors.primaryBlue),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
