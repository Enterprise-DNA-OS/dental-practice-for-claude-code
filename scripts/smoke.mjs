import assert from 'node:assert/strict';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {spawnSync} from 'node:child_process';
import {getDb,REPO_ROOT} from './lib/db.mjs';
import {migrate} from './migrate.mjs';
import {seed} from './seed.mjs';
import {run,READS,TABLES,importCore,date} from './dental.mjs';
import {parseCsv} from './lib/csv.mjs';
const temp=fs.mkdtempSync(path.join(os.tmpdir(),'dental-test-'));
// Never inherit a live database. PostgreSQL tests require this dedicated variable.
process.env.DATABASE_URL=process.env.TEST_DATABASE_URL||'';
process.env.DATA_DIR=path.join(temp,'db');process.env.OUTPUT_DIR=temp;
let db;let assertions=0;
function ok(v,msg){assert.ok(v,msg);assertions++;}
async function rejects(fn,re){await assert.rejects(fn,re);assertions++;}
function cli(file,args=[]){const r=spawnSync(process.execPath,[path.join(REPO_ROOT,'scripts',file),...args],{env:process.env,encoding:'utf8',cwd:REPO_ROOT});assert.equal(r.status,0,r.stderr||r.stdout);return r.stdout;}
function data(name,v){const f=path.join(temp,name+'.json');fs.writeFileSync(f,JSON.stringify(v));return '--data='+f;}
try{
 db=await getDb();await migrate(db);ok((await migrate(db)).ran.length===0,'migration idempotence');await seed(db);await seed(db);ok((await run(db,['patients'])).length===4,'seed idempotence');
 for(const c of Object.keys(READS)){const result=await run(db,[c]);ok(Array.isArray(result),c+' is a read');}
 ok((await run(db,['help'])).reads.length===Object.keys(READS).length,'help covers reads');
 ok((await run(db,['patient','aLeX mOrGaN'])).patient.external_id==='CP001','case-insensitive resolution');
 await rejects(()=>run(db,['patient','Alex']),/Ambiguous.*patients/s);await rejects(()=>run(db,['patient','not-a-patient']),/No patients/);await rejects(()=>run(db,['unknown']),/Unknown command/);
 assert.throws(()=>date('2026-02-30'));assert.throws(()=>parseCsv('Name,Name\na,b'));assert.throws(()=>parseCsv('Name\n"unclosed'));
 ok(parseCsv('\ufeffName,Note\r\n"A, B","Line 1\nLine ""2"""\r\n')[0].Note==='Line 1\nLine "2"','CSV escaping');
 const pat=await run(db,['add','patients',data('patient',{name:'Test Patient',external_id:'TEST1',dob:'1990-01-01'})]);
 const prov=await run(db,['add','providers',data('provider',{code:'TEST',name:'Test Provider'})]);
 const app=await run(db,['add','appointments',data('appointment',{patient_id:'TEST1',provider_id:'TEST',location:'Test',day:'2026-10-10',starts:'09:00',minutes:30,status:'booked'})]);
 await rejects(()=>run(db,['add','appointments',data('overlap',{patient_id:'TEST1',provider_id:'TEST',location:'Test',day:'2026-10-10',starts:'09:15',minutes:30,status:'booked'})]),/overlaps/);
 await rejects(()=>run(db,['add','patients',data('bad-field',{name:'X','oops':'bad'})]),/Unsupported field/);
 const plan=await run(db,['add','plans',data('plan',{code:'TESTPLAN',patient_id:'TEST1',provider_id:'TEST',title:'Test recorded plan',proposed_on:'2026-10-01'})]);
 await run(db,['add','plan-items',data('item',{plan_id:'TESTPLAN',item_code:'DEMO',description:'Test',tooth:16,surface:'O',fee_cents:100})]);
 await rejects(()=>run(db,['add','plan-items',data('bad-tooth',{plan_id:'TESTPLAN',item_code:'DEMO',description:'Test',tooth:19,fee_cents:100})]),/check constraint/);
 await rejects(()=>run(db,['accept-plan','TESTPLAN','--date=2026-10-05']),/evidence/);
 ok((await run(db,['accept-plan','TESTPLAN','--date=2026-10-05','--evidence=Reviewed paper consent'])).status==='accepted','recorded consent');
 await rejects(()=>run(db,['accept-plan','TESTPLAN','--date=2026-10-05','--evidence=Duplicate']),/Only proposed/);
 const recall=await run(db,['add','recalls',data('recall',{patient_id:'TEST1',due_on:'2026-10-01',reason:'Review'})]);
 await run(db,['close-recall',recall.id,'--status=closed']);
 await run(db,['appointment-status',app.id,'--status=completed']);
 const note=await run(db,['log','TEST1','--author=Test operator','--text=Recorded visit','--appointment='+app.id]);
 await run(db,['log','TEST1','--author=Test operator','--text=Clarification','--corrects='+note.id,'--reason=Typo']);
 await rejects(()=>run(db,['log','CP001','--author=Test','--text=Wrong patient','--appointment='+app.id]),/different patient/);
 await rejects(()=>run(db,['log','CP001','--author=Test','--text=Wrong correction','--corrects='+note.id,'--reason=Test']),/different patient/);
 await rejects(()=>db.query('update dental.notes set body=$2 where id=$1',[note.id,'altered']),/append-only/);
 await rejects(()=>db.query('delete from dental.notes where id=$1',[note.id]),/append-only/);
 await run(db,['contact','TEST1','--author=Test operator','--text=Called about booking']);
 ok((await run(db,['patient','TEST1'])).notes.length===2,'correction preserves original');
 const inv=await run(db,['add','invoices',data('invoice',{code:'TESTINV',patient_id:'TEST1',issued_on:'2026-10-01',due_on:'2026-10-10',description:'Test invoice',total_cents:100})]);
 await rejects(()=>run(db,['receipt','TESTINV','--reference=OVER','--cents=101','--date=2026-10-05']),/exceeds/);
 await run(db,['receipt','TESTINV','--reference=TEST-RECEIPT','--cents=100','--date=2026-10-05']);
 ok(Number((await db.query('select balance_cents from dental.balances where id=$1',[inv.id]))[0].balance_cents)===0,'receipt reconciliation');
 const csv=path.join(REPO_ROOT,'examples/core-practice-appointments.csv');
 ok((await importCore(db,csv,'Example',true)).inserted===1,'dry run parses');
 ok(!(await db.query("select id from dental.patients where external_id='DEMO900'")).length,'dry run rolls back related records');
 ok((await run(db,['import','core-practice','--file='+csv,'--location=Example'])).inserted===1,'CSV import');
 ok((await importCore(db,csv,'Example')).skipped===1,'repeat import');
 const bad=path.join(temp,'changed.csv');fs.writeFileSync(bad,fs.readFileSync(csv,'utf8').replace('Patient cancelled','Changed note'));
 await rejects(()=>importCore(db,bad,'Example'),/Changed imported/);
 const atomic=path.join(temp,'atomic.csv');fs.writeFileSync(atomic,fs.readFileSync(csv,'utf8')+'Dr Example,30/Jul/2026,10:00AM,10:45AM,45,Cancelled,Cancelled,Wrong Person,CP001,0400000900,Review,,,Conflict\n');
 const before=await db.query('select count(*) n from dental.appointments');await rejects(()=>importCore(db,atomic,'Rollback'),/identity conflict/);assert.deepEqual(await db.query('select count(*) n from dental.appointments'),before);
 const {default:ExcelJS}=await import('exceljs');const book=new ExcelJS.Workbook();const sheet=book.addWorksheet('Appointments');sheet.addRow(['Appointment Received Report']);const parsed=parseCsv(fs.readFileSync(csv,'utf8'));sheet.addRow(Object.keys(parsed[0]));sheet.addRow(Object.values(parsed[0]));const xlsx=path.join(temp,'report.xlsx');await book.xlsx.writeFile(xlsx);ok((await importCore(db,xlsx,'Excel')).inserted===1,'XLSX title row import');
 await run(db,['medical-review','CP002','--date='+new Date().toISOString().slice(0,10),'--author=Test operator','--evidence=Reviewed history form']);
 ok(!(await run(db,['compliance'])).some(r=>r.rule==='medical-review'&&r.patient==='Jamie Wilson'),'medical review resolves gap');
 await rejects(()=>run(db,['import','core-practice','--file='+csv,'--location=Example','--dry-run=false']),/boolean flag/);
 await rejects(()=>run(db,['patients','--typo']),/Unknown option/);
 const ex=await run(db,['export']);ok(TABLES.every(t=>Array.isArray(ex[t])),'full export includes every domain table');
 const exportFile=path.join(temp,'backup.json');await run(db,['export','--out='+exportFile]);await rejects(()=>run(db,['export','--out='+exportFile]),/EEXIST/);
 const draft=await run(db,['draft-weekly']);ok(fs.readFileSync(draft.file,'utf8').includes('Draft practice review')&&!draft.sent,'draft only');
 const rls=await db.query("select count(*) n from pg_tables where schemaname='dental' and rowsecurity");ok(Number(rls[0].n)===TABLES.length,'all domain tables protected');
 await db.exec('create role dental_test_reader');await db.exec('grant usage on schema dental to dental_test_reader');await db.exec('grant select on all tables in schema dental to dental_test_reader');await db.exec('set role dental_test_reader');ok((await db.query('select * from dental.patients')).length===0,'unprivileged role sees no patients');ok((await db.query('select * from dental.day_book')).length===0,'view respects RLS');await db.exec('reset role');
 await db.close();db=null;
 ok(JSON.parse(cli('dental.mjs',['patients','--json'])).length>=4,'CLI JSON');
 const ambiguous=spawnSync(process.execPath,['scripts/dental.mjs','patient','Alex'],{env:process.env,cwd:REPO_ROOT,encoding:'utf8'});ok(ambiguous.status===1&&ambiguous.stderr.includes('Alex Morgan')&&ambiguous.stderr.includes('Alex Murray'),'CLI ambiguity exit and candidates');
 cli('view.mjs');cli('docs.mjs');const html=fs.readFileSync(path.join(temp,'views/week.html'),'utf8');ok(html.includes('Practice week')&&html.includes('Jamie Wilson'),'rendered data');
 for(const name of ['treatment-plan','statement','patient-record','recall-letter'])ok(fs.readdirSync(path.join(temp,'docs-out',name)).length>0,name+' documents');
 console.log(`PASS: ${assertions} checks; every read and write command; CSV/XLSX imports, rollback, evidence, RLS and four document families (${process.env.TEST_DATABASE_URL?'PostgreSQL':'PGlite'}).`);
}finally{await db?.close();fs.rmSync(temp,{recursive:true,force:true});}
