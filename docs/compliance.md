# Record checks and their limits

Checked 5 October 2026. `npm run dental -- compliance` lists missing evidence for human review. It does not decide whether care was lawful, consent valid, a code billable or a claim payable. No patient care is authorised by a clean result.

| Rule | Implemented check | Source |
|---|---|---|
| record-note | A completed appointment has no linked note | AU-RECORDS and NZ-RECORDS |
| consent-evidence | An accepted or completed plan has no consent date or reference | AU-CONSENT and NZ-CONSENT |
| medical-review | An upcoming booked patient has no medical history review date | AU-RECORDS and NZ-RECORDS |

AU-RECORDS: Ahpra's [shared Code of conduct](https://www.ahpra.gov.au/Resources/Code-of-conduct/Shared-Code-of-conduct), section 8.3, covers health records. AU-CONSENT: the same code, section 4.2, covers informed consent. Maintain accurate records and record actual care and discussions. A database date does not establish the content or adequacy of either.

NZ-RECORDS: Dental Council [Patient records and privacy of health information practice standard](https://dcnz.org.nz/assets/Uploads/Practice-standards/Patient-records-and-privacy-of-health-information-practice-standard-1Dec20.pdf). NZ-CONSENT: Dental Council [Informed consent practice standard](https://dcnz.org.nz/assets/Uploads/Practice-standards/Informed-consent-practice-standard-May18.pdf). The Council's [current standards index](https://dcnz.org.nz/resources-and-publications/resources/practice-standards) linked these versions on the checked date.

The seven-day appointment window and thirty-day recall look-ahead are operational choices, not legal deadlines. There is no automatic retention deletion. The consent evidence can refer to an oral discussion or written material; the software does not claim written consent is mandatory for every procedure. The practitioner assesses capacity, explanation, currency and scope of consent. Notes are append-only and corrections link back to the original. Author fields are supplied labels, not verified signatures.

ADA item eligibility, health fund schedules, ACC entitlements, retention periods by jurisdiction, infection prevention, imaging and clinical decision support are outside these checks. No claiming or payment connection is included. The practice must validate its applicable record policies, privacy controls, access permissions, backups and agent processing arrangements before live use.
