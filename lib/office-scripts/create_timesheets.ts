const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];

interface ShiftRecord {
    Forename: string;
    Surname: string;
    "Shift Start": string;
    "Shift End": string;
    "Lunch Duration (Hours)": string;
    ItemInternalId: string;
    "@odata.etag": string;
}


function parseWrappedJson(input: string): ShiftRecord[]  {
    // Find the first "[" which starts the array
    const startIndex = input.indexOf('[');
    // Find the last "]" which ends the array
    const endIndex = input.lastIndexOf(']');

    // Extract only the JSON array string
    const jsonString = input.substring(startIndex, endIndex + 1);

    console.log(jsonString);
    // Parse it into a JSON array
    const parsedArray = JSON.parse(jsonString) as ShiftRecord[];
    return parsedArray;
}



// Creates a worksheet for each day
function createWorksheets(workbook: ExcelScript.Workbook) {

    // Creates worksheets for each day
    for (let day of days) {
        workbook.addWorksheet(day);
    }

    // Deletes the default sheet
    const sheetToDelete = workbook.getWorksheet("Sheet1");
    if (sheetToDelete) {
        sheetToDelete.delete();
    }
}


function fillInSheets(workbook: ExcelScript.Workbook, colleagues: ShiftRecord[]) {
    let header = ["Name", "Sign In", "Sign Out"];
    let data = [header];
    for (let day of days) {
        let sheet = workbook.getWorksheet(day);
        sheet.getRange("A1").getResizedRange(0, header.length - 1).setValues(data);
    }
}




function main(workbook: ExcelScript.Workbook, rows: string) {
    let sheet = workbook.getActiveWorksheet();

    let colleagues = parseWrappedJson(rows);

    // Creates worksheets for each day
    createWorksheets(workbook);

    fillInSheets(workbook, colleagues);


}
