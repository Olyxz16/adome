<script lang="ts">
  import { createEventDispatcher, tick } from 'svelte';
  import { renderMermaid } from '../../lib/services/mermaid';
  import type { GraphTheme } from '../../lib/stores/theme';

  export let code: string;
  export let theme: GraphTheme;
  export let layout: string = '';
  
  let container: HTMLElement;
  let error = '';
  const dispatch = createEventDispatcher();

  // Trigger render on prop changes
  // Note: We intentionally DO NOT include 'container' here to avoid infinite loops.
  // The 'init' action handles the initial render when the DOM is ready.
  $: if (code && theme && layout !== undefined) {
      render();
  }

  // Action to run when element is created/mounted
  function init(node: HTMLElement) {
      // Ensure container is set (though bind:this does this too)
      container = node; 
      render();
  }

  async function render() {
      if (!container || !code) return;
      // console.log('[MermaidCanvas] Initiating Mermaid render...');
      try {
          const id = 'mermaid-' + Math.random().toString(36).substr(2, 9);
          const svg = await renderMermaid(id, code, theme, layout);
          if (container) container.innerHTML = svg;
          error = '';
          dispatch('rendered', { svg });
      } catch (e: any) {
          console.error(e);
          error = e.message || 'Error rendering Mermaid';
          dispatch('error', e);
      }
  }
</script>

<div class="canvas-root" bind:this={container} use:init></div>
{#if error}
  <div class="error-overlay">{error}</div>
{/if}

<style>
    .canvas-root {
        display: inline-block; /* Helps with width calculation */
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