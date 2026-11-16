// Runs the original HTML app headless and records state after each scripted step.
const {JSDOM}=require('jsdom'); const fs=require('fs');
// usage: node run_original.js <prototype.html> <steps.json> <out.json>
const html=fs.readFileSync(process.argv[2],'utf8');
// the prototype keeps some settings in localStorage: start from none, as a fresh install
const steps=JSON.parse(fs.readFileSync(process.argv[3],'utf8'));
const pre='<script>window.matchMedia=()=>({matches:false,addEventListener(){},removeEventListener(){}})</script>';
const dom=new JSDOM('<!doctype html><html><head></head><body>'+pre+html+'</body></html>',{runScripts:'dangerously',pretendToBeVisual:true,url:'https://x.test/'});
const w=dom.window; w.Element.prototype.scrollTo=function(){}; w.Element.prototype.scrollIntoView=function(){}; w.matchMedia=()=>({matches:false,addEventListener(){},removeEventListener(){}}); w.eval('var matchMedia=window.matchMedia');
w.HTMLCanvasElement.prototype.getContext=function(){ return new Proxy({},{get:(t,k)=>k==='canvas'?this:k==='getTransform'?()=>({a:1}):k==='getImageData'?()=>({data:new Uint8ClampedArray(4)}):()=>{} ,set:()=>true}) };
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
const snap=()=>JSON.parse(w.eval(`JSON.stringify({screen:S.screen,hist:S.hist,lens:S.lens,rx:S.rx,rxL:S.rxL,eye:S.eye,only:S.only,peye:S.peye||'P',aq:S.aq||1,persona:S.persona,
  wish:[...S.wish],dropped:S.dropped||0,bulk:{pid:S.bulk.pid,li:S.bulk.li,grid:S.bulk.grid,grids:Object.fromEntries(Object.entries(S.bulk.grids||{}).filter(([,g])=>Object.keys(g).length))},
  cart:S.cart.map(c=>({kind:c.kind,pid:c.pid||null,li:c.li||0,liL:c.liL==null?null:c.liL,qR:c.qR,qL:c.qL,qty:c.qty,price:Math.round(c.price*1000)/1000,rx:c.rx,rxL:c.rxL||null,diff:!!c.diff,stock:c.stock,cells:c.cells||0,grid:c.grid||{},ref:c.ref||'',note:c.note||'',pref:c.pref||'',grp:cgroup(c),free:!!c.free})),
  last:S.lastOrder?{n:S.lastOrder.n,v:Math.round(S.lastOrder.v*1000)/1000,as:S.lastOrder.as,cancelled:S.lastOrder.cancelled,group:S.lastOrder.group||'parcel'}:null,
  matches:(S.matches||[]).length, prod:S.prod?{mi:S.prod.mi==null?null:S.prod.mi,pid:S.prod.pid||null,n:S.prod.n||null}:null, rxMode:!!S.rxMode, field:S.field,
  lockR:S.lockR||null, off:S.off||{sph:false,cyl:false}, pview:S.pview||'wheel', pq:S.pq||{}, rgType:S.rgType||'SV', rgI:S.rgI||0, wishR:[...S.wishR], wishP:[...S.wishP],
  pre:S.pre.map(x=>({kind:x.kind,pid:x.pid,li:x.li,rx:x.rx||null,qR:x.qR||0,qL:x.qL||0,qty:x.qty,eye:x.eye||'',eta:x.eta||''})), bopen:[...(S.bopen||[])],
  via:S.via, byPow:!!S.byPow, pcLi:S.pcLi==null?null:S.pcLi, pqs:Object.fromEntries(Object.entries(S.pqs||{}).filter(([,q])=>Object.keys(q).length)), coGroup:S.coGroup||null, cview:S.cview||'all',
  saved:S.saved.map(c=>({kind:c.kind,pid:c.pid||null,li:c.li||0,qty:c.qty,grp:cgroup(c)}))})`));
(async()=>{ await sleep(50); const out=[];
  for(const st of steps){ try{
    if(st.click){ const el=w.document.querySelector(st.click); if(!el) throw new Error('no element '+st.click); el.click() }
    if(st.js) w.eval(st.js);
    if(st.input){ const el=w.document.querySelector(st.input[0]); if(!el) throw new Error('no input '+st.input[0]); el.value=st.input[1]; el.dispatchEvent(new w.Event('input',{bubbles:true})) }
    if(st.focus){ const el=w.document.querySelector(st.focus); el.dispatchEvent(new w.FocusEvent('focusin',{bubbles:true})) }
    await sleep(st.wait||30);
    out.push({step:st.name,state:snap()}) }catch(e){ out.push({step:st.name,error:String(e)}) } }
  fs.writeFileSync(process.argv[4],JSON.stringify(out,null,0)); console.log('steps',out.length,'errors',out.filter(x=>x.error).length); process.exit(0) })();
