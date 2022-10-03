var definition_template = """class %%%name%%%Definition {
  final String tableName = "%%%tableName%%%";

~~~columns|column_subTemplate~~~

  List<Column> get allColumns => [%%%columnNamesDelimited%%%];

  %%%modelName%%% getTypeFromRow(Map<String, Map<String, dynamic>> row) {
    return %%%modelName%%%(
~~~propertySetColumns|propertySet_subTemplate~~~
    );
  }
}""";
