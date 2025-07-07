



import 'package:haj_repairs_sign_in/spreadsheet_utilities.dart';
import 'customerHAJ.dart';

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
      bool success = await appendRowToTable(fileId: fileId!, tableId: tableId, accessToken: accessToken, row: newRow);

      // If upload was a success then return true else return false
      return success;
    }


    // Returns a list of all the customers that are currently signed in
  Future<List<CustomerHAJ>> retrieveCustomers() async {
    String? accessToken = await authenticateWithClientSecret();
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
        String signInDate = row[5].toString();
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
          signOutDate: "",
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


  Future<bool> writeToSignedOutCustomers(CustomerHAJ customer) async {
    // Creates the row to be inserted into customer details
    List<String>? newRow = [
                            customer.registration,
                            customer.company,
                            customer.reasonForVisit,
                            customer.signInDriverName,
                            customer.signInDriverNumber,
                            customer.signInDate,
                            customer.signIn,
                            customer.signOutDriverName,
                            customer.signOutDriverNumber,
                            customer.signOutDate,
                            customer.signOut
                            ];


    String? accessToken = await authenticateWithClientSecret();
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String tableId = "Signed_Out";
    bool success = await appendRowToTable(fileId: fileId!, tableId: tableId, accessToken: accessToken, row: newRow);

    // If upload was a success then return true else return false
    return success;
  }

  // Gets the row number the given customer is on
  Future<int?> getCustomerRowNum(CustomerHAJ customer) async {
    String? accessToken = await authenticateWithClientSecret();
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String sheet = "Signed-Out";
    List<dynamic>? rows = await readSpreadsheet(fileId!, sheet, accessToken);

    if (rows == null || rows.isEmpty) {
      print("No customers found");
      return null;
    } else {

      int? customerRowIndex;
      for (var i = 1; i < rows.length; i++) {
        var customerDetailsList = rows[i];
        String registration = customerDetailsList[0].toString();
        if (customer.registration == registration) {
          customerRowIndex = i;
          break;
        }
      }
      return customerRowIndex;
    }
  }



  Future<bool> deleteRowfromSignedIn(int rowNumber) async {
    String? accessToken = await authenticateWithClientSecret();
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String tableId = "Signed_In";
    return deleteTableRow(fileId: fileId!, tableName: tableId, rowIndex: rowNumber, accessToken: accessToken);
}


  // Writes the customer to the sign out sheet and remove them from the sign in
  Future<(bool, String)> signCustomerOut(CustomerHAJ customer) async {
    bool successfullyWritten = await writeToSignedOutCustomers(customer);
    (bool, String) response = (false, "");

    if (successfullyWritten) {
      int? customerRowNum = await getCustomerRowNum(customer);

      if (customerRowNum != null) {
        bool rowDeleted = await deleteRowfromSignedIn(customerRowNum);

        if (rowDeleted) {
          response = (true, "Your vehicle has successfully been signed out");
        } else {
          response = (false, "Failed to delete the customer row from sign-in sheet");
        }
      } else {
        response = (false, "Failed to find vehicle in sign-in sheet");
      }
    } else {
      response = (false, "Failed to write customer details to sign-out sheet");
    }

  return response;
  }
  
}