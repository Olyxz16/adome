<script lang="ts">
  import { createEventDispatcher } from 'svelte';
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
      if (!container) {
          console.warn("D2Canvas: Container not ready");
          return;
      }
      if (!code) {
          console.warn("D2Canvas: No code to render");
          return;
      }
      try {
          // 0 = Default Light, 200 = Dark Mode
          const themeID = $isDarkMode ? 200 : 0;
          console.log(`D2Canvas: Requesting compile. ThemeID: ${themeID}, Code length: ${code.length}`);
          
          const svg = await compileD2(code, themeID);
          
          console.log(`D2Canvas: Received SVG. Length: ${svg?.length}`);
          
          if (container) {
              container.innerHTML = svg;
              console.log("D2Canvas: Updated container.innerHTML");
          }
          error = '';
          dispatch('rendered', { svg });
      } catch (e: any) {
          console.error("D2Canvas: Render Error:", e);
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
        min-width: 100px;
        min-height: 100px;
    }
    /* Force SVG to display correctly */
    .canvas-root :global(svg) {
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
