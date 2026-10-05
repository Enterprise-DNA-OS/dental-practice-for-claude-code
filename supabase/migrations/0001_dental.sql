create schema dental;
revoke all on schema dental from public;
create function dental.touch_updated() returns trigger language plpgsql as $$ begin new.updated_at=now(); return new; end $$;
create function dental.preserve_evidence() returns trigger language plpgsql as $$ begin raise exception 'Evidence is append-only; add a correction instead'; end $$;
create table dental.patients (id uuid primary key default gen_random_uuid(), external_id text unique, name text not null check(length(trim(name))>0), dob date, mobile text, email text, health_fund text, medical_reviewed_on date, active boolean not null default true, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.patients for each row execute function dental.touch_updated();
alter table dental.patients enable row level security;
create table dental.providers (id uuid primary key default gen_random_uuid(), code text not null unique, name text not null, registration_ref text, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.providers for each row execute function dental.touch_updated();
alter table dental.providers enable row level security;
create table dental.appointments (id uuid primary key default gen_random_uuid(), source_key text unique, patient_id uuid not null references dental.patients(id), provider_id uuid not null references dental.providers(id), location text not null, day date not null, starts time not null, minutes integer not null check(minutes>0 and minutes<=1440), status text not null check(status in ('booked','arrived','completed','cancelled','no-show')), reason text not null default '', note text not null default '', created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.appointments for each row execute function dental.touch_updated();
alter table dental.appointments enable row level security;
create index appointments_patient_id_idx on dental.appointments(patient_id);
create index appointments_provider_id_idx on dental.appointments(provider_id);
create table dental.plans (id uuid primary key default gen_random_uuid(), code text not null unique, patient_id uuid not null references dental.patients(id), provider_id uuid not null references dental.providers(id), title text not null, proposed_on date not null, status text not null default 'proposed' check(status in ('proposed','accepted','completed','declined')), consent_on date, consent_ref text, currency text not null default 'AUD' check(currency in ('AUD','NZD')), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.plans for each row execute function dental.touch_updated();
alter table dental.plans enable row level security;
create index plans_patient_id_idx on dental.plans(patient_id);
create index plans_provider_id_idx on dental.plans(provider_id);
create table dental.plan_items (id uuid primary key default gen_random_uuid(), plan_id uuid not null references dental.plans(id), item_code text not null, description text not null, tooth integer check((tooth between 11 and 48 and tooth%10 between 1 and 8) or (tooth between 51 and 85 and tooth%10 between 1 and 5)), surface text, fee_cents integer not null check(fee_cents>=0), completed_on date, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.plan_items for each row execute function dental.touch_updated();
alter table dental.plan_items enable row level security;
create index plan_items_plan_id_idx on dental.plan_items(plan_id);
create table dental.notes (id uuid primary key default gen_random_uuid(), patient_id uuid not null references dental.patients(id), appointment_id uuid references dental.appointments(id), author text not null check(length(trim(author))>0), recorded_on date not null, body text not null check(length(trim(body))>0), corrects_id uuid references dental.notes(id), correction_reason text, check(corrects_id is null or length(trim(correction_reason))>0), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.notes for each row execute function dental.touch_updated();
alter table dental.notes enable row level security;
create index notes_patient_id_idx on dental.notes(patient_id);
create index notes_appointment_id_idx on dental.notes(appointment_id);
create index notes_corrects_id_idx on dental.notes(corrects_id);
create trigger preserve_evidence before update or delete on dental.notes for each row execute function dental.preserve_evidence();
create table dental.recalls (id uuid primary key default gen_random_uuid(), patient_id uuid not null references dental.patients(id), due_on date not null, reason text not null, status text not null default 'due' check(status in ('due','booked','closed')), last_contact_on date, created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.recalls for each row execute function dental.touch_updated();
alter table dental.recalls enable row level security;
create index recalls_patient_id_idx on dental.recalls(patient_id);
create table dental.invoices (id uuid primary key default gen_random_uuid(), code text not null unique, patient_id uuid not null references dental.patients(id), issued_on date not null, due_on date not null, description text not null, total_cents integer not null check(total_cents>=0), currency text not null default 'AUD' check(currency in ('AUD','NZD')), check(due_on>=issued_on), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.invoices for each row execute function dental.touch_updated();
alter table dental.invoices enable row level security;
create index invoices_patient_id_idx on dental.invoices(patient_id);
create table dental.receipts (id uuid primary key default gen_random_uuid(), invoice_id uuid not null references dental.invoices(id), reference text not null unique, received_on date not null, amount_cents integer not null check(amount_cents>0), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.receipts for each row execute function dental.touch_updated();
alter table dental.receipts enable row level security;
create index receipts_invoice_id_idx on dental.receipts(invoice_id);
create trigger preserve_evidence before update or delete on dental.receipts for each row execute function dental.preserve_evidence();
create table dental.contacts (id uuid primary key default gen_random_uuid(), patient_id uuid not null references dental.patients(id), contacted_on date not null, author text not null check(length(trim(author))>0), summary text not null check(length(trim(summary))>0), created_at timestamptz not null default now(), updated_at timestamptz not null default now());
create trigger touch_updated before update on dental.contacts for each row execute function dental.touch_updated();
alter table dental.contacts enable row level security;
create index contacts_patient_id_idx on dental.contacts(patient_id);
create trigger preserve_evidence before update or delete on dental.contacts for each row execute function dental.preserve_evidence();
create index appointments_day_idx on dental.appointments(day,provider_id);
create index recalls_due_idx on dental.recalls(due_on) where status='due';
create index patients_name_idx on dental.patients(lower(name));
create view dental.day_book with (security_invoker=true) as
 select a.id,a.day,a.starts,a.minutes,p.name patient,p.external_id patient_no,r.name provider,a.location,a.status,a.reason,a.note
 from dental.appointments a join dental.patients p on p.id=a.patient_id join dental.providers r on r.id=a.provider_id;
create view dental.recall_queue with (security_invoker=true) as
 select r.id,p.name patient,p.external_id patient_no,r.due_on,current_date-r.due_on days_overdue,r.reason,r.last_contact_on,
 (select min(a.day) from dental.appointments a where a.patient_id=p.id and a.day>=current_date and a.status in ('booked','arrived')) next_booking,
 (select count(*) from dental.appointments a where a.patient_id=p.id and a.status='no-show') missed_visits
 from dental.recalls r join dental.patients p on p.id=r.patient_id where r.status='due' and p.active;
create view dental.balances with (security_invoker=true) as
 select i.id,i.code,p.name patient,i.issued_on,i.due_on,i.currency,i.total_cents,
 coalesce((select sum(r.amount_cents) from dental.receipts r where r.invoice_id=i.id),0)::bigint received_cents,
 (i.total_cents-coalesce((select sum(r.amount_cents) from dental.receipts r where r.invoice_id=i.id),0))::bigint balance_cents
 from dental.invoices i join dental.patients p on p.id=i.patient_id;
create view dental.plan_followup with (security_invoker=true) as
 select t.id,t.code,p.name patient,r.name provider,t.title,t.status,t.proposed_on,current_date-t.proposed_on age_days,t.consent_on,t.consent_ref,t.currency,
 coalesce((select sum(i.fee_cents) from dental.plan_items i where i.plan_id=t.id),0)::bigint fee_cents,
 (select min(a.day) from dental.appointments a where a.patient_id=p.id and a.day>=current_date and a.status in ('booked','arrived')) next_booking
 from dental.plans t join dental.patients p on p.id=t.patient_id join dental.providers r on r.id=t.provider_id;
create view dental.compliance_gaps with (security_invoker=true) as
 select 'record-note' rule,a.id record_id,p.name patient,'Completed visit has no recorded note' issue,'AU-RECORDS / NZ-RECORDS' source
 from dental.appointments a join dental.patients p on p.id=a.patient_id where a.status='completed' and not exists(select 1 from dental.notes n where n.appointment_id=a.id)
 union all select 'consent-evidence',t.id,p.name,'Accepted or completed plan lacks recorded consent evidence','AU-CONSENT / NZ-CONSENT'
 from dental.plans t join dental.patients p on p.id=t.patient_id where t.status in ('accepted','completed') and (t.consent_on is null or nullif(trim(t.consent_ref),'') is null)
 union all select 'medical-review',p.id,p.name,'Upcoming visit has no medical history review recorded','AU-RECORDS / NZ-RECORDS'
 from dental.patients p where p.medical_reviewed_on is null and exists(select 1 from dental.appointments a where a.patient_id=p.id and a.day between current_date and current_date+7 and a.status='booked');
