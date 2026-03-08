class User {
  final int id;
  final String username;
  final String namaLengkap;
  final String jabatan;
  final String? email;

  User({
    required this.id,
    required this.username,
    required this.namaLengkap,
    required this.jabatan,
    this.email,
  });

  /// Returns true for roles with full TPQ management access.
  /// Both 'Developer' and 'Pimpinan TPQ' qualify.
  bool get isFullAccess =>
      jabatan == 'Developer' || jabatan == 'Pimpinan TPQ';

  /// Returns true only for the Developer super-admin role.
  bool get isDeveloper => jabatan == 'Developer';

  /// Returns true if user has at least Pimpinan-level access.
  bool get isPimpinanOrAbove => isFullAccess;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? '',
      namaLengkap: json['nama_lengkap'] ?? '',
      jabatan: json['jabatan'] ?? '',
      email: json['email'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'nama_lengkap': namaLengkap,
        'jabatan': jabatan,
        'email': email,
      };
}
