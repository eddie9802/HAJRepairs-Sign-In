const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];


class CellComment {
    range: string;
    comment: string;

    constructor(range: string, comment: string) {
        this.range = range;
        this.comment = comment;
    }
}


class DayHours {
    hours: number;
    lunchBreakApplied: boolean;

    constructor(hours: number, lunchBreakApplied: boolean){
        this.hours = hours;
        this.lunchBreakApplied = lunchBreakApplied;
    }

}

class Colleague {
    forename: string;
    surname: string;
    shiftStart: Date;
    shiftEnd: Date;
    lunchDuration: number;
    dailyHours: Map<string, DayHours>;


    constructor(forename: string, surname: string, shiftStart: Date, shiftEnd: Date, lunchDuration: number) {
        this.forename = forename;
        this.surname = surname;
        this.shiftStart = shiftStart;
        this.shiftEnd = shiftEnd;
        this.lunchDuration = lunchDuration;
        this.dailyHours = new Map<string, DayHours>();
    }

    getTotalHours(): number {
        if (!this.dailyHours) return 0;

        let total = 0;
        const entries = Array.from(this.dailyHours.entries());

        for (let i = 0; i < entries.length; i++) {
            const dayHours = entries[i][1];
            if (dayHours.hours === -1) {
                return -1; // Invalid total due to incomplete shift
            }
            total += dayHours.hours;
        }

        return total;
    }

    // Returns the shift with the grace period added
    getGracePeriodStart(): Date {
        const gracePeriodTime = new Date(this.shiftStart.getTime() + 3 * 60 * 1000); // add 3 minutes
        return gracePeriodTime;
    }


    getShiftDuration(): number {
        const durationMs = this.shiftEnd.getTime() - this.shiftStart.getTime();
        return durationMs / (1000 * 60 * 60);
    }

    getFullName(): string {
        return `${this.forename} ${this.surname}`;
    }
}



function roundDownToNearest15Minutes(hours: number): number {
    const increment = 0.25; // 15 minutes in hours
    return Math.floor(hours / increment) * increment;
}


// Helper: convert Excel timestamp or time string to Date object
function parseExcelTime(value: unknown): Date | null {
    if (typeof value === "number") {
        const msInDay = 24 * 60 * 60 * 1000;
        const excelEpoch = new Date(Date.UTC(1899, 11, 30)); // Dec 30, 1899 - Excel epoch offset

        // value may include both date and time (e.g. 44204.5)
        // Separate days and fractional day for time:
        const days = Math.floor(value);
        const fractionalDay = value - days;

        const date = new Date(excelEpoch.getTime() + days * msInDay + fractionalDay * msInDay);
        return date;
    }
    return null;
}



// Reads the Colleague Details worksheet returns a map of all the colleague
// And their details
function getAllColleagues(workbook: ExcelScript.Workbook) {
    let sheet = workbook.getWorksheet("Colleague Details");
    const values = sheet.getUsedRange().getValues();
    const allColleagues = new Map<string, Colleague>();

    for (let row of values.slice(1)) {
        let forename = row[0] as string;
        let surname = row[1] as string;
        let shiftStart = parseExcelTime(row[2]);
        let shiftEnd = parseExcelTime(row[3]);
        let lunchDuration = row[4] as number;
        const colleague = new Colleague(forename, surname, shiftStart, shiftEnd, lunchDuration);
        let fullname = `${forename} ${surname}`;
        allColleagues.set(fullname, colleague);
    }
    return allColleagues;
}



function clipTimes(signTime: Date, colleague: Colleague) {
    const shiftStart = colleague.shiftStart;
    const graceStart = new Date(shiftStart.getTime() + 3 * 60 * 1000); // add 3 minutes
    let diffInMins = (graceStart.getTime() - signTime.getTime()) / (1000 * 60);
    
    if (diffInMins >= 0) {
        return shiftStart;
    }

    const shiftEnd = colleague.shiftEnd;
    diffInMins = (shiftEnd.getTime() - signTime.getTime()) / (1000 * 60);

    if (diffInMins < 0) {
        return shiftEnd;
    }

    return signTime;
}


function adjustSignOutTimes(signOut: Date, shiftEnd: Date) {
    const diffInMins = (shiftEnd.getTime() - signOut.getTime()) / (1000 * 60);
    return diffInMins < 0 ? shiftEnd : signOut
}


// This will get all the colleague hours for each day and then for each colleague 
// Set their daily hours
function setDailyHours(workbook: ExcelScript.Workbook, allColleagues: Map<string, Colleague>) {
    for (let day of days) {
        const sheet = workbook.getWorksheet(day);
        const values = sheet.getUsedRange().getValues();

        const header = values[0];         // First row (column titles)
        const dataRows = values.slice(1); // All colleague rows

        for (const row of dataRows) {
            const name = row[0] as string;
            let colleague = allColleagues.get(name)
            let totalHours = 0;

            // Loop through timestamp pairs: (signIn, signOut)
            for (let i = 1; i < row.length - 1; i += 2) {
                let signIn = parseExcelTime(row[i]);
                let signOut = parseExcelTime(row[i + 1]);
                const shiftStart = colleague.shiftStart;


                if (signIn && signOut) {

                    // Adjusts the sign in and out times if they are before the shift start plus grace period
                    signIn = clipTimes(signIn, colleague);
                    signOut = clipTimes(signOut, colleague);

                    const durationMs = signOut.getTime() - signIn.getTime();
                    totalHours += roundDownToNearest15Minutes(durationMs / (1000 * 60 * 60)); // hours
                }  else if (signIn && !signOut) {
                    totalHours = -1;
                    break;
                }
            }

            let lunchBreakApplied = false;
            // Subtracts the lunch break if need be
            if (totalHours > (colleague.getShiftDuration() / 2)) {
                totalHours -= colleague.lunchDuration;
                lunchBreakApplied = true;
            }

            let dayHours = new DayHours(totalHours, lunchBreakApplied);
            colleague.dailyHours.set(day, dayHours);
        }
    }
}





// Takes a number and gives a letter corresponding to a column in an excel spreadsheet
function numberToColumnLetter(colNum: number): string {
    let column = '';
    while (colNum > 0) {
        const remainder = (colNum - 1) % 26;
        column = String.fromCharCode(65 + remainder) + column;
        colNum = Math.floor((colNum - 1) / 26);
    }
    return column;
}

function writeTotalHours(
  workbook: ExcelScript.Workbook,
    allColleagues: Map<string, Colleague>
) {
    const sheet = workbook.getWorksheet("Total Hours");
    let newRows: (string | number | boolean)[][] = [];
    let cellsToComment: CellComment[] = [];


    // Helper to safely get cell value
    const formatHours = (value: number | undefined): string | number => {
        return value === -1 || value === undefined ? "Invalid" : value;
    };

    let entities = Array.from(allColleagues.values());

    for (let i = 0; i < entities.length; i++) {
        let colleague = entities[i];
        let newRow: (string | number | boolean)[] = [];
        let name = colleague.getFullName();
        newRow.push(name);

        for (let j = 0; j < days.length; j++) {
            let day = days[j];
            let dayHours = formatHours(colleague.dailyHours.get(day).hours);
            newRow.push(dayHours);

            // Calculates a comment to write to the cells of the 
            let lunchDuration = colleague.lunchDuration;
            let comment = "";
            if (colleague.dailyHours.get(day).lunchBreakApplied) {
                const hoursLabel = lunchDuration === 1 ? 'hour has' : 'hours have';
                comment = `${lunchDuration} ${hoursLabel} been deducted for lunch break.`;
            } else {
                if (colleague.getTotalHours() > 0) {
                    comment = `No lunch break has been deducted.`;
                }
            }
            // Names start on row number 2
            let rowNum = i + 2;

            // Monday is on the second column
            let colLetter = numberToColumnLetter(j + 1);
            let range = `${colLetter}${rowNum}`;
            let cellComment = new CellComment(range, comment);
            cellsToComment.push(cellComment);
        }
        newRow.push(0); // For additional hours
        let totalHours = formatHours(colleague.getTotalHours());
        newRow.push(totalHours); // For total hours
        newRows.push(newRow);
    }

    const startRow = 2; // Row 2 (1-based index)
    const startCol = 1; // Column A
    const rowCount = newRows.length;
    const colCount = newRows[0].length;

    const targetRange = sheet.getRangeByIndexes(startRow - 1, startCol - 1, rowCount, colCount);
    targetRange.setValues(newRows);


    // Write comments
    // for (let cellComment of cellsToComment) {
    //     const cell = sheet.getRange(cellComment.range);

    //     cell.setNote(cellComment.comment, ExcelScript.ContentType.plain);

    // }
}




function main(workbook: ExcelScript.Workbook) {
    const allColleagues = getAllColleagues(workbook);
    setDailyHours(workbook, allColleagues);
    writeTotalHours(workbook, allColleagues);
}