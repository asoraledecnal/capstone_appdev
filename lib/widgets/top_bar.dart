import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ViewMode { regional, provincial }

class TopBar extends StatelessWidget implements PreferredSizeWidget {
  final ViewMode mode;
  final ValueChanged<ViewMode> onModeChanged;
  final VoidCallback onLogout;
  final bool showMenuButton;

  const TopBar({
    super.key,
    required this.mode,
    required this.onModeChanged,
    required this.onLogout,
    this.showMenuButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    // Scaffold gives this widget a height of (preferredSize.height + the
    // device's top safe-area inset) automatically. The previous version
    // fixed the Container at exactly 64px and then used SafeArea *inside*
    // that same 64px, which ate into it a second time and caused the
    // "bottom overflowed" error on phones with a notch/status bar. Instead,
    // add the inset as top padding so the total height matches what
    // Scaffold actually allocated, and keep the toolbar row itself at a
    // fixed 64px underneath it.
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
            // Below this width there isn't room for full labels everywhere,
            // so we switch to a text-dropdown / overflow-menu layout instead
            // of letting Flutter squeeze text into a single-character column.
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

  // Shortened from "DICT-4A WAZUH" to "DICT SIEM" — on some phones the
  // longer title overlapped the Regional/Provincial pill next to it. The
  // subtitle is still hidden in the compact row (showSubtitle: false) to
  // keep that space tight as well.
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
        _ToggleButton(
          label: 'Regional View',
          icon: Icons.grid_view_rounded,
          selected: mode == ViewMode.regional,
          onTap: () => onModeChanged(ViewMode.regional),
        ),
        const SizedBox(width: 8),
        _ToggleButton(
          label: 'Provincial View',
          icon: Icons.person_outline,
          selected: mode == ViewMode.provincial,
          onTap: () => onModeChanged(ViewMode.provincial),
        ),
        const SizedBox(width: 8),
        _PillButton(label: 'Lance', icon: Icons.person_outline, onTap: () {}),
        const SizedBox(width: 8),
        _PillButton(label: 'Logout', icon: Icons.logout, onTap: onLogout),
      ],
    );
  }

  /// Text-label dropdown for the view switcher + overflow menu for logout,
  /// used on phone-width screens. Replaces the old icon-only toggle so the
  /// current mode is readable instead of relying on icon meaning alone.
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
        _ViewDropdown(mode: mode, onModeChanged: onModeChanged),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          padding: EdgeInsets.zero,
          color: AppColors.card,
          icon: const Icon(Icons.more_vert,
              color: AppColors.textSecondary, size: 20),
          onSelected: (v) {
            if (v == 'logout') onLogout();
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              enabled: false,
              child: Text('Signed in as Lance',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 16, color: AppColors.red),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: AppColors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Text-based dropdown for switching between Regional/Provincial view.
/// Shows the current mode as a readable label ("Regional View ▾") instead
/// of a bare icon, and opens a menu with full text options.
///
/// Built on PopupMenuButton instead of a hand-rolled Overlay/LayerLink so
/// the menu's position is computed by Flutter itself and always renders
/// directly attached under the button, regardless of screen width.
class _ViewDropdown extends StatelessWidget {
  final ViewMode mode;
  final ValueChanged<ViewMode> onModeChanged;

  const _ViewDropdown({required this.mode, required this.onModeChanged});

  String _label(ViewMode m) =>
      m == ViewMode.regional ? 'Regional View' : 'Provincial View';

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ViewMode>(
      color: AppColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      // Nudges the menu down a bit and keeps its right edge lined up with
      // the button's right edge (PopupMenuButton anchors from its own
      // bounds, so this stays correct at any button position on screen).
      offset: const Offset(0, 44),
      onSelected: onModeChanged,
      itemBuilder: (context) => [
        for (final m in ViewMode.values)
          PopupMenuItem(
            value: m,
            child: Row(
              children: [
                Icon(
                  m == ViewMode.regional
                      ? Icons.grid_view_rounded
                      : Icons.person_outline,
                  size: 15,
                  color: m == mode ? AppColors.teal : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  _label(m),
                  style: TextStyle(
                    color: m == mode ? AppColors.teal : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.teal),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _label(mode),
              style: const TextStyle(
                color: AppColors.teal,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: AppColors.teal,
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _PillButton(
      label: label,
      icon: icon,
      onTap: onTap,
      filled: selected,
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.teal : Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: filled ? AppColors.teal : AppColors.cardBorder,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: filled ? Colors.black : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: filled ? Colors.black : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
