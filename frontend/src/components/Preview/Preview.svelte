<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { editorContent, renderingEngine, layoutEngine, elkAlgorithm, editorCommand, type CommandType, triggerRender } from '../../lib/stores/editor';
  import { currentTheme } from '../../lib/stores/theme';
  import { ExportSVG, ExportPNG } from '../../lib/services/bridge';
  
  import MermaidCanvas from './MermaidCanvas.svelte';
  import D2Canvas from './D2Canvas.svelte';

  let previewPane: HTMLElement;
  let container: HTMLElement;
  
  let scale = 1;
  let translateX = 0;
  let translateY = 0;
  let isPanning = false;
  let startX = 0;
  let startY = 0;

  let debouncedContent = $editorContent;
  let debounceTimer: any;

  // Debounce logic
  $: {
      const content = $editorContent;
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => {
          debouncedContent = content;
      }, 500);
  }

  // Force render logic
  triggerRender.subscribe(() => {
      debouncedContent = $editorContent;
  });

  // Export Logic
  editorCommand.subscribe(async (cmd) => {
      // Check timestamp to avoid stale commands if any
      if (cmd.type === 'none' || Date.now() - cmd.timestamp > 2000) return;
      
      const svg = getSVG();
      if (!svg) return;

      if (cmd.type === 'export-svg') {
          await ExportSVG(svg);
      } else if (cmd.type === 'export-png') {
          try {
             const pngBase64 = await convertSvgToPng(svg);
             await ExportPNG(pngBase64);
          } catch(e) {
              console.error("PNG export failed", e);
          }
      }
  });

  function getSVG() {
     if (!container) return '';
     const svgEl = container.querySelector('svg');
     if (!svgEl) return '';
     return new XMLSerializer().serializeToString(svgEl);
  }

  function convertSvgToPng(svgString: string): Promise<string> {
      return new Promise((resolve, reject) => {
          const img = new Image();
          const svgBase64 = btoa(unescape(encodeURIComponent(svgString)));
          img.src = 'data:image/svg+xml;base64,' + svgBase64;
          
          img.onload = () => {
              // Extract width/height from SVG string or image natural size
              // We use image natural size which is parsed from SVG
              const width = img.width || 800;
              const height = img.height || 600;
              
              const canvas = document.createElement('canvas');
              const scaleFactor = 2; // 2x resolution
              canvas.width = width * scaleFactor;
              canvas.height = height * scaleFactor;
              const ctx = canvas.getContext('2d');
              
              if (ctx) {
                  ctx.fillStyle = $currentTheme.background; // fill background
                  ctx.fillRect(0, 0, canvas.width, canvas.height);
                  ctx.drawImage(img, 0, 0, canvas.width, canvas.height);
                  const dataURL = canvas.toDataURL('image/png');
                  resolve(dataURL.replace(/^data:image\/png;base64,/, ''));
              } else {
                  reject("Canvas context not available");
              }
          };
          img.onerror = reject;
      });
  }

  // Mouse Handlers
  function onMouseDown(e: MouseEvent) {
    if (e.button !== 0 && e.button !== 1) return;
    isPanning = true;
    startX = e.clientX - translateX;
    startY = e.clientY - translateY;
    if (previewPane) previewPane.style.cursor = 'grabbing';
  }

  function onMouseMove(e: MouseEvent) {
    if (!isPanning) return;
    e.preventDefault();
    translateX = e.clientX - startX;
    translateY = e.clientY - startY;
  }

  function onMouseUp() {
    isPanning = false;
    if (previewPane) previewPane.style.cursor = 'grab';
  }
  
  function onWheel(e: WheelEvent) {
    e.preventDefault();
    if (!previewPane) return;
    
    const rect = previewPane.getBoundingClientRect();
    const offsetX = e.clientX - rect.left;
    const offsetY = e.clientY - rect.top;

    const delta = e.deltaY > 0 ? 0.9 : 1.1;
    const prevScale = scale;
    scale *= delta;
    scale = Math.min(Math.max(0.1, scale), 10);

    // Zoom towards cursor
    translateX = offsetX - (offsetX - translateX) * (scale / prevScale);
    translateY = offsetY - (offsetY - translateY) * (scale / prevScale);
  }

  function fitView() {
    if (!previewPane || !container) return;
    const paneRect = previewPane.getBoundingClientRect();
    // Use container's first child (the canvas wrapper) for content size
    const content = container.firstElementChild as HTMLElement;
    if (!content) return;
    
    const contentRect = content.getBoundingClientRect();
    // Unscaled dimensions
    const contentW = contentRect.width / scale;
    const contentH = contentRect.height / scale;

    if (contentW === 0 || contentH === 0) return;

    const scaleX = (paneRect.width * 0.9) / contentW;
    const scaleY = (paneRect.height * 0.9) / contentH;
    
    scale = Math.min(scaleX, scaleY);
    translateX = (paneRect.width - contentW * scale) / 2;
    translateY = (paneRect.height - contentH * scale) / 2;
  }
</script>

<div 
  class="preview-pane" 
  bind:this={previewPane}
  on:mousedown={onMouseDown} 
  on:mousemove={onMouseMove} 
  on:mouseup={onMouseUp} 
  on:mouseleave={onMouseUp}
  on:wheel={onWheel}
  role="presentation"
>
  <div 
    bind:this={container} 
    class="zoom-layer"
    style="transform: translate({translateX}px, {translateY}px) scale({scale});"
  >
      {#if $renderingEngine === 'mermaid'}
        <MermaidCanvas
            code={debouncedContent}
            theme={$currentTheme}
            layout={$layoutEngine === 'elk' ? $elkAlgorithm : ''} 
         />
      {:else}
         <D2Canvas code={debouncedContent} />
      {/if}
  </div>
  
  <button class="fit-btn" on:click|stopPropagation={fitView} title="Fit to Screen">
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"></path>
    </svg>
  </button>
</div>

<style>
  .preview-pane {
    flex: 1;
    overflow: hidden;
    position: relative;
    background-color: var(--bg-preview);
    cursor: grab;
    width: 100%;
    height: 100%;
    user-select: none;
  }
  .zoom-layer {
      position: absolute;
      top: 0; left: 0;
      transform-origin: 0 0;
      width: 100%; /* Make it fill the parent */
      height: 100%; /* Make it fill the parent */
  }
  .fit-btn {
    position: absolute;
    bottom: 20px;
    right: 20px;
    width: 36px;
    height: 36px;
    background-color: var(--bg-ribbon-content);
    border: 1px solid var(--border-color);
    color: var(--text-main);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    border-radius: 4px;
    z-index: 100;
  }
</style>
