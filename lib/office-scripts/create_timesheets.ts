const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];


// Reads the names of all colleagues and puts them into an array
function getAllColleagues(workbook: ExcelScript.Workbook) {
    let allColleagues = [] as string[];

    let sheet = workbook.getWorksheet("Colleague Details");
    const values = sheet.getUsedRange().getValues();

    for (let row of values.slice(1)) {  // skip header
        // Concatenate first and last names, handling possible undefined/null cells
        let firstName = row[0] ? row[0].toString().trim() : "";
        let lastName = row[1] ? row[1].toString().trim() : "";
        let name = (firstName + " " + lastName).trim();

        if (name !== "") {
            allColleagues.push(name);
        }
    }
    
    return allColleagues;
}


// Creates all the worksheets for the workbook
function initaliseWorksheets(workbook: ExcelScript.Workbook) {

    // Creates worksheets for each day
    for (let day of days) {
        workbook.addWorksheet(day);
    }


    // Adds the total hours worksheet
    workbook.addWorksheet("Total Hours");

    // Deletes the default sheet
    const colleagueSheet = workbook.getWorksheet("List");
    if (colleagueSheet) {
        colleagueSheet.setName("Colleague Details");
        // Sets the positions to just after Sunday
        colleagueSheet.setPosition(days.length);
    }
}


function fillInSheets(workbook: ExcelScript.Workbook, allColleagues: string[]) {
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
        data.push([colleague, '', '', '', '', '', '']);
    }

    for (let day of days) {
        let sheet = workbook.getWorksheet(day);
        // Resize range to match full data dimensions (rows x columns)
        let range = sheet.getRange("A1").getResizedRange(data.length - 1, header.length - 1);
        range.setValues(data);

    }
}


function createTotalHoursSheet(workbook: ExcelScript.Workbook, allColleagues : string[]) {
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
                "Total Hours",
                "Bonus Hours",
                "Comments"
                ];
    let data = [header];

    // Adds the colleague rows to the table
    for (let colleague of allColleagues) {
        data.push([
                    colleague,
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    '0',
                    ''
                    ]);
    }


    let sheet = workbook.getWorksheet("Total Hours");

    // Resize range to match full data dimensions (rows x columns)
    let range = sheet.getRange("A1").getResizedRange(data.length - 1, header.length - 1);
    range.setValues(data);
}




function main(workbook: ExcelScript.Workbook) {
    let sheet = workbook.getActiveWorksheet();

    // Creates worksheets for each day
    initaliseWorksheets(workbook);

    // Gets all the colleagues
    let allColleagues = getAllColleagues(workbook);


    fillInSheets(workbook, allColleagues);
    
    createTotalHoursSheet(workbook, allColleagues);


}
