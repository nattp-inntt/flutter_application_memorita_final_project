import 'package:hive/hive.dart';

part 'memory_model.g.dart';

@HiveType(typeId: 0)
class Memory extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String? locationName;

  @HiveField(5)
  double? lat;

  @HiveField(6)
  double? lng;

  @HiveField(7)
  String mood;

  @HiveField(8)
  List<String> mediaPaths;

  @HiveField(9)
  List<String> tags;

  Memory({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    this.locationName,
    this.lat,
    this.lng,
    required this.mood,
    required this.mediaPaths,
    required this.tags,
  });

  // ✅ MOVE OUTSIDE constructor
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'mood': mood,
      'mediaPaths': mediaPaths, // ✅ FIXED
      'tags': tags,
      'locationName': locationName,
      'lat': lat,
      'lng': lng,
    };
  }
}