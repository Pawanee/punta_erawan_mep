import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/grouping_factor.dart';

class Table5_8Repository {
  Future<List<GroupingFactor>> load() async {
    final jsonString = await rootBundle.loadString(
      'lib/assets/json/table_5_8.json',
    );

    final List<dynamic> jsonData = json.decode(jsonString);

    return jsonData
        .map(
          (e) => GroupingFactor.fromJson(e),
        )
        .toList();
  }
}