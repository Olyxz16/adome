<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { SaveMermaid, LoadMermaid, ExportSVG, ExportPNG, IsDarkTheme } from '../wailsjs/go/main/App.js';
  import Ribbon from './lib/Ribbon.svelte';
  import Editor from './lib/Editor.svelte';
  import Preview from './lib/Preview.svelte';

  let input = `graph TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
  `;
  
  let previewComponent: Preview;
  
  // Mermaid Themes
  const mermaidThemes = ['auto', 'default', 'neutral', 'dark', 'forest', 'base'];
  let currentMermaidTheme = 'auto';

  // App Themes
  const appThemes = ['light', 'dark', 'system'];
  let currentAppTheme = 'system';
  let isDarkMode = false; // Resolved state

  let mediaQueryList;

  onMount(() => {
    // specific listeners for system theme changes
    mediaQueryList = window.matchMedia('(prefers-color-scheme: dark)');
    mediaQueryList.addEventListener('change', handleSystemThemeChange);

    resolveTheme().then(() => {
        triggerRender();
    });
  });

  onDestroy(() => {
    if (mediaQueryList) {
      mediaQueryList.removeEventListener('change', handleSystemThemeChange);
    }
  });

  function handleSystemThemeChange(e) {
    if (currentAppTheme === 'system') {
      resolveTheme().then(() => triggerRender());
    }
  }

  async function resolveTheme() {
    if (currentAppTheme === 'system') {
      let matches = window.matchMedia('(prefers-color-scheme: dark)').matches;
      if (!matches) {
          try {
              matches = await IsDarkTheme();
          } catch (e) {
              console.error("Failed to check system theme:", e);
          }
      }
      isDarkMode = matches;
    } else {
      isDarkMode = currentAppTheme === 'dark';
    }
    updateBodyClass();
  }

  function updateBodyClass() {
    if (isDarkMode) {
      document.body.classList.add('dark-theme');
    } else {
      document.body.classList.remove('dark-theme');
    }
  }

  function handleAppThemeChange(event) {
    currentAppTheme = event.detail;
    resolveTheme().then(() => triggerRender());
  }

  function handleMermaidThemeChange(event) {
    currentMermaidTheme = event.detail;
    triggerRender();
  }

  function getEffectiveMermaidTheme() {
      if (currentMermaidTheme === 'auto') {
          return isDarkMode ? 'dark' : 'default';
      }
      return currentMermaidTheme;
  }

  function triggerRender() {
    if (previewComponent) {
      previewComponent.render(input, getEffectiveMermaidTheme());
    }
  }

  // Auto-render when input changes
  let timer;
  function handleInputChange(event) {
    input = event.detail; // Sync value from Editor
    clearTimeout(timer);
    timer = setTimeout(triggerRender, 500);
  }

  async function handleSave() {
    try {
      const msg = await SaveMermaid(input);
      console.log(msg);
    } catch (e) {
      console.error(e);
    }
  }

  async function handleExportMMD() {
      await handleSave();
  }

  async function handleExportSVG() {
      if (!previewComponent) return;
      try {
          const content = previewComponent.getSVG();
          if (!content) {
              console.error("No SVG content to export");
              return;
          }
          const msg = await ExportSVG(content);
          console.log(msg);
      } catch (e) {
          console.error(e);
      }
  }

  async function handleExportPNG() {
      if (!previewComponent) return;
      try {
          const base64 = await previewComponent.getPNG();
          const msg = await ExportPNG(base64);
          console.log(msg);
      } catch (e) {
          console.error(e);
      }
  }

  async function handleLoad() {
    try {
      const content = await LoadMermaid();
      if (content) {
        input = content;
        triggerRender();
      }
    } catch (e) {
      console.error(e);
    }
  }
</script>

<main>
  <Ribbon 
    {currentAppTheme}
    {currentMermaidTheme}
    {appThemes}
    {mermaidThemes}
    on:load={handleLoad}
    on:save={handleSave}
    on:exportMMD={handleExportMMD}
    on:exportSVG={handleExportSVG}
    on:exportPNG={handleExportPNG}
    on:render={triggerRender}
    on:appThemeChange={handleAppThemeChange}
    on:mermaidThemeChange={handleMermaidThemeChange}
  />
  
  <div class="workspace">
    <Editor 
      value={input} 
      on:input={handleInputChange} 
    />
    <Preview bind:this={previewComponent} />
  </div>
</main>

<style>
  /* Workspace Styles - layout only */
  main {
    display: flex;
    flex-direction: column;
    flex: 1;
    width: 100%;
    height: 100%;
    overflow: hidden;
    background-color: var(--bg-app);
  }

  .workspace {
    display: flex;
    flex: 1;
    overflow: hidden;
    height: 100%; /* Ensure it fills parent */
    
    /* Prevent selection in layout gaps */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }
</style>
