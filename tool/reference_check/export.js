// Reference vectors for the Dart port, from the HTML prototype itself (6 Nov 2026, v116).
// Loads the prototype headless with jsdom and runs its own functions, so nothing is copied by hand.
//
//   npm i jsdom@24
//   node export.js ../../reference/air-smart-lens-prototype.html ../../test/fixtures/js_reference.json
const { JSDOM, VirtualConsole } = require('jsdom');
const fs = require('fs');

const [, , htmlPath, outPath] = process.argv;
const vc = new VirtualConsole();
const dom = new JSDOM(fs.readFileSync(htmlPath, 'utf8'), {
  runScripts: 'dangerously',
  pretendToBeVisual: true,
  virtualConsole: vc,
  beforeParse(w) {
    w.HTMLCanvasElement.prototype.getContext = () =>
      new Proxy({}, { get: (t, k) => (k === 'canvas' ? {} : typeof k === 'string' && /^(create|get|measure)/.test(k) ? () => ({ addColorStop() {}, data: new Uint8ClampedArray(4), width: 0 }) : () => {}) });
    w.matchMedia = () => ({ matches: false, addEventListener() {}, addListener() {} });
    w.requestAnimationFrame = (f) => setTimeout(f, 16);
    w.cancelAnimationFrame = clearTimeout;
    w.scrollTo = () => {};
    w.Element.prototype.scrollTo = function () {};
    w.Element.prototype.scrollIntoView = function () {};
  },
});

const vec = dom.window.eval(`(() => {
  const vec={hash:[],grids:[],match:[],sentences:[],money:[],codes:[],fill:[],cells:[],pow:[],na:[],qr:[],scan:[],ranges:{},price:[]};
  ['a','12:0','last0|-0.25','1:3:-2/-0.5@90|1.25','मूल्य','so:6:0:-2|-0.5'].forEach(s=>vec.hash.push([s,hash(s)]));
  CATALOG.forEach(p=>p.lines.forEach((l,li)=>{ const g=lineGrid(p,li);
    vec.grids.push({pid:p.id,li,isAdd:g.isAdd,rows:g.rows.map(r=>[r.key,r.label]),cols:g.cols,cells:[...g.cells].sort(),sm:g.sm||null,smt:g.smt||null});
    // simulated stock of every 7th box of every range
    [...g.cells].sort().forEach((k,i)=>{ if(i%7===0){ const s=cellStock(p,li,k); vec.cells.push([p.id,li,k,s.state,!!s.low,s.qty??null,s.eta||'']) } }) }));
  const rxs=[]; for(const lt of ['SV','KT','PROG']) for(const sph of [-8,-6.25,-4.75,-3,-2,-1.25,-0.25,0,0.75,2,3.25,4.5]) for(const cyl of [0,-0.5,-1.25,-2.25,-4.75,0.5,1.75]) for(const ax of (lt==='SV'?[90]:[45,90,100,180])) for(const add of (lt==='SV'?[2]:[0.75,2,3.25])) rxs.push([lt,{sph,cyl,axis:ax,add}]);
  rxs.forEach(([lt,rx])=>{ const m=matchProducts(lt,rx,null);
    vec.match.push({lt,rx,res:m.map(x=>[x.p.id,x.li,x.liL,x.uR.sph,x.uR.cyl,x.uR.axis,x.uR.add,x.diff,x.mto]),code:rxCode(m,rx,null)});
    m.forEach((x,i)=>{ if(x.mto) return; const ps=powStock(x); vec.pow.push({lt,rx,i,key:cellKey(x.p,x.li,x.uR),state:ps.state,low:!!ps.low,eta:ps.eta||''});
      if(ps.state==='na') vec.na.push({lt,rx,i,alts:naAlts(x).map(a=>({sph:a.rx.sph,cyl:a.rx.cyl,label:a.lab,low:!!a.low}))});
      if(i<2) vec.qr.push({lt,rx,i,eye:'P',code:qrCodeFor(x,'P')}); }) });
  [[{sph:-2,cyl:-0.5,axis:90,add:2},{sph:-2.5,cyl:-0.75,axis:90,add:2}],[{sph:1,cyl:0,axis:90,add:2},{sph:1.5,cyl:-0.5,axis:180,add:2}]].forEach(([r,l])=>['SV','KT','PROG'].forEach(lt=>{
    const m=matchProducts(lt,r,l); vec.match.push({lt,rx:r,rxL:l,res:m.map(x=>[x.p.id,x.li,x.liL,x.uR.sph,x.uR.cyl,x.uR.axis,x.uR.add,x.diff,x.mto,x.uL?x.uL.sph:null,x.uL?x.uL.cyl:null]),code:rxCode(m,r,l)});
    m.slice(0,2).forEach((x,i)=>{ if(!x.mto) vec.qr.push({lt,rx:r,rxL:l,i,eye:lt==='PROG'?'P':'P',code:qrCodeFor(x,'P')}) }) }));
  [0,5,38,1234,99999,125680,374320,2479680,12345678.6].forEach(n=>vec.money.push([n,money(n)]));
  [[0,0],[-2,0],[-2,-0.5],[2,-1],[-7,-3],[-13,-1],[4,2],[-16,-5]].forEach(([s,c])=>vec.codes.push([s,c,rangeCode(s,c)]));
  // sentences
  S.cart=[]; let m=matchProducts('SV',{sph:-2,cyl:-0.5,axis:90,add:2},null); pushLine(m[0],1.5,1.5); vec.sentences.push([S.cart[0],sentence(S.cart[0])]);
  S.cart=[]; m=matchProducts('PROG',{sph:-1.5,cyl:-0.5,axis:90,add:2},null); pushLine(m[0],1,0); vec.sentences.push([S.cart[0],sentence(S.cart[0])]);
  S.cart=[]; m=matchProducts('PROG',{sph:-1.5,cyl:-0.5,axis:90,add:2},{sph:-1.75,cyl:-0.5,axis:90,add:2}); pushLine(m[0],1,1); vec.sentences.push([S.cart[0],sentence(S.cart[0])]);
  S.cart=[];
  // repeat-order grid
  S.bulk={pid:META.repeat,li:0,grid:{},sel:null}; fillPast('last'); vec.fill.push(['last',{...S.bulk.grid}]); fillPast('aug'); vec.fill.push(['aug',{...S.bulk.grid}]);
  // scanning: good codes, and the errors
  [...SCAN_SAMPLES, ...vec.qr.slice(0,40).map(q=>q.code), 'hello', 'VOC1|999|P|0|-2|0|180|2', 'VOC1|1|P|99|-2|0|180|2', 'VOC1|1|P|0|-30|0|180|2', 'VOC1|1|X|0|-2|0|180|2', ' voc1|1|P|0|-2|0|180|2']
    .forEach(c=>{ const r=parseScan(c); vec.scan.push(r.err?{code:c,err:r.err}:{code:c,pid:r.p.id,eye:r.eye,li:r.li,rx:r.rx,liL:r.liL,rxL:r.rxL}) });
  // QR modules of a few codes (qrcode-generator, M)
  vec.qrm=SCAN_SAMPLES.slice(0,3).map(c=>[c,qrMatrix(c).map(r=>r.map(b=>b?1:0).join('')).join('/')]);
  // Shop by range
  ['SV','KT','PROG'].forEach(t=>{ vec.ranges[t]=rangeIndex(t).map(r=>[r.code,r.g,r.items.length,r.from??null]) });
  CATALOG.forEach(p=>vec.price.push([p.id,fromPrice(p)??null,p.lines.map((l,li)=>pairPrice(p,li,li)??null)]));
  // 6 Nov: search with the trade's short forms (lensTags / lensMatch)
  vec.tags=CATALOG.map(p=>[p.id,lensTags(p)]);
  vec.search=['BC','brc','PC','PG','photogray','HC','hard coat','V2','prog','LRB','O2','DC','BBC','pg bc 1.56','pc v2','opal','1.67','hmc','kt green','air smart 1.60','x'].map(q=>[q,CATALOG.filter(p=>lensMatch(p,q)).map(p=>p.id)]);
  return JSON.stringify(vec);
})()`);
fs.writeFileSync(outPath, vec);
const v = JSON.parse(vec);
console.log('ok', Object.fromEntries(Object.entries(v).map(([k, x]) => [k, Array.isArray(x) ? x.length : Object.keys(x).length])));
process.exit(0);
