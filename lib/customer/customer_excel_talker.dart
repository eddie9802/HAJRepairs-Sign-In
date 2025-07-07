



import 'package:haj_repairs_sign_in/spreadsheet_utilities.dart';

class CustomerExcelTalker {



    // Takes all the customer data and uploads it to the customer data spreadsheet
  Future<bool> uploadCustomerData(Map<String, String> formData) async {

      // Creates the row to be inserted into customer details
      List<String>? newRow = [
                                          formData["Registration"]!,
                                          formData["Company"]!,
                                          formData["Reason For Visit"]!,
                                          formData["Name"]!,
                                          formData["Driver Number"]!.toString(),
                                          formData["Date"]!,
                                          formData["Sign in"]!,
                                          ];

      String? accessToken = await authenticateWithClientSecret();
      String fileName = "Customer-Reception.xlsx";
      final pathSegments = ['HAJ-Reception', 'Customer'];
      String? fileId = await getFileId(fileName, pathSegments, accessToken!);
      String tableId = "Signed_In";
      bool success = await appendRowToSpreadsheet(fileId: fileId!, tableId: tableId, accessToken: accessToken, row: newRow);

      // If upload was a success then return true else return false
      return success;
    }



    // Checks if the given customer is already signed in
  Future<bool> hasCustomerSignedIn(String customerReg) async {
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    String? accessToken = await authenticateWithClientSecret();
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    getFileId(fileName, pathSegments, accessToken);
    String worksheetId = "Signed-In";
    final rows = await readSpreadsheet(fileId!, worksheetId, accessToken);

    for (var row in rows!) {
      String reg = row[0].toString();
      if (reg == customerReg) {
        return true;
      } 
    }

    // Customer has not signed in
    return false;
  }

  // Signs the customer in
  Future<(bool, String)> signCustomerIn(Map<String, String> formData) async {
    (bool, String) response = (false, "");
    String registration = formData["Registration"]!;

    bool signedIn = await hasCustomerSignedIn(registration);

    if (!signedIn) {
      if (await uploadCustomerData(formData)) {
        response = (true, "Your vehicle has successfully been signed in");
      } else {
        response = (false, "Sign in failed");
      }
    } else {
      response = (false, "Vehicle has already been signed in");
    }


    return response;
  }
  
}