-- this Google Appscript code is meant to receive the JSON webhook response from the previous Three KPI Combo Query within this repo. 
-- AFter being added to the sheet, if the data is new and there weren't any 0 values for the day then It'll send the tweet to the @BernIntern Twitter/X account.
       -- The tweet process is handled using Albato (Zapier Competitor) to check the sheet for new updates every 24 hrs then send to Twitter if the parameters are correct. 
-- Dashboard Link: https://flipsidecrypto.xyz/HitmonleeCrypto/burnt-bern-by-bernzy-t7S6n2


function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('Custom Menu')
    .addItem('Parse JSON to Sheet', 'parseJSONtoSheet')
    .addToUi();
}

function parseJSONtoSheet() {
  const sheetName = "Daily Bernzy Burn/Rewards";
  const url = "Query Link Here";

  try {
    // Fetch the JSON data from the URL
    const response = UrlFetchApp.fetch(url);
    const jsonData = JSON.parse(response.getContentText());

    // Open the spreadsheet and select the sheet
    const spreadsheet = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = spreadsheet.getSheetByName(sheetName);

    // Determine the next available row
    let nextRow = sheet.getLastRow() + 1;

    // Check if we received data
    if (jsonData.length === 0) {
      // No data was parsed
      sheet.getRange(nextRow, 7).setValue(new Date()); // Write the current date and time in column G
      sheet.getRange(nextRow, 12).setValue('TRUE'); // Write TRUE in column L
    } else {
      // Data was parsed
      jsonData.forEach(dataPoint => {
        let column = 1;
        let rowData = [];
        for (const key in dataPoint) {
          if (dataPoint.hasOwnProperty(key)) {
            rowData.push(dataPoint[key]);
            column++;
          }
        }

        // Check and apply the conditions for columns B, D, and F
        if (nextRow > 1) {
          let prevRow = nextRow - 1;
          if (sheet.getRange(prevRow, 2).getValue() === rowData[1]) {
            rowData[0] = "0.00";
          }
          if (sheet.getRange(prevRow, 4).getValue() === rowData[3]) {
            rowData[2] = "0.00";
          }
          if (sheet.getRange(prevRow, 6).getValue() === rowData[5]) {
            rowData[4] = "0.00";
          }
        }

        // Write the data to the sheet
        sheet.getRange(nextRow, 1, 1, rowData.length).setValues([rowData]);

        // Write the current date and time in column G
        sheet.getRange(nextRow, 7).setValue(new Date());

        // Check if columns A, C, and E all contain 0.00 and write TRUE in column L if so
        if (rowData[0] === "0.00" && rowData[2] === "0.00" && rowData[4] === "0.00") {
          sheet.getRange(nextRow, 12).setValue('TRUE');
        } else {
          sheet.getRange(nextRow, 12).setValue('FALSE');
        }

        // Move to the next row for the next data point
        nextRow++;
      });

      // Adjust the formula for the new row in column K
      const formula = `=TEXT((J${nextRow - 1}-G${nextRow - 1})*86400, "0") & " seconds"`;
      sheet.getRange(nextRow - 1, 11).setFormula(formula);
    }

  } catch (error) {
    Logger.log('Error: ' + error.message);
  }
}
