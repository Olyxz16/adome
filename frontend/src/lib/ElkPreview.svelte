<script lang="ts">
  import { layoutGraph } from './elk/elk-api';
  import { parseTextToGraph } from './elk/parser';
  import type { ElkGraph } from './elk/parser';
  
  export let errorMsg = '';
  let graph: any = null;
  let container: HTMLElement;
  let previewPane: HTMLElement;
  
  // Zoom/Pan State
  let scale = 1;
  let translateX = 20;
  let translateY = 20;
  let isPanning = false;
  let startX = 0;
  let startY = 0;

  // Measurement
  let ctx: CanvasRenderingContext2D | null = null;
  
  function measureText(text: string) {
      if (!ctx) {
          const canvas = document.createElement('canvas');
          ctx = canvas.getContext('2d');
      }
      if (ctx) {
          ctx.font = '14px sans-serif';
          const metrics = ctx.measureText(text);
          return {
              width: metrics.width + 30, // Padding
              height: 40 // Fixed height for now, or approx based on font size
          };
      }
      return { width: 100, height: 50 };
  }

  export async function render(input: string, algorithm: string) {
    if (!container) return;
    errorMsg = '';
    try {
      const rawGraph = parseTextToGraph(input, measureText);
      // Ensure we pass the algorithm
      const layoutedGraph = await layoutGraph(rawGraph, algorithm);
      graph = layoutedGraph;
    } catch (e: any) {
      console.error(e);
      errorMsg = e.message || 'Error rendering graph';
    }
  }

  function onMouseDown(e: MouseEvent) {
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
    if (!previewPane || !graph) return;
    
    const paneRect = previewPane.getBoundingClientRect();
    const contentWidth = graph.width || 100;
    const contentHeight = graph.height || 100;
    
    const scaleX = (paneRect.width * 0.9) / contentWidth;
    const scaleY = (paneRect.height * 0.9) / contentHeight;
    
    scale = Math.min(scaleX, scaleY, 1);
    
    translateX = (paneRect.width - contentWidth * scale) / 2;
    translateY = (paneRect.height - contentHeight * scale) / 2;
  }

  export function getSVG() {
      return container ? container.innerHTML : '';
  }

  export function getPNG() {
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
          
          // Get dimensions from graph or SVG attributes
          let width = graph ? graph.width : 0;
          let height = graph ? graph.height : 0;
          
          if (!width || !height) {
             width = parseInt(svgElement.getAttribute('width'));
             height = parseInt(svgElement.getAttribute('height'));
          }

          // Scale factor for better resolution
          const scaleFactor = 2;
          width *= scaleFactor;
          height *= scaleFactor;

          const canvas = document.createElement('canvas');
          canvas.width = width;
          canvas.height = height;
          const ctx = canvas.getContext('2d');
          
          // Fill background white (since ELK preview has transparent/CSS bg)
          ctx.fillStyle = '#ffffff';
          ctx.fillRect(0, 0, width, height);
          
          const img = new Image();
          const svgBase64 = btoa(unescape(encodeURIComponent(svgString)));
          img.src = 'data:image/svg+xml;base64,' + svgBase64;
          
          img.onload = () => {
              ctx.drawImage(img, 0, 0, width, height);
              const dataURL = canvas.toDataURL('image/png');
              const base64 = dataURL.replace(/^data:image\/png;base64,/, '');
              resolve(base64);
          };
          
          img.onerror = (e) => {
              reject(e);
          };
      });
  }

    function getEdgePath(edge: any) {

        if (!edge.sections || edge.sections.length === 0) return '';

        const s = edge.sections[0];

        let path = `M ${s.startPoint.x} ${s.startPoint.y}`;

        if (s.bendPoints) {

            s.bendPoints.forEach((p: any) => {

                path += ` L ${p.x} ${p.y}`;

            });

        }

        path += ` L ${s.endPoint.x} ${s.endPoint.y}`;

        return path;

    }

  

    function getEdgeCenter(edge: any) {

        if (!edge.sections || edge.sections.length === 0) return { x: 0, y: 0 };

        const s = edge.sections[0];

        

        // Simple midpoint of start/end of the section

        // For more complex paths (bends), we could approximate the middle segment

        // But start/end is usually "good enough" for straightish lines

        

        let start = s.startPoint;

        let end = s.endPoint;

        

        if (s.bendPoints && s.bendPoints.length > 0) {

            // If bends, pick the middle segment roughly

            const midIndex = Math.floor(s.bendPoints.length / 2);

            // If even points, use the middle point. If odd, mid segment.

            // Let's just use the bounding box center of the path for now? 

            // No, simple average of all points is safer to stay "near" the line

            // Actually, let's just take the middle bend point if available

            return {

                x: s.bendPoints[midIndex].x,

                y: s.bendPoints[midIndex].y

            };

        }

        

        return {

            x: (start.x + end.x) / 2,

            y: (start.y + end.y) / 2

        };

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

      class="graph-container"

      style="transform: translate({translateX}px, {translateY}px) scale({scale});"

    >

      {#if graph}

         <svg width={graph.width} height={graph.height} style="overflow: visible;">

            <defs>

               <!-- Adjusted refX to ensure tip touches the node (approx 10) -->

               <marker id="arrowhead" viewBox="0 0 10 7" markerWidth="10" markerHeight="7" 

               refX="10" refY="3.5" orient="auto">

                 <polygon points="0 0, 10 3.5, 0 7" fill="var(--diagram-marker-fill, #333)" />

               </marker>

            </defs>

            

            <!-- Recursively render children (Handling Components) -->

            {#each graph.children || [] as child}

               <g transform="translate({child.x}, {child.y})">

                   {#if child.children && child.children.length > 0}

                       <!-- It's a component container -->

                       <!-- Render Component Edges -->

                       {#each child.edges || [] as edge}

                          <path d={getEdgePath(edge)} stroke="var(--diagram-edge-stroke, #333)" stroke-width="var(--diagram-edge-stroke-width, 2)" fill="none" marker-end="url(#arrowhead)"/>

                          {#if edge.labels}

                              {#each edge.labels as label}

                                  <!-- Manual Position override: ELK label.x/y might be relative or wrong. 

                                       We calculate absolute center of edge section relative to this container -->

                                  {@const pos = getEdgeCenter(edge)}

                                  <!-- Center the label box on that point -->

                                  <g transform="translate({pos.x - label.width/2}, {pos.y - label.height/2})">

                                      <rect width={label.width} height={label.height} fill="var(--diagram-label-bg, #f0f0f0)" opacity="1" rx="2" ry="2"/>

                                      <text x={label.width / 2} y={label.height / 2} dominant-baseline="middle" text-anchor="middle" fill="var(--diagram-node-text, #000)" font-size="12" font-family="var(--diagram-font-family, sans-serif)">{label.text}</text>

                                  </g>

                              {/each}

                          {/if}

                       {/each}

                       

                       <!-- Render Component Nodes -->

                       {#each child.children as node}

                           <g transform="translate({node.x}, {node.y})">

                              <rect width={node.width} height={node.height} fill="var(--diagram-node-bg, #fff)" stroke="var(--diagram-node-stroke, #333)" rx="5" ry="5" stroke-width="var(--diagram-node-stroke-width, 1.5)"/>

                              <text x={node.width / 2} y={node.height / 2} dominant-baseline="middle" text-anchor="middle" fill="var(--diagram-node-text, #000)" font-size="14" font-family="var(--diagram-font-family, sans-serif)">{node.labels?.[0]?.text || node.id}</text>

                           </g>

                       {/each}

                   {:else}

                       <!-- It's a leaf node (fallback for flat graph) -->

                       <rect width={child.width} height={child.height} fill="var(--diagram-node-bg, #fff)" stroke="var(--diagram-node-stroke, #333)" rx="5" ry="5" stroke-width="var(--diagram-node-stroke-width, 1.5)"/>

                       <text x={child.width / 2} y={child.height / 2} dominant-baseline="middle" text-anchor="middle" fill="var(--diagram-node-text, #000)" font-size="14" font-family="var(--diagram-font-family, sans-serif)">{child.labels?.[0]?.text || child.id}</text>

                   {/if}

               </g>

            {/each}

            

            <!-- Render Root Edges (if any, for flat graph) -->

            {#each graph.edges || [] as edge}

               <path d={getEdgePath(edge)} stroke="var(--diagram-edge-stroke, #333)" stroke-width="var(--diagram-edge-stroke-width, 2)" fill="none" marker-end="url(#arrowhead)"/>

               {#if edge.labels}

                   {#each edge.labels as label}

                       {@const pos = getEdgeCenter(edge)}

                       <g transform="translate({pos.x - label.width/2}, {pos.y - label.height/2})">

                           <rect width={label.width} height={label.height} fill="var(--diagram-label-bg, #f0f0f0)" opacity="1" rx="2" ry="2"/>

                           <text x={label.width / 2} y={label.height / 2} dominant-baseline="middle" text-anchor="middle" fill="var(--diagram-node-text, #000)" font-size="12" font-family="var(--diagram-font-family, sans-serif)">{label.text}</text>

                       </g>

                   {/each}

               {/if}

            {/each}

         </svg>

       {/if}

    </div>
  
  <button class="fit-btn" on:click|stopPropagation={fitView} title="Fit to Screen">
    <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
      <path d="M8 3H5a2 2 0 0 0-2 2v3m18 0V5a2 2 0 0 0-2-2h-3m0 18h3a2 2 0 0 0 2-2v-3M3 16v3a2 2 0 0 0 2-2h3"></path>
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
    user-select: none;
  }

  .graph-container {
    position: absolute;
    top: 0;
    left: 0;
    transform-origin: 0 0;
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
