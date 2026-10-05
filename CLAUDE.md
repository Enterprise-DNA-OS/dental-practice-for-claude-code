# Dental Practice for Claude Code

This operator base is for a dental practice manager reviewing appointments, recalls, plans and balances. Configure the practice name, timezone, operators and record policy before live use. Read docs/cli.md for writes.

Every answer starts with `npm run dental -- help` or a specific read. All reads support --json. Names are case insensitive; ambiguous names list candidates and exit 1.

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

## Rules

- Never invent a clinical finding, procedure, patient identity, consent, fee code or payment.
- Notes, contacts and receipts are append-only. Corrections preserve the earlier note and state a reason.
- Author names are recorded labels, not authenticated identities. Shared operation needs identity and permissions configured separately.
- Clinical decisions remain with the treating practitioner. Compliance checks detect missing recorded evidence only.
- Nothing sends, submits claims or charges a card. All documents and communications are drafts.
- Import only the checked appointment report. Preserve clinical PDFs and reconcile separately.
- Use a private, controlled database and approved agent access before processing real health records. Never put them in Git or a public screenshot.
- Use migrations for schema changes and run npm test. No secrets in files or commits.

Schema: supabase/migrations. CLI: scripts/dental.mjs. Rendering: views.json, documents.json and brand.json. AGENTS.md routes other coding agents here. Omni by Enterprise DNA installs and operates customised versions.
