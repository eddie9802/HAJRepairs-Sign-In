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

class Colleague {
    constructor(
        public forename: string,
        public surname: string,
        public shiftStart: string,
        public shiftEnd: string,
        public lunchDuration: string,
    ) {}

    get fullName(): string {
        return `${this.forename} ${this.surname}`;
    }
}


// Reads all the shift records and creates colleague instances from them
function getAllColleagues(allShiftRecords: ShiftRecord[]) {
    let allColleagues = [] as Colleague[];
    for (let shiftRecord of allShiftRecords) {
        let colleague = new Colleague(
                                shiftRecord.Forename,
                                shiftRecord.Surname,
                                shiftRecord["Shift Start"],
                                shiftRecord["Shift End"],
                                shiftRecord["Lunch Duration (Hours)"]
                                );
        allColleagues.push(colleague);
    }
    return allColleagues;
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


    // Adds the total hours worksheet
    workbook.addWorksheet("Total Hours");

    // Deletes the default sheet
    const sheetToDelete = workbook.getWorksheet("Sheet1");
    if (sheetToDelete) {
        sheetToDelete.delete();
    }
}


function fillInSheets(workbook: ExcelScript.Workbook, allColleagues: Colleague[]) {
    let header = [
                "Name",
                "Sign In",
                "Sign Out",
                "Sign In",
                "Sign Out",
                "Sign In",
                "Sign Out",
                ];
    let data = [header];

    for (let colleague of allColleagues) {
        data.push([colleague.fullName, '', '', '', '', '', '']);
    }

    for (let day of days) {
        let sheet = workbook.getWorksheet(day)
        ;
        // Resize range to match full data dimensions (rows x columns)
        let range = sheet.getRange("A1").getResizedRange(data.length - 1, header.length - 1);
        range.setValues(data);

    }
}


function createTotalHoursSheet(workbook: ExcelScript.Workbook, allColleagues : Colleague[]) {
    let header = [
                "Name",
                "Monday",
                "Tuesday",
                "Wednesday",
                "Thursday",
                "Friday",
                "Saturday",
                "Sunday",
                "Additional Hours",
                "Total Hours"
                ];
    let data = [header];

    // Adds the colleague rows to the table
    for (let colleague of allColleagues) {
        data.push([
                    colleague.fullName,
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0'
                    ]);
    }


    let sheet = workbook.getWorksheet("Total Hours");

    // Resize range to match full data dimensions (rows x columns)
    let range = sheet.getRange("A1").getResizedRange(data.length - 1, header.length - 1);
    range.setValues(data);
}




function main(workbook: ExcelScript.Workbook, rows: string) {
    let sheet = workbook.getActiveWorksheet();

    // Creates worksheets for each day
    createWorksheets(workbook);

    // Gets all the colleagues
    let shiftRecords = parseWrappedJson(rows);
    let allColleagues = getAllColleagues(shiftRecords);


    fillInSheets(workbook, allColleagues);
    
    createTotalHoursSheet(workbook, allColleagues);


}