



class Colleague {
  final String forename;
  final String surname;
  String? lastSigningTime;
  List<String> signings = [];

  Colleague({required this.forename, required this.surname});


  String getFullName() {
    return '$forename $surname';
  }
}