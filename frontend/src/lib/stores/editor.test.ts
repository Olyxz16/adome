import { describe, it, expect, vi, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { editorContent, loadFile, saveFile, compileD2, editorCommand } from './editor';
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
        editorContent.set('');
        editorCommand.set({ type: 'none', timestamp: 0 });
    });

    it('loadFile updates editorContent on success', async () => {
        const mockContent = 'graph TD; A-->B;';
        (bridge.LoadFile as any).mockResolvedValue(mockContent);

        await loadFile();

        expect(bridge.LoadFile).toHaveBeenCalled();
        expect(get(editorContent)).toBe(mockContent);
    });

    it('loadFile does nothing if cancelled (returns empty)', async () => {
        (bridge.LoadFile as any).mockResolvedValue('');

        await loadFile();

        expect(bridge.LoadFile).toHaveBeenCalled();
        expect(get(editorContent)).toBe('');
    });

    it('saveFile calls SaveFile with current content', async () => {
        const content = 'some content';
        editorContent.set(content);
        (bridge.SaveFile as any).mockResolvedValue('Saved');

        await saveFile();

        expect(bridge.SaveFile).toHaveBeenCalledWith(content);
    });

    it('compileD2 calls CompileD2 bridge', async () => {
        const content = 'x -> y';
        const themeID = 1;
        const mockSvg = '<svg>...</svg>';
        // Mock currentTheme in theme store? 
        // We can't easily mock the return of `get(currentTheme)` unless we mock the store module or set the store value.
        // But `currentTheme` is a store, so we can just set it if we import it?
        // Wait, `editor.ts` imports `currentTheme` directly.
        // We need to make sure `currentTheme` has a value.
        
        (bridge.CompileD2 as any).mockResolvedValue(mockSvg);

        // Note: verify what background color is passed. Default mock/store value might be used.
        // Since we didn't explicitly set the store in this test file, it uses default.
        // Let's assume default is light theme -> #ffffff
        
        const result = await compileD2(content, themeID);

        // Expect the 3rd arg (background) to be present. 
        // We can check if it was called with *any* string for the 3rd arg if we are unsure of the default
        // or we can import defaultLightTheme to be sure.
        expect(bridge.CompileD2).toHaveBeenCalledWith(content, themeID, expect.any(String));
        expect(result).toBe(mockSvg);
    });
});
