



class Employee {
  final String forename;
  final String surname;
  String? lastSigningTime;
  List<String> signings = [];

  Employee({required this.forename, required this.surname});


  String getFullName() {
    return '$forename $surname';
  }
}