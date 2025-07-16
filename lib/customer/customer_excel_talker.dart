import 'package:haj_repairs_sign_in/spreadsheet_utilities.dart';
import 'customerHAJ.dart';
import '../haj_response.dart';

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

      HAJResponse response = (await authenticateWithClientSecret())!;
      if (response.statusCode != 200) {
        print("Failed to authenticate: ${response.message}");
        return false;
      }
      String? accessToken = response.body;
      String fileName = "Customer-Reception.xlsx";
      final pathSegments = ['HAJ-Reception', 'Customer'];
      String? fileId = await getFileId(fileName, pathSegments, accessToken!);
      String tableId = "Signed_In";
      bool success = await appendRowToTable(fileId: fileId!, tableId: tableId, accessToken: accessToken, row: newRow);

      // If upload was a success then return true else return false
      return success;
    }


  // Returns a list of all the customers that are currently signed in
  Future<List<CustomerHAJ>> retrieveCustomers() async {
    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return [];
    }
    String? accessToken = response.body;
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String sheet = "Signed-In";
    final values = await readSpreadsheet(fileId!, sheet, accessToken);
    final List<CustomerHAJ> allCustomers = [];
    if (values == null || values.isEmpty) {
      print("No customers found");
    } else {

      // .skip(1) skips the header row
      for (var row in values.skip(1)) {
        String registration = row[0].toString();
        String company = row[1].toString();
        String reasonForVisit = row[2].toString();
        String signInDriverName = row[3].toString();
        String signInDriverNumber = row[4].toString();
        DateTime signInDate = excelDateToDateTime(toDoubleSafe(row[5])!);
        String signIn = row[6].toString();

        // Creates a CustomerHAJ instance for each customer
        allCustomers.add(CustomerHAJ(
          registration: registration,
          company: company,
          reasonForVisit: reasonForVisit,
          signInDriverName: signInDriverName,
          signInDriverNumber: signInDriverNumber,
          signOutDriverName: "",
          signOutDriverNumber: "",
          signInDate: signInDate,
          signOutDate: null,
          signIn: signIn,
          signOut: ""
        ));
      }
    }
    return allCustomers;
  }



    // Checks if the given customer is already signed in
  Future<bool> hasCustomerSignedIn(String customerReg) async {
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return false;
    }
    String? accessToken = response.body;
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


  Future<bool> writeToSignedOutCustomers(CustomerHAJ customer, String fileId, String tableId, String accessToken) async {
    // Creates the row to be inserted into customer details
    List<String>? newRow = [
                            customer.registration,
                            customer.company,
                            customer.reasonForVisit,
                            customer.signInDriverName,
                            customer.signInDriverNumber,
                            formatDateMDY(customer.signInDate),
                            customer.signIn,
                            customer.signOutDriverName,
                            customer.signOutDriverNumber,
                            formatDateMDY(customer.signOutDate!),
                            customer.signOut
                            ];


    bool success = await appendRowToTable(fileId: fileId, tableId: tableId, accessToken: accessToken, row: newRow);

    // If upload was a success then return true else return false
    return success;
  }


  Future<bool> deleteRowfromSignedIn(String rowId, fileId, ) async {
    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return false;
    }
    String? accessToken = response.body;
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String tableId = "Signed_In";
    return deleteTableRow(fileId: fileId!, tableName: tableId, rowId: rowId, accessToken: accessToken);
}


  // Writes the customer to the sign out sheet and remove them from the sign in
  Future<(bool, String)> signCustomerOut(CustomerHAJ customer) async {
    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return (false, "Authentication failed");
    }
    String? accessToken = response.body;
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String signedInTable = "Signed_In";
    String signedOutTable = "Signed_Out";
    bool successfullyWritten = await writeToSignedOutCustomers(customer, fileId!, signedOutTable, accessToken);
    (bool, String) res = (false, "");

    if (successfullyWritten) {
      String? rowId = await getRowId(fileId: fileId, tableName: signedInTable, identifier: customer.registration, accessToken: accessToken);
      if (rowId != null) {
        bool rowDeleted = await deleteTableRow(fileId: fileId, tableName: signedOutTable, rowId: rowId, accessToken: accessToken);

        if (rowDeleted) {
          res = (true, "Your vehicle has successfully been signed out");
        } else {
          res = (false, "Failed to delete the customer row from sign-in sheet");
        }
      } else {
        res = (false, "Failed to find vehicle in sign-in sheet");
      }
    } else {
      res = (false, "Failed to write customer details to sign-out sheet");
    }

  return res;
  }
  
}