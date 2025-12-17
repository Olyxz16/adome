import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';

class Ribbon extends StatelessWidget {
  const Ribbon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF2D2D2D), // Dark ribbon bg
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Row(
              children: [
                _buildTab('Home', true),
                _buildTab('View', false), // Placeholder
              ],
            ),
          ),
          // Content
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: Color(0xFF333333), // Slightly lighter content bg
              border: Border(top: BorderSide(color: Color(0xFF444444))),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFileGroup(context),
                _buildSeparator(),
                _buildExportGroup(context),
                _buildSeparator(),
                _buildEngineGroup(context),
                _buildSeparator(),
                _buildAppearanceGroup(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF333333) : Colors.transparent,
        border: isActive 
            ? const Border(top: BorderSide(color: Color(0xFF444444)), left: BorderSide(color: Color(0xFF444444)), right: BorderSide(color: Color(0xFF444444)))
            : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: Colors.grey[700],
    );
  }

  Widget _buildGroupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(color: Colors.grey, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFileGroup(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildLargeButton(
                icon: Icons.folder_open,
                label: 'Load',
                onTap: () => context.read<AppState>().openFile(),
              ),
              _buildLargeButton(
                icon: Icons.save,
                label: 'Save',
                onTap: () => context.read<AppState>().saveFile(),
              ),
            ],
          ),
        ),
        _buildGroupTitle('File'),
      ],
    );
  }

  Widget _buildExportGroup(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildLargeButton(
                icon: Icons.image,
                label: 'SVG',
                onTap: () => context.read<AppState>().exportSvg(),
              ),
              // PNG Export button (disabled/placeholder for now)
              Opacity(
                opacity: 0.5,
                child: _buildLargeButton(
                  icon: Icons.photo_camera,
                  label: 'PNG',
                  onTap: () {}, // Not implemented
                ),
              ),
            ],
          ),
        ),
        _buildGroupTitle('Export'),
      ],
    );
  }

  Widget _buildEngineGroup(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              // Config Column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDropdownRow<RenderingEngine>(
                    context: context,
                    label: 'Engine',
                    value: state.engine,
                    items: const [
                      DropdownMenuItem(value: RenderingEngine.mermaid, child: Text('Mermaid')),
                      DropdownMenuItem(value: RenderingEngine.d2, child: Text('D2')),
                    ],
                    onChanged: (v) => context.read<AppState>().setEngine(v!),
                  ),
                  if (state.engine == RenderingEngine.mermaid) ...[
                    const SizedBox(height: 4),
                    _buildDropdownRow<String>(
                      context: context,
                      label: 'Layout',
                      value: state.mermaidLayout,
                      items: const [
                        DropdownMenuItem(value: 'default', child: Text('Default')),
                        DropdownMenuItem(value: 'elk', child: Text('ELK')),
                      ],
                      onChanged: (v) => context.read<AppState>().setMermaidLayout(v!),
                    ),
                    if (state.mermaidLayout == 'elk') ...[
                      const SizedBox(height: 4),
                      _buildDropdownRow<String>(
                        context: context,
                        label: 'Algo',
                        value: state.mermaidElkAlgorithm,
                        items: const [
                          DropdownMenuItem(value: 'layered', child: Text('Layered')),
                          DropdownMenuItem(value: 'stress', child: Text('Stress')),
                          DropdownMenuItem(value: 'force', child: Text('Force')),
                        ],
                        onChanged: (v) => context.read<AppState>().setMermaidElkAlgorithm(v!),
                      ),
                    ]
                  ]
                ],
              ),
              const SizedBox(width: 8),
              // Action Column
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLargeButton(
                    icon: Icons.refresh,
                    label: 'Render',
                    onTap: () => context.read<AppState>().manualRender(),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              // Auto Checkbox
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: state.autoRender, 
                        onChanged: (v) => context.read<AppState>().setAutoRender(v!),
                        checkColor: Colors.black,
                        activeColor: Colors.white,
                      ),
                      const Text('Auto', style: TextStyle(color: Colors.white, fontSize: 12)),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
        _buildGroupTitle('Engine'),
      ],
    );
  }

  Widget _buildAppearanceGroup(BuildContext context) {
    final state = context.watch<AppState>();
    return Column(
      children: [
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDropdownRow<ThemeMode>(
                context: context,
                label: 'App',
                value: state.appTheme,
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                ],
                onChanged: (v) => context.read<AppState>().setAppTheme(v!),
              ),
              const SizedBox(height: 4),
              if (state.engine == RenderingEngine.d2)
                _buildDropdownRow<int>(
                  context: context,
                  label: 'Theme',
                  value: state.d2Theme,
                  items: [0, 1, 3, 4, 5, 6, 7, 8, 100, 101, 102, 103, 104, 105, 300, 301, 302] // Common D2 themes
                      .map((id) => DropdownMenuItem(value: id, child: Text(id.toString())))
                      .toList(),
                  onChanged: (v) => context.read<AppState>().setD2Theme(v!),
                )
              else
                _buildDropdownRow<String>(
                  context: context,
                  label: 'Theme',
                  value: state.mermaidTheme,
                  items: const [
                    DropdownMenuItem(value: 'default', child: Text('Default')),
                    DropdownMenuItem(value: 'neutral', child: Text('Neutral')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                    DropdownMenuItem(value: 'forest', child: Text('Forest')),
                    DropdownMenuItem(value: 'base', child: Text('Base')),
                  ],
                  onChanged: (v) => context.read<AppState>().setMermaidTheme(v!),
                ),
            ],
          ),
        ),
        _buildGroupTitle('Appearance'),
      ],
    );
  }

  Widget _buildLargeButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownRow<T>({
    required BuildContext context,
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    // Find the selected item's text label for display
    final selectedItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );
    final selectedLabel = (selectedItem.child as Text).data ?? '';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 45, 
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11))
        ),
        SizedBox(
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF444444),
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: const Color(0xFF555555)),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: const PopupMenuThemeData(
                  color: Color(0xFF444444), // Menu background
                  textStyle: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
              child: PopupMenuButton<T>(
                initialValue: value,
                onSelected: onChanged,
                tooltip: '', // Disable tooltip to look less like a toolbar button
                offset: const Offset(0, 24), // Position below the button
                padding: EdgeInsets.zero,
                itemBuilder: (context) {
                  return items.map((item) {
                    final text = (item.child as Text).data ?? '';
                    return PopupMenuItem<T>(
                      value: item.value,
                      height: 28, // Compact height
                      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11)),
                    );
                  }).toList();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(selectedLabel, style: const TextStyle(color: Colors.white, fontSize: 11)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
