import ELK from 'elkjs/lib/elk.bundled.js';

const elk = new ELK();

// Algorithm-specific configurations
const algorithmConfigs: Record<string, any> = {
    'layered': {
        'elk.direction': 'DOWN',
        'elk.spacing.nodeNode': '60',
        'elk.layered.spacing.nodeNodeBetweenLayers': '60',
        'elk.spacing.edgeNode': '20'
    },
    'stress': {
        'elk.algorithm': 'stress', 
        'elk.stress.desiredEdgeLength': '300.0', // Increased significantly to prevent linear clamping
    },
    'force': {
        'elk.force.iterations': '500',
        'elk.force.repulsion': '100', // Balanced
        'elk.spacing.nodeNode': '80'
    },
    'mrtree': {
        'elk.direction': 'DOWN',
        'elk.spacing.nodeNode': '60',
        'elk.spacing.edgeNode': '30',
        // MrTree specific label placement
        'elk.edgeLabels.inline': 'true',
        'elk.edgeLabels.placement': 'CENTER'
    },
    'radial': {
        'elk.spacing.nodeNode': '60',
        'elk.radial.compaction': 'true',
        // Radial specific label placement
        'elk.edgeLabels.inline': 'true',
        'elk.edgeLabels.placement': 'CENTER'
    },
    'disco': {
        'elk.disco.componentCompaction.componentSpacing': '60',
        'elk.spacing.nodeNode': '60'
    }
};

const commonConfig = {
    'elk.padding': '[top=40,left=40,bottom=40,right=40]'
};

export async function layoutGraph(graph: any, algorithm: string = 'layered') {
    // Check for hierarchical structure (Root -> Components -> Nodes)
    const isHierarchical = graph.children && graph.children.length > 0 && graph.children[0].children && graph.children[0].children.length > 0;

    if (isHierarchical) {
        // 1. Layout each component independently
        const layoutPromises = graph.children.map(async (component: any) => {
            if (!component.layoutOptions) component.layoutOptions = {};
            
            // Set Component Algorithm
            component.layoutOptions['elk.algorithm'] = algorithm;
            Object.assign(component.layoutOptions, commonConfig);
            if (algorithmConfigs[algorithm]) {
                Object.assign(component.layoutOptions, algorithmConfigs[algorithm]);
            }

            try {
                // Layout this individual component
                return await elk.layout(component);
            } catch (e) {
                console.error("Component layout error", e);
                return component; // Return un-layouted if fail
            }
        });

        const laidOutComponents = await Promise.all(layoutPromises);

        // 2. Manual Packing (Shelf Algorithm)
        // Arrange the laid-out components into a grid/shelf structure
        const gap = 50; // Spacing between components
        let currentX = 0;
        let currentY = 0;
        let rowHeight = 0;
        
        // Calculate a target width to keep aspect ratio roughly square
        const totalArea = laidOutComponents.reduce((sum, c) => sum + (c.width * c.height), 0);
        const targetWidth = Math.sqrt(totalArea) * 1.5; // Slightly wider than square

        // Calculate full graph bounds
        let maxX = 0;
        let maxY = 0;

        for (const component of laidOutComponents) {
             // If this component pushes us past target width, wrap to new row
             if (currentX > 0 && currentX + component.width > targetWidth) {
                 currentX = 0;
                 currentY += rowHeight + gap;
                 rowHeight = 0;
             }

             // Position component
             component.x = currentX;
             component.y = currentY;

             // Update row stats
             currentX += component.width + gap;
             rowHeight = Math.max(rowHeight, component.height);
             
             // Update global bounds
             maxX = Math.max(maxX, component.x + component.width);
             maxY = Math.max(maxY, component.y + component.height);
        }

        // 3. Return the Root with updated children
        graph.children = laidOutComponents;
        graph.width = maxX;
        graph.height = maxY;
        
        return graph;

    } else {
        // Fallback for flat graph
        if (!graph.layoutOptions) graph.layoutOptions = {};
        graph.layoutOptions['elk.algorithm'] = algorithm;
        Object.assign(graph.layoutOptions, commonConfig);
        if (algorithmConfigs[algorithm]) {
            Object.assign(graph.layoutOptions, algorithmConfigs[algorithm]);
        }
        return await elk.layout(graph);
    }
}

