<script lang="ts">
  import { editorContent, triggerRender } from '../../lib/stores/editor';

  function handleKeydown(e: KeyboardEvent) {
    if (e.shiftKey && e.key === 'Enter') {
      e.preventDefault();
      triggerRender.update(n => n + 1);
    }
  }
</script>

<div class="editor-pane">
  <textarea 
    bind:value={$editorContent} 
    on:keydown={handleKeydown} 
    placeholder="Enter Mermaid or D2 code here..."
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