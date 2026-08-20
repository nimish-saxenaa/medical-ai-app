import 'package:flutter/material.dart';

import '../../Components/colors.dart';
import '../../functions.dart';


class AvatarColors {
  final Color background;
  final Color foreground;

  const AvatarColors({
    required this.background,
    required this.foreground,
  });
}

class CustomNameInitial extends StatelessWidget {
  const CustomNameInitial({
    super.key,
    required this.name,
    this.size = 40,
  });

  final String name;
  final double size;

  static const List<AvatarColors> _avatarPalettes = [
    // bg-brand-light text-brand
    AvatarColors(
      background: AppColors.primaryLight,
      foreground: AppColors.primary,
    ),

    // bg-blue-100 text-blue-700
    AvatarColors(
      background: AppColors.avatarBlueBg,
      foreground: AppColors.avatarBlueText,
    ),

    // bg-emerald-100 text-emerald-700
    AvatarColors(
      background: AppColors.avatarGreenBg,
      foreground: AppColors.avatarGreenText,
    ),

    // bg-amber-100 text-amber-800
    AvatarColors(
      background: AppColors.avatarAmberBg,
      foreground: AppColors.avatarAmberText,
    ),

    // bg-rose-100 text-rose-700
    AvatarColors(
      background: AppColors.avatarPinkBg,
      foreground: AppColors.avatarPinkText,
    ),
  ];

  AvatarColors get palette {
    int h = 0;

    for (final code in name.codeUnits) {
      h = (h * 31 + code) & 0xfffff;
    }

    return _avatarPalettes[h % _avatarPalettes.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = palette;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        getInitials(name),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: colors.foreground,
          fontSize: size / 2.5,
        ),
      ),
    );
  }
}