import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sportify_app/models/sport_model.dart';
import 'package:sportify_app/models/team_model.dart';
import 'package:sportify_app/utils/logger.dart';

/// Service to fetch sports and teams data from TheSportsDB API
/// Applies Single Responsibility Principle (SRP) - handles only sports API calls
class SportsApiService {
  static const String _baseUrl = 'https://www.thesportsdb.com/api/v1/json';
  static const String _apiKey = '3'; // Free tier API key

  /// Fetches top 5 sports: Football, Cricket, Basketball, F1, Rugby
  Future<List<Sport>> getTopSports({int limit = 5}) async {
    // Return the specific 5 sports requested
    return _getTop5Sports();
  }

  /// Returns the top 5 sports with their API-compatible names
  List<Sport> _getTop5Sports() {
    return [
      Sport(
        id: '1',
        name: 'Football',
        logoUrl: 'https://www.thesportsdb.com/images/sports/soccer.jpg',
      ),
      Sport(
        id: '2',
        name: 'Cricket',
        logoUrl: 'https://www.thesportsdb.com/images/sports/cricket.jpg',
      ),
      Sport(
        id: '3',
        name: 'Basketball',
        logoUrl: 'https://www.thesportsdb.com/images/sports/basketball.jpg',
      ),
      Sport(
        id: '4',
        name: 'F1',
        logoUrl: 'https://www.thesportsdb.com/images/sports/motorsport.jpg',
      ),
      Sport(
        id: '5',
        name: 'Rugby',
        logoUrl: 'https://www.thesportsdb.com/images/sports/rugby.jpg',
      ),
    ];
  }

  /// Fetches top teams for a specific sport
  /// Maps display names to API-compatible names
  Future<List<Team>> getTopTeamsBySport(String sportName, {int limit = 5}) async {
    // Map display names to API-compatible names
    String apiSportName = _mapSportNameToApi(sportName);
    
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiKey/search_all_teams.php?s=$apiSportName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> teamsList = data['teams'] ?? [];
        
        // Filter and take top teams
        final teams = teamsList
            .take(limit)
            .map((team) => Team.fromJson(team))
            .toList();
        
        Logger.info('Fetched ${teams.length} teams for $sportName (API: $apiSportName)', tag: 'SportsApiService');
        
        // If no teams found, try alternative API endpoints
        if (teams.isEmpty) {
          return await _getFallbackTeams(sportName, limit);
        }
        
        return teams;
      } else {
        Logger.error('Failed to fetch teams: ${response.statusCode}', tag: 'SportsApiService');
        return await _getFallbackTeams(sportName, limit);
      }
    } catch (e) {
      Logger.error('Error fetching teams for $sportName', error: e, tag: 'SportsApiService');
      return await _getFallbackTeams(sportName, limit);
    }
  }

  /// Maps display sport names to API-compatible names
  String _mapSportNameToApi(String displayName) {
    switch (displayName.toLowerCase()) {
      case 'football':
        return 'Soccer'; // TheSportsDB uses "Soccer" for football
      case 'cricket':
        return 'Cricket';
      case 'basketball':
        return 'Basketball';
      case 'f1':
      case 'formula 1':
      case 'formula1':
        return 'Motorsport'; // TheSportsDB uses "Motorsport" for F1
      case 'rugby':
        return 'Rugby';
      default:
        return displayName;
    }
  }

  /// Fallback teams if API doesn't return results
  Future<List<Team>> _getFallbackTeams(String sportName, int limit) async {
    // Try alternative endpoints or return default teams
    final defaultTeams = _getDefaultTeamsForSport(sportName);
    if (defaultTeams.isNotEmpty) {
      return defaultTeams.take(limit).toList();
    }
    return [];
  }

  /// Default teams for each sport (fallback)
  List<Team> _getDefaultTeamsForSport(String sportName) {
    switch (sportName.toLowerCase()) {
      case 'football':
        return [
          Team(id: '1', name: 'Real Madrid', sport: 'Football', country: 'Spain'),
          Team(id: '2', name: 'FC Barcelona', sport: 'Football', country: 'Spain'),
          Team(id: '3', name: 'Manchester United', sport: 'Football', country: 'England'),
          Team(id: '4', name: 'Liverpool', sport: 'Football', country: 'England'),
          Team(id: '5', name: 'Bayern Munich', sport: 'Football', country: 'Germany'),
        ];
      case 'cricket':
        return [
          Team(id: '1', name: 'India', sport: 'Cricket', country: 'India'),
          Team(id: '2', name: 'Australia', sport: 'Cricket', country: 'Australia'),
          Team(id: '3', name: 'England', sport: 'Cricket', country: 'England'),
          Team(id: '4', name: 'Pakistan', sport: 'Cricket', country: 'Pakistan'),
          Team(id: '5', name: 'New Zealand', sport: 'Cricket', country: 'New Zealand'),
        ];
      case 'basketball':
        return [
          Team(id: '1', name: 'Los Angeles Lakers', sport: 'Basketball', country: 'USA'),
          Team(id: '2', name: 'Chicago Bulls', sport: 'Basketball', country: 'USA'),
          Team(id: '3', name: 'Boston Celtics', sport: 'Basketball', country: 'USA'),
          Team(id: '4', name: 'Golden State Warriors', sport: 'Basketball', country: 'USA'),
          Team(id: '5', name: 'Miami Heat', sport: 'Basketball', country: 'USA'),
        ];
      case 'f1':
        return [
          Team(id: '1', name: 'Red Bull Racing', sport: 'F1', country: 'Austria'),
          Team(id: '2', name: 'Mercedes', sport: 'F1', country: 'Germany'),
          Team(id: '3', name: 'Ferrari', sport: 'F1', country: 'Italy'),
          Team(id: '4', name: 'McLaren', sport: 'F1', country: 'UK'),
          Team(id: '5', name: 'Aston Martin', sport: 'F1', country: 'UK'),
        ];
      case 'rugby':
        return [
          Team(id: '1', name: 'New Zealand All Blacks', sport: 'Rugby', country: 'New Zealand'),
          Team(id: '2', name: 'South Africa Springboks', sport: 'Rugby', country: 'South Africa'),
          Team(id: '3', name: 'England', sport: 'Rugby', country: 'England'),
          Team(id: '4', name: 'Australia Wallabies', sport: 'Rugby', country: 'Australia'),
          Team(id: '5', name: 'Ireland', sport: 'Rugby', country: 'Ireland'),
        ];
      default:
        return [];
    }
  }

  /// Fetches team details by team name (for favorite teams)
  Future<Team?> getTeamByName(String teamName) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$_apiKey/searchteams.php?t=$teamName'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> teamsList = data['teams'] ?? [];
        
        if (teamsList.isNotEmpty) {
          return Team.fromJson(teamsList[0]);
        }
      }
      return null;
    } catch (e) {
      Logger.error('Error fetching team: $teamName', error: e, tag: 'SportsApiService');
      return null;
    }
  }

}

