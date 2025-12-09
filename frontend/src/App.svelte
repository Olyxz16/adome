<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import Ribbon from './components/Ribbon/Ribbon.svelte';
  import Editor from './components/Editor/Editor.svelte';
  import Preview from './components/Preview/Preview.svelte';
  import { initTheme, destroyTheme } from './lib/stores/theme';
  import { initMermaid } from './lib/services/mermaid';

  onMount(() => {
      initTheme();
      initMermaid();
  });

  onDestroy(() => {
      destroyTheme();
  });
</script>

<main>
  <Ribbon />
  <div class="workspace">
    <Editor />
    <Preview />
  </div>
</main>

<style>
  main {
    display: flex;
    flex-direction: column;
    flex: 1;
    width: 100%;
    height: 100vh;
    overflow: hidden;
    background-color: var(--bg-app);
  }

  .workspace {
    display: flex;
    flex: 1;
    overflow: hidden;
  }
</style>
