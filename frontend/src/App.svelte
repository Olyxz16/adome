<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import Ribbon from './components/Ribbon/Ribbon.svelte';
  import Editor from './components/Editor/Editor.svelte';
  import Preview from './components/Preview/Preview.svelte';
  import { initTheme, destroyTheme } from './lib/stores/theme';
  import { initMermaid } from './lib/services/mermaid';
  import { GetStartupFilePath, LoadFileByPath } from './lib/services/bridge'; // Import GetStartupFilePath and LoadFileByPath
  import { renderingEngine, contentStores, triggerRender } from './lib/stores/editor'; // Import renderingEngine, contentStores, and triggerRender from editor store
  import { get } from 'svelte/store'; // Import get to read store value

  onMount(async () => {
      initTheme();
      initMermaid();

      // Check for startup file path
      const startupFilePath = await GetStartupFilePath();
      if (startupFilePath) {
          console.log('Loading startup file:', startupFilePath);
          // Determine engine based on file extension
          const fileExtension = startupFilePath.split('.').pop()?.toLowerCase();
          if (fileExtension === 'mmd' || fileExtension === 'mermaid') {
              renderingEngine.set('mermaid');
          } else if (fileExtension === 'd2') {
              renderingEngine.set('d2');
          } else {
              console.warn("Unknown file extension for startup file:", startupFilePath);
              return; // Don't try to load if extension is unknown
          }
          // Load the file content using LoadFileByPath
          try {
              const content = await LoadFileByPath(startupFilePath);
              // Manually set the store and trigger render
              const currentEngine = get(renderingEngine);
              const store = contentStores[currentEngine];
              if (store) {
                  store.set(content);
                  triggerRender.update(n => n + 1);
              } else {
                  console.error(`No content store found for engine: ${currentEngine}`);
              }
          } catch (e) {
              console.error("Failed to load startup file:", e);
          }
      }
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
