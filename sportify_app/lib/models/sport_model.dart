class Sport {
  final String id;
  final String name;
  final String? logoUrl;
  final String? description;

  Sport({
    required this.id,
    required this.name,
    this.logoUrl,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'description': description,
    };
  }

  factory Sport.fromJson(Map<String, dynamic> json) {
    return Sport(
      id: json['id'] ?? json['idSport'] ?? '',
      name: json['name'] ?? json['strSport'] ?? '',
      logoUrl: json['logoUrl'] ?? json['strSportThumb'] ?? json['strSportIconGreen'],
      description: json['description'] ?? json['strSportDescription'],
    );
  }
}

