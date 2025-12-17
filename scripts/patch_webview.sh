#!/bin/bash
# Patch desktop_webview_window to allow headless mode on Linux
# This applies a modification to the C++ plugin code to make the window invisible/headless
# when a 1x1 size is requested.

# Target file in the ephemeral directory (symlinked to pub cache)
TARGET="linux/flutter/ephemeral/.plugin_symlinks/desktop_webview_window/linux/webview_window.cc"

if [ ! -f "$TARGET" ]; then
    echo "Target not found at $TARGET."
    echo "Running 'flutter pub get' to attempt to restore plugin symlinks..."
    flutter pub get
fi

if [ -f "$TARGET" ]; then
    echo "Patching $TARGET..."
    
    # We replace the default positioning logic with our custom headless logic.
    # The original code we are replacing:
    # gtk_window_set_position(GTK_WINDOW(window_), GTK_WIN_POS_CENTER);
    
    # The new code handles 1x1 windows by making them utility/invisible.
    
    SEARCH='gtk_window_set_position(GTK_WINDOW(window_), GTK_WIN_POS_CENTER);'
    REPLACE='if (width == 1 \&\& height == 1) { gtk_window_set_skip_taskbar_hint(GTK_WINDOW(window_), TRUE); gtk_window_set_skip_pager_hint(GTK_WINDOW(window_), TRUE); gtk_window_set_type_hint(GTK_WINDOW(window_), GDK_WINDOW_TYPE_HINT_UTILITY); gtk_window_set_resizable(GTK_WINDOW(window_), FALSE); gtk_window_set_decorated(GTK_WINDOW(window_), FALSE); gtk_widget_set_opacity(GTK_WIDGET(window_), 0.0); gtk_window_move(GTK_WINDOW(window_), -10000, -10000); } else { gtk_window_set_position(GTK_WINDOW(window_), GTK_WIN_POS_CENTER); }'
    
    # Check if already patched to avoid double patching (idempotency)
    if grep -q "gtk_widget_set_opacity" "$TARGET"; then
        echo "Patch already applied."
    else
        sed -i "s|$SEARCH|$REPLACE|" "$TARGET"
        echo "Patch applied successfully."
    fi
else
    echo "Error: Could not locate desktop_webview_window plugin source."
    exit 1
fi
