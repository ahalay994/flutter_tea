class FacetItem {
  final int id;
  final String name;
  final int count;

  FacetItem({
    required this.id,
    required this.name,
    required this.count,
  });

  factory FacetItem.fromJson(Map<String, dynamic> json) {
    return FacetItem(
      id: json['id'] as int,
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

class FacetResponse {
  final List<FacetItem> countries;
  final List<FacetItem> types;
  final List<FacetItem> appearances;
  final List<FacetItem> flavors;

  FacetResponse({
    required this.countries,
    required this.types,
    required this.appearances,
    required this.flavors,
  });

  factory FacetResponse.fromJson(Map<String, dynamic> json) {
    return FacetResponse(
      countries: (json['countries'] as List)
          .map((item) => FacetItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      types: (json['types'] as List)
          .map((item) => FacetItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      appearances: (json['appearances'] as List)
          .map((item) => FacetItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      flavors: (json['flavors'] as List)
          .map((item) => FacetItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}