import mermaid from 'mermaid';
import elkLayouts from '@mermaid-js/layout-elk';
import { type GraphTheme, getMermaidThemeVariables } from '../stores/theme';

// Declare global Wails logging bridge
declare global {
  interface Window {
    go: {
      main: {
        App: {
          Log(message: string): void;
          LogError(message: string): void; // Assuming a dedicated error logging function exists
        };
      };
    };
  }
}

let isInitialized = false;
let lastThemeName = ''; // Should capture name + isDark

export function initMermaid() {
  if (isInitialized) return;
  
  mermaid.registerLayoutLoaders(elkLayouts);
  mermaid.initialize({
    startOnLoad: false,
    securityLevel: 'strict', // <-- Corrected: simplified/hardened
    theme: 'base',
    flowchart: { 
        htmlLabels: false, // <-- Corrected: simplified
        curve: 'basis' 
    },
    suppressErrorRendering: true 
  });
  isInitialized = true;
}

export async function renderMermaid(id: string, code: string, theme: GraphTheme, elkAlgorithm: string = ''): Promise<string> {
    if (!isInitialized) {
        initMermaid();
    }
    
    // Theme Configuration Logic - Corrected to use name + isDark and include reset
    if (lastThemeName !== theme.name + theme.isDark) { 
        const themeVariables = getMermaidThemeVariables(theme);
        mermaid.initialize({
            theme: 'base',
            themeVariables: themeVariables
        });
        lastThemeName = theme.name + theme.isDark; // <-- Corrected: full theme string
    }

    const useElk = !!elkAlgorithm;
    let graphDefinition = code;

    // Inject ELK Frontmatter logic (this section should be stable)
    if (useElk) {
        let layoutName = 'elk';
        let elkOptions = '';
        const layoutOpts = theme.layoutOptions;
        
        if (elkAlgorithm && elkAlgorithm !== 'layered') {
            layoutName = `elk.${elkAlgorithm}`;
        }

        if (elkAlgorithm === 'stress' || elkAlgorithm === 'force') {
            elkOptions = `
  org.eclipse.elk.force.repulsivePower: ${layoutOpts.repulsivePower}
  org.eclipse.elk.stress.desiredEdgeLength: ${layoutOpts.desiredEdgeLength}`;
        } else if (elkAlgorithm === 'layered') {
            elkOptions = `
  org.eclipse.elk.spacing.nodeNode: ${layoutOpts.nodeNodeSpacing}
  org.eclipse.elk.layered.spacing.nodeNodeBetweenLayers: ${layoutOpts.nodeNodeBetweenLayersSpacing}
  org.eclipse.elk.layered.spacing.baseValue: ${layoutOpts.baseValueSpacing}`;
        }

        if (!graphDefinition.match(/layout:\s*elk/)) {
            const frontmatter = `---\nconfig:
  layout: ${layoutName}
  elk: ${elkOptions}
---\n`;
            graphDefinition = frontmatter + graphDefinition;
        }
    }

    try {
        const { svg } = await mermaid.render(id, graphDefinition);
        return svg;
    } catch (error: any) {
        console.error("Mermaid render warning:", error);
        // Attempt to log to Wails backend - Corrected to throw error
        if (window.go && window.go.main && window.go.main.App) {
            const errorMessage = `[Mermaid Renderer Error] ${error.message || error.toString()}`;
            if (window.go.main.App.LogError) {
                window.go.main.App.LogError(errorMessage);
            } else if (window.go.main.App.Log) {
                window.go.main.App.Log(errorMessage);
            }
        }
        throw error; // <-- Corrected: Re-throw error after logging
    }
}