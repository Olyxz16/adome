import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../services/theme_service.dart';
import '../../models/app_theme_config.dart';

class Ribbon extends StatelessWidget {
  const Ribbon({super.key});

  @override
  Widget build(BuildContext context) {
    // Determine ribbon styling based on the APP Theme (not diagram theme)
    final isAppDark = Theme.of(context).brightness == Brightness.dark;

    final ribbonColor = isAppDark ? const Color(0xFF2D2D2D) : const Color(0xFFE0E0E0);
    final contentColor = isAppDark ? const Color(0xFF333333) : const Color(0xFFF5F5F5);
    final borderColor = isAppDark ? const Color(0xFF444444) : const Color(0xFFBDBDBD);
    final textColor = isAppDark ? Colors.white : Colors.black87;
    final iconColor = isAppDark ? Colors.white : Colors.black54;
    final labelColor = isAppDark ? Colors.grey : Colors.black54;

    return Container(
      color: ribbonColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tabs
          Container(
            padding: const EdgeInsets.only(left: 8, top: 4),
            child: Row(
              children: [
                _buildTab('Home', true, contentColor, borderColor, textColor),
                _buildTab('View', false, contentColor, borderColor, labelColor), // Placeholder
              ],
            ),
          ),
          // Content
          Container(
            height: 100,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: contentColor,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            // Fix Overflow: Allow horizontal scrolling if ribbon content is too wide
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFileGroup(context, iconColor, textColor, labelColor),
                  _buildSeparator(isAppDark),
                  _buildExportGroup(context, iconColor, textColor, labelColor),
                  _buildSeparator(isAppDark),
                  _buildEngineGroup(context, isAppDark, iconColor, textColor, labelColor, borderColor),
                  _buildSeparator(isAppDark),
                  _buildAppearanceGroup(context, isAppDark, textColor, labelColor, borderColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isActive, Color contentColor, Color borderColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? contentColor : Colors.transparent,
        border: isActive 
            ? Border(top: BorderSide(color: borderColor), left: BorderSide(color: borderColor), right: BorderSide(color: borderColor))
            : null,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isActive ? textColor : Colors.grey,
          fontSize: 13,
          fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSeparator(bool isDark) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isDark ? Colors.grey[700] : Colors.grey[400],
    );
  }

  Widget _buildGroupTitle(String title, Color labelColor) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: labelColor, fontSize: 10, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildFileGroup(BuildContext context, Color iconColor, Color textColor, Color labelColor) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildLargeButton(
                icon: Icons.folder_open,
                label: 'Load',
                onTap: () => context.read<AppState>().openFile(),
                iconColor: iconColor,
                textColor: textColor,
              ),
              _buildLargeButton(
                icon: Icons.save,
                label: 'Save',
                onTap: () => context.read<AppState>().saveFile(),
                iconColor: iconColor,
                textColor: textColor,
              ),
            ],
          ),
        ),
        _buildGroupTitle('File', labelColor),
      ],
    );
  }

  Widget _buildExportGroup(BuildContext context, Color iconColor, Color textColor, Color labelColor) {
    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _buildLargeButton(
                icon: Icons.image,
                label: 'SVG',
                onTap: () => context.read<AppState>().exportSvg(),
                iconColor: iconColor,
                textColor: textColor,
              ),
              Opacity(
                opacity: 0.5,
                child: _buildLargeButton(
                  icon: Icons.photo_camera,
                  label: 'PNG',
                  onTap: () {}, 
                  iconColor: iconColor,
                  textColor: textColor,
                ),
              ),
            ],
          ),
        ),
        _buildGroupTitle('Export', labelColor),
      ],
    );
  }

  Widget _buildEngineGroup(BuildContext context, bool isDark, Color iconColor, Color textColor, Color labelColor, Color borderColor) {
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
                    textColor: textColor,
                    labelColor: labelColor,
                    borderColor: borderColor,
                    isDark: isDark,
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
                      textColor: textColor,
                      labelColor: labelColor,
                      borderColor: borderColor,
                      isDark: isDark,
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
                        textColor: textColor,
                        labelColor: labelColor,
                        borderColor: borderColor,
                        isDark: isDark,
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
                    iconColor: iconColor,
                    textColor: textColor,
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
                        checkColor: isDark ? Colors.black : Colors.white,
                        activeColor: isDark ? Colors.white : Colors.black,
                        side: BorderSide(color: textColor),
                      ),
                      Text('Auto', style: TextStyle(color: textColor, fontSize: 12)),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
        _buildGroupTitle('Engine', labelColor),
      ],
    );
  }

  Widget _buildAppearanceGroup(BuildContext context, bool isDark, Color textColor, Color labelColor, Color borderColor) {
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
                value: state.appThemeMode,
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                ],
                onChanged: (v) => context.read<AppState>().setAppThemeMode(v!),
                textColor: textColor,
                labelColor: labelColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
              const SizedBox(height: 4),
              _buildDropdownRow<AppThemeConfig>(
                context: context,
                label: 'Theme',
                value: state.activeThemeConfig,
                items: ThemeService.availableThemes
                    .map((theme) => DropdownMenuItem(
                      value: theme,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            theme.isDark ? Icons.dark_mode : Icons.light_mode, 
                            size: 14, 
                            color: theme.isDark ? Colors.amber[200] : Colors.orange[800]
                          ),
                          const SizedBox(width: 8),
                          Text(theme.name),
                        ],
                      ),
                    ))
                    .toList(),
                onChanged: (v) => context.read<AppState>().setDiagramTheme(v!),
                textColor: textColor,
                labelColor: labelColor,
                borderColor: borderColor,
                isDark: isDark,
              ),
            ],
          ),
        ),
        _buildGroupTitle('Appearance', labelColor),
      ],
    );
  }

  Widget _buildLargeButton({
    required IconData icon, 
    required String label, 
    required VoidCallback onTap,
    required Color iconColor,
    required Color textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: textColor, fontSize: 11)),
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
    required Color textColor,
    required Color labelColor,
    required Color borderColor,
    required bool isDark,
  }) {
    final selectedItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => items.first,
    );
    
    Widget displayLabel;
    if (selectedItem.child is Text) {
      displayLabel = Text(
        (selectedItem.child as Text).data ?? '', 
        style: TextStyle(color: textColor, fontSize: 11)
      );
    } else if (selectedItem.child is Row) {
      if (value is AppThemeConfig) {
         final theme = value as AppThemeConfig;
         displayLabel = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                theme.isDark ? Icons.dark_mode : Icons.light_mode, 
                size: 12, 
                color: textColor
              ),
              const SizedBox(width: 4),
              Text(theme.name, style: TextStyle(color: textColor, fontSize: 11)),
            ],
         );
      } else {
         displayLabel = selectedItem.child;
      }
    } else {
      displayLabel = selectedItem.child;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 45, 
          child: Text(label, style: TextStyle(color: labelColor, fontSize: 11))
        ),
        SizedBox(
          height: 24,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF444444) : Colors.white,
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: borderColor),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(
                popupMenuTheme: PopupMenuThemeData(
                  color: isDark ? const Color(0xFF444444) : Colors.white,
                  textStyle: TextStyle(color: textColor, fontSize: 11),
                ),
              ),
              child: PopupMenuButton<T>(
                initialValue: value,
                onSelected: onChanged,
                tooltip: '',
                offset: const Offset(0, 24),
                padding: EdgeInsets.zero,
                itemBuilder: (context) {
                  return items.map((item) {
                    return PopupMenuItem<T>(
                      value: item.value,
                      height: 28,
                      child: DefaultTextStyle(
                        style: TextStyle(color: textColor, fontSize: 11),
                        child: item.child,
                      ),
                    );
                  }).toList();
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      displayLabel,
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: labelColor, size: 16),
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
