#!/bin/sh
export WEBKIT_DISABLE_COMPOSITING_MODE=1
export WEBKIT_DISABLE_DMABUF_RENDERER=1
export WEBKIT_FORCE_SANDBOX=0

cd /opt/adome/
exec ./adome "$@"
