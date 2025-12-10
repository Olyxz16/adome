import { describe, it, expect, vi, beforeEach } from 'vitest';
import { get } from 'svelte/store';
import { 
    userThemes, 
    loadThemes, 
    saveThemes, 
    resolveTheme, 
    isDarkMode, 
    currentAppTheme,
    getMermaidThemeVariables,
    defaultLightTheme
} from './theme';
import * as bridge from '../services/bridge';

// Mock the bridge module
vi.mock('../services/bridge', () => ({
    LoadPalettes: vi.fn(),
    SavePalettes: vi.fn(),
    IsDarkTheme: vi.fn(),
}));

describe('Theme Store', () => {
    beforeEach(() => {
        vi.clearAllMocks();
        userThemes.set([]);
        // Reset matchMedia mock if needed, or window properties
        Object.defineProperty(window, 'matchMedia', {
            writable: true,
            value: vi.fn().mockImplementation(query => ({
                matches: false,
                media: query,
                onchange: null,
                addListener: vi.fn(), // Deprecated
                removeListener: vi.fn(), // Deprecated
                addEventListener: vi.fn(),
                removeEventListener: vi.fn(),
                dispatchEvent: vi.fn(),
            })),
        });
    });

    it('loadThemes updates userThemes from valid JSON', async () => {
        const themes = [{ name: 'MyTheme', isDark: false }];
        (bridge.LoadPalettes as any).mockResolvedValue(JSON.stringify(themes));

        await loadThemes();

        expect(bridge.LoadPalettes).toHaveBeenCalled();
        expect(get(userThemes)).toEqual(themes);
    });

    it('saveThemes calls SavePalettes with JSON string', async () => {
        const themes = [{ name: 'MyTheme', isDark: false }];
        // @ts-ignore
        userThemes.set(themes);

        await saveThemes();

        expect(bridge.SavePalettes).toHaveBeenCalledWith(JSON.stringify(themes));
    });

    it('resolveTheme checks system preference when appTheme is system', async () => {
        currentAppTheme.set('system');
        // Mock system theme check via bridge (fallback) or matchMedia
        // The store logic checks matchMedia first.
        // Let's mock matchMedia to return true for dark
        Object.defineProperty(window, 'matchMedia', {
            writable: true,
            value: vi.fn().mockImplementation(query => ({
                matches: true, // Dark mode preferred
                media: query,
                addEventListener: vi.fn(),
                removeEventListener: vi.fn(),
            })),
        });

        await resolveTheme();

        expect(get(isDarkMode)).toBe(true);
        expect(document.body.classList.contains('dark-theme')).toBe(true);
    });

    it('resolveTheme uses manual preference', async () => {
        currentAppTheme.set('light');
        
        await resolveTheme();

        expect(get(isDarkMode)).toBe(false);
        expect(document.body.classList.contains('dark-theme')).toBe(false);

        currentAppTheme.set('dark');
        await resolveTheme();

        expect(get(isDarkMode)).toBe(true);
        expect(document.body.classList.contains('dark-theme')).toBe(true);
    });

    it('getMermaidThemeVariables maps graph theme correctly', () => {
        const theme = { ...defaultLightTheme, background: '#123456', nodeBackground: '#abcdef' };
        const vars = getMermaidThemeVariables(theme);

        expect(vars.background).toBe('#123456');
        expect(vars.primaryColor).toBe('#abcdef');
        expect(vars.darkMode).toBe(false);
        // Check mapped fields
        expect(vars.mainBkg).toBe('#abcdef');
        expect(vars.clusterBkg).toBe('#123456');
    });
});
