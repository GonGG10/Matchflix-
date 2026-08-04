class CategoryEntity {
  const CategoryEntity({required this.id, required this.name});
  final String id;
  final String name;

  factory CategoryEntity.fromJson(Map<String, dynamic> json) =>
      CategoryEntity(id: json['id'] as String, name: json['name'] as String);
}
