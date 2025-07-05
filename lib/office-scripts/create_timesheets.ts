const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"];



function getColleagueTotalHoursForDay(workbook: ExcelScript.Workbook, day: string): [string, number][] {
    const sheet = workbook.getWorksheet(day);
    const values = sheet.getUsedRange().getValues();

    const header = values[0];       // First row (column titles)
    const dataRows = values.slice(1); // All colleague rows

    const results: [string, number][] = [];

    for (const row of dataRows) {
        const name = row[0] as string;
        let totalHours = 0;

        // Loop through timestamp pairs: (signIn, signOut)
        for (let i = 1; i < row.length - 1; i += 2) {
            const signIn = parseExcelTime(row[i]);
            const signOut = parseExcelTime(row[i + 1]);

            if (signIn && signOut) {
                const durationMs = signOut.getTime() - signIn.getTime();
                totalHours += roundDownToNearest15Minutes(durationMs / (1000 * 60 * 60)); // convert ms to hours
            } else if (signIn && !signOut) {
                totalHours = -1
                break;
            }
        }
        results.push([name, totalHours]);
    }

    return results;
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


function initialiseHoursTotal(workbook: ExcelScript.Workbook) {
    const allHourTotalsMap = new Map<string, number>();

    for (let day of days) {
        allHourTotalsMap.set(day, 0);
    }
    allHourTotalsMap.set("Total", 0);
    return allHourTotalsMap;
}


function initialiseAllColleagueTotalHours(workbook: ExcelScript.Workbook) {
    let sheet = workbook.getWorksheet("Total Hours");
    const values = sheet.getUsedRange().getValues();
    const allColleagueTotalHours = new Map<string, Map<string, number>>();

    for (let row of values.slice(1)) {
        let name = row[0] as string;
        const allHourTotalsMap = initialiseHoursTotal(workbook);
        allColleagueTotalHours.set(name, allHourTotalsMap);
    }
    return allColleagueTotalHours;
}


function setTotalHours(allColleagueTotalHours: Map<string, Map<string, number>>) {
    const entries = Array.from(allColleagueTotalHours.entries());
    for (let i = 0; i < entries.length; i++) {
        const [name, hoursTotalMap] = entries[i]; // Map<string, number>
        const hourEntries = Array.from(hoursTotalMap.entries());

        let weeklyHours = 0;
        for (let j = 0; j < hourEntries.length; j++) {
            const [day, hours] = hourEntries[j];
            if (hours == -1 && weeklyHours != -1) {
                weeklyHours = -1;
            } else if (weeklyHours != -1) {
                weeklyHours += hours;
            }
        }
        allColleagueTotalHours.get(name).set("Total", weeklyHours);
    }
}

function setDailyHours(workbook: ExcelScript.Workbook, allColleagueTotalHours: Map<string, Map<string, number>>) {
    for (let day of days) {
        const dailyResults = getColleagueTotalHoursForDay(workbook, day);
        for (let row of dailyResults) {
            let name = row[0];
            let hours = row[1];
            let hoursTotalMap = allColleagueTotalHours.get(name);
            let hoursForDay = hoursTotalMap.get(day);
            if (hoursForDay != -1 && hours == -1) {
                hoursTotalMap.set(day, -1);
            } else if (hoursForDay != -1 && hours != -1) {
                hoursTotalMap.set(day, hours);
            }
        }
    }
}

function writeTotalHours(
  workbook: ExcelScript.Workbook,
  allColleagueTotalHours: Map<string, Map<string, number>>
) {
  const sheet = workbook.getWorksheet("Total Hours");
  const values = sheet.getUsedRange().getValues();

  // Helper to safely get cell value
  const formatHours = (value: number | undefined): string | number => {
    return value === -1 || value === undefined ? "Invalid" : value;
  };

  for (let i = 1; i < values.length; i++) {
    const row = values[i];
    const name = row[0] as string;
    const hoursMap = allColleagueTotalHours.get(name);
    if (!hoursMap) continue;

    // Set daily hours
    for (let j = 0; j < days.length; j++) {
      const day = days[j];
      const dayHours = hoursMap.get(day);
      row[j + 1] = formatHours(dayHours);
    }

    // Set total hours in column J (index 9)
    const totalHours = hoursMap.get("Total");
    row[9] = formatHours(totalHours);
  }

  sheet.getUsedRange().setValues(values);
}




function main(workbook: ExcelScript.Workbook) {
    const allColleagueTotalHours = initialiseAllColleagueTotalHours(workbook);
    setDailyHours(workbook, allColleagueTotalHours);
    setTotalHours(allColleagueTotalHours);
    writeTotalHours(workbook, allColleagueTotalHours);
}
