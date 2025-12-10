import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { initMermaid, renderMermaid, resetMermaidStateForTesting } from './mermaid';
import mermaid from 'mermaid';
import { defaultLightTheme, defaultDarkTheme } from '../stores/theme';

// Mock mermaid
vi.mock('mermaid', () => ({
    default: {
        registerLayoutLoaders: vi.fn(),
        initialize: vi.fn(),
        render: vi.fn(),
        mermaidAPI: {
            reset: vi.fn(),
        },
    },
}));

describe('Mermaid Service', () => {
    beforeEach(() => {
        vi.clearAllMocks();
        resetMermaidStateForTesting();
        
        // Mock window.go for logging
        window.go = {
            main: {
                App: {
                    Log: vi.fn(),
                    LogError: vi.fn(),
                },
            },
        } as any;
    });

    afterEach(() => {
        delete (window as any).go;
    });

    it('initMermaid initializes mermaid', () => {
        initMermaid();
        expect(mermaid.initialize).toHaveBeenCalledWith(expect.objectContaining({
            startOnLoad: false,
            securityLevel: 'strict',
            theme: 'base',
        }));
    });

    it('renderMermaid renders basic graph', async () => {
        const id = 'graph-1';
        const code = 'graph TD; A-->B;';
        const mockSvg = '<svg>...</svg>';
        (mermaid.render as any).mockResolvedValue({ svg: mockSvg });

        const result = await renderMermaid(id, code, defaultLightTheme);

        expect(result).toBe(mockSvg);
        expect(mermaid.render).toHaveBeenCalledWith(id, code);
    });

    it('renderMermaid resets and re-initializes on theme change', async () => {
        const id = 'graph-2';
        const code = 'graph TD; B-->C;';
        (mermaid.render as any).mockResolvedValue({ svg: '<svg></svg>' });

        // First render with light theme
        // - initMermaid() called -> initialize call #1
        // - theme mismatch (current '' vs light) -> initialize call #2
        await renderMermaid(id, code, defaultLightTheme);
        
        // Second render with dark theme
        // - theme mismatch (light vs dark) -> initialize call #3
        await renderMermaid(id, code, defaultDarkTheme);

        expect(mermaid.mermaidAPI.reset).toHaveBeenCalled();
        expect(mermaid.initialize).toHaveBeenCalledTimes(3); 
        
        // Check if initialize was called with dark mode vars
        const lastCall = (mermaid.initialize as any).mock.calls[2][0];
        expect(lastCall.themeVariables.darkMode).toBe(true);
    });

    it('renderMermaid injects ELK frontmatter for layered algorithm', async () => {
        const id = 'graph-elk-1';
        const code = 'graph TD; A-->B;';
        (mermaid.render as any).mockResolvedValue({ svg: '<svg></svg>' });

        await renderMermaid(id, code, defaultLightTheme, 'layered');

        // layered algorithm uses "layout: elk" not "layout: elk.layered"
        const expectedCodeStart = '---\nconfig:\n  layout: elk\n';
        expect(mermaid.render).toHaveBeenCalledWith(id, expect.stringContaining(expectedCodeStart));
    });

    it('renderMermaid injects ELK frontmatter for stress algorithm', async () => {
        const id = 'graph-elk-2';
        const code = 'graph TD; A-->B;';
        (mermaid.render as any).mockResolvedValue({ svg: '<svg></svg>' });

        await renderMermaid(id, code, defaultLightTheme, 'stress');

        const expectedCodeStart = '---\nconfig:\n  layout: elk.stress';
        expect(mermaid.render).toHaveBeenCalledWith(id, expect.stringContaining(expectedCodeStart));
        expect(mermaid.render).toHaveBeenCalledWith(id, expect.stringContaining('org.eclipse.elk.stress.desiredEdgeLength'));
    });

    it('renderMermaid handles errors and logs to Wails', async () => {
        const id = 'graph-error';
        const code = 'graph TD; A-->;'; // Invalid syntax
        const error = new Error('Syntax Error');
        (mermaid.render as any).mockRejectedValue(error);

        await expect(renderMermaid(id, code, defaultLightTheme)).rejects.toThrow('Syntax Error');

        expect(window.go.main.App.LogError).toHaveBeenCalledWith(expect.stringContaining('[Mermaid Renderer Error] Syntax Error'));
    });
});
