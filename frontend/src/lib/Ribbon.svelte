<script lang="ts">
  import { createEventDispatcher } from 'svelte';

  export let currentAppTheme: string;
  export let currentMermaidTheme: string;
  export let appThemes: string[];
  export let mermaidThemes: string[];
  export let autoRender = true;
  
  // ELK Integration
  export let layoutEngine = 'mermaid'; // 'mermaid' | 'elk'
  export let currentElkAlgorithm = 'layered';
  const elkAlgorithms = ['layered', 'stress', 'mrtree', 'radial', 'force', 'disco'];

  const dispatch = createEventDispatcher();

  function handleLoad() {
    dispatch('load');
  }

  function handleSave() {
    dispatch('save');
  }
  
  function handleExportMMD() {
      dispatch('exportMMD');
  }

  function handleExportSVG() {
      dispatch('exportSVG');
  }

  function handleExportPNG() {
      dispatch('exportPNG');
  }

  function render() {
    dispatch('render');
  }
  
  function handleAutoRenderChange() {
    dispatch('toggleAutoRender', autoRender);
  }

  function handleAppThemeChange() {
    dispatch('appThemeChange', currentAppTheme);
  }

  function handleMermaidThemeChange() {
    dispatch('mermaidThemeChange', currentMermaidTheme);
  }
  
  function handleLayoutEngineChange() {
      dispatch('layoutEngineChange', layoutEngine);
  }

  function handleElkAlgorithmChange() {
      dispatch('elkAlgorithmChange', currentElkAlgorithm);
  }
</script>

<div class="ribbon">
  <div class="ribbon-tabs">
    <div class="tab active">Home</div>
  </div>
  <div class="ribbon-content">
    
    <div class="ribbon-group">
      <div class="group-title">File</div>
      <div class="group-content">
        <div class="ribbon-btn" role="button" tabindex="0" on:click={handleLoad} on:keypress={(e) => e.key === 'Enter' && handleLoad()}>
          <span class="icon">📂</span>
          <span class="label">Load</span>
        </div>
        <div class="ribbon-btn" role="button" tabindex="0" on:click={handleSave} on:keypress={(e) => e.key === 'Enter' && handleSave()}>
          <span class="icon">💾</span>
          <span class="label">Save</span>
        </div>
      </div>
    </div>

    <div class="ribbon-separator"></div>
    
    <div class="ribbon-group">
      <div class="group-title">Export</div>
      <div class="group-content">
        <div class="ribbon-btn" role="button" tabindex="0" on:click={handleExportMMD} on:keypress={(e) => e.key === 'Enter' && handleExportMMD()}>
          <span class="icon">📄</span>
          <span class="label">MMD</span>
        </div>
        <div class="ribbon-btn" role="button" tabindex="0" on:click={handleExportSVG} on:keypress={(e) => e.key === 'Enter' && handleExportSVG()}>
          <span class="icon">🖼️</span>
          <span class="label">SVG</span>
        </div>
        <div class="ribbon-btn" role="button" tabindex="0" on:click={handleExportPNG} on:keypress={(e) => e.key === 'Enter' && handleExportPNG()}>
          <span class="icon">📷</span>
          <span class="label">PNG</span>
        </div>
      </div>
    </div>

    <div class="ribbon-separator"></div>

    <div class="ribbon-group">
      <div class="group-title">Diagram</div>
      <div class="group-content">
        <div class="ribbon-btn" role="button" tabindex="0" on:click={render} on:keypress={(e) => e.key === 'Enter' && render()}>
          <span class="icon">🔄</span>
          <span class="label">Render</span>
        </div>
        
        <div class="control-box" style="margin-left: 10px;">
          <label for="engine-select">Engine</label>
          <select id="engine-select" bind:value={layoutEngine} on:change={handleLayoutEngineChange}>
            <option value="mermaid">Mermaid</option>
            <option value="elk">ELK (Exp)</option>
          </select>
        </div>
        
        {#if layoutEngine === 'elk'}
            <div class="control-box" style="margin-left: 10px;">
              <label for="elk-algo-select">Algorithm</label>
              <select id="elk-algo-select" bind:value={currentElkAlgorithm} on:change={handleElkAlgorithmChange}>
                {#each elkAlgorithms as algo}
                  <option value={algo}>{algo}</option>
                {/each}
              </select>
            </div>
        {/if}

        <div class="control-box" style="margin-left: 10px; justify-content: center;">
             <label style="display: flex; align-items: center; cursor: pointer;">
                <input type="checkbox" bind:checked={autoRender} on:change={handleAutoRenderChange} style="margin-right: 5px;">
                Auto-Sync
             </label>
        </div>
      </div>
    </div>

    <div class="ribbon-separator"></div>

    <div class="ribbon-group">
      <div class="group-title">Appearance</div>
      <div class="group-content">
        <div class="control-box">
          <label for="app-theme-select">App Mode</label>
          <select id="app-theme-select" bind:value={currentAppTheme} on:change={handleAppThemeChange}>
            {#each appThemes as theme}
              <option value={theme}>{theme}</option>
            {/each}
          </select>
        </div>
        <div class="control-box" style="margin-left: 10px;">
          <label for="mermaid-theme-select">Diagram Theme</label>
          <select id="mermaid-theme-select" bind:value={currentMermaidTheme} on:change={handleMermaidThemeChange}>
            {#each mermaidThemes as theme}
              <option value={theme}>{theme}</option>
            {/each}
          </select>
        </div>
      </div>
    </div>

  </div>
</div>

<style>
  /* Ribbon Styles */
  .ribbon {
    background-color: var(--bg-ribbon);
    border-bottom: 1px solid var(--border-color);
    display: flex;
    flex-direction: column;
    flex-shrink: 0;
  }

  .ribbon-tabs {
    display: flex;
    background-color: var(--bg-ribbon-tabs);
    padding-top: 5px;
    padding-left: 10px;
    border-bottom: 1px solid var(--border-separator);
  }

  .tab {
    padding: 5px 15px;
    cursor: pointer;
    font-size: 13px;
    color: var(--text-tab);
    border: 1px solid transparent;
    border-bottom: none;
    margin-right: 2px;
    /* Make unselectable */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  .tab.active {
    background-color: var(--bg-ribbon-content);
    border-color: var(--border-color);
    border-bottom-color: var(--bg-ribbon-content);
    color: var(--text-tab-active);
    font-weight: 500;
    position: relative;
    top: 1px;
  }

  .ribbon-content {
    background-color: var(--bg-ribbon-content);
    padding: 10px;
    display: flex;
    align-items: stretch;
    height: 90px;
    box-sizing: border-box;
    transition: background-color 0.3s;
  }

  .ribbon-group {
    display: flex;
    flex-direction: column;
    padding: 0 10px;
    align-items: center;
    justify-content: space-between;
  }

  .group-title {
    font-size: 11px;
    color: var(--text-group-title);
    margin-top: auto;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    padding-top: 4px;
    /* Make unselectable */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  .group-content {
    display: flex;
    align-items: center;
    flex: 1;
  }

  .ribbon-btn {
    display: flex;
    flex-direction: column;
    align-items: center;
    justify-content: center;
    
    background-color: transparent;
    border: 1px solid transparent;
    padding: 5px 10px;
    cursor: pointer;
    border-radius: 3px;
    color: var(--text-main);
    min-width: 50px;
    
    margin: 0;
    font-family: inherit;
    line-height: normal;
    outline: none;
    user-select: none; /* Already here for button div, kept */
  }

  .ribbon-btn:hover {
    background-color: var(--btn-hover);
    border-color: var(--btn-border-hover);
  }

  .ribbon-btn:active {
    background-color: var(--btn-active);
    border-color: var(--btn-active);
  }

  .ribbon-btn .icon {
    font-size: 20px;
    margin-bottom: 4px;
    /* Make unselectable */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  .ribbon-btn .label {
    font-size: 12px;
    /* Make unselectable */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  .ribbon-separator {
    width: 1px;
    background-color: var(--border-separator);
    margin: 5px 0;
  }

  .control-box {
    display: flex;
    flex-direction: column;
    align-items: flex-start;
  }

  .control-box label {
    font-size: 12px;
    margin-bottom: 2px;
    color: var(--text-label);
    /* Make unselectable */
    -webkit-user-select: none;
    -moz-user-select: none;
    -ms-user-select: none;
    user-select: none;
  }

  .control-box select {
    padding: 4px 24px 4px 8px; /* Extra padding for custom arrow */
    font-size: 13px;
    border: 1px solid var(--input-border);
    border-radius: 2px;
    background-color: var(--input-bg);
    color: var(--text-main);
    
    /* Remove native styling */
    appearance: none;
    -webkit-appearance: none;
    -moz-appearance: none;
    
    /* Custom Arrow */
    background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23555' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
    background-repeat: no-repeat;
    background-position: right 4px center;
    background-size: 16px;
    cursor: pointer;
  }
  
  :global(.dark-theme) .control-box select {
      /* Lighter arrow for dark mode */
      background-image: url("data:image/svg+xml;charset=UTF-8,%3csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 24 24' fill='none' stroke='%23ccc' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'%3e%3cpolyline points='6 9 12 15 18 9'%3e%3c/polyline%3e%3c/svg%3e");
  }

  .control-box select:hover {
    border-color: var(--text-label);
  }
  
  .control-box select:focus {
    outline: none;
    border-color: var(--text-tab-active);
  }
</style>
