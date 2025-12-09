<script lang="ts">
  import { createEventDispatcher } from 'svelte';
  import { compileD2 } from '../../lib/stores/editor';

  export let code: string;
  
  let container: HTMLElement;
  let error = '';
  const dispatch = createEventDispatcher();

  $: if (container && code) {
      render();
  }

  async function render() {
      if (!container || !code) return;
      try {
          const svg = await compileD2(code);
          if (container) container.innerHTML = svg;
          error = '';
          dispatch('rendered', { svg });
      } catch (e: any) {
          console.error(e);
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
        display: inline-block;
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
