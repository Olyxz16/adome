export namespace config {
	
	export class Preferences {
	    activeThemeName: string;
	
	    static createFrom(source: any = {}) {
	        return new Preferences(source);
	    }
	
	    constructor(source: any = {}) {
	        if ('string' === typeof source) source = JSON.parse(source);
	        this.activeThemeName = source["activeThemeName"];
	    }
	}

}

