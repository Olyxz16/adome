<script lang="ts">
  import { createEventDispatcher, onMount, tick } from 'svelte';
  import { compileD2 } from '../../lib/stores/editor';
  import { isDarkMode } from '../../lib/stores/theme';

  export let code: string;
  
  let container: HTMLElement;
  let error = '';
  const dispatch = createEventDispatcher();

  $: if (container && code !== undefined && $isDarkMode !== undefined) {
      render();
  }

  async function render() {
      if (!container) return;
      if (!code) return;
      try {
          const themeID = $isDarkMode ? 200 : 0;
          const svg = await compileD2(code, themeID);
          
          if (container && svg) {
              // Strip XML declaration
              const cleanSvg = svg.replace(/<\?xml.*?\?>/g, '');
              container.innerHTML = cleanSvg;
              
              // Check for nested SVG and unwrap
              const outerSvg = container.querySelector('svg');
              if (outerSvg) {
                  const innerSvg = outerSvg.querySelector('svg');
                  if (innerSvg) {
                      console.log("D2Canvas: Nested SVG detected. Unwrapping...");
                      // Move inner SVG to container
                      container.innerHTML = innerSvg.outerHTML;
                  }
              }
              
              await tick(); // Wait for DOM update
              
              // Update debug info
              const rect = container.getBoundingClientRect();
              debugInfo = `
                  SVG Len: ${svg.length}
                  Clean SVG Len: ${cleanSvg.length}
                  Container: ${Math.round(rect.width)}x${Math.round(rect.height)}
                  Child Nodes: ${container.childNodes.length}
                  First Child: ${container.firstElementChild?.tagName}
                  Inner HTML Len: ${container.innerHTML.length}
              `.trim();
          }
          error = '';
          dispatch('rendered', { svg });
      } catch (e: any) {
          error = e.message || 'Error rendering D2';
          dispatch('error', e);
      }
  }
</script>

<div class="canvas-root" bind:this={container}></div>
{#if error}
  <div class="error-overlay">{error}</div>
{/if}

<style>
    .canvas-root {
        display: flex;
        justify-content: center;
        align-items: center;
        width: 100%;
        height: 100%;
        min-width: 0;
        min-height: 0;
        overflow: auto;
    }
    .canvas-root :global(svg) {
        display: block;
        max-width: 100%;
        height: auto;
    }
    .error-overlay {
        position: fixed;
        top: 10px;
        left: 10px;
        background: rgba(255, 200, 200, 0.9);
        color: #d8000c;
        border: 1px solid #d8000c;
        padding: 5px 10px;
        border-radius: 4px;
        pointer-events: none;
    }
</style>
