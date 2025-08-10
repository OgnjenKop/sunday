class UserPreferences {
  int clothingLevel;
  int skinType;
  int userAge;
  DateTime createdAt;
  DateTime updatedAt;

  UserPreferences({
    this.clothingLevel = 1,
    this.skinType = 3,
    this.userAge = 30,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      clothingLevel: json['clothingLevel'],
      skinType: json['skinType'],
      userAge: json['userAge'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'clothingLevel': clothingLevel,
      'skinType': skinType,
      'userAge': userAge,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class VitaminDSession {
  DateTime startTime;
  DateTime? endTime;
  double totalIU;
  double averageUV;
  double peakUV;
  int clothingLevel;
  int skinType;

  VitaminDSession({
    required this.startTime,
    this.endTime,
    this.totalIU = 0,
    this.averageUV = 0,
    this.peakUV = 0,
    required this.clothingLevel,
    required this.skinType,
  });

  factory VitaminDSession.fromJson(Map<String, dynamic> json) {
    return VitaminDSession(
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      totalIU: json['totalIU'],
      averageUV: json['averageUV'],
      peakUV: json['peakUV'],
      clothingLevel: json['clothingLevel'],
      skinType: json['skinType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalIU': totalIU,
      'averageUV': averageUV,
      'peakUV': peakUV,
      'clothingLevel': clothingLevel,
      'skinType': skinType,
    };
  }
}

class CachedUVData {
  double latitude;
  double longitude;
  DateTime date;
  List<double> hourlyUV;
  List<double> hourlyCloudCover;
  double maxUV;
  DateTime sunrise;
  DateTime sunset;
  DateTime lastUpdated;

  CachedUVData({
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.hourlyUV,
    required this.hourlyCloudCover,
    required this.maxUV,
    required this.sunrise,
    required this.sunset,
    required this.lastUpdated,
  });

  factory CachedUVData.fromJson(Map<String, dynamic> json) {
    return CachedUVData(
      latitude: json['latitude'],
      longitude: json['longitude'],
      date: DateTime.parse(json['date']),
      hourlyUV: List<double>.from(json['hourlyUV']),
      hourlyCloudCover: List<double>.from(json['hourlyCloudCover']),
      maxUV: json['maxUV'],
      sunrise: DateTime.parse(json['sunrise']),
      sunset: DateTime.parse(json['sunset']),
      lastUpdated: DateTime.parse(json['lastUpdated']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'date': date.toIso8601String(),
      'hourlyUV': hourlyUV,
      'hourlyCloudCover': hourlyCloudCover,
      'maxUV': maxUV,
      'sunrise': sunrise.toIso8601String(),
      'sunset': sunset.toIso8601String(),
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}
