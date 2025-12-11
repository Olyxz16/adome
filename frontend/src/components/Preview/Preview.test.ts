import { render, screen } from '@testing-library/svelte';
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import Preview from './Preview.svelte';
import { writable } from 'svelte/store';
import { tick } from 'svelte';

// Mock the Bridge service
vi.mock('../../lib/services/bridge', () => ({
    ExportSVG: vi.fn(),
    ExportPNG: vi.fn(),
    Log: vi.fn()
}));

// Mock Mermaid Service
vi.mock('../../lib/services/mermaid', () => ({
    renderMermaid: vi.fn(async (id, code) => {
        return `<svg>${code}</svg>`;
    })
}));

// Mock the stores
vi.mock('../../lib/stores/editor', async () => {
    const { writable } = await import('svelte/store');
    return {
        contentStores: {
            mermaid: writable('initial mermaid'),
            d2: writable('initial d2')
        },
        renderingEngine: writable('mermaid'),
        layoutEngine: writable('default'),
        elkAlgorithm: writable('layered'),
        editorCommand: writable({ type: 'none', timestamp: 0 }),
        triggerRender: writable(0),
        compileD2: vi.fn(async (code) => `<svg>${code}</svg>`)
    };
});

vi.mock('../../lib/stores/theme', async () => {
    const { writable } = await import('svelte/store');
    return {
        currentTheme: writable({ background: '#ffffff' }),
        isDarkMode: writable(false)
    };
});

describe('Preview Component Debounce', () => {
    beforeEach(() => {
        vi.useFakeTimers();
    });

    afterEach(() => {
        vi.useRealTimers();
        vi.clearAllMocks();
    });

    it('should debounce content updates by 500ms', async () => {
        // dynamic import to get the mocked stores
        const { contentStores } = await import('../../lib/stores/editor');
        
        render(Preview);
        
        // Initial render might take a tick
        await tick();
        await vi.advanceTimersByTimeAsync(10); // Let async render settle
        await tick();

        // Initial state
        expect(document.body.innerHTML).toContain('initial mermaid');

        // Update store
        contentStores.mermaid.set('updated content');
        await tick(); // Let store update propagate to component

        // Should NOT be updated immediately (debouncer)
        expect(document.body.innerHTML).toContain('initial mermaid');
        expect(document.body.innerHTML).not.toContain('updated content');

        // Advance time by 200ms
        await vi.advanceTimersByTimeAsync(200);
        await tick();
        expect(document.body.innerHTML).toContain('initial mermaid');

        // Advance time by another 301ms (total > 500)
        await vi.advanceTimersByTimeAsync(301);
        await tick(); // Let debounced value propagate
        
        // Need to wait for the async renderMermaid to finish and update DOM
        // Since we are using fake timers, and renderMermaid is async (Promise),
        // we might need a few ticks or real microtask flush.
        // vi.advanceTimersByTimeAsync should help flush promises.
        await tick(); 
        await tick(); 

        // Now it should be updated
        expect(document.body.innerHTML).toContain('updated content');
    });
});
