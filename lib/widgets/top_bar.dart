import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'common.dart';

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
              'DICT-4A WAZUH',
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

  /// Wide-screen row. Every pill here is wrapped in Flexible + built from
  /// AdaptivePill, so even the "full" desktop row auto-shrinks gracefully
  /// if the window gets dragged narrower than expected, instead of only
  /// being safe in the dedicated `_compactRow` layout.
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
        Flexible(
          child: _TappablePill(
            label: 'Regional View',
            shortLabel: 'Regional',
            icon: Icons.grid_view_rounded,
            filled: mode == ViewMode.regional,
            onTap: () => onModeChanged(ViewMode.regional),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _TappablePill(
            label: 'Provincial View',
            shortLabel: 'Provincial',
            icon: Icons.person_outline,
            filled: mode == ViewMode.provincial,
            onTap: () => onModeChanged(ViewMode.provincial),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _TappablePill(
            label: 'Lance',
            icon: Icons.person_outline,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: _TappablePill(
            label: 'Logout',
            icon: Icons.logout,
            onTap: onLogout,
          ),
        ),
      ],
    );
  }

  /// Compact (phone-width) row: text-label dropdown for the view switcher
  /// + overflow menu for logout. The dropdown pill is an AdaptivePill, so
  /// it measures its own label against whatever room `Flexible` actually
  /// leaves it — no more guessing a pixel breakpoint per screen.
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
        // Flexible = the dropdown always gets whatever real width is left,
        // and AdaptivePill inside it measures against exactly that.
        Flexible(
          child: _ViewDropdown(mode: mode, onModeChanged: onModeChanged),
        ),
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
///
/// The trigger pill itself is an AdaptivePill: it automatically drops to
/// "Regional"/"Provincial" and finally to icon-only as space shrinks. The
/// open menu always shows the full label, since that has room to spare.
class _ViewDropdown extends StatelessWidget {
  final ViewMode mode;
  final ValueChanged<ViewMode> onModeChanged;

  const _ViewDropdown({required this.mode, required this.onModeChanged});

  String _fullLabel(ViewMode m) =>
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
                  _fullLabel(m),
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
      child: AdaptivePill(
        label: _fullLabel(mode),
        shortLabel: mode == ViewMode.regional ? 'Regional' : 'Provincial',
        leadingIcon: mode == ViewMode.regional
            ? Icons.grid_view_rounded
            : Icons.person_outline,
        trailingIcon: Icons.keyboard_arrow_down,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

/// A simple tappable AdaptivePill — used by the full-width row's
/// mode-toggle/profile/logout buttons.
class _TappablePill extends StatelessWidget {
  final String label;
  final String? shortLabel;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _TappablePill({
    required this.label,
    this.shortLabel,
    required this.icon,
    this.filled = false,
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
        child: AdaptivePill(
          label: label,
          shortLabel: shortLabel,
          leadingIcon: icon,
          filled: filled,
        ),
      ),
    );
  }
}
