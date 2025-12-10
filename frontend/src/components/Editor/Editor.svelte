<script lang="ts">
  import { contentStores, renderingEngine, triggerRender } from '../../lib/stores/editor';

  // Reactively select the store based on the engine
  $: activeStore = contentStores[$renderingEngine];

  function handleKeydown(e: KeyboardEvent) {
    if (e.shiftKey && e.key === 'Enter') {
      e.preventDefault();
      triggerRender.update(n => n + 1);
    }
  }
</script>

<div class="editor-pane">
  {#if activeStore}
    <textarea 
      bind:value={$activeStore} 
      on:keydown={handleKeydown} 
      placeholder={`Enter ${$renderingEngine} code here...`}
      spellcheck="false"
    ></textarea>
  {:else}
    <div class="error-msg">Unknown engine: {$renderingEngine}</div>
  {/if}
</div>

<style>
  .editor-pane {
    flex: 1;
    display: flex;
    flex-direction: column;
    padding: 0;
    overflow: hidden;
    border-right: 1px solid var(--border-color);
    background-color: var(--bg-editor);
  }

  textarea {
    flex: 1;
    resize: none;
    padding: 1rem;
    font-family: 'Fira Code', 'Consolas', 'Monaco', monospace;
    font-size: 14px;
    border: none;
    outline: none;
    line-height: 1.5;
    color: var(--text-main);
    background-color: transparent;
    transition: color 0.3s;
  }
</style>