import 'package:hive_flutter/hive_flutter.dart';
import 'package:qr_two_factor/resources_model.dart';

class SigletonResource {
  static Box<Resource> getResource() => Hive.box<Resource>('resources');
}
