class CustomerHAJ {
  final String registration;
  final String company;
  final String signInDriverName;
  final String signInDriverNumber;
  final String reasonForVisit;
  final String signInDate;
  final String signIn;
  String signOutDate;
  String signOutDriverName;
  String signOutDriverNumber;
  String signOut;



  CustomerHAJ({
    required this.registration,
    required this.company,
    required this.signInDriverName,
    required this.signInDriverNumber,
    required this.signOutDriverName,
    required this.signOutDriverNumber,
    required this.reasonForVisit,
    required this.signInDate,
    required this.signOutDate,
    required this.signIn,
    required this.signOut
    });
}