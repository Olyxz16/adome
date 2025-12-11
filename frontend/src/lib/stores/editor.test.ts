import { describe, it, expect, vi, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { contentStores, renderingEngine, loadFile, saveFile, compileD2, editorCommand } from './editor';
import * as bridge from '../services/bridge';

// Mock the bridge module
vi.mock('../services/bridge', () => ({
    LoadFile: vi.fn(),
    SaveFile: vi.fn(),
    CompileD2: vi.fn(),
}));

describe('Editor Store', () => {
    beforeEach(() => {
        vi.clearAllMocks();
        contentStores['mermaid'].set('');
        contentStores['d2'].set('');
        renderingEngine.set('mermaid');
        editorCommand.set({ type: 'none', timestamp: 0 });
    });

    it('loadFile updates mermaid store when engine is mermaid', async () => {
        renderingEngine.set('mermaid');
        const mockContent = 'graph TD; A-->B;';
        (bridge.LoadFile as any).mockResolvedValue(mockContent);

        await loadFile();

        expect(bridge.LoadFile).toHaveBeenCalled();
        expect(get(contentStores['mermaid'])).toBe(mockContent);
        expect(get(contentStores['d2'])).toBe('');
    });

    it('loadFile updates d2 store when engine is d2', async () => {
        renderingEngine.set('d2');
        const mockContent = 'x -> y';
        (bridge.LoadFile as any).mockResolvedValue(mockContent);

        await loadFile();

        expect(bridge.LoadFile).toHaveBeenCalled();
        expect(get(contentStores['d2'])).toBe(mockContent);
        expect(get(contentStores['mermaid'])).toBe('');
    });

    it('loadFile does nothing if cancelled (returns empty)', async () => {
        (bridge.LoadFile as any).mockResolvedValue('');

        await loadFile();

        expect(bridge.LoadFile).toHaveBeenCalled();
        expect(get(contentStores['mermaid'])).toBe('');
        expect(get(contentStores['d2'])).toBe('');
    });

    it('saveFile calls SaveFile with mermaid content when engine is mermaid', async () => {
        renderingEngine.set('mermaid');
        const content = 'mermaid content';
        contentStores['mermaid'].set(content);
        (bridge.SaveFile as any).mockResolvedValue('Saved');

        await saveFile();

        expect(bridge.SaveFile).toHaveBeenCalledWith(content, 'mermaid');
    });

    it('saveFile calls SaveFile with d2 content when engine is d2', async () => {
        renderingEngine.set('d2');
        const content = 'd2 content';
        contentStores['d2'].set(content);
        (bridge.SaveFile as any).mockResolvedValue('Saved');

        await saveFile();

        expect(bridge.SaveFile).toHaveBeenCalledWith(content, 'd2');
    });

    it('compileD2 calls CompileD2 bridge', async () => {
        const content = 'x -> y';
        const themeID = 1;
        const mockSvg = '<svg>...</svg>';
        
        (bridge.CompileD2 as any).mockResolvedValue(mockSvg);

        const result = await compileD2(content, themeID);

        expect(bridge.CompileD2).toHaveBeenCalledWith(content, themeID, expect.any(String));
        expect(result).toBe(mockSvg);
    });
});

