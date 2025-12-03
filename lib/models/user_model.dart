class User {
  final String id;
  final String name;
  final String avatar;
  final String phone;
  final String bio;
  final String location;
  final int itemsListed;
  final double rating;

  User({
    required this.id,
    required this.name,
    required this.avatar,
    required this.phone,
    required this.bio,
    required this.location,
    this.itemsListed = 0,
    this.rating = 4.5,
  });
}
