import * as App from '../../../wailsjs/go/app/App';
import * as D2 from '../../../wailsjs/go/d2/Service';
import * as Config from '../../../wailsjs/go/config/Service';
import * as Files from '../../../wailsjs/go/files/Service';

// Interfaces
export interface Preferences {
    activeThemeName: string;
}

// App
export const IsDarkTheme = App.IsDarkTheme;
export const GetStartupFilePath = App.GetStartupFilePath;

// D2
export const CompileD2 = D2.Compile;

// Config
export const SavePalettes = Config.SavePalettes;
export const LoadPalettes = Config.LoadPalettes;
export const LoadPreferences = Config.LoadPreferences;
export const SavePreferences = Config.SavePreferences;

// Files
export const LoadFile = Files.LoadFile;
export const SaveFile = Files.SaveFile as (content: string, engine: string) => Promise<string>;
export const LoadFileByPath = Files.LoadFileByPath;
export const ExportSVG = Files.ExportSVG;
export const ExportPNG = Files.ExportPNG;
