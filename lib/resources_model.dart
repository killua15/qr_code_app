import 'package:hive/hive.dart';

part 'resources_model.g.dart';

@HiveType(typeId: 1)
class Resource {
  @HiveField(0)
  late String secret;

  @HiveField(1)
  late String resource;
}
