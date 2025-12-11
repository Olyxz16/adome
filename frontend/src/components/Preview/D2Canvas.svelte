<script lang="ts">
  import { createEventDispatcher, onMount, tick } from 'svelte';
  import { compileD2 } from '../../lib/stores/editor';
  import { isDarkMode } from '../../lib/stores/theme';

  export let code: string;
  
  let container: HTMLElement;
  let error = ''; // Kept for internal logging/dispatch, but not displayed
  let debugInfo = ''; 
  const dispatch = createEventDispatcher();

  // Trigger render on prop changes (code, isDarkMode)
  // Intentionally excluded 'container' to avoid loops.
  $: if (code !== undefined && $isDarkMode !== undefined) {
      render();
  }

  function init(node: HTMLElement) {
      container = node;
      render();
  }

  async function render() {
      if (!container) return;
      console.log('[D2Canvas] Initiating D2 render...');
      error = ''; // For internal logging/dispatch

      if (!code) { // Handle empty code specifically
          container.innerHTML = ''; // Clear previous SVG if code is empty
          return; // Do nothing else
      }

      try {
          const themeID = $isDarkMode ? 200 : 0;
          const svg = await compileD2(code, themeID); // This will return SVG on success
          
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
          } else {
            // If compileD2 succeeded but returned empty SVG, or container is null
            container.innerHTML = ''; // Clear content
          }
          error = ''; // Clear error on success
          dispatch('rendered', { svg });
      } catch (e: any) {
          error = e.message || 'Error rendering D2';
          dispatch('error', e);
          container.innerHTML = ''; // Clear content on error
      } finally {
          // No loading state to manage
      }
  }
</script>

<div class="canvas-root" bind:this={container} use:init></div>

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
    /* Removed error-overlay styling and usage from template */
    /* Removed loading-overlay styling and usage from template */
</style>
