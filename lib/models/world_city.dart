/// A city shown in the world clock, backed by an IANA time zone id.
class WorldCity {
  const WorldCity(this.name, this.country, this.timeZone);

  final String name;
  final String country;
  final String timeZone;

  String get key => '$name|$timeZone';

  Map<String, String> toJson() =>
      <String, String>{'name': name, 'country': country, 'tz': timeZone};

  factory WorldCity.fromJson(Map<String, dynamic> json) => WorldCity(
        json['name'] as String,
        (json['country'] as String?) ?? '',
        json['tz'] as String,
      );

  @override
  bool operator ==(Object other) => other is WorldCity && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

/// Hand-picked list of popular cities. Every other IANA zone is still
/// searchable from the city picker.
const List<WorldCity> kPopularCities = <WorldCity>[
  WorldCity('Abu Dhabi', 'United Arab Emirates', 'Asia/Dubai'),
  WorldCity('Accra', 'Ghana', 'Africa/Accra'),
  WorldCity('Addis Ababa', 'Ethiopia', 'Africa/Addis_Ababa'),
  WorldCity('Adelaide', 'Australia', 'Australia/Adelaide'),
  WorldCity('Amsterdam', 'Netherlands', 'Europe/Amsterdam'),
  WorldCity('Anchorage', 'United States', 'America/Anchorage'),
  WorldCity('Athens', 'Greece', 'Europe/Athens'),
  WorldCity('Auckland', 'New Zealand', 'Pacific/Auckland'),
  WorldCity('Baghdad', 'Iraq', 'Asia/Baghdad'),
  WorldCity('Bangkok', 'Thailand', 'Asia/Bangkok'),
  WorldCity('Barcelona', 'Spain', 'Europe/Madrid'),
  WorldCity('Beijing', 'China', 'Asia/Shanghai'),
  WorldCity('Bengaluru', 'India', 'Asia/Kolkata'),
  WorldCity('Berlin', 'Germany', 'Europe/Berlin'),
  WorldCity('Bogotá', 'Colombia', 'America/Bogota'),
  WorldCity('Boston', 'United States', 'America/New_York'),
  WorldCity('Brisbane', 'Australia', 'Australia/Brisbane'),
  WorldCity('Brussels', 'Belgium', 'Europe/Brussels'),
  WorldCity('Bucharest', 'Romania', 'Europe/Bucharest'),
  WorldCity('Budapest', 'Hungary', 'Europe/Budapest'),
  WorldCity('Buenos Aires', 'Argentina', 'America/Argentina/Buenos_Aires'),
  WorldCity('Cairo', 'Egypt', 'Africa/Cairo'),
  WorldCity('Cape Town', 'South Africa', 'Africa/Johannesburg'),
  WorldCity('Caracas', 'Venezuela', 'America/Caracas'),
  WorldCity('Casablanca', 'Morocco', 'Africa/Casablanca'),
  WorldCity('Chennai', 'India', 'Asia/Kolkata'),
  WorldCity('Chicago', 'United States', 'America/Chicago'),
  WorldCity('Colombo', 'Sri Lanka', 'Asia/Colombo'),
  WorldCity('Copenhagen', 'Denmark', 'Europe/Copenhagen'),
  WorldCity('Dallas', 'United States', 'America/Chicago'),
  WorldCity('Delhi', 'India', 'Asia/Kolkata'),
  WorldCity('Denver', 'United States', 'America/Denver'),
  WorldCity('Dhaka', 'Bangladesh', 'Asia/Dhaka'),
  WorldCity('Doha', 'Qatar', 'Asia/Qatar'),
  WorldCity('Dubai', 'United Arab Emirates', 'Asia/Dubai'),
  WorldCity('Dublin', 'Ireland', 'Europe/Dublin'),
  WorldCity('Edinburgh', 'United Kingdom', 'Europe/London'),
  WorldCity('Frankfurt', 'Germany', 'Europe/Berlin'),
  WorldCity('Geneva', 'Switzerland', 'Europe/Zurich'),
  WorldCity('Hanoi', 'Vietnam', 'Asia/Ho_Chi_Minh'),
  WorldCity('Helsinki', 'Finland', 'Europe/Helsinki'),
  WorldCity('Ho Chi Minh City', 'Vietnam', 'Asia/Ho_Chi_Minh'),
  WorldCity('Hong Kong', 'China', 'Asia/Hong_Kong'),
  WorldCity('Honolulu', 'United States', 'Pacific/Honolulu'),
  WorldCity('Houston', 'United States', 'America/Chicago'),
  WorldCity('Hyderabad', 'India', 'Asia/Kolkata'),
  WorldCity('Istanbul', 'Türkiye', 'Europe/Istanbul'),
  WorldCity('Jakarta', 'Indonesia', 'Asia/Jakarta'),
  WorldCity('Jeddah', 'Saudi Arabia', 'Asia/Riyadh'),
  WorldCity('Jerusalem', 'Israel', 'Asia/Jerusalem'),
  WorldCity('Johannesburg', 'South Africa', 'Africa/Johannesburg'),
  WorldCity('Kabul', 'Afghanistan', 'Asia/Kabul'),
  WorldCity('Karachi', 'Pakistan', 'Asia/Karachi'),
  WorldCity('Kathmandu', 'Nepal', 'Asia/Kathmandu'),
  WorldCity('Kolkata', 'India', 'Asia/Kolkata'),
  WorldCity('Kuala Lumpur', 'Malaysia', 'Asia/Kuala_Lumpur'),
  WorldCity('Kuwait City', 'Kuwait', 'Asia/Kuwait'),
  WorldCity('Kyiv', 'Ukraine', 'Europe/Kiev'),
  WorldCity('Lagos', 'Nigeria', 'Africa/Lagos'),
  WorldCity('Lahore', 'Pakistan', 'Asia/Karachi'),
  WorldCity('Las Vegas', 'United States', 'America/Los_Angeles'),
  WorldCity('Lima', 'Peru', 'America/Lima'),
  WorldCity('Lisbon', 'Portugal', 'Europe/Lisbon'),
  WorldCity('London', 'United Kingdom', 'Europe/London'),
  WorldCity('Los Angeles', 'United States', 'America/Los_Angeles'),
  WorldCity('Madrid', 'Spain', 'Europe/Madrid'),
  WorldCity('Manila', 'Philippines', 'Asia/Manila'),
  WorldCity('Melbourne', 'Australia', 'Australia/Melbourne'),
  WorldCity('Mexico City', 'Mexico', 'America/Mexico_City'),
  WorldCity('Miami', 'United States', 'America/New_York'),
  WorldCity('Milan', 'Italy', 'Europe/Rome'),
  WorldCity('Montreal', 'Canada', 'America/Toronto'),
  WorldCity('Moscow', 'Russia', 'Europe/Moscow'),
  WorldCity('Mumbai', 'India', 'Asia/Kolkata'),
  WorldCity('Munich', 'Germany', 'Europe/Berlin'),
  WorldCity('Muscat', 'Oman', 'Asia/Muscat'),
  WorldCity('Nairobi', 'Kenya', 'Africa/Nairobi'),
  WorldCity('New York', 'United States', 'America/New_York'),
  WorldCity('Osaka', 'Japan', 'Asia/Tokyo'),
  WorldCity('Oslo', 'Norway', 'Europe/Oslo'),
  WorldCity('Paris', 'France', 'Europe/Paris'),
  WorldCity('Perth', 'Australia', 'Australia/Perth'),
  WorldCity('Phoenix', 'United States', 'America/Phoenix'),
  WorldCity('Prague', 'Czechia', 'Europe/Prague'),
  WorldCity('Reykjavík', 'Iceland', 'Atlantic/Reykjavik'),
  WorldCity('Rio de Janeiro', 'Brazil', 'America/Sao_Paulo'),
  WorldCity('Riyadh', 'Saudi Arabia', 'Asia/Riyadh'),
  WorldCity('Rome', 'Italy', 'Europe/Rome'),
  WorldCity('San Francisco', 'United States', 'America/Los_Angeles'),
  WorldCity('Santiago', 'Chile', 'America/Santiago'),
  WorldCity('São Paulo', 'Brazil', 'America/Sao_Paulo'),
  WorldCity('Seattle', 'United States', 'America/Los_Angeles'),
  WorldCity('Seoul', 'South Korea', 'Asia/Seoul'),
  WorldCity('Shanghai', 'China', 'Asia/Shanghai'),
  WorldCity('Singapore', 'Singapore', 'Asia/Singapore'),
  WorldCity('Stockholm', 'Sweden', 'Europe/Stockholm'),
  WorldCity('Sydney', 'Australia', 'Australia/Sydney'),
  WorldCity('Taipei', 'Taiwan', 'Asia/Taipei'),
  WorldCity('Tehran', 'Iran', 'Asia/Tehran'),
  WorldCity('Tokyo', 'Japan', 'Asia/Tokyo'),
  WorldCity('Toronto', 'Canada', 'America/Toronto'),
  WorldCity('Vancouver', 'Canada', 'America/Vancouver'),
  WorldCity('Vienna', 'Austria', 'Europe/Vienna'),
  WorldCity('Warsaw', 'Poland', 'Europe/Warsaw'),
  WorldCity('Washington, D.C.', 'United States', 'America/New_York'),
  WorldCity('Wellington', 'New Zealand', 'Pacific/Auckland'),
  WorldCity('Yangon', 'Myanmar', 'Asia/Yangon'),
  WorldCity('Zurich', 'Switzerland', 'Europe/Zurich'),
];
