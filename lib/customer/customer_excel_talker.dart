import 'package:haj_repairs_sign_in/spreadsheet_utilities.dart';
import 'customerHAJ.dart';
import '../haj_response.dart';

class CustomerExcelTalker {



    // Takes all the customer data and uploads it to the customer data spreadsheet
  Future<HAJResponse> uploadCustomerData(Map<String, String> formData) async {

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

      HAJResponse? response = await authenticateWithClientSecret();
      if (response == null) {
        return HAJResponse(statusCode: 500, message: "An unknown error has occurred");
      }

      if (response.statusCode != 200) {
        print("${response.message}");
        return response;
      }
      String? accessToken = response.body;
      String fileName = "Customer-Reception.xlsx";
      final pathSegments = ['HAJ-Reception', 'Customer'];
      HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
      if (fileIdResponse.statusCode != 200) {
        print("Could not find customer file");
        return fileIdResponse;
      }
      String fileId = fileIdResponse.body;
      String tableId = "Signed_In";
      HAJResponse appendResponse = await appendRowToTable(fileId: fileId, tableId: tableId, accessToken: accessToken, row: newRow);

      // If upload was a success then return true else return false
      return HAJResponse(statusCode: appendResponse.statusCode, message: appendResponse.message);
    }


  // Returns a list of all the customers that are currently signed in
  Future<HAJResponse> retrieveCustomers() async {
    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return response;
    }
    String? accessToken = response.body;
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    String fileId = fileIdResponse.body;
    String sheet = "Signed-In";

    // Reads the spreadsheet and returns a list of customers
    HAJResponse spreadsheetResponse = await readSpreadsheet(fileId, sheet, accessToken);
    if (spreadsheetResponse.statusCode != 200) {
      print("Failed to read spreadsheet: ${spreadsheetResponse.message}");
      return spreadsheetResponse;
    }
    List<dynamic>? values = spreadsheetResponse.body;


    final List<CustomerHAJ> allCustomers = [];
    HAJResponse result = HAJResponse(statusCode: 200, message: 'Success', body: allCustomers);
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
    return result;
  }



    // Checks if the given customer is already signed in
  Future<HAJResponse> hasCustomerSignedIn(String customerReg) async {
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];

    // Authenticates with the client secret
    HAJResponse? response = await authenticateWithClientSecret();

    if (response == null) {
      return HAJResponse(statusCode: 500, message: "An unknown error has occurred");
    }

    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return response;
    }
    String? accessToken = response.body;

    // Gets the file id of the customer reception file
    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (fileIdResponse.statusCode != 200) {
      print("Could not find customer file");
      return fileIdResponse;
    }
    String fileId = fileIdResponse.body;

    // Reads the signed in customers sheet
    String worksheetId = "Signed-In";
    HAJResponse spreadsheetResponse = await readSpreadsheet(fileId, worksheetId, accessToken);

    if (spreadsheetResponse.statusCode != 200) {
      print("Failed to read spreadsheet: ${spreadsheetResponse.message}");
      return spreadsheetResponse;
    }

    List<dynamic>? rows = spreadsheetResponse.body;
    HAJResponse result = new HAJResponse(statusCode: 200, message: 'Success', body: false);

    for (var row in rows!) {
      String reg = row[0].toString();
      if (reg == customerReg) {
        result.body = true;
      } 
    }

    // Customer has not signed in
    return result;
  }

  Future<HAJResponse> signCustomerIn(Map<String, String> formData) async {
    final String? registration = formData["Registration"];

    if (registration == null || registration.trim().isEmpty) {
      return HAJResponse(
        statusCode: 400,
        message: "Missing or invalid registration number",
      );
    }

    try {
      final HAJResponse signedInResponse = await hasCustomerSignedIn(registration);

      if (!signedInResponse.isSuccess) {
        return signedInResponse;
      }

      final bool signedIn = signedInResponse.body;

      if (signedIn) {
        return HAJResponse(
          statusCode: 200,
          message: "Customer is already signed in",
        );
      }

      HAJResponse uploadResponse = await uploadCustomerData(formData);
      if (!uploadResponse.isSuccess) {
        return HAJResponse(
          statusCode: uploadResponse.statusCode,
          message: uploadResponse.message,
        );
      } else {
        return HAJResponse(
          statusCode: uploadResponse.statusCode,
          message: "Sign in successful",
        );
      }

    } catch (e) {
      return HAJResponse(
        statusCode: 500,
        message: "Unexpected error: $e",
      );
    }
  }



  Future<HAJResponse> writeToSignedOutCustomers(CustomerHAJ customer, String fileId, String tableId, String accessToken) async {
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


    return await appendRowToTable(fileId: fileId, tableId: tableId, accessToken: accessToken, row: newRow);
  }


  Future<HAJResponse> deleteRowfromSignedIn(String rowId, fileId, ) async {
    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return HAJResponse(statusCode: 500, message: "Failed to authenticate");
    }
    String? accessToken = response.body;
    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];
    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (fileIdResponse.statusCode != 200) {
      print("Could not find customer file");
      return HAJResponse(statusCode: 404, message: "Customer file not found");
    }
    String tableId = "Signed_In";
    String fileId = fileIdResponse.body;
    return deleteTableRow(fileId: fileId, tableName: tableId, rowId: rowId, accessToken: accessToken);
}


  // Writes the customer to the sign out sheet and remove them from the sign in
  Future<HAJResponse> signCustomerOut(CustomerHAJ customer) async {

    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return response;
    }
    String? accessToken = response.body;


    String fileName = "Customer-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Customer'];


    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (fileIdResponse.statusCode != 200) {
      print("Could not find customer file");
      return fileIdResponse;
    }
    String fileId = fileIdResponse.body;

    String signedInTable = "Signed_In";
    String signedOutTable = "Signed_Out";
    HAJResponse appendResponse = await writeToSignedOutCustomers(customer, fileId, signedOutTable, accessToken);

    if (appendResponse.isSuccess) {
      String? rowId = await getRowId(fileId: fileId, tableName: signedInTable, identifier: customer.registration, accessToken: accessToken);
      if (rowId != null) {
        HAJResponse deleteResponse = await deleteTableRow(fileId: fileId, tableName: signedOutTable, rowId: rowId, accessToken: accessToken);

        if (deleteResponse.isSuccess) {
          return HAJResponse(statusCode: deleteResponse.statusCode, message: "Sign out successful");
        } else {
          return HAJResponse(statusCode: deleteResponse.statusCode, message: "Failed to delete customer from sign-in sheet");
        }

      } else {
        return HAJResponse(statusCode: 404, message: "Failed to find vehicle in sign-in sheet");
      }
    } else {
      return HAJResponse(statusCode: 500, message: "Failed to write customer details to sign-out sheet");
    }
  }
  
}