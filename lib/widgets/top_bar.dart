import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ViewMode { regional, provincial }

class _ModeIndicator extends StatelessWidget {
  final ViewMode mode;
  const _ModeIndicator({required this.mode});

  @override
  Widget build(BuildContext context) {
    final isRegional = mode == ViewMode.regional;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.teal.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRegional ? Icons.grid_view_rounded : Icons.person_outline,
            size: 14,
            color: AppColors.teal,
          ),
          const SizedBox(width: 6),
          Text(
            isRegional ? 'Regional View' : 'Provincial View',
            style: const TextStyle(
              color: AppColors.teal,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final ViewMode mode;
  final bool showMenuButton;
  final String userLabel;
  final VoidCallback onLogout;

  const TopBar({
    super.key,
    required this.mode,
    required this.showMenuButton,
    required this.userLabel,
    required this.onLogout,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  /// Short display form for tight spaces (the pill button): if the label
  /// is an email, show only the part before '@' so it doesn't overflow a
  /// pill-shaped button. The full email is still shown in the compact
  /// dropdown's "Signed in as ..." line where there's more room.
  String get _shortLabel =>
      userLabel.contains('@') ? userLabel.split('@').first : userLabel;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(top: topInset),
      decoration: const BoxDecoration(
        color: AppColors.panelDark,
        border: Border(bottom: BorderSide(color: AppColors.sidebarBorder)),
      ),
      child: SizedBox(
        height: 64,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 640;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: compact ? _compactRow(context) : _fullRow(context),
            );
          },
        ),
      ),
    );
  }

  Widget _brand({bool showSubtitle = true}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.shield_outlined, color: AppColors.teal, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DICT SIEM',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.4,
              ),
            ),
            if (showSubtitle)
              const Text(
                'SIEM/EDR HUB-AND-SPOKE',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 9.5,
                  letterSpacing: 0.4,
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _fullRow(BuildContext context) {
    return Row(
      children: [
        if (showMenuButton)
          IconButton(
            icon: const Icon(Icons.menu, color: AppColors.textSecondary),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        _brand(),
        const Spacer(),
        _ModeIndicator(mode: mode),
        const SizedBox(width: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 160),
          child: _PillButton(
            label: _shortLabel,
            icon: Icons.person_outline,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        _PillButton(label: 'Logout', icon: Icons.logout, onTap: onLogout),
      ],
    );
  }

  Widget _compactRow(BuildContext context) {
    return Row(
      children: [
        if (showMenuButton)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.menu,
                color: AppColors.textSecondary, size: 22),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        const SizedBox(width: 4),
        Expanded(child: _brand(showSubtitle: false)),
        const SizedBox(width: 8),
        _ModeIndicator(mode: mode),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          color: AppColors.card,
          constraints: const BoxConstraints(maxWidth: 150, minWidth: 130),
          icon: const Icon(Icons.more_vert,
              color: AppColors.textSecondary, size: 20),
          onSelected: (v) {
            if (v == 'logout') onLogout();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('Signed in as $userLabel',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ),
            ),
            const PopupMenuItem(
              value: 'logout',
              height: 36,
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Logout', style: TextStyle(color: AppColors.red)),
                    SizedBox(width: 6),
                    Icon(Icons.logout, size: 15, color: AppColors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
