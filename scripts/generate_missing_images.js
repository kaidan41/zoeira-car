const fs=require('fs');
const path=require('path');
const OUT_DIR=path.join(__dirname,'..','assets','images','vehicles');
if(!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR,{recursive:true});
const vehicles=require('./data/vehicles');
const missing=vehicles.filter(v=>!v.thumbnail_url || v.thumbnail_url==='');
console.log(`Encontrados ${missing.length} sem imagem.`);
const batch=missing.slice(0,10);
if(batch.length===0){ console.log('Nenhum pendente.'); process.exit(0); }
console.log(`Gerando lote de ${batch.length}: ${batch.map(v=> v.brand+' '+v.model).join(', ')}`);
async function genOne(v){
  const brandSlug=v.brand.toLowerCase().replace(/\s+/g,'_').replace(/[^a-z0-9_]/g,'');
  const modelSlug=v.model.toLowerCase().replace(/\s+/g,'_').replace(/[^a-z0-9_]/g,'');
  const fileName=`${brandSlug}_${modelSlug}.jpg`;
  const prompt=`${v.brand} ${v.model} ${v.version} side view, realistic vector illustration, white background, studio lighting, highly detailed`;
  for(let a=0;a<3;a++){
    const url=`https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=1024&height=1024&model=flux&seed=${Math.floor(Math.random()*1e6)}&nologo=true`;
    console.log(`  🎨 ${v.brand} ${v.model}...`);
    try{
      const r=await fetch(url);
      const b=Buffer.from(await r.arrayBuffer());
      if(b.length<5000){ console.log('    rate limit, 40s...'); await new Promise(r=>setTimeout(r,40000)); continue; }
      fs.writeFileSync(path.join(OUT_DIR,fileName),b);
      console.log(`    ✅ ${fileName} ${(b.length/1024).toFixed(0)}KB`);
      await new Promise(r=>setTimeout(r,35000));
      return fileName;
    }catch(e){ console.log('    erro',e.message); await new Promise(r=>setTimeout(r,10000)); }
  }
  return null;
}
(async()=>{
  let text=fs.readFileSync(path.join(__dirname,'data','vehicles.js'),'utf8');
  let ok=0;
  for(const v of batch){
    const fn=await genOne(v);
    if(fn){
      const asset=`assets/images/vehicles/${fn}`;
      const escB=v.brand.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
      const escM=v.model.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
      const escV=v.version.replace(/[.*+?^${}()|[\]\\]/g,'\\$&');
      const re=new RegExp(`(brand: '${escB}',\\s+model: '${escM}',\\s+version: '${escV}',[\\s\\S]*?thumbnail_url: )'[^']*'`);
      text=text.replace(re,`$1'${asset}'`);
      ok++;
    }
  }
  fs.writeFileSync(path.join(__dirname,'data','vehicles.js'),text,'utf8');
  console.log(`\n✅ ${ok} imagens geradas e vehicles.js atualizado. Total em disco: ${fs.readdirSync(OUT_DIR).length}`);
})();