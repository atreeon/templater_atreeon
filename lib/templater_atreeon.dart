import 'dart:io';

import 'package:path/path.dart' as p;

class Templater {
  String? templateMain;
  Map<String, String> templatesOther;
  final String? templateDir;

  Templater({
    this.templateMain,
    this.templatesOther = const {},
    this.templateDir,
  });

  String replaceInternal(String template, Map<String, dynamic> input) {
    var result = template;

    var firstTwoChars = result.substring(0, 2);
    while (firstTwoChars == "--") {
      result = result.substring(result.indexOf('\n') + 1);
      firstTwoChars = result.substring(0, 2);
    }

    var patternToken = "%%%(.*?)%%%";
    var regexToken = RegExp(patternToken);

    RegExpMatch? matchToken = regexToken.firstMatch(result);
    while (matchToken != null) {
      var keyToken = result.substring(matchToken.start + 3, matchToken.end - 3);
      var valueToken = input[keyToken];
      if (valueToken == null) //
        throw Exception("The token %%%'$keyToken'%%% not found in data");
      result = result.replaceRange(matchToken.start, matchToken.end, valueToken);

      matchToken = regexToken.firstMatch(result);
    }

    var patternSub = "###(.*?)###";
    var regexSub = RegExp(patternSub);

    RegExpMatch? matchSub = regexSub.firstMatch(result);
    while (matchSub != null) {
      var regexValueSub = result.substring(matchSub.start + 3, matchSub.end - 3);
      var index = regexValueSub.indexOf("|");
      var mapKey = regexValueSub.substring(0, index);
      var mapInput = input[mapKey];
      if (mapInput == null) //
        throw Exception("The token ###'$mapKey'### item not found in data");

      var templateKey = regexValueSub.substring(index + 1);
      var template = templatesOther[templateKey];
      if (template == null) //
        throw Exception("'$templateKey' not found");

      var templateResult = replaceInternal(template, mapInput);
      result = result.replaceRange(matchSub.start, matchSub.end, templateResult);

      matchSub = regexSub.firstMatch(result);
    }

    var patternRepeat = "~~~(.*?)~~~";
    var regexRepeat = RegExp(patternRepeat);

    RegExpMatch? matchRepeat = regexRepeat.firstMatch(result);
    while (matchRepeat != null) {
      var regexValueRepeat = result.substring(matchRepeat.start + 3, matchRepeat.end - 3);
      var index = regexValueRepeat.indexOf("|");
      var listKey = regexValueRepeat.substring(0, index);
      var list = input[listKey];
      if (list == null) //
        throw Exception("'$list' item not found in data");
      if (list is! List<Map<String, dynamic>>) //
        throw Exception("'$listKey' must be of type List<Map<String, dynamic>>");

      var templateKey = regexValueRepeat.substring(index + 1);
      var template = templatesOther[templateKey];
      if (template == null) //
        throw Exception("'$templateKey' not found");

      var templateResult = list.map((e) => replaceInternal(template, e)).join();
      result = result.replaceRange(matchRepeat.start, matchRepeat.end, templateResult);

      matchRepeat = regexSub.firstMatch(result);
    }

    return result;
  }

  ///Determines whether we use the directory or the passed in templates
  ///Looks up the files in the directory specified if one is supplied
  ///Sets the templateMain depending where it is specified
  Future<void> setTemplates() async {
    if (templateDir != null) {
      var myDir = Directory(templateDir!);
      if (!await myDir.exists()) //
        throw Exception("Directory specified '$myDir' not found, current Dir = '${Directory.current.path}'");

      var files = await myDir.list().toList();

      for (var file in files) {
        var templateName = p.basenameWithoutExtension(file.path);
        var fileContents = await File.fromUri(file.uri).readAsString();

        if (templateName.substring(0, 4).toLowerCase() == "main") {
          if (templateMain != null) //
            throw Exception("'templateMain' already specified, check folder location and argument 'templateMain'. Only one allowed");
          templateMain = fileContents;
        }

        templatesOther = {
          ...templatesOther,
          ...{templateName: fileContents}
        };
      }
    }
  }

  ///Replaces the various tokens with those passed in using
  ///the templates specified either in the directory or passed in
  Future<String> replace(Map<String, dynamic> input) async {
    await setTemplates();
    if (templateMain == null) //
      throw Exception("Failed to set 'templateMain'");

    return replaceInternal(templateMain!, input);
  }

  ///Takes a list of files and writes the output
  Future<List<String>> writeFiles(String outputDir, Map<String, Map<String, dynamic>> inputs, {bool writeFiles = true}) async {
    late Directory dir;
    if (writeFiles) {
      dir = Directory(outputDir);
      if (!await dir.exists()) //
        throw Exception("'outputDir' couldn't be found");
    }

    await setTemplates();
    if (templateMain == null) //
      throw Exception("Failed to set 'templateMain'");

    if (writeFiles) {
      //delete all files in dir
      var outputFiles = await dir.list().toList();
      for (var o in outputFiles) {
        await o.delete();
      }
    }

    var outputs = inputs.keys.toList().map((key) async {
      var value = inputs[key];
      var result = replaceInternal(templateMain!, value!);

      if (writeFiles) {
        var file = File(p.join(outputDir, key));
        await file.writeAsString(result);
      }

      return result;
    });

    //must wait here before we do our dart format,
    // otherwise our files will be written after we format
    var outputsWaited = await Future.wait(outputs);

    if (writeFiles) {
      await Process.runSync(
        'dart',
        ['format', '.'],
        workingDirectory: dir.path,
      );
    }

    return outputsWaited;
  }
}
