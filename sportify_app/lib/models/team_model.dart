class Team {
  final String id;
  final String name;
  final String? logoUrl;
  final String? sport;
  final String? country;
  final String? league;
  final String? description;

  Team({
    required this.id,
    required this.name,
    this.logoUrl,
    this.sport,
    this.country,
    this.league,
    this.description,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'logoUrl': logoUrl,
      'sport': sport,
      'country': country,
      'league': league,
      'description': description,
    };
  }

  factory Team.fromJson(Map<String, dynamic> json) {
    return Team(
      id: json['id'] ?? json['idTeam'] ?? '',
      name: json['name'] ?? json['strTeam'] ?? '',
      logoUrl: json['logoUrl'] ?? json['strTeamBadge'] ?? json['strTeamLogo'],
      sport: json['sport'] ?? json['strSport'],
      country: json['country'] ?? json['strCountry'],
      league: json['league'] ?? json['strLeague'],
      description: json['description'] ?? json['strDescriptionEN'],
    );
  }
}

