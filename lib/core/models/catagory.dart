class Category {
  final String id; // Firestore document ID
  final String name;
  final String? parentId;
  final String? imageUrl;

  Category({
    required this.id,
    required this.name,
    this.parentId,
    this.imageUrl,
  });

  factory Category.fromMap(Map<String, dynamic> data, String documentId) {
    print('Data received: $data');
    return Category(
      id: documentId, // Use the document ID directly from Firestore
      name: data['name'] ?? "",
      parentId: data['parentId'],
      imageUrl: data['imageurl'] ?? "" as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {'name': name, 'parentId': parentId, 'imageurl': imageUrl};
  }
}
