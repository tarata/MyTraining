
const { chromium, webkit } = require('playwright');
const { strict: assert } = require('node:assert');
const { resolve } = require('node:path');
const { pathToFileURL } = require('node:url');
(async()=>{
 for(const [engine,path] of [[chromium,'app/src/main/assets/index.html'],[webkit,'ios/RUOSS/index.html']]){
  const browser=await engine.launch();
  try{
   const page=await browser.newPage({viewport:{width:360,height:780},timezoneId:'Europe/Rome'});
   const errors=[];
   page.on('pageerror',e=>errors.push(e.message));
   await page.goto(pathToFileURL(resolve(path)).href);
   await page.evaluate(()=>{
    window.calls=[];
    window.Android=new Proxy({}, {get:(_,key)=>(...args)=>window.calls.push([key,...args])});
   });
   const click=text=>page.getByRole('button',{name:text,exact:true}).click();
   const menu=async text=>{await page.locator('#toolsMenu summary').click();await click(text)};
   await menu('Schede');
   await click('Scarica Template');
   await page.evaluate(()=>importPlan(calls.at(-1)[3]));
   await click('Chiudi');
   await click('+ Esercizio');
   await page.locator('#exerciseName').fill('Rematore test');
   await click('Salva');
   assert.equal(await page.locator('#editorStatus').innerText(),'Schede salvate.');
   await click('Condividi');
   assert.equal(await page.evaluate(()=>JSON.parse(calls.at(-1)[3]).plans.A.at(-1)[0]),'Rematore test');
   await page.reload();
   assert(await page.getByRole('heading',{name:'Rematore test'}).count());
   await menu('Schede');await click('Reset');await click('Salva');
   await page.locator('#nav button').first().click();
   assert.equal(await page.getByRole('heading',{name:'Rematore test'}).count(),0);
   for(const [width,height] of [[320,568],[393,852],[844,390]]){
     await page.setViewportSize({width,height});
     const rect=await page.locator('#toolsMenu summary').boundingBox();
     assert(rect.height>=48 && rect.width>=48 && rect.x>=0 && rect.x+rect.width<=width);
     await menu('Storico');
     await page.locator('#nav button').first().click();
   }
   await page.setViewportSize({width:360,height:780});
   const feedback=await page.evaluate(()=>{
     let tones=0;
     const play=playStartTone;
     playStartTone=()=>{tones++;play()};
     const button=el('startWorkout');
     button.click();
     const timestamp=s.started;
     for(let i=0;i<200;i++)button.click();
     return {tones,started:timestamp===s.started && timestamp>0,label:button.textContent,disabled:button.disabled,status:el('status').textContent};
   });
   assert.deepEqual(feedback,{tones:1,started:true,label:'In corso',disabled:true,status:'SESSIONE IN CORSO · A'});
   await page.waitForFunction(()=>el('clock').textContent!=='00:00:00');
   await page.reload();
   assert(await page.locator('#startWorkout').isDisabled());
   await click('Termina');await click('Salva sessione');
   await menu('Storico');
   assert.equal(await page.locator('.historyHead').count(),1);
   for(const label of ['Settimana scorsa','Questo mese','Mese scorso','Questa settimana'])await click(label);
   await page.evaluate(()=>{
     window.calls=[];window.Android={saveFile:(...args)=>calls.push(args)};
     for(let i=0;i<5000;i++)s.history.push({date:new Date(2021,0,1).toISOString(),day:'A',duration:60,data:{Test:[{kg:20,rep:10,done:true}]}});
     save();showHistory();
   });
   assert.equal(await page.locator('.historyHead').count(),1);
   await menu('Progressi');await click('Esporta');
   assert.equal(await page.evaluate(()=>calls.at(-1)[2].split('\r\n').length),5001);
   assert(await page.evaluate(()=>{
    const max={}; for(const d of ['A','B','C'])max[d]=Array.from({length:50},(_,i)=>['E'+i,30,'6–8',3600,'',0]);
    validate(max);max.C[0][2]='xx';try{validate(max);return false}catch{}
    const [a,b]=periodBounds(1,new Date(2026,0,1));
    return a.getDate()===22&&b.getDate()===29&&a.getMonth()===11&&document.documentElement.scrollWidth<=innerWidth;
   }));
   assert.deepEqual(errors,[]);await page.close();
   console.log(path+' passed: editor, history, CSV, 5000 sessions and 150 exercises');
  }finally{await browser.close()}
 }
})().catch(e=>{console.error(e);process.exit(1)});
