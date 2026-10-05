# Dental CLI

Run `npm run dental -- help`. Every read accepts --json. Practice dates use YYYY-MM-DD. Appointment times are local wall-clock times, never converted to UTC. Financial values are integer cents with AUD or NZD stored per invoice or plan; reports do not combine currencies.

## Reads

- `patients`: Find patients by name and patient number.
- `providers`: Read the provider list.
- `day-book`: Review the next seven days by provider and location.
- `appointments`: Read appointment history.
- `recalls-due`: Review recalls due within thirty days, future bookings and missed visits.
- `unscheduled-recalls`: Find overdue recalls with no booking.
- `plan-followup`: Review outstanding plans and their age.
- `unbooked-plans`: Find proposed or accepted plans without a booking.
- `debtors`: Review overdue invoice balances after recorded receipts.
- `invoices`: Reconcile invoices and receipts.
- `missed-visits`: Review cancellations and missed visits over ninety days.
- `provider-week`: Review provider minutes for the coming week.
- `compliance`: Check for absent record and consent evidence. Read docs/compliance.md before interpreting results.
- `attention`: Bring overdue recalls, old plans, balances and record gaps into one list.

`patient <name|number|partial-uuid>` returns the complete patient record held here. Exact identities take priority; ambiguous partial matches list candidates and fail.

## Add a record

Write a JSON object, then `npm run dental -- add <type> --data=<file.json>`. Foreign keys accept an exact identifier, patient number, provider code, plan code or unambiguous name.

| Type | Required fields | Optional fields |
|---|---|---|
| patients | name | external_id, dob, mobile, email, health_fund, medical_reviewed_on |
| providers | code, name | registration_ref |
| appointments | patient_id, provider_id, location, day, starts, minutes, status | reason, note |
| plans | code, patient_id, provider_id, title, proposed_on | currency |
| plan-items | plan_id, item_code, description, fee_cents | tooth, surface |
| recalls | patient_id, due_on, reason | |
| invoices | code, patient_id, issued_on, due_on, description, total_cents | currency |

Appointment status is booked, arrived, completed, cancelled or no-show. Example patient JSON: `{"name":"Example Patient","external_id":"LOCAL001"}`. Plan-item tooth numbers use FDI permanent or deciduous notation. Surface text is recorded as provided. The system does not validate clinical appropriateness or health fund eligibility.

## Record events

```bash
npm run dental -- log CP001 --author="Practice recorder" --text="Supplied note" --date=2026-10-05
npm run dental -- contact CP001 --author="Reception" --text="Spoke about booking" --date=2026-10-05
npm run dental -- medical-review CP002 --date=2026-10-05 --author="Treating practitioner" --evidence="Reviewed history form reference"
npm run dental -- accept-plan PLAN001 --date=2026-10-05 --evidence="Recorded consent discussion reference"
npm run dental -- receipt INV001 --reference=EXTERNAL-RECEIPT-2 --cents=1000 --date=2026-10-05
```

A note can include --appointment=<id>. A correction uses --corrects=<note-id> and --reason=<reason>; both must belong to the same patient. Medical review stores a note as well as its date. Record only real events confirmed by the operator. Receipt recording is an accounting record of money already received, not payment processing.

`appointment-status <id> --status=<status>` records the supplied attendance change. Reopening an appointment checks overlaps. `close-recall <id> --status=booked|closed` requires the operator to check the actual booking first.

`export --out=<new-file.json>` saves all ten record types. It refuses to overwrite an existing file. It is a portable snapshot, not a tested full database disaster-recovery procedure. Keep database backups too.

`draft-weekly` reads attention, plan-followup and debtors and writes a new Markdown file under drafts/. It never sends. OUTPUT_DIR can move generated files for tests. Treat all exports, drafts and HTML containing real records as private health information.
