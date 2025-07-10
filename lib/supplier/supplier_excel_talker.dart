import 'package:haj_repairs_sign_in/supplier/supplierHAJ.dart';

import '../spreadsheet_utilities.dart';




class SupplierExcelTalker {


    // Takes all the customer data and uploads it to the customer data spreadsheet
  Future<bool> uploadSupplierData(Map<String, String> formData) async {
    // Creates the row to be inserted into customer details
    List<String>? newRow = [
                                        formData["Name"]!,
                                        formData["Company"]!,
                                        formData["Reason For Visit"]!,
                                        formData["Date"]!,
                                        formData["Sign in"]!.toString(),
                                        ];


    String? accessToken = await authenticateWithClientSecret();
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String tableId = "Signed_In";
    bool isSuccess = await appendRowToTable(fileId: fileId!, tableId: tableId, accessToken: accessToken, row: newRow);

    // If upload was a success then return true else return false
    return isSuccess;
  }



  void deleteSupplierData(int rowNumber) async {
    String? accessToken = await authenticateWithClientSecret();
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String tableId = "Signed_In";
    print("Row number: $rowNumber");
    String? rowId = await getRowIdByNumber(fileId: fileId!, tableName: tableId, rowNumber: rowNumber, accessToken: accessToken);
    print("Row ID: $rowId");
    bool isSuccess = await deleteTableRow(fileId: fileId, tableName: tableId, rowId: rowId!, accessToken: accessToken);

    if (isSuccess) {
      print("Successfully deleted supplier data for row $rowNumber");
    } else {
      print("Failed to delete supplier data for row $rowNumber");

    }
  }


    // Checks if the given customer is already signed in
  Future<bool> hasSupplierSignedIn(String supplierName, String supplierCompany, String signInDate) async {
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    String? accessToken = await authenticateWithClientSecret();
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String worksheetId = "Signed-In";
    final rows = await readSpreadsheet(fileId!, worksheetId, accessToken);

    for (var i = 1; i < rows!.length; i++) {
      var row = rows[i];
      String name = row[0].toString();
      String company = row[1].toString();
      String rowSignInDate = excelDateToDateTimeStr(toDoubleSafe(row[3])!);
      if (name.toLowerCase() == supplierName.toLowerCase() && company.toLowerCase() == supplierCompany.toLowerCase() && rowSignInDate == signInDate) {
        return true;
      } else if (name.toLowerCase() == supplierName.toLowerCase() && company.toLowerCase() == supplierCompany.toLowerCase()) {
        var rowNumber = i - 1; // Adjust for header row
        deleteSupplierData(rowNumber);
        break;
      }
    }

    // Customer has not signed in
    return false;
  }


  // Signs the supplier in
  Future<(bool, String)> signSupplierIn(Map<String, String> formData) async {
    (bool, String) response = (false, "");
    String name = formData["Name"]!;
    String company = formData["Company"]!;

    bool signedIn = await hasSupplierSignedIn(name, company, formData["Date"]!);

    if (!signedIn) {
      if (await uploadSupplierData(formData)) {
        response = (true, "Sign in successful");
      } else {
        response = (false, "Sign in failed");
      }
    } else {
      response = (false, "${formData["Name"]} from ${formData["Company"]} is already signed in");
    }


    return response;
  }


  // Returns a list of all the suppliers that are currently signed in
  Future<List<SupplierHAJ>> retrieveSuppliers() async {
    String? accessToken = await authenticateWithClientSecret();
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String sheet = "Signed-In";
    final values = await readSpreadsheet(fileId!, sheet, accessToken);
    final List<SupplierHAJ> allSuppliers = [];
    if (values == null || values.isEmpty) {
      print("No suppliers found");
    } else {

      // .skip(1) skips the header row
      for (var row in values.skip(1)) {
        String name = row[0].toString();
        String company = row[1].toString();
        String reasonForVisit = row[2].toString();
        String date = row[3].toString();
        String signIn = row[4].toString();

        // Creates a SupplierHAJ instance for each supplier
        allSuppliers.add(SupplierHAJ(
          name: name,
          company: company,
          reasonForVisit: reasonForVisit,
          date: date,
          signIn: signIn,
          signOut: ""
        ));
      }
    }
    return allSuppliers;
  }



    Future<bool> writeToSignedOutSuppliers(SupplierHAJ supplier, String fileId, String tableId, String accessToken) async {
      // Creates the row to be inserted into customer details
      List<String>? newRow = [
                                          supplier.name,
                                          supplier.company,
                                          supplier.reasonForVisit,
                                          supplier.date,
                                          supplier.signIn,
                                          supplier.signOut,
                                          ];

      bool success = await appendRowToTable(fileId: fileId, tableId: tableId, accessToken: accessToken, row: newRow);
      return success;
  }




    // Writes the customer to the sign out sheet and remove them from the sign in
  Future<(bool, String)> signSupplierOut(SupplierHAJ supplier) async {
    String? accessToken = await authenticateWithClientSecret();
    String fileName = "Supplier-Reception.xlsx";
    final pathSegments = ['HAJ-Reception', 'Supplier'];
    String? fileId = await getFileId(fileName, pathSegments, accessToken!);
    String signedInTable = "Signed_In";
    String signedOutTable = "Signed_Out";
    bool successfullyWritten = await writeToSignedOutSuppliers(supplier, fileId!, signedOutTable, accessToken);
    (bool, String) response = (false, "");

    if (successfullyWritten) {
      String? rowId = await getRowId(fileId: fileId, tableName: signedInTable, identifier: supplier.name, accessToken: accessToken);

      if (rowId != null) {
        bool rowDeleted = await deleteTableRow(fileId: fileId, tableName: signedOutTable, rowId: rowId, accessToken: accessToken);

        if (rowDeleted) {
          response = (true, "Sign out successful");
        } else {
          response = (false, "Failed to delete the supplier row from sign-in sheet");
        }
      } else {
        response = (false, "Failed to find supplier in sign-in sheet");
      }
    } else {
      response = (false, "Failed to write supplier details to sign-out sheet");
    }

  return response;
  }
}


