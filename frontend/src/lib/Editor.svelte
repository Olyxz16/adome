<script lang="ts">
  import { createEventDispatcher } from 'svelte';

  export let value: string;

  const dispatch = createEventDispatcher();

  function handleInput(e) {
    dispatch('input', e);
  }
</script>

<div class="editor-pane">
  <textarea 
    bind:value={value} 
    on:input={handleInput} 
    placeholder="Enter Mermaid code here..."
    spellcheck="false"
  ></textarea>
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
    
    /* Prevent selecting the container itself */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  textarea {
    flex: 1;
    resize: none;
    padding: 1rem;
    font-family: 'Consolas', 'Monaco', monospace;
    font-size: 14px;
    border: none;
    outline: none;
    line-height: 1.5;
    color: var(--text-main);
    background-color: var(--bg-editor);
    transition: background-color 0.3s, color 0.3s;
    
    /* Allow text selection inside */
    -webkit-user-select: text;
    -moz-user-select: text;
    -ms-user-select: text;
    user-select: text;
  }

  textarea:focus {
    background-color: var(--bg-ribbon-content);
  }
</style>
