import { writable } from 'svelte/store';

export interface GraphTheme {
    name: string;
    isDark: boolean;
    // Core Colors
    background: string;
    nodeBackground: string;
    nodeBorder: string;
    nodeText: string;
    edgeColor: string;
    markerColor: string;
    labelBackground: string;
    
    // Typography
    fontFamily: string;
    
    // Dimensions
    nodeBorderWidth: string;
    edgeWidth: string;
    nodeRx: string;
}

export interface GraphLayoutOptions {
    nodeNodeSpacing: number;
    nodeNodeBetweenLayersSpacing: number;
    repulsivePower: number; // for force-directed algorithms
    desiredEdgeLength: number; // for stress algorithm
    baseValueSpacing: number; // general spacing
}

export const defaultLightTheme: GraphTheme = {
    name: 'light',
    isDark: false,
    background: '#ffffff',
    nodeBackground: '#eaeaea',
    nodeBorder: '#333333',
    nodeText: '#333333',
    edgeColor: '#333333',
    markerColor: '#333333',
    labelBackground: '#f9f9f9',
    fontFamily: '"Nunito", sans-serif',
    nodeBorderWidth: '1px',
    edgeWidth: '1.5px',
    nodeRx: '0px',
    layoutOptions: {
        nodeNodeSpacing: 80,
        nodeNodeBetweenLayersSpacing: 60,
        repulsivePower: 5,
        desiredEdgeLength: 450,
        baseValueSpacing: 40
    }
};

export const defaultDarkTheme: GraphTheme = {
    name: 'dark',
    isDark: true,
    background: '#252526',
    nodeBackground: '#333333',
    nodeBorder: '#eaeaea',
    nodeText: '#eaeaea',
    edgeColor: '#eaeaea',
    markerColor: '#eaeaea',
    labelBackground: '#383838',
    fontFamily: '"Nunito", sans-serif',
    nodeBorderWidth: '1px',
    edgeWidth: '1.5px',
    nodeRx: '0px',
    layoutOptions: {
        nodeNodeSpacing: 80,
        nodeNodeBetweenLayersSpacing: 60,
        repulsivePower: 5,
        desiredEdgeLength: 450,
        baseValueSpacing: 40
    }
};

export const currentTheme = writable<GraphTheme>(defaultLightTheme);

export function applyTheme(theme: GraphTheme) {
    const root = document.documentElement;
    
    // Update CSS Variables for ELK and UI
    root.style.setProperty('--diagram-bg', theme.background);
    root.style.setProperty('--diagram-node-bg', theme.nodeBackground);
    root.style.setProperty('--diagram-node-stroke', theme.nodeBorder);
    root.style.setProperty('--diagram-node-text', theme.nodeText);
    root.style.setProperty('--diagram-edge-stroke', theme.edgeColor);
    root.style.setProperty('--diagram-marker-fill', theme.markerColor);
    root.style.setProperty('--diagram-label-bg', theme.labelBackground);
    root.style.setProperty('--diagram-font-family', theme.fontFamily);
    root.style.setProperty('--diagram-node-stroke-width', theme.nodeBorderWidth);
    root.style.setProperty('--diagram-edge-stroke-width', theme.edgeWidth);
    root.style.setProperty('--diagram-node-rx', theme.nodeRx);
}

// Helper to convert our theme to Mermaid theme variables
export function getMermaidThemeVariables(theme: GraphTheme) {
    return {
        // Base
        darkMode: theme.isDark,
        background: theme.background,
        fontFamily: theme.fontFamily,
        
        // Nodes
        primaryColor: theme.nodeBackground,
        primaryBorderColor: theme.nodeBorder,
        primaryTextColor: theme.nodeText,
        
        // Edges
        lineColor: theme.edgeColor,
        textColor: theme.nodeText,
        
        // Flowchart specific (Mermaid uses specific keys for different diagram types, we try to cover them)
        mainBkg: theme.nodeBackground,
        nodeBorder: theme.nodeBorder,
        clusterBkg: theme.background,
        clusterBorder: theme.nodeBorder,
        defaultLinkColor: theme.edgeColor,
        edgeLabelBackground: theme.labelBackground,
        
        // Arrows
        arrowheadColor: theme.markerColor,
    };
}
