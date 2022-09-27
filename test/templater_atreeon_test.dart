import 'dart:io';

import 'package:templater_atreeon/templater_atreeon.dart';
import 'package:test/test.dart';

void main() {
  test('a1 replaces tokens', () async {
    var template = """
this is my test %%%value1%%% to see
if these tokens %%%value2%%% are
replaced %%%value3%%%
""";

    var input = {
      "value1": "hello",
      "value2": "howdy",
      "value3": "gday",
    };

    var expected = """
this is my test hello to see
if these tokens howdy are
replaced gday
""";

    var templater = Templater(templateMain: template);
    var result = await templater.replace(input);

    expect(result, expected);
  });

  test('a2 replaces sub template', () async {
    var template = """
this is my test to see
if a sub template of a pet ###pet|templatePet### and
another sub template of a person
###person|templatePerson###
has been replaced
so %%%value3%%%
""";

    var otherTemplates = {
      "templatePet": "Here is my pet %%%name%%% and it is a %%%type%%%",
      "templatePerson": "Hello %%%name%%% you have %%%eyeColour%%% eyes",
    };

    var input = {
      "value3": "gday",
      "pet": {
        "name": "Sandy",
        "type": "cat",
      },
      "person": {
        "name": "Mel",
        "eyeColour": "green",
      },
    };

    var expected = """
this is my test to see
if a sub template of a pet Here is my pet Sandy and it is a cat and
another sub template of a person
Hello Mel you have green eyes
has been replaced
so gday
""";

    var templater = Templater(
      templateMain: template,
      templatesOther: otherTemplates,
    );
    var result = await templater.replace(input);

    expect(result, expected);
  });

  test('a3 replaces sub sub template', () async {
    var template = """
this is my test to see
owner
###person|templatePerson###
so %%%value3%%%
""";

    var otherTemplates = {
      "templatePet": "Here is my pet %%%name%%% and it is a %%%type%%%",
      "templatePerson": """Hello %%%name%%% you have %%%eyeColour%%% eyes
has a pet of
###pet|templatePet###
and thats all from %%%name%%%""",
    };

    var input = {
      "value3": "gday",
      "person": {
        "name": "Mel",
        "eyeColour": "green",
        "pet": {
          "name": "Sandy",
          "type": "cat",
        },
      },
    };

    var expected = """
this is my test to see
owner
Hello Mel you have green eyes
has a pet of
Here is my pet Sandy and it is a cat
and thats all from Mel
so gday
""";

    var templater = Templater(
      templateMain: template,
      templatesOther: otherTemplates,
    );
    var result = await templater.replace(input);

    expect(result, expected);
  });

  test('a4 repeatable', () async {
    var template = """
Yo! %%%value1%%% to you all
Here are my favourite pet types
~~~pets|petTemplate~~~
so %%%value2%%%
""";

    var otherTemplates = {
      "petTemplate": """I had %%%name%%% and it was a %%%type%%%
""",
    };

    var input = {
      "value1": "howdy",
      "value2": "gday",
      "pets": [
        {
          "name": "Sandy",
          "type": "cat",
        },
        {
          "name": "Simon",
          "type": "fish",
        },
        {
          "name": "Tommy",
          "type": "tortoise",
        },
      ]
    };

    var expected = """
Yo! howdy to you all
Here are my favourite pet types
I had Sandy and it was a cat
I had Simon and it was a fish
I had Tommy and it was a tortoise

so gday
""";

    var templater = Templater(
      templateMain: template,
      templatesOther: otherTemplates,
    );
    var result = await templater.replace(input);

    expect(result, expected);
  });

  test('a5 remove comments (first lines only)', () async {
    var template = """
--double dash is a comment and should be removed
--even on the second line
this is my test %%%value1%%% to see
if these tokens %%%value2%%% are
replaced %%%value3%%%
""";

    var input = {"value1": "hello", "value2": "howdy", "value3": "gday"};

    var expected = """
this is my test hello to see
if these tokens howdy are
replaced gday
""";

    var templater = Templater(templateMain: template);
    var result = await templater.replace(input);

    expect(result, expected);
  });

  test('a6 looks in relative sub dir', () async {
    var input = {
      "value3": "gday",
      "pet": {
        "name": "Sandy",
        "type": "cat",
      },
      "person": {
        "name": "Mel",
        "eyeColour": "green",
      },
    };

    var expected = """
this is my test to see
if a sub template of a pet Here is my pet Sandy and it is a cat and
another sub template of a person
Hello Mel you have green eyes
has been replaced
so gday""";
    var templateDir = Directory.current.path + "/test/testTemplates2";

    var templater = Templater(templateDir: templateDir);
    var result = await templater.replace(input);

    expect(result, expected);
  });

  test('a7 outputs files to directory', () async {
    var template = "%%%value1%%% %%%value2%%%";
    var input1 = {"value1": "hello", "value2": "bye"};
    var input2 = {"value1": "guten morgan", "value2": "tchus"};
    var input3 = {"value1": "bonjour", "value2": "bon chance"};

    var outputDir = Directory.current.path + "/test/output";
    var templater = Templater(templateMain: template);
    await templater.writeFiles(outputDir, {"output1.txt": input1, "output2.txt": input2, "output3.txt": input3});

    var dirAfter = Directory(outputDir);

    var outputFiles = await dirAfter.list().toList();

    expect(outputFiles.length, 3);

    // cleanup
    for (var o in outputFiles ) {
      o.delete();
    }
  });
}
