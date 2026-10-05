# Dental Practice for Claude Code

Appointments, recalls, treatment plans, notes and account balances in a database you own. Built by Enterprise DNA. MIT licence. Works with Claude Code, Codex, OpenCode or Cursor.

| Do it yourself | We customise it | We run it for you |
|---|---|---|
| Free code. Install and operate it. Your hosting and agent costs remain yours. | Your fields, practice rules, screens and Core Practice data mapping. [Book a call](https://enterprisedna.co/omni/book?offer=replace-software&utm_campaign=core-practice&utm_medium=github). | Installed and operated through Omni by Enterprise DNA. One setup fee, then a retainer. [The offer](https://enterprisedna.co/omni/instead-of/core-practice). |

## Quick start

```bash
git clone https://github.com/Enterprise-DNA-OS/dental-practice-for-claude-code.git
cd dental-practice-for-claude-code
npm install
npm run demo
npm test
npm run view
npm run docs
```

Node 20 or newer. Local mode uses embedded PGlite. The seed contains four fictional patients, two providers, missed visits, overdue recalls, an old plan and missing record evidence. It is idempotent. Never seed a live practice database. Start with `/day-book`, `/recalls-due` and `/weekly-review`.

For shared PostgreSQL 15 or newer, supply DATABASE_URL through your environment and run npm run migrate. Tables live in the private dental schema, with row security and no public access policy. Use a controlled database owner connection for this operator prototype. Per-staff identity, least-privilege policies, encrypted backups, access logging and practice validation are deployment work. Local mode supports one process at a time.

## What it covers

Ten record types hold patients, providers, appointments, plans, plan items by tooth and surface, append-only notes, recalls, invoices, external receipts and contact history. Five database views drive the day book, recall queue, balances, plan follow-up and record checks. Notes can be corrected by adding a linked entry; their earlier text remains. Provider bookings reject overlapping active visits. Receipt recording rejects overpayments.

This is a practice administration and recordkeeping base. Practitioners supply their own treatment decisions and item codes. It does not diagnose, recommend treatment, process payments, submit health fund claims or certify compliance. The example item labels are fictional, not an ADA fee schedule. Visual charting, imaging and HICAPS connections require separate implementation and validation.

Core Practice's [pricing page](https://www.corepractice.com.au/pricing/) does not state a base subscription amount, checked 5 October 2026. Request a practice-specific quote. The free code has no per-provider licence charge; running and supporting it still costs money.

## Weekly practice jobs

| Recipe | Work |
|---|---|
| /patients | Find patients by name and patient number. |
| /providers | Read the provider list. |
| /day-book | Review the next seven days by provider and location. |
| /appointments | Read appointment history. |
| /recalls-due | Review recalls due within thirty days, future bookings and missed visits. |
| /unscheduled-recalls | Find overdue recalls with no booking. |
| /plan-followup | Review outstanding plans and their age. |
| /unbooked-plans | Find proposed or accepted plans without a booking. |
| /debtors | Review overdue invoice balances after recorded receipts. |
| /invoices | Reconcile invoices and receipts. |
| /missed-visits | Review cancellations and missed visits over ninety days. |
| /provider-week | Review provider minutes for the coming week. |
| /compliance | Check for absent record and consent evidence. Read docs/compliance.md before interpreting results. |
| /attention | Bring overdue recalls, old plans, balances and record gaps into one list. |
| /patient | Run `npm run dental -- patient "<name or patient number>"`. Resolve ambiguity from the listed candidates. Read notes, corrections and the appointment history before answering. |
| /add | Read docs/cli.md and the current records. Put only supplied fields in a local JSON file. Run `npm run dental -- add <type> --data=<file>`. Never invent a date, identity, treatment item or consent event. Read the new record back. |
| /log | Read the patient first. Run `npm run dental -- log <patient> --author="<actual recorder>" --text="<supplied note>" --appointment=<id>`. To correct, add `--corrects=<note-id> --reason="<reason>"`. Keep earlier notes. Never compose clinical findings from a billing entry. |
| /contact | Read the patient. Record only a completed contact: `npm run dental -- contact <patient> --author="<recorder>" --text="<actual contact summary>" --date=YYYY-MM-DD`. Nothing sends. |
| /medical-review | Record a review already performed by the practitioner: `npm run dental -- medical-review <patient> --date=YYYY-MM-DD --author="<recorder>" --evidence="<review reference>"`. Never infer that a history was reviewed from attendance. |
| /accept-plan | Read the plan and patient. Record only an existing consent discussion: `npm run dental -- accept-plan <code> --date=YYYY-MM-DD --evidence="<record reference>"`. This stores evidence, it does not obtain or validate consent. |
| /appointment-status | Read the appointment and patient. Run `npm run dental -- appointment-status <id> --status=<booked\|arrived\|completed\|cancelled\|no-show>` only for a supplied event. Read the day book back. Completing a visit does not create a clinical note. |
| /close-recall | Read the recall and appointment history. Run `npm run dental -- close-recall <id> --status=<booked\|closed>` only when the operator confirms the booking or closure. |
| /receipt | Read the invoice. Record an external receipt with `npm run dental -- receipt <invoice> --reference="<unique reference>" --cents=<integer> --date=YYYY-MM-DD`. Read the balance back. No payment or claim is sent. |
| /import | Read docs/replace-core-practice.md. Export Appointment Details to Excel. Run `npm run dental -- import core-practice --file=<export.xlsx> --location="<practice location>" --dry-run`, reconcile headings and counts, then repeat without --dry-run. Preserve PDFs separately. Refuse identity conflicts and never guess the missing clinical history. |
| /export | Run `npm run dental -- export --out=<new-private-file.json>`. Check counts for all ten record types. Preserve the complete output in the practice backup location. Never publish it. |
| /weekly-review | Run `npm run dental -- attention`, `npm run dental -- plan-followup` and `npm run dental -- debtors`. Summarise who needs follow-up, missing evidence and balances by currency. Name the underlying records. Use draft-weekly to save it. |
| /draft-weekly | Run `npm run dental -- draft-weekly`. Read the saved Markdown in drafts/. It combines three current reads. Check names and scope before presenting it to the operator. Nothing sends. |
| /documents | Run `npm run docs`. Inspect the treatment plans, statements, patient extracts and recall letters in docs-out/. Every document stays a draft until a person checks it. Set brand.json once for the practice. |
| /new-view | Read views.json and the existing database views. Add a read-only query answering the requested question. Use parameter-free fixed SQL in views.json, keep private data local, then run npm run view and npm test. Inspect the generated HTML. |
| /customise | Read the current records and take a new export. Write a numbered migration under supabase/migrations for the requested field or rule. Preserve history. Apply it with npm run migrate. Update the CLI allowlist, command recipe and documents, then run npm test and exercise the changed workflow. Never directly edit production records to imitate a migration. |

## Ten questions across your records

These are implemented queries, not a claim that Core Practice cannot produce equivalent reports. Core Practice offers reporting and export. The difference here is that you own and can change the questions.

1. Which overdue recalls have no future booking? (`unscheduled-recalls`)
2. Which recall patients also have missed visits? (`recalls-due`)
3. Which proposed plans have been waiting longest? (`plan-followup`)
4. Which plans have no next appointment? (`unbooked-plans`)
5. Which providers carry the booked minutes this week? (`provider-week`)
6. Which completed visits have no recorded note? (`compliance`)
7. Which accepted plans lack recorded consent evidence? (`compliance`)
8. Which upcoming patients have no medical history review recorded? (`compliance`)
9. Which overdue accounts still have a balance after recorded receipts? (`debtors`)
10. What was originally written before a patient note was corrected? (`patient CP001`)

## Paperwork and views

npm run docs renders draft treatment plans, account statements, patient record extracts including corrections, and recall letters. npm run view renders a read-only practice-week report. Both read the same records as the CLI and use brand.json for the business name, logo and colours. Generated files stay local and out of Git. These reports are not a booking interface.

## Your first hour: ten things to ask for

1. Put our practice name and logo on documents.
2. Add our patient reference field.
3. Load our provider names and locations.
4. Import one week of appointment history for reconciliation.
5. Set the recall review window to our policy.
6. Show unscheduled recalls by location.
7. Add our recorded treatment item labels.
8. Change the statement wording.
9. Add our own consent evidence checklist.
10. Draft the Monday review from current records.

/customise writes a migration and tests the changed workflow. /new-view adds a read-only report.

## Instead of Core Practice

The [switch guide](docs/replace-core-practice.md) follows the vendor's Appointment Details Excel report, supports that workbook or a CSV saved from it, and explains the supported headings. The one-command import brings appointment history and basic patient/provider identifiers across. It does not import a complete clinical archive. Clinical PDFs, images, consent documents, treatment plans and balances need separate mapping and reconciliation.

```bash
npm run dental -- import core-practice --file=examples/core-practice-appointments.csv --location=Example --dry-run
npm run dental -- export --out=private-backup.json
```

Identical reimports skip existing records. Changed source appointments and conflicting patient names stop the entire batch. A dry run rolls back all rows. Names are case insensitive; ambiguous matches list candidates and exit 1. Every CLI read supports --json. See [CLI details](docs/cli.md), [record checks](docs/compliance.md) and [why no front end](docs/why-no-front-end.md).

## Verification

npm test creates a temporary database and output directory, exercises every CLI read and write, imports CSV and XLSX, checks rollback and idempotence, confirms that notes cannot be overwritten, checks row security and renders all four document families. TEST_DATABASE_URL selects a dedicated empty PostgreSQL test database; ordinary DATABASE_URL is ignored by tests. Hosted CI covers Linux, Windows and PostgreSQL. Local and hosted results are reported separately.

MIT. Copyright 2026 Enterprise DNA.
