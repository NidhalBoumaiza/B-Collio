class Contact {
  final String id;
  final String name;
  final String email;
  final String? image;
  final String? phoneNumber;
  final bool isPhoneContact; // Add this field

  Contact({
    required this.id,
    required this.name,
    required this.email,
    this.image,
    this.phoneNumber,
    this.isPhoneContact = false,
  });

  // Convert a Contact object to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'image': image,
      'phoneNumber': phoneNumber,
      'isPhoneContact': isPhoneContact,
    };
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? '', // Provide a default value if null
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      image: json['image'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      isPhoneContact: json['isPhoneContact'] ?? false,
    );
  }
}
