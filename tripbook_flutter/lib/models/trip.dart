class Trip {
  final int id;
  final String tripCode;
  final String? urlToken;
  final String name;
  final String? description;
  final String currencySymbol;
  final String role;

  Trip({
    required this.id,
    required this.tripCode,
    this.urlToken,
    required this.name,
    this.description,
    required this.currencySymbol,
    required this.role,
  });

  String get title => name;
  String get destination => description ?? '';

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      tripCode: json['trip_code'] ?? '',
      urlToken: json['url_token'],
      name: json['name'] ?? json['title'] ?? 'Trip',
      description: json['description'] ?? json['destination'],
      currencySymbol: json['currency_symbol'] ?? '₹',
      role: json['role'] ?? 'member',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trip_code': tripCode,
      'url_token': urlToken,
      'name': name,
      'description': description,
      'currency_symbol': currencySymbol,
      'role': role,
    };
  }
}
