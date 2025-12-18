import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

class WindowControls extends StatelessWidget {
  final Color iconColor;
  final bool isDark;

  const WindowControls({
    super.key,
    required this.iconColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (Platform.isMacOS) return const SizedBox.shrink();

    final isLinux = Platform.isLinux;
    // Linux (Adwaita/GNOME) typically puts controls: Minimize, Maximize, Close.
    // Spacing is usually tighter or grouped.
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _WindowButton(
          icon: Icons.minimize, // Use minimize icon which is better aligned
          onTap: windowManager.minimize,
          iconColor: iconColor,
          type: WindowButtonType.minimize,
          isLinux: isLinux,
        ),
        if (isLinux) const SizedBox(width: 4),
        _WindowButton(
          icon: Icons.crop_square,
          onTap: () async {
            if (await windowManager.isMaximized()) {
              windowManager.unmaximize();
            } else {
              windowManager.maximize();
            }
          },
          iconColor: iconColor,
          type: WindowButtonType.maximize,
          isLinux: isLinux,
        ),
        if (isLinux) const SizedBox(width: 4),
        _WindowButton(
          icon: Icons.close,
          onTap: windowManager.close,
          iconColor: iconColor,
          type: WindowButtonType.close,
          isLinux: isLinux,
        ),
        if (isLinux) const SizedBox(width: 8),
      ],
    );
  }
}

enum WindowButtonType { minimize, maximize, close }

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;
  final WindowButtonType type;
  final bool isLinux;

  const _WindowButton({
    required this.icon,
    required this.onTap,
    required this.iconColor,
    required this.type,
    required this.isLinux,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.isLinux) {
      return _buildLinuxButton();
    } else {
      return _buildWindowsButton();
    }
  }

  Widget _buildWindowsButton() {
    final isClose = widget.type == WindowButtonType.close;
    final backgroundColor = _isHovered
        ? (isClose ? const Color(0xFFE81123) : Colors.grey.withValues(alpha: 0.1))
        : Colors.transparent;
        
    final iconColor = _isHovered && isClose ? Colors.white : widget.iconColor;
    
    // Windows buttons are typically 46x32
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 46,
          height: 32,
          color: backgroundColor,
          child: Center(
            child: Icon(widget.icon, size: 10, color: iconColor), // Smaller icon for Windows look
          ),
        ),
      ),
    );
  }

  Widget _buildLinuxButton() {
    // Linux (Adwaita-ish) Style: Circular, slightly smaller
    final isClose = widget.type == WindowButtonType.close;
    
    Color backgroundColor = Colors.transparent;
    Color iconColor = widget.iconColor;

    if (_isHovered) {
      if (isClose) {
        backgroundColor = const Color(0xFFD32F2F); // Red circle for close
        iconColor = Colors.white;
      } else {
        backgroundColor = Colors.grey.withValues(alpha: 0.2);
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(widget.icon, size: 14, color: iconColor),
          ),
        ),
      ),
    );
  }
}
