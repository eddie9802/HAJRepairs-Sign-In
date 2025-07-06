const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];


class Colleague {
    forename: string;
    surname: string;
    shiftStart: Date;
    shiftEnd: Date;
    lunchDuration: number;
    dailyHours: Map<string, number>;


    constructor(forename: string, surname: string, shiftStart: Date, shiftEnd: Date, lunchDuration: number) {
        this.forename = forename;
        this.surname = surname;
        this.shiftStart = shiftStart;
        this.shiftEnd = shiftEnd;
        this.lunchDuration = lunchDuration;
        this.dailyHours = new Map<string, number>();
    }

    getTotalHours(): number {
        if (!this.dailyHours) return 0;

        let total = 0;
        const entries = Array.from(this.dailyHours.entries());

        for (let i = 0; i < entries.length; i++) {
            const hours = entries[i][1];
            if (hours === -1) {
                return -1; // Invalid total due to incomplete shift
            }
            total += hours;
        }

        return total;
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
            let totalHours = 0;

            // Loop through timestamp pairs: (signIn, signOut)
            for (let i = 1; i < row.length - 1; i += 2) {
                const signIn = parseExcelTime(row[i]);
                const signOut = parseExcelTime(row[i + 1]);

                if (signIn && signOut) {
                    const durationMs = signOut.getTime() - signIn.getTime();
                    totalHours += roundDownToNearest15Minutes(durationMs / (1000 * 60 * 60)); // hours
                } else if (signIn && !signOut) {
                    totalHours = -1;
                    break;
                }
            }
            
            // Subtracts the lunch break if need be
            let colleague = allColleagues.get(name)

            if (totalHours > (colleague.getShiftDuration() / 2)) {
                totalHours -= colleague.lunchDuration;
            }

            colleague.dailyHours.set(day, totalHours);
        }
    }
}

function writeTotalHours(
  workbook: ExcelScript.Workbook,
    allColleagues: Map<string, Colleague>
) {
    const sheet = workbook.getWorksheet("Total Hours");
    let newRows: (string | number | boolean)[][] = [];

    // Helper to safely get cell value
    const formatHours = (value: number | undefined): string | number => {
        return value === -1 || value === undefined ? "Invalid" : value;
    };

    let entities = Array.from(allColleagues.values());

    for (let colleague of entities) {
        let newRow: (string | number | boolean)[] = [];
        let name = colleague.getFullName();
        newRow.push(name);

        for (let day of days) {
            let dayHours = formatHours(colleague.dailyHours.get(day));
            newRow.push(dayHours);
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
}




function main(workbook: ExcelScript.Workbook) {
    const allColleagues = getAllColleagues(workbook);
    setDailyHours(workbook, allColleagues);
    writeTotalHours(workbook, allColleagues);
}
