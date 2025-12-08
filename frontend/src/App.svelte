<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { get } from 'svelte/store';
  import { SaveMermaid, LoadMermaid, ExportSVG, ExportPNG, IsDarkTheme } from '../wailsjs/go/main/App.js';
  import { currentTheme, applyTheme, defaultLightTheme, defaultDarkTheme } from './lib/theme-store';
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
  
  // Mermaid Themes (Deprecated in favor of Unified Theme, keeping for Ribbon compat)
  const mermaidThemes = ['auto', 'default', 'neutral', 'dark', 'forest', 'base'];
  let currentMermaidTheme = 'auto';

  // ELK Settings
  let layoutEngine = 'mermaid'; // 'mermaid' | 'elk'
  let currentElkAlgorithm = 'layered';

  // App Themes
  const appThemes = ['light', 'dark', 'system'];
  let currentAppTheme = 'system';
  let isDarkMode = false; // Resolved state
  
  // Auto Render
  let autoRender = true;

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
    
    // Unified Theme Logic
    const newTheme = isDarkMode ? defaultDarkTheme : defaultLightTheme;
    currentTheme.set(newTheme);
    applyTheme(newTheme);
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
    // We ignore specific mermaid theme changes for now as we enforce the unified theme
    // But we trigger render to ensure state consistency
    if (layoutEngine === 'mermaid') triggerRender();
  }
  
  function handleLayoutEngineChange(event) {
      layoutEngine = event.detail;
      // Wait for component switch then render
      setTimeout(triggerRender, 0);
  }

  function handleElkAlgorithmChange(event) {
      currentElkAlgorithm = event.detail;
      if (layoutEngine === 'elk') triggerRender();
  }

  function triggerRender() {
    if (previewComponent) {
      const useElk = layoutEngine === 'elk';
      // Pass the full theme object and the ELK flag
      previewComponent.render(input, get(currentTheme), useElk);
    }
  }

  // Auto-render when input changes
  let timer;
  function handleInputChange(event) {
    input = event.detail; // Sync value from Editor
    clearTimeout(timer);
    if (autoRender) {
        timer = setTimeout(triggerRender, 200);
    }
  }
  
  function handleToggleAutoRender(event) {
      autoRender = event.detail;
      if (autoRender) {
          triggerRender();
      }
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
      try {
          let content = '';
          if (previewComponent) {
               content = previewComponent.getSVG();
          }
          
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
      try {
          let base64 = '';
          if (previewComponent) {
               base64 = await previewComponent.getPNG();
          }

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
    {autoRender}
    {layoutEngine}
    {currentElkAlgorithm}
    on:load={handleLoad}
    on:save={handleSave}
    on:exportMMD={handleExportMMD}
    on:exportSVG={handleExportSVG}
    on:exportPNG={handleExportPNG}
    on:render={triggerRender}
    on:toggleAutoRender={handleToggleAutoRender}
    on:appThemeChange={handleAppThemeChange}
    on:mermaidThemeChange={handleMermaidThemeChange}
    on:layoutEngineChange={handleLayoutEngineChange}
    on:elkAlgorithmChange={handleElkAlgorithmChange}
  />
  
  <div class="workspace">
    <Editor 
      value={input} 
      on:input={handleInputChange}
      on:refresh={triggerRender} 
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
