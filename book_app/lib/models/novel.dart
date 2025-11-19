
import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class Novel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final List<String> authors;

  @HiveField(3)
  final String description;

  @HiveField(4)
  final Map<String, dynamic> raw;

  Novel({
    required this.id,
    required this.title,
    required this.authors,
    required this.description,
    required this.raw,
  });

  factory Novel.fromMap(Map<String, dynamic> m) {
    return Novel(
      id: m['id'] as String,
      title: m['title'] ?? '',
      authors: (m['authors'] as List?)?.map((e) => e.toString()).toList() ?? [],
      description: m['description'] ?? '',
      raw: Map<String, dynamic>.from(m['raw'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'title': title, 'authors': authors, 'description': description, 'raw': raw};
  }
}

// Manual TypeAdapter so build_runner isn't required
class NovelAdapter extends TypeAdapter<Novel> {
  @override
  final int typeId = 0;

  @override
  Novel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{};
    for (var i = 0; i < numOfFields; i++) {
      final key = reader.readByte();
      final value = reader.read();
      fields[key] = value;
    }

    return Novel(
      id: fields[0] as String,
      title: fields[1] as String,
      authors: (fields[2] as List).cast<String>(),
      description: fields[3] as String,
      raw: (fields[4] as Map).cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, Novel obj) {
    writer.writeByte(5);
    writer.writeByte(0);
    writer.write(obj.id);
    writer.writeByte(1);
    writer.write(obj.title);
    writer.writeByte(2);
    writer.write(obj.authors);
    writer.writeByte(3);
    writer.write(obj.description);
    writer.writeByte(4);
    writer.write(obj.raw);
  }
}
