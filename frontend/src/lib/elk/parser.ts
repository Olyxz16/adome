export interface ElkNode {
    id: string;
    width: number;
    height: number;
    x?: number;
    y?: number;
    labels?: { text: string }[];
    children?: ElkNode[];
    layoutOptions?: any;
}

export interface ElkEdge {
    id: string;
    sources: string[];
    targets: string[];
    sections?: any[];
    labels?: { text: string, width: number, height: number, x?: number, y?: number }[];
}

export interface ElkGraph {
    id: string;
    layoutOptions?: any;
    children: ElkNode[];
    edges: ElkEdge[];
}

export function parseTextToGraph(text: string, measureText?: (text: string) => { width: number, height: number }): ElkGraph {
    const nodes: Map<string, ElkNode> = new Map();
    const edges: ElkEdge[] = [];
    const lines = text.split('\n');
    let edgeCount = 0;
    
    // Default measurement if none provided
    const defaultMeasure = (str: string) => ({ width: Math.max(60, str.length * 8 + 20), height: 40 });
    const measurer = measureText || defaultMeasure;

    const getOrCreateNode = (id: string, label?: string) => {
        if (!nodes.has(id)) {
            const text = label || id;
            const size = measurer(text);
            nodes.set(id, {
                id,
                width: size.width,
                height: size.height,
                labels: [{ text: text }]
            });
        } else if (label) {
             const node = nodes.get(id)!;
             if (node.labels && node.labels[0].text === id) {
                 node.labels[0].text = label;
                 const size = measurer(label);
                 node.width = size.width;
                 node.height = size.height;
             }
        }
        return nodes.get(id)!;
    };

    for (const line of lines) {
        const trimmed = line.trim();
        if (!trimmed) continue;
        if (trimmed.startsWith('graph ') || trimmed.startsWith('flowchart ')) continue; // Skip mermaid header
        
        // Robust splitter for Mermaid arrows:
        // 1. -->|Label| or ->|Label|
        // 2. -- Label --> or -- Label ->
        // 3. --> or ->
        const delimiterRegex = /(\s*(?:-?->\|[^|]+\||--\s+[^>]+\s+-?>|-?->)\s*)/;
        const parts = trimmed.split(delimiterRegex);

        if (parts.length >= 3) {
             const parseNodeStr = (str: string) => {
                 str = str.trim();
                 const match = str.match(/^([^\s\[\(\{]+)(?:\s*[\$\[\(\{](.*?)[\$\]\)\}])$/);
                 if (match) {
                     return { id: match[1], label: match[2] };
                 }
                 return { id: str, label: undefined };
             };

             const source = parseNodeStr(parts[0]);
             const target = parseNodeStr(parts[2]); // Index 2 is the target, Index 1 is the separator
             const separator = parts[1].trim();

             // Extract Edge Label
             let edgeLabel = '';
             // Case 1: -->|Label|
             const pipeMatch = separator.match(/\|([^|]+)\|/);
             if (pipeMatch) {
                 edgeLabel = pipeMatch[1];
             } else {
                 // Case 2: -- Label -->
                 const middleMatch = separator.match(/--\s+([^>]+?)\s+-?>/);
                 if (middleMatch) {
                     edgeLabel = middleMatch[1];
                 }
             }
             
             // If either is empty/invalid, skip
             if (!source.id || !target.id) continue;

             getOrCreateNode(source.id, source.label);
             getOrCreateNode(target.id, target.label);
             
             const edge: ElkEdge = {
                 id: `e${edgeCount++}`,
                 sources: [source.id],
                 targets: [target.id]
             };
             
             if (edgeLabel) {
                 const size = measurer(edgeLabel);
                 edge.labels = [{ 
                     text: edgeLabel,
                     width: size.width,
                     height: size.height
                 }];
             }

             edges.push(edge);
        } else {
            // Just a node definition? A[Label]
            const match = trimmed.match(/^([^\s\[\(\{]+)(?:\s*[\$\[\(\{](.*?)[\$\]\)\}])$/);
            if (match) {
                getOrCreateNode(match[1], match[2]);
            }
        }
    }

    // --- Connected Components Logic ---
    const allNodeIds = Array.from(nodes.keys());
    const adj = new Map<string, string[]>();
    
    // Initialize adj list
    for (const id of allNodeIds) adj.set(id, []);
    
    // Fill adj list (undirected for connectivity)
    for (const edge of edges) {
        for (const src of edge.sources) {
            for (const tgt of edge.targets) {
                adj.get(src)?.push(tgt);
                adj.get(tgt)?.push(src);
            }
        }
    }

    const visited = new Set<string>();
    const components: ElkNode[] = [];
    let compIndex = 0;

    for (const nodeId of allNodeIds) {
        if (visited.has(nodeId)) continue;
        
        // BFS for component
        const componentNodes: ElkNode[] = [];
        const q = [nodeId];
        visited.add(nodeId);
        
        while (q.length > 0) {
            const curr = q.shift()!;
            componentNodes.push(nodes.get(curr)!);
            
            for (const neighbor of adj.get(curr) || []) {
                if (!visited.has(neighbor)) {
                    visited.add(neighbor);
                    q.push(neighbor);
                }
            }
        }

        // Filter edges internal to this component
        const compNodeIds = new Set(componentNodes.map(n => n.id));
        const compEdges = edges.filter(e => 
            e.sources.every(s => compNodeIds.has(s)) && 
            e.targets.every(t => compNodeIds.has(t))
        );

        components.push({
            id: `component_${compIndex++}`,
            // We don't set width/height for the container, ELK calculates it
            children: componentNodes,
            edges: compEdges,
            layoutOptions: {
                // This will be overridden by elk-api.ts with the user selected algorithm
            }
        });
    }

    // Return Root that packs the components
    return {
        id: 'root',
        layoutOptions: { 
            // The root uses a packing algorithm to arrange the components
            'elk.algorithm': 'rectpacking',
            'elk.spacing.nodeNode': '40', // Spacing between components
            'elk.padding': '[top=40,left=40,bottom=40,right=40]'
        },
        children: components,
        edges: [] // No edges between components
    };
}
