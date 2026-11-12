import 'package:flutter/material.dart';
import '../../core/constants/tactical_strings.dart';
import '../../core/theme/app_colors.dart';

class TacticalNavBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const TacticalNavBar({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tabs = [
      (Icons.dashboard_rounded, TacticalStrings.dashboard),
      (Icons.satellite_alt_rounded, TacticalStrings.mataSatelit),
      (Icons.psychology_rounded, TacticalStrings.aiIntel),
      (Icons.lock_clock_rounded, TacticalStrings.blockchain),
      (Icons.show_chart_rounded, TacticalStrings.telemetri),
      (Icons.shield_rounded, TacticalStrings.operasi),
      (Icons.admin_panel_settings_rounded, 'VERIFIKASI WILAYAH'),
      (Icons.remove_red_eye_rounded, 'LOG AKTIVITAS'),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: AppColors.glassBorder.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C0F1B2D),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(tabs.length, (index) {
            final isSelected = selectedIndex == index;
            final (icon, title) = tabs[index];

            return Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Semantics(
                button: true,
                selected: isSelected,
                label: 'Navigasi ke $title',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onTabSelected(index),
                    borderRadius: BorderRadius.circular(8),
                    hoverColor: isSelected ? null : AppColors.cyberCyan.withValues(alpha: 0.08),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        gradient: isSelected
                            ? const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFFE8001A),
                                  Color(0xFFCC0001),
                                  Color(0xFF9E0000),
                                ],
                              )
                            : null,
                        color: isSelected ? null : Colors.white.withValues(alpha: 0.9),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.merahVibrant
                              : AppColors.glassBorder.withValues(alpha: 0.4),
                          width: isSelected ? 1.5 : 1.2,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFCC0001).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : const [
                                BoxShadow(
                                  color: Color(0x080F1B2D),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : AppColors.cyberCyan.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              icon,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.cyberCyanDeep,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                              letterSpacing: 0.8,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontFamily: 'monospace',
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white,
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
