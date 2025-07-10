const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];


class HighlightedCell {
    colour: string;
    range: string;

    constructor(colour: string, range: string) {
        this.colour = colour;
        this.range = range;
    }
}

class DayHours {
    hours: number;
    lunchBreakApplied: boolean;
    isHoliday: boolean;
    isHalfDay: boolean;
    isSick: boolean;

    constructor(hours: number, lunchBreakApplied: boolean) {
        this.hours = hours;
        this.lunchBreakApplied = lunchBreakApplied;
        this.isHoliday = false;
        this.isHalfDay = false;
        this.isSick = false;
    }

}

class Colleague {
    forename: string;
    surname: string;
    shiftStart: Date;
    shiftEnd: Date;
    lunchDuration: number;
    dailyHours: Map<string, DayHours>;
    additionalHours: number;
    bonusHours: number;
    comment: string;


    constructor(forename: string, surname: string, shiftStart: Date, shiftEnd: Date, lunchDuration: number) {
        this.forename = forename;
        this.surname = surname;
        this.shiftStart = shiftStart;
        this.shiftEnd = shiftEnd;
        this.lunchDuration = lunchDuration;
        this.dailyHours = new Map<string, DayHours>();
        this.additionalHours = 0;
    }

    getTotalHours(): number {
        if (!this.dailyHours) return 0;

        let total = 0;
        const entries = Array.from(this.dailyHours.entries());

        for (let i = 0; i < entries.length; i++) {
            const dayHours = entries[i][1];
            let nHours = 0;
            if (dayHours.hours === -1) {
                return -1; // Invalid total due to incomplete shift
            }
            if (dayHours.isHoliday) {
                nHours += (this.getShiftDuration() - this.lunchDuration);
            } else if (dayHours.isHalfDay) {
                nHours += ((this.getShiftDuration() - this.lunchDuration) / 2);
            }
            nHours += dayHours.hours;
            
            total += nHours;
        }
        
        // Adds the additional hours
        total += this.additionalHours;
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


// Any times before the shift start + grace period are set to the shift start time
function clipTimesBeforeSignIn(signIn: Date, colleague: Colleague) {
    const shiftStart = colleague.shiftStart;
    const graceStart = new Date(shiftStart.getTime() + 3 * 60 * 1000); // add 3 minutes
    let diffInMins = (graceStart.getTime() - signIn.getTime()) / (1000 * 60);
    
    if (diffInMins >= 0) {
        return shiftStart;
    }

  return signIn;
}


function adjustSignOutTimes(signOut: Date, shiftEnd: Date) {
    const diffInMins = (shiftEnd.getTime() - signOut.getTime()) / (1000 * 60);
    return diffInMins < 0 ? shiftEnd : signOut
}


function roundTimeUpToNearest15Minutes(date: Date): Date {
    let ms = 1000 * 60 * 15;
    return new Date(Math.ceil(date.getTime() / ms) * ms);
}


function roundTimeDownToNearest15Minutes(date: Date): Date {
    let ms = 1000 * 60 * 15;
    return new Date(Math.floor(date.getTime() / ms) * ms);
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
                    signIn = clipTimesBeforeSignIn(signIn, colleague);
                    signOut = clipTimesBeforeSignIn(signOut, colleague);

                    signIn = roundTimeUpToNearest15Minutes(signIn);
                    signOut = roundTimeDownToNearest15Minutes(signOut);

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


// Checks for holidays and sets the additional and bonus hours as well as comments
function setAuxiliaryHoursAndComments(workbook: ExcelScript.Workbook, allColleagues: Map<string, Colleague>) {
    const sheet = workbook.getWorksheet('Total Hours');
    const values = sheet.getUsedRange().getValues();

    for (let i = 1; i < values.length; i++) {
        let row = values[i];
        

        let name: string = row[0] as string;
        let colleague = allColleagues.get(name);

        // Loops through the days of the week in total hours
        for (let j = 0; j < days.length; j++) {

            // Gets the value of the cell
            let dayCell = row[j + 1];
            let str = dayCell != null ? String(dayCell) : null;

            let day = days[j];
            if (str.startsWith('H/2')) {
                colleague.dailyHours.get(day).isHalfDay = true;
            } else if (str.startsWith('H')) {
                colleague.dailyHours.get(day).isHoliday = true;
            } else if (str.startsWith('S')) {
                colleague.dailyHours.get(day).isSick = true;
            }
        }

        let additionalHours: number = Number(row[8]);
        let bonusHours: number = Number(row[10]);
        let comment: string = row[11] as string;
        colleague.additionalHours = additionalHours;
        colleague.bonusHours = bonusHours;
        colleague.comment = comment;
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
    let highlightedCells: HighlightedCell[] = [];

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

            let dailyHours = colleague.dailyHours.get(day);
            let dayHours = formatHours(dailyHours.hours);

            let highlightColour = "";
            let sickHolidayStatus = '';
            if (dailyHours.isHoliday) {
                sickHolidayStatus = 'H';
                highlightColour = 'yellow';
            } else if (dailyHours.isHalfDay) {
                sickHolidayStatus = 'H/2';
                highlightColour = 'yellow';
            } else if (dailyHours.isSick){
                sickHolidayStatus = 'S';
                highlightColour = 'orange';
            }

            if (sickHolidayStatus) {
                newRow.push(dayHours == 0 ? sickHolidayStatus : `${sickHolidayStatus} (${dayHours})`);
            } else {
                newRow.push(dayHours);
            }

            // Adds the cell to highlight to highlightedcells
            let range = `${numberToColumnLetter(j + 2)}${i + 2}`;
            let cell = new HighlightedCell(highlightColour, range);
            highlightedCells.push(cell);

        }
        newRow.push(colleague.additionalHours); // For additional hours
        let totalHours = formatHours(colleague.getTotalHours());
        newRow.push(totalHours); // For total hours
        newRow.push(colleague.bonusHours); // For bonus hours
        newRow.push(colleague.comment); // For comment

        newRows.push(newRow);
    }

    const startRow = 2; // Row 2 (1-based index)
    const startCol = 1; // Column A
    const rowCount = newRows.length;
    const colCount = newRows[0].length;

    const targetRange = sheet.getRangeByIndexes(startRow - 1, startCol - 1, rowCount, colCount);
    targetRange.setValues(newRows);


    // Set the highlighted cells
    for (let highlightedCell of highlightedCells) {
        const cell = sheet.getRange(highlightedCell.range);
        if (highlightedCell.colour == '') {
            cell.getFormat().getFill().clear();
        } else {
            cell.getFormat().getFill().setColor(highlightedCell.colour);
        }
    }
}




function main(workbook: ExcelScript.Workbook) {
    const allColleagues = getAllColleagues(workbook);
    setDailyHours(workbook, allColleagues);
    setAuxiliaryHoursAndComments(workbook, allColleagues);
    writeTotalHours(workbook, allColleagues);
}
