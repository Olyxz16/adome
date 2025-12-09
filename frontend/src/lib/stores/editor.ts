import { writable, get } from 'svelte/store';
import { LoadFile, SaveFile, CompileD2 } from '../services/bridge';

export const editorContent = writable<string>(`graph TD
    A[Christmas] -->|Get money| B(Go shopping)
    B --> C{Let me think}
    C -->|One| D[Laptop]
    C -->|Two| E[iPhone]
    C -->|Three| F[fa:fa-car Car]
`);

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
            editorContent.set(content);
            // Trigger a render after load
            triggerRender.update(n => n + 1);
        }
    } catch (e) {
        console.error("Failed to load file:", e);
    }
}

export async function saveFile() {
    try {
        const content = get(editorContent);
        const msg = await SaveFile(content);
        console.log(msg);
    } catch (e) {
        console.error("Failed to save file:", e);
    }
}

export async function compileD2(content: string, themeID: number): Promise<string> {
    try {
        console.log(`[Store] Calling CompileD2 via Wails. Content len: ${content.length}, ThemeID: ${themeID}`);
        const result = await CompileD2(content, themeID);
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
