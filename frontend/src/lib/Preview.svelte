<script lang="ts">
  import mermaid from 'mermaid';
  import elkLayouts from '@mermaid-js/layout-elk';
  import { type GraphTheme, getMermaidThemeVariables } from './theme-store';
  
  // Register ELK layout
  mermaid.registerLayoutLoaders(elkLayouts);
  
  let container: HTMLElement;
  export let errorMsg = '';

  // Zoom/Pan State
  let scale = 1;
  let translateX = 20;
  let translateY = 20;
  let isPanning = false;
  let startX = 0;
  let startY = 0;
  let previewPane: HTMLElement;

  export async function render(input: string, theme: GraphTheme, elkAlgorithm: string = '') {
    if (!container) return;
    errorMsg = '';
    const useElk = !!elkAlgorithm;

    try {
      const themeVariables = getMermaidThemeVariables(theme);
      
      mermaid.initialize({ 
        startOnLoad: false, 
        theme: 'base', // Use 'base' to allow full customization via variables
        themeVariables: themeVariables,
        securityLevel: 'loose',
        flowchart: { htmlLabels: true, curve: 'basis' }
      });

      let graphDefinition = input;
      
      // Inject ELK Frontmatter if requested
      if (useElk) {
          // Determine layout string
          // Default to 'elk' (which maps to layered)
          let layoutName = 'elk';
          let elkOptions = '';
          const layoutOpts = theme.layoutOptions;
          
          if (elkAlgorithm && elkAlgorithm !== 'layered') {
              layoutName = `elk.${elkAlgorithm}`;
          }

          // Dynamically add ELK layout options based on the algorithm
          if (elkAlgorithm === 'stress' || elkAlgorithm === 'force') {
              elkOptions = `
    org.eclipse.elk.force.repulsivePower: ${layoutOpts.repulsivePower}
    org.eclipse.elk.stress.desiredEdgeLength: ${layoutOpts.desiredEdgeLength}`;
          } else if (elkAlgorithm === 'layered') {
              elkOptions = `
    org.eclipse.elk.spacing.nodeNode: ${layoutOpts.nodeNodeSpacing}
    org.eclipse.elk.layered.spacing.nodeNodeBetweenLayers: ${layoutOpts.nodeNodeBetweenLayersSpacing}
    org.eclipse.elk.layered.spacing.baseValue: ${layoutOpts.baseValueSpacing}`;
          }
          // Add other specific options as needed for other algorithms


          // Check if frontmatter already exists to avoid duplication or conflict
          // We check for the specific 'layout: elk' or 'layout: elk.' pattern
          if (!graphDefinition.match(/layout:\s*elk/)) {
              const frontmatter = `---\nconfig:\n  layout: ${layoutName}\n  elk: ${elkOptions}\n---\n`;
              // Add newline if input doesn't start with one, though frontmatter handles it
              graphDefinition = frontmatter + graphDefinition;
          }
      }

      // Unique ID for each render to prevent conflicts
      const id = 'mermaid-' + Math.random().toString(36).substr(2, 9);
      const { svg } = await mermaid.render(id, graphDefinition);
      container.innerHTML = svg;
    } catch (e) {
      console.error(e);
      errorMsg = e.message || 'Error rendering graph';
    }
  }  function onMouseDown(e: MouseEvent) {
    if (e.button !== 0 && e.button !== 1) return; // Only Left or Middle click
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

    const delta = e.deltaY > 0 ? 0.95 : 1.05;
    const prevScale = scale;
    scale *= delta;
    
    // Limits
    scale = Math.min(Math.max(0.1, scale), 10);

    // Zoom towards cursor
    translateX = offsetX - (offsetX - translateX) * (scale / prevScale);
    translateY = offsetY - (offsetY - translateY) * (scale / prevScale);
  }

  function fitView() {
    if (!previewPane || !container) return;
    
    const paneRect = previewPane.getBoundingClientRect();
    const contentRect = container.getBoundingClientRect();
    
    // We need the unscaled dimensions of the content
    // Since contentRect is affected by current scale, we divide by current scale
    const contentWidth = contentRect.width / scale;
    const contentHeight = contentRect.height / scale;
    
    if (contentWidth === 0 || contentHeight === 0) return;

    const scaleX = (paneRect.width * 0.9) / contentWidth;
    const scaleY = (paneRect.height * 0.9) / contentHeight;
    
    // Choose the smaller scale to ensure it fits entirely
    const newScale = Math.min(scaleX, scaleY, 1); // Cap at 1 to prevent expanding small diagrams too much? Or allow zoom in? Let's allow max 1.5 or just min.
    // Actually standard fit-to-view usually allows zooming out but maybe caps zooming in at 100% if it's small, or fills screen. 
    // Let's stick to fitting the screen, even if it means zooming in.
    scale = Math.min(scaleX, scaleY);
    
    // Recenter
    translateX = (paneRect.width - contentWidth * scale) / 2;
    translateY = (paneRect.height - contentHeight * scale) / 2;
  }

  export function getSVG() {
      return container ? container.innerHTML : '';
  }

  export function getPNG(): Promise<string> {
      return new Promise((resolve, reject) => {
          if (!container) {
              reject('No content');
              return;
          }
          
          const svgElement = container.querySelector('svg');
          if (!svgElement) {
              reject('No SVG found');
              return;
          }

          // Serialize SVG
          const serializer = new XMLSerializer();
          const svgString = serializer.serializeToString(svgElement);
          
          // Get dimensions
          // Try to get viewBox or width/height attributes
          let width = parseInt(svgElement.getAttribute('width'));
          let height = parseInt(svgElement.getAttribute('height'));
          
          // If not set, check viewBox
          if (!width || !height) {
              const viewBox = svgElement.getAttribute('viewBox');
              if (viewBox) {
                  const parts = viewBox.split(/\s+|,/);
                  if (parts.length === 4) {
                      width = parseFloat(parts[2]);
                      height = parseFloat(parts[3]);
                  }
              }
          }
          
          // Fallback to bounding rect if still unknown (though mermaid usually sets them)
          if (!width || !height) {
              const rect = svgElement.getBoundingClientRect();
              width = rect.width;
              height = rect.height;
          }
          
          // Multiply by a factor for better resolution? e.g. 2x
          const scaleFactor = 2;
          width *= scaleFactor;
          height *= scaleFactor;

          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          
          const img = new Image();
          // We need to encode the SVG string to base64 for the image source
          // to avoid issues with special characters
          const svgBase64 = btoa(unescape(encodeURIComponent(svgString)));
          img.src = 'data:image/svg+xml;base64,' + svgBase64;
          
          img.onload = () => {
              ctx.drawImage(img, 0, 0, width, height);
              const dataURL = canvas.toDataURL('image/png');
              // Remove prefix to get raw base64
              const base64 = dataURL.replace(/^data:image\/png;base64,/, '');
              resolve(base64);
          };
          
          img.onerror = (e) => {
              reject(e);
          };
      });
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
  {#if errorMsg}
    <div class="error">{errorMsg}</div>
  {/if}
  <div 
    bind:this={container} 
    class="mermaid-container"
    style="transform: translate({translateX}px, {translateY}px) scale({scale});"
  ></div>
  
  <button class="fit-btn" on:click|stopPropagation={fitView} title="Fit to Screen">
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2 2h3"></path>
    </svg>
  </button>
</div>

<style>
  .preview-pane {
    flex: 1;
    display: block;
    padding: 0;
    overflow: hidden;
    position: relative;
    background-color: var(--bg-preview);
    transition: background-color 0.3s;
    cursor: grab;
    width: 100%;
    height: 100%;
    user-select: none; /* Prevent selection while panning */
  }

  .mermaid-container {
    position: absolute;
    top: 0;
    left: 0;
    transform-origin: 0 0;
    /* Ensure it doesn't collapse */
    width: max-content;
    height: max-content;
  }

  .error {
    position: absolute;
    top: 10px;
    left: 10px;
    right: 10px;
    color: #d8000c;
    background-color: #ffd2d2;
    border: 1px solid #d8000c;
    padding: 10px;
    border-radius: 4px;
    z-index: 10;
    font-size: 13px;
    pointer-events: none;
  }

  .fit-btn {
    position: absolute;
    bottom: 20px;
    right: 20px;
    width: 36px;
    height: 36px;
    border-radius: 4px;
    background-color: var(--bg-ribbon-content);
    border: 1px solid var(--border-color);
    color: var(--text-main);
    display: flex;
    align-items: center;
    justify-content: center;
    cursor: pointer;
    box-shadow: 0 2px 5px rgba(0,0,0,0.1);
    transition: background-color 0.2s, transform 0.1s;
    z-index: 100;
    padding: 0;
  }
  
  .fit-btn:hover {
    background-color: var(--btn-hover);
  }
  
  .fit-btn:active {
    background-color: var(--btn-active);
    transform: translateY(1px);
  }
</style>
