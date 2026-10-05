# Bring Core Practice appointment history across

Checked 5 October 2026 against Core Practice's own [Appointment Details Report guide](https://support.corepractice.com.au/hc/en-us/articles/16673996759183-What-is-an-Appointment-Details-Report). The guide documents Excel and PDF export. Its screenshot shows the report headings used by this importer. The sample in examples/ is synthetic, not a customer export.

1. Open Report, Appointment Details. Select one location and a date range. Leave attendance filters blank to include all appointment types. Run the report and export to Excel.
2. Keep the original workbook. Use the XLSX directly, or save the data sheet as CSV with the heading row first. Legacy XLS files must be saved as XLSX or CSV. If you exported across locations using a provider calendar, split it into verified location-specific files first.
3. Run `npm run dental -- import core-practice --file=<report.xlsx> --location="<location>" --dry-run`. The workbook importer finds the heading row beneath the title. No records survive the dry run.
4. Check the patient numbers, names, attendance totals, dates and durations against Core Practice. Run the same command without --dry-run only after reconciliation. One command imports the supported report; this is not a one-day promise for all clinical history.
5. Export the new database and retain the original source. Compare appointment counts and sampled records before deciding on any cutover.

## Mapping

| Core Practice heading | Destination |
|---|---|
| Patient No | Stable patient external identifier |
| Patient | Patient display name, kept as exported |
| Mobile | Mobile on a newly created patient |
| Calendar | Provider label and source provider code |
| Date, Start, Dur | Practice-local appointment day, start and duration |
| Status, Attendance | Booked, arrived, completed, cancelled or no-show |
| Reason, Note | Appointment reason and cancellation note |
| End, Description, Tags | Not imported; keep the original workbook |

Use the location argument consistently. Source identity combines location, calendar, patient number, date and start time. An identical row is skipped. A changed existing row fails the whole batch for deliberate reconciliation. A rescheduled appointment with a different date or start is a different source identity; reconcile moved visits manually. Existing patient demographics are never silently replaced. Names and patient numbers must match; the importer does not fuzzy-merge patients.

Supported dates include YYYY-MM-DD, DD/MM/YYYY and DD/Mon/YYYY. Excel date cells and AM/PM times are supported. Unknown attendance labels, invalid dates or missing required headings stop the import. Exported completed visits do not create notes, so the record checks will show missing notes until the historical evidence is reconciled.

## Clinical records and full migration

Core Practice's [patient record export guide](https://support.corepractice.com.au/hc/en-us/articles/16674510075279-How-do-I-export-patient-records) describes Treatments, More, Print Patient Records and PDF download. Keep those PDFs as source documents. The appointment import does not read PDFs, imaging, chart findings, treatment plans, balances, consent documents, health fund claims, sterilisation records or access logs.

Core Practice also documents an [Excel patient list via a campaign report](https://support.corepractice.com.au/hc/en-us/articles/15658737076111-How-to-generate-a-Patient-List-with-Post-Codes). That is a separate format, not supported by this appointment importer. Map and validate a fuller migration with Enterprise DNA or your own implementer. Do not cancel the source system until the practice has reconciled its complete record retention needs.
