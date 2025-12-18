import 'dart:io';
import 'package:file_selector/file_selector.dart' as selector;

class FileService {
  Future<String?> openFile() async {
    const selector.XTypeGroup typeGroup = selector.XTypeGroup(
      label: 'Diagrams',
      extensions: <String>['d2', 'mmd', 'mermaid', 'txt'],
    );
    final selector.XFile? file = await selector.openFile(acceptedTypeGroups: <selector.XTypeGroup>[typeGroup]);
    if (file == null) {
      return null;
    }
    return await file.readAsString();
  }

  Future<String?> openFilePath() async {
    const selector.XTypeGroup typeGroup = selector.XTypeGroup(
      label: 'Diagrams',
      extensions: <String>['d2', 'mmd', 'mermaid', 'txt'],
    );
    final selector.XFile? file = await selector.openFile(acceptedTypeGroups: <selector.XTypeGroup>[typeGroup]);
    return file?.path;
  }

  Future<void> saveFile(String content, String? path) async {
    if (path == null) {
      const String fileName = 'diagram.d2';
      final selector.FileSaveLocation? result = await selector.getSaveLocation(suggestedName: fileName);
      if (result == null) {
        return;
      }
      path = result.path;
    }
    
    final File file = File(path);
    await file.writeAsString(content);
  }

  Future<String?> saveFileAs(String content, {String suggestedFileName = 'diagram.txt'}) async {
    final selector.FileSaveLocation? result = await selector.getSaveLocation(suggestedName: suggestedFileName);
    if (result == null) {
      return null;
    }
    final File file = File(result.path);
    await file.writeAsString(content);
    return result.path;
  }

  Future<String?> saveBinaryFileAs(List<int> bytes, {String suggestedFileName = 'image.png'}) async {
    final selector.FileSaveLocation? result = await selector.getSaveLocation(suggestedName: suggestedFileName);
    if (result == null) {
      return null;
    }
    final File file = File(result.path);
    await file.writeAsBytes(bytes);
    return result.path;
  }
}
