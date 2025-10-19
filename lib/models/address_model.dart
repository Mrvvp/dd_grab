class Address {
  final int id;
  final String firstName;
  final String lastName;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String zip;
  final String country;
  final bool isDefault;

  Address({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    required this.isDefault,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'],
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      zip: json['zip'] ?? '',
      country: json['country'] ?? '',
      isDefault: json['isDefault'] ?? false,
    );
  }
}
