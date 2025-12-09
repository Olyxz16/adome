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
let lastThemeName = '';

export function initMermaid() {
  if (isInitialized) return;
  
  //mermaid.registerLayoutLoaders(elkLayouts);
  mermaid.initialize({
    startOnLoad: false,
    // securityLevel: 'loose', // Removed to simplify
    theme: 'base',
    flowchart: { 
        htmlLabels: false, // Changed to false for simpler rendering
        curve: 'basis' 
    },
    // Prevent layout drift
    suppressErrorRendering: true 
  });
  isInitialized = true;
}

export async function renderMermaid(id: string, code: string, theme: GraphTheme, elkAlgorithm: string = ''): Promise<string> {
    if (!isInitialized) {
        initMermaid();
    }
    
     // Temporarily bypass theme configuration to rule it out as a cause of freeze
     // if (lastThemeName !== theme.name + theme.isDark) { // This block was commented out in previous steps
     //    const themeVariables = getMermaidThemeVariables(theme);
     //    mermaid.mermaidAPI.setConfig({
     //        theme: 'base',
     //        themeVariables: themeVariables
     //    });
     //    lastThemeName = theme.name + theme.isDark;
     // }

    const useElk = !!elkAlgorithm;
    let graphDefinition = code;

    // Inject ELK Frontmatter logic
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
    }
}
