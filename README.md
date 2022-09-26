# templater atreeon

aka Text Template Transformation or T4 templates

Can be used for source code generation

Takes a file and replaces the tokens with those from the map.
Supports simple token replace, sub templates, sub sub templates and iterative templates.

`%%%keyName%%%` type must be String

`###keyName|||subTemplateName###` type must be Map<String, dynamic>

`~~~keyName|||repeatableTemplateName~~~` type must be List<Map<String,dynamic>> 

```
var t = templateAtreeon(starterTemplate, [templateResources]);
var replaces = {"tableName":"employees", "columns":[{"name":"id", "dbType":"int64", "dartType":"int"}]
var output = templateAtreeon.replace()
```

Comments must be at the beginning of the template file, no blank lines and begin with two dashes (--)

## Sample usage
### Simple replace of tokens
```
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
    
    var templater = Templater(input, templateMain: template);
    var result = await templater.replace();
```

### Sub templates are supported
```
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
    
    var templater = Templater(
      input,
      templateMain: template,
      templatesOther: otherTemplates,
    );
    var result = await templater.replace();
```

### Sub Sub Templates
```
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
```
### Repeatable
```
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
```