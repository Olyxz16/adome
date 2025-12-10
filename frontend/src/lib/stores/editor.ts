import { writable, get, type Writable } from 'svelte/store';
import { LoadFile, SaveFile, CompileD2 } from '../services/bridge';
import { currentTheme } from './theme'; // Import currentTheme

const DEFAULT_MERMAID = `graph TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
`;

const DEFAULT_D2 = `direction: right
A -> B: Hello World
`;

// Registry of content stores for each engine
export const contentStores: Record<string, Writable<string>> = {
    mermaid: writable<string>(DEFAULT_MERMAID),
    d2: writable<string>(DEFAULT_D2)
};

// 'mermaid' | 'd2'
export const renderingEngine = writable<string>('mermaid');

// 'default' | 'elk' (only for mermaid)
export const layoutEngine = writable<string>('default');

// 'layered' | 'stress' | 'force' ...
export const elkAlgorithm = writable<string>('layered');

export const autoRender = writable<boolean>(true);
export const isDirty = writable<boolean>(false);

// Signal to trigger a render manually or from auto-render logic
export const triggerRender = writable<number>(0);

// Command bus for actions that need component access (like Export PNG which needs DOM)
export type CommandType = 'export-svg' | 'export-png' | 'none';
export const editorCommand = writable<{ type: CommandType; timestamp: number }>({ type: 'none', timestamp: 0 });

export async function loadFile() {
    try {
        const content = await LoadFile();
        if (content) {
            const engine = get(renderingEngine);
            const store = contentStores[engine];
            if (store) {
                store.set(content);
                // Trigger a render after load
                triggerRender.update(n => n + 1);
            } else {
                console.error(`No content store found for engine: ${engine}`);
            }
        }
    } catch (e) {
        console.error("Failed to load file:", e);
    }
}

export async function saveFile() {
    try {
        const engine = get(renderingEngine);
        const store = contentStores[engine];
        if (store) {
            const content = get(store);
            const msg = await SaveFile(content);
            console.log(msg);
        } else {
            console.error(`No content store found for engine: ${engine}`);
        }
    } catch (e) {
        console.error("Failed to save file:", e);
    }
}

export async function compileD2(content: string, themeID: number): Promise<string> {
    try {
        console.log(`[Store] Calling CompileD2 via Wails. Content len: ${content.length}, ThemeID: ${themeID}`);
        
        // Pass "transparent" so D2 doesn't render a background rect. 
        // We rely on the app's CSS background for the preview, 
        // which avoids rendering issues with root rects in some webviews.
        const themeBackground = "transparent";

        const result = await CompileD2(content, themeID, themeBackground);
        console.log(`[Store] Wails CompileD2 returned. Result len: ${result?.length}`);
        return result;
    } catch (e) {
        console.error("D2 Compilation failed:", e);
        throw e;
    }
}

export function requestExportSVG() {
    editorCommand.set({ type: 'export-svg', timestamp: Date.now() });
}

export function requestExportPNG() {
    editorCommand.set({ type: 'export-png', timestamp: Date.now() });
}