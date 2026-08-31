const fs=require('fs');
const path=require('path');

const OUT_DIR=path.join(__dirname,'..','assets','images','vehicles');
if(!fs.existsSync(OUT_DIR)) fs.mkdirSync(OUT_DIR,{recursive:true});

const CARS=[
  {slug:'ferrari_f8_tributo', prompt:'Ferrari F8 Tributo red supercar side view, realistic vector illustration, flat design, white background, studio lighting, highly detailed, 4k, car silhouette'},
  {slug:'ferrari_488_gtb', prompt:'Ferrari 488 GTB red supercar side view, realistic vector illustration, white background'},
  {slug:'ferrari_roma', prompt:'Ferrari Roma elegant red GT coupe side view, realistic vector illustration, white background'},
  {slug:'ferrari_sf90_stradale', prompt:'Ferrari SF90 Stradale red hybrid hypercar side view, realistic vector illustration, white background'},
  {slug:'ferrari_296_gtb', prompt:'Ferrari 296 GTB yellow hybrid supercar side view, realistic vector illustration, white background'},
  {slug:'ferrari_purosangue', prompt:'Ferrari Purosangue red SUV V12 side view, realistic vector illustration, white background'},
  {slug:'porsche_911_carrera', prompt:'Porsche 911 Carrera 992 silver sports car side view, realistic vector illustration, white background'},
  {slug:'porsche_911_gt3', prompt:'Porsche 911 GT3 white supercar side view, realistic vector illustration, white background'},
  {slug:'porsche_taycan', prompt:'Porsche Taycan electric sedan side view, realistic vector illustration, white background'},
  {slug:'porsche_cayenne', prompt:'Porsche Cayenne black SUV side view, realistic vector illustration, white background'},
  {slug:'porsche_panamera', prompt:'Porsche Panamera silver sedan side view, realistic vector illustration, white background'},
  {slug:'porsche_macan', prompt:'Porsche Macan grey SUV side view, realistic vector illustration, white background'},
  {slug:'lamborghini_aventador', prompt:'Lamborghini Aventador SVJ yellow supercar side view, realistic vector illustration, white background'},
  {slug:'lamborghini_huracan', prompt:'Lamborghini Huracan EVO green supercar side view, realistic vector illustration, white background'},
  {slug:'lamborghini_urus', prompt:'Lamborghini Urus yellow SUV side view, realistic vector illustration, white background'},
  {slug:'lamborghini_revuelto', prompt:'Lamborghini Revuelto orange hybrid supercar side view, realistic vector illustration, white background'},
  {slug:'mclaren_720s', prompt:'McLaren 720S orange supercar side view, realistic vector illustration, white background'},
  {slug:'aston_martin_db11', prompt:'Aston Martin DB11 green GT coupe side view, realistic vector illustration, white background'},
  {slug:'bentley_continental_gt', prompt:'Bentley Continental GT blue luxury coupe side view, realistic vector illustration, white background'},
  {slug:'maserati_mc20', prompt:'Maserati MC20 white supercar side view, realistic vector illustration, white background'},
  {slug:'chevrolet_camaro', prompt:'Chevrolet Camaro SS yellow muscle car side view, realistic vector illustration, white background'},
  {slug:'ford_mustang_gt', prompt:'Ford Mustang GT 5.0 blue muscle car side view, realistic vector illustration, white background'},
];

async function genOne({slug, prompt}){
  const url=`https://image.pollinations.ai/prompt/${encodeURIComponent(prompt)}?width=1024&height=1024&model=flux&seed=${Math.floor(Math.random()*1000000)}&nologo=true`;
  console.log(`\n🎨 ${slug}...`);
  const res=await fetch(url);
  if(!res.ok){ console.log(`  ❌ ${res.status}`); return false; }
  const buf=Buffer.from(await res.arrayBuffer());
  const out=path.join(OUT_DIR, `${slug}.jpg`);
  fs.writeFileSync(out, buf);
  console.log(`  ✅ ${slug}.jpg ${(buf.length/1024).toFixed(0)}KB`);
  return true;
}

(async()=>{
  // primeiro lote 5 Ferraris
  const batch=CARS.slice(0,5);
  for(const c of batch){
    await genOne(c);
    await new Promise(r=>setTimeout(r,1500));
  }
  console.log(`\nPronto lote 1/5. Total no disco: ${fs.readdirSync(OUT_DIR).length} imagens`);
})();