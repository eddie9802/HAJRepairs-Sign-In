import 'package:haj_repairs_sign_in/supplier/supplierHAJ.dart';

import '../spreadsheet_utilities.dart';
import '../haj_response.dart';




class SupplierExcelTalker {


    // Takes all the customer data and uploads it to the customer data spreadsheet
  Future<HAJResponse> uploadSupplierData(Map<String, dynamic> formData) async {
    // Creates the row to be inserted into customer details
    List<String>? newRow = [
                                        formData["Name"]!,
                                        formData["Company"]!,
                                        formData["Reason For Visit"]!,
                                        formatDateMDY(formData["Date"]!),
                                        formData["Sign in"]!.toString(),
                                        ];


    HAJResponse? authenticateRes = await authenticateWithClientSecret();
    if (authenticateRes == null) {
      print("Failed to authenticate");
      return HAJResponse(statusCode: 500, message: "Failed to authenticate: An unknown error occurred");
    }
    
    if (authenticateRes.statusCode != 200) {
      print("Failed to authenticate: ${authenticateRes.message}");
      return authenticateRes;
    }
    String? accessToken = authenticateRes.body;

    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];

    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (fileIdResponse.statusCode != 200) {
      print("Could not find supplier file");
      return fileIdResponse;
    }
    String fileId = fileIdResponse.body;

    String tableId = "Signed_In";
    HAJResponse appendResponse = await appendRowToTable(fileId: fileId, tableId: tableId, accessToken: accessToken, row: newRow);

    // If upload was a success then return true else return false
    return appendResponse;
  }



  Future<HAJResponse> deleteSupplierData(int rowNumber) async {
    
    HAJResponse authenticateRes = (await authenticateWithClientSecret())!;
    if (authenticateRes.statusCode != 200) {
      print("${authenticateRes.message}");
      return authenticateRes;
    }
    String? accessToken = authenticateRes.body;
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (fileIdResponse.statusCode != 200) {
      print("Could not find supplier file");
      return fileIdResponse;
    }
    String? fileId = fileIdResponse.body;
    String tableId = "Signed_In";
    String? rowId = await getRowIdByNumber(fileId: fileId!, tableName: tableId, rowNumber: rowNumber, accessToken: accessToken);
    HAJResponse deleteResponse = await deleteTableRow(fileId: fileId, tableName: tableId, rowId: rowId!, accessToken: accessToken);

    if (deleteResponse.statusCode == 204) {
      String message = "Successfully deleted supplier data for row $rowNumber";
      print(message);
      return HAJResponse(statusCode: 200, message: message, body: true);
    } else {
      String message = "Failed to delete supplier data for row $rowNumber";
      print(message);
      return HAJResponse(statusCode: deleteResponse.statusCode, message: message, body: false);
    }
  }


    // Checks if the given customer is already signed in
  Future<HAJResponse> hasSupplierSignedIn(String supplierName, String supplierCompany, DateTime signInDate) async {
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];

    // Authenticates with the client secret to get an access token
    HAJResponse authenticateRes = (await authenticateWithClientSecret())!;
    if (authenticateRes.statusCode != 200) {
      print("Failed to authenticate: ${authenticateRes.message}");
      return authenticateRes;
    }
    String? accessToken = authenticateRes.body;

    // Gets the file ID of the supplier file
    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (fileIdResponse.statusCode != 200) {
      print("Could not find supplier file");
      return fileIdResponse;
    }
    String? fileId = fileIdResponse.body;
    
    String worksheetId = "Signed-In";
    HAJResponse spreadsheetResponse = await readSpreadsheet(fileId!, worksheetId, accessToken);
    if (spreadsheetResponse.statusCode != 200) {
      print("${spreadsheetResponse.message}");
      return spreadsheetResponse;
    }
    List<dynamic>? rows = spreadsheetResponse.body;


    for (var i = 1; i < rows!.length; i++) {
      var row = rows[i];
      String name = row[0].toString();
      String company = row[1].toString();
      DateTime rowSignInDate = excelDateToDateTime(row[3]);
      if (name.toLowerCase() == supplierName.toLowerCase() && company.toLowerCase() == supplierCompany.toLowerCase() && isSameDate(signInDate, rowSignInDate)) {
        return HAJResponse(statusCode: 409, message: "$supplierName from $supplierCompany is already signed in", body: true);
      } else if (name.toLowerCase() == supplierName.toLowerCase() && company.toLowerCase() == supplierCompany.toLowerCase()) {
        var rowNumber = i - 1; // Adjust for header row
        HAJResponse deleteSupplierRes = await deleteSupplierData(rowNumber);
        if (deleteSupplierRes.isSuccess) {
          print("Successfully deleted supplier data for row $rowNumber");
          break;
        } else {
          print("Failed to delete supplier data for row $rowNumber");
          return deleteSupplierRes;
        }
      }
    }

    // Customer has not signed in
    return HAJResponse(statusCode: 200, message: "Supplier not signed in", body: false);
  }


  // Signs the supplier in
  Future<HAJResponse> signSupplierIn(Map<String, dynamic> formData) async {
    String name = formData["Name"]!;
    String company = formData["Company"]!;

    HAJResponse supplierSignedInRes = await hasSupplierSignedIn(name, company, formData["Date"]!);

    if (!supplierSignedInRes.isSuccess) {
      return supplierSignedInRes;
    }
    bool signedIn = supplierSignedInRes.body;

    if (!signedIn) {
      HAJResponse uploadResponse = await uploadSupplierData(formData);
      if (uploadResponse.isSuccess) {
        return HAJResponse(statusCode: uploadResponse.statusCode, message: "Sign in successful");
      } else {
        return HAJResponse(statusCode: uploadResponse.statusCode, message: "Sign in failed");
      }
    } else {
      String message = "$name from $company is already signed in";
      print(message);
      return HAJResponse(statusCode: 409, message: message);
    }
  }


  // Returns a list of all the suppliers that are currently signed in
  Future<HAJResponse> retrieveSuppliers() async {
    HAJResponse? response = await authenticateWithClientSecret();

    if (response == null) {
      print("Failed to authenticate");
      return HAJResponse(statusCode: 500, message: "Failed to authenticate: An unknown error occurred");
    }

    if (!response.isSuccess) {
      print(response.message);
      return HAJResponse(statusCode: response.statusCode, message: response.message);
    }
    String? accessToken = response.body;

    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    
    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (!fileIdResponse.isSuccess) {
      print("Could not find supplier file");
      return HAJResponse(statusCode: 404, message: "Supplier file not found");
    }
    String fileId = fileIdResponse.body;
    String sheet = "Signed-In";

    // Reads the signed in suppliers sheet
    HAJResponse spreadsheetResponse = await readSpreadsheet(fileId, sheet, accessToken);
    if (!spreadsheetResponse.isSuccess) {
      print("Failed to read spreadsheet: ${spreadsheetResponse.message}");
      return HAJResponse(statusCode: 500, message: "Failed to read spreadsheet");
    }
    List<dynamic>? values = spreadsheetResponse.body;


    final List<SupplierHAJ> allSuppliers = [];
    HAJResponse result = new HAJResponse(statusCode: 200, message: "Successfully retrieved suppliers", body: allSuppliers);
    if (values == null || values.isEmpty) {
      print("No suppliers found");
    } else {

      // .skip(1) skips the header row
      for (var row in values.skip(1)) {
        String name = row[0].toString();
        String company = row[1].toString();
        String reasonForVisit = row[2].toString();
        double date = toDoubleSafe(row[3])!;
        String signIn = row[4].toString();

        // Creates a SupplierHAJ instance for each supplier
        allSuppliers.add(SupplierHAJ(
          name: name,
          company: company,
          reasonForVisit: reasonForVisit,
          date: excelDateToDateTime(date),
          signIn: signIn,
          signOut: ""
        ));
      }
    }
    return result;
  }



    Future<HAJResponse> writeToSignedOutSuppliers(SupplierHAJ supplier, String fileId, String tableId, String accessToken) async {
      // Creates the row to be inserted into customer details
      List<String>? newRow = [
                                          supplier.name,
                                          supplier.company,
                                          supplier.reasonForVisit,
                                          formatDateMDY(supplier.date),
                                          supplier.signIn,
                                          supplier.signOut,
                                          ];

      return await appendRowToTable(fileId: fileId, tableId: tableId, accessToken: accessToken, row: newRow);
  }




    // Writes the customer to the sign out sheet and remove them from the sign in
  Future<HAJResponse> signSupplierOut(SupplierHAJ supplier) async {
    HAJResponse response = (await authenticateWithClientSecret())!;
    if (response.statusCode != 200) {
      print("Failed to authenticate: ${response.message}");
      return response;
    }
    String? accessToken = response.body;
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    HAJResponse fileIdResponse = await getFileId(fileName, pathSegments, accessToken!);
    if (fileIdResponse.statusCode != 200) {
      print("Could not find supplier file");
      return fileIdResponse;
    }
    String fileId = fileIdResponse.body;
    String signedInTable = "Signed_In";
    String signedOutTable = "Signed_Out";
    HAJResponse writeToSignedOutRes = await writeToSignedOutSuppliers(supplier, fileId, signedOutTable, accessToken);

    bool successfullyWritten = writeToSignedOutRes.statusCode == 200;

    if (successfullyWritten) {
      String? rowId = await getRowId(fileId: fileId, tableName: signedInTable, identifier: supplier.name, accessToken: accessToken);

      if (rowId != null) {
        HAJResponse deleteResponse = await deleteTableRow(fileId: fileId, tableName: signedOutTable, rowId: rowId, accessToken: accessToken);
        bool deleteSuccessful = deleteResponse.statusCode == 204;

        if (deleteSuccessful) {
          return HAJResponse(statusCode: 200, message: "Sign out successful", body: true);
        } else {
          return HAJResponse(statusCode: 500, message: "Failed to delete the supplier row from sign-in sheet", body: false);
        }
      } else {
        return HAJResponse(statusCode: 404, message: "Failed to find supplier in sign-in sheet", body: false);
      }
    } else {
      return HAJResponse(statusCode: 500, message: "Failed to write supplier details to sign-out sheet", body: false);
    }
  }
}


