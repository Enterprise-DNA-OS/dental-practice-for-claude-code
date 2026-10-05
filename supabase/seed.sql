-- Fictional demonstration records. Never seed a live practice database.
insert into dental.providers(id,code,name,registration_ref) values
('10000000-0000-4000-8000-000000000001','PROV1','Dr Maya Chen','DEMO-ONLY'),
('10000000-0000-4000-8000-000000000002','PROV2','Dr Liam Patel','DEMO-ONLY') on conflict do nothing;
insert into dental.patients(id,external_id,name,dob,mobile,email,medical_reviewed_on) values
('20000000-0000-4000-8000-000000000001','CP001','Alex Morgan','1986-03-12','0400000001','alex@example.test',current_date-20),
('20000000-0000-4000-8000-000000000002','CP002','Jamie Wilson','1991-07-21','0400000002','jamie@example.test',null),
('20000000-0000-4000-8000-000000000003','CP003','Alex Murray','1975-11-04','0400000003','murray@example.test',current_date-30),
('20000000-0000-4000-8000-000000000004','CP004','Taylor Singh','2000-04-16','0400000004','taylor@example.test',current_date-2) on conflict do nothing;
insert into dental.appointments(id,patient_id,provider_id,location,day,starts,minutes,status,reason) values
('30000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Harbour',current_date-30,'09:00',30,'no-show','Recall examination'),
('30000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','Harbour',current_date+1,'09:00',45,'booked','Planned visit'),
('30000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000003','10000000-0000-4000-8000-000000000002','Harbour',current_date-2,'10:00',30,'completed','Examination'),
('30000000-0000-4000-8000-000000000004','20000000-0000-4000-8000-000000000004','10000000-0000-4000-8000-000000000002','Harbour',current_date,'11:00',30,'booked','Recall examination') on conflict do nothing;
insert into dental.plans(id,code,patient_id,provider_id,title,proposed_on,status,consent_on,consent_ref) values
('40000000-0000-4000-8000-000000000001','PLAN001','20000000-0000-4000-8000-000000000001','10000000-0000-4000-8000-000000000001','Recorded restoration plan',current_date-45,'proposed',null,null),
('40000000-0000-4000-8000-000000000002','PLAN002','20000000-0000-4000-8000-000000000002','10000000-0000-4000-8000-000000000001','Recorded follow-up plan',current_date-12,'accepted',null,null) on conflict do nothing;
insert into dental.plan_items(id,plan_id,item_code,description,tooth,surface,fee_cents) values
('50000000-0000-4000-8000-000000000001','40000000-0000-4000-8000-000000000001','DEMO-REST','Illustrative restoration entry',16,'O',25000),
('50000000-0000-4000-8000-000000000002','40000000-0000-4000-8000-000000000002','DEMO-REVIEW','Illustrative review entry',null,null,9500) on conflict do nothing;
insert into dental.recalls(id,patient_id,due_on,reason,last_contact_on) values
('60000000-0000-4000-8000-000000000001','20000000-0000-4000-8000-000000000001',current_date-35,'Recall examination',current_date-40),
('60000000-0000-4000-8000-000000000002','20000000-0000-4000-8000-000000000003',current_date-10,'Plan review',null),
('60000000-0000-4000-8000-000000000003','20000000-0000-4000-8000-000000000004',current_date+5,'Recall examination',current_date-1) on conflict do nothing;
insert into dental.invoices(id,code,patient_id,issued_on,due_on,description,total_cents) values
('70000000-0000-4000-8000-000000000001','INV001','20000000-0000-4000-8000-000000000001',current_date-45,current_date-31,'Demo account balance',30000),
('70000000-0000-4000-8000-000000000002','INV002','20000000-0000-4000-8000-000000000003',current_date-2,current_date+12,'Demo account balance',12000) on conflict do nothing;
insert into dental.receipts(id,invoice_id,reference,received_on,amount_cents) values
('80000000-0000-4000-8000-000000000001','70000000-0000-4000-8000-000000000001','DEMO-RECEIPT',current_date-20,10000) on conflict do nothing;
