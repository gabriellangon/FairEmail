import 'package:flutter/material.dart';
import '../utils/zoom_controller.dart';

/// Bottom sheet with zoom controls.
///
/// Mirrors FairEmail's display settings: view_zoom cycle button,
/// message_zoom slider, and overview_mode toggle.
class ZoomControlsSheet extends StatefulWidget {
  final ZoomController controller;

  const ZoomControlsSheet({super.key, required this.controller});

  @override
  State<ZoomControlsSheet> createState() => _ZoomControlsSheetState();
}

class _ZoomControlsSheetState extends State<ZoomControlsSheet> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.format_size, size: 22),
              const SizedBox(width: 8),
              const Text('Contrôles de zoom',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),

          // View zoom — 3 levels (like FragmentMessages.onMenuZoom)
          const Text('Niveau de zoom',
              style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              _ZoomLevelChip(
                label: 'Petit',
                icon: Icons.text_decrease,
                selected: ctrl.viewZoom == 0,
                onTap: () {
                  while (ctrl.viewZoom != 0) {
                    ctrl.cycleViewZoom();
                  }
                },
              ),
              const SizedBox(width: 8),
              _ZoomLevelChip(
                label: 'Normal',
                icon: Icons.text_fields,
                selected: ctrl.viewZoom == 1,
                onTap: () {
                  while (ctrl.viewZoom != 1) {
                    ctrl.cycleViewZoom();
                  }
                },
              ),
              const SizedBox(width: 8),
              _ZoomLevelChip(
                label: 'Grand',
                icon: Icons.text_increase,
                selected: ctrl.viewZoom == 2,
                onTap: () {
                  while (ctrl.viewZoom != 2) {
                    ctrl.cycleViewZoom();
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Message zoom slider — 50% to 250% (like sbMessageZoom)
          Row(
            children: [
              const Text('Zoom texte',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const Spacer(),
              Text(
                '${ctrl.messageZoom}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ctrl.messageZoom != 100
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ],
          ),
          Slider(
            value: ctrl.messageZoom.toDouble(),
            min: 50,
            max: 250,
            divisions: 40,
            label: '${ctrl.messageZoom}%',
            onChanged: (v) => ctrl.setMessageZoom(v.round()),
          ),

          // Font size preview
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Aperçu: Ceci est un texte de démonstration.',
              style: TextStyle(fontSize: ctrl.effectiveFontSize),
            ),
          ),
          const SizedBox(height: 16),

          // Overview mode toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mode aperçu'),
            subtitle: const Text('Ajuster la largeur à l\'écran'),
            value: ctrl.overviewMode,
            onChanged: ctrl.setOverviewMode,
          ),

          // Pinch-to-zoom hint
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Row(
              children: [
                Icon(Icons.pinch, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Pincez pour zoomer dans le contenu',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomLevelChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ZoomLevelChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
            border: selected
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            children: [
              Icon(icon,
                  size: 22,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade700,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
