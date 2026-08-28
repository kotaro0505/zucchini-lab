import { weightedSucculent } from './data.js';
import { saveFind } from './collection.js';

const clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
const lerp=(a,b,t)=>a+(b-a)*t;

export function drawSucculent(c,x,y,r,s,rot=0){
  c.save(); c.translate(x,y); c.rotate(rot); c.shadowColor='#0007'; c.shadowBlur=r*.2;
  for(let ring=0;ring<3;ring++){
    const n=11-ring*2, rr=r*(1-ring*.25);
    for(let i=0;i<n;i++){
      const a=i/n*Math.PI*2+ring*.45, len=rr*(s.isBig?1.2:1); c.save(); c.rotate(a);
      const g=c.createLinearGradient(0,0,0,-len); g.addColorStop(0,s.palette[2]); g.addColorStop(.55,s.palette[0]); g.addColorStop(1,s.palette[1]); c.fillStyle=g;
      c.beginPath(); c.moveTo(-r*.13,0); c.bezierCurveTo(-r*.3,-len*.38,-r*.16,-len*.82,0,-len); c.bezierCurveTo(r*.16,-len*.82,r*.3,-len*.38,r*.13,0); c.fill(); c.restore();
    }
  }
  c.fillStyle='#f6e5c8'; c.beginPath(); c.arc(0,0,r*.12,0,7); c.fill(); c.restore();
}

export class Game{
  constructor(canvas,ui,audio,assets){
    this.cv=canvas; this.c=canvas.getContext('2d'); this.ui=ui; this.audio=audio; this.assets=assets;
    this.running=false; this.speed=1; this.t=0; this.roadBits=[]; this.scenery=[]; this.tracks=[]; this.trackClock=0;
    for(let i=0;i<68;i++) this.roadBits.push({z:Math.random(),x:(Math.random()-.5)*1.75,size:.3+Math.random()});
    for(let i=0;i<19;i++) this.scenery.push({z:Math.random(),side:Math.random()<.5?-1:1,type:i%3,seed:Math.random()});
    this.resize(); addEventListener('resize',()=>this.resize()); this.bind();
  }
  resize(){const d=Math.min(devicePixelRatio,2); this.w=this.cv.clientWidth; this.h=this.cv.clientHeight; this.cv.width=this.w*d; this.cv.height=this.h*d; this.c.setTransform(d,0,0,d,0,0)}
  bind(){
    const move=e=>{if(!this.running)return; const r=this.cv.getBoundingClientRect(),x=(e.touches?.[0]?.clientX??e.clientX)-r.left; this.targetX=clamp((x/r.width-.5)*2,-1,1)};
    this.cv.addEventListener('pointerdown',e=>{this.drag=true;move(e)}); this.cv.addEventListener('pointermove',e=>this.drag&&move(e)); addEventListener('pointerup',()=>this.drag=false); this.cv.addEventListener('touchmove',move,{passive:false});
  }
  start(){this.running=true;this.elapsed=0;this.score=0;this.rare=0;this.totalGet=0;this.maxSpeed=1;this.playerX=0;this.targetX=0;this.entities=[];this.particles=[];this.tracks=[];this.haul={};this.spawnTimer=.35;this.last=performance.now();requestAnimationFrame(t=>this.loop(t))}
  loop(now){const dt=Math.min((now-this.last)/1000,.034);this.last=now;this.t+=dt;if(this.running)this.update(dt);this.draw();if(this.running)requestAnimationFrame(t=>this.loop(t))}
  update(dt){
    this.elapsed+=dt; this.speed=Math.min(1+this.elapsed/42,2.35); this.maxSpeed=Math.max(this.maxSpeed,this.speed); const steer=Math.abs(this.targetX-this.playerX); this.playerX=lerp(this.playerX,this.targetX,1-Math.pow(.002,dt));
    this.spawnTimer-=dt*this.speed; if(this.spawnTimer<=0){this.spawnWave();this.spawnTimer=.9+Math.random()*.38}
    for(const b of this.roadBits)b.z=(b.z+dt*(.23+.09*this.speed))%1;
    for(const s of this.scenery)s.z=(s.z+dt*(.12+.07*this.speed))%1;
    this.trackClock-=dt;if(this.trackClock<=0){this.tracks.push({x:this.playerX,y:this.h*.825,life:1,strong:clamp(steer*2+.18,0,1)});this.trackClock=.045}
    for(const tr of this.tracks){tr.y+=dt*(72+this.speed*38);tr.life-=dt*(.32-.05*this.speed)}this.tracks=this.tracks.filter(tr=>tr.life>0&&tr.y<this.h*1.05);
    for(const e of this.entities){e.z+=dt*(.20+.035*this.speed);e.rot+=dt*(e.kind==='rock'?.35:.16);if(e.z>.68&&!e.hit&&Math.abs(e.x-this.playerX*.62)<(e.kind==='rock'?.18:e.data.isBig?.24:.16)){e.hit=true;if(e.kind==='rock')return this.crash();this.collect(e)}}
    this.entities=this.entities.filter(e=>e.z<1.13&&!e.hit);
    for(const p of this.particles){p.life-=dt;p.x+=p.vx*dt;p.y+=p.vy*dt;p.vy+=p.dust?-8:30} this.particles=this.particles.filter(p=>p.life>0);
    if(Math.random()<(.5+.5*steer)*this.speed) this.particles.push({x:this.w/2+this.playerX*this.w*.24+(Math.random()-.5)*this.w*.24,y:this.h*.84,vx:(Math.random()-.5)*55,vy:8+Math.random()*40,life:.35+Math.random()*.55,color:'#e5bb7a',dust:true});
    this.score+=dt*8*this.speed; this.ui.update(this);
  }
  spawnWave(){const lanes=[-.72,-.36,0,.36,.72],count=2+Math.floor(Math.random()*3),chosen=[];while(chosen.length<count){const i=Math.floor(Math.random()*lanes.length);if(!chosen.includes(i))chosen.push(i)}chosen.forEach((lane,i)=>{const rockChance=Math.min(.28+this.elapsed/180,.4),kind=i===0?'succulent':Math.random()<rockChance?'rock':'succulent';this.entities.push({kind,x:lanes[lane]+(Math.random()-.5)*.09,z:.025+Math.random()*.025,rot:Math.random()*6,data:kind==='succulent'?weightedSucculent():null,hit:false})})}
  collect(e){const s=e.data;this.score+=s.score;this.totalGet++;this.haul[s.id]=(this.haul[s.id]||0)+1;if(s.rarity!=='Normal'){saveFind(s.id);this.rare++}const kind=s.isBig?'big':s.rarity==='Normal'?'normal':'rare';this.audio.get(kind);this.ui.toast(s.isBig?'BIG LAUI GET!':s.rarity==='Normal'?`GET +${s.score}`:`${s.rarity.toUpperCase()}! +${s.score}`,kind);for(let i=0;i<(s.isBig?40:18);i++)this.particles.push({x:this.w/2+e.x*this.w*.35,y:this.h*.72,vx:(Math.random()-.5)*200,vy:-50-Math.random()*150,life:.5+Math.random()*.55,color:s.palette[i%3]})}
  crash(){this.running=false;this.audio.get('crash');this.ui.toast('CRASH!','big');setTimeout(()=>this.ui.finish(this),700)}
  project(e){const q=e.z*e.z;return{x:this.w/2+e.x*lerp(this.w*.11,this.w*.72,q),y:lerp(this.h*.325,this.h*.89,q),scale:lerp(.1,1.15,q)}}
  draw(){const c=this.c,w=this.w,h=this.h;c.clearRect(0,0,w,h);this.drawWorld(c,w,h);this.drawTracks(c);for(const e of[...(this.entities||[])].sort((a,b)=>a.z-b.z))this.entity(c,e);this.drawDust(c);if(this.running)this.drawJeep(c,w,h)}
  drawWorld(c,w,h){
    const bg=this.assets.background;
    if(bg.complete&&bg.naturalWidth){const cover=Math.max(w/bg.width,h/bg.height),dw=bg.width*cover,dh=bg.height*cover,pan=this.playerX*w*.018;c.drawImage(bg,(w-dw)/2-pan,(h-dh)/2,dw,dh)}
    else{const g=c.createLinearGradient(0,0,0,h);g.addColorStop(0,'#5bb8d7');g.addColorStop(1,'#b86b32');c.fillStyle=g;c.fillRect(0,0,w,h)}
    const haze=c.createLinearGradient(0,h*.18,0,h*.57);haze.addColorStop(0,'#fff0');haze.addColorStop(.6,'#f7d59b0d');haze.addColorStop(1,'#d28a4030');c.fillStyle=haze;c.fillRect(0,0,w,h*.65);
    for(const s of [...this.scenery].sort((a,b)=>a.z-b.z))this.drawScenery(c,s);
    for(const b of this.roadBits){const q=b.z*b.z,y=lerp(h*.34,h*1.02,q),half=lerp(w*.025,w*.55,q),x=w/2+b.x*half,len=2+q*18;c.strokeStyle=`rgba(90,51,25,${.08+q*.32})`;c.lineWidth=.5+q*2.8;c.beginPath();c.moveTo(x,y);c.lineTo(x+b.x*3,y+len);c.stroke()}
    c.globalCompositeOperation='screen';for(let i=0;i<7;i++){const y=h*(.43+i*.078)+(this.t*this.speed*66)%50;c.fillStyle='#ffe4ad20';c.fillRect(w*.17,y,w*.66,1+i*.5)}c.globalCompositeOperation='source-over';
  }
  drawTracks(c){if(this.tracks.length<2)return;c.save();c.lineCap='round';for(const offset of[-1,1]){c.beginPath();for(let i=0;i<this.tracks.length;i++){const tr=this.tracks[i],x=this.w/2+tr.x*this.w*.24+offset*this.w*.055,y=tr.y;if(i===0)c.moveTo(x,y);else c.lineTo(x,y)}const last=this.tracks[this.tracks.length-1];c.strokeStyle=`rgba(73,42,23,${.18+last.strong*.16})`;c.lineWidth=3+last.strong*2;c.setLineDash([3,5]);c.stroke()}c.setLineDash([]);c.restore()}
  drawScenery(c,s){const q=s.z*s.z,y=lerp(this.h*.33,this.h*1.12,q),x=this.w/2+s.side*lerp(this.w*.2,this.w*.68,q),r=lerp(2,65,q)*(1+s.seed*.45);c.save();c.translate(x,y);c.globalAlpha=clamp(s.z*4,0,.78);c.fillStyle='#422c2070';c.beginPath();c.ellipse(0,r*.04,r*.7,r*.18,0,0,7);c.fill();if(s.type===0){const g=c.createLinearGradient(-r,-r,r,r);g.addColorStop(0,'#b77d55');g.addColorStop(1,'#4b3426');c.fillStyle=g;c.beginPath();c.moveTo(-r*.72,0);c.lineTo(-r*.48,-r*.55);c.lineTo(0,-r*.76);c.lineTo(r*.65,-r*.42);c.lineTo(r*.72,0);c.closePath();c.fill()}else{c.fillStyle=s.type===1?'#365d43':'#496d55';c.fillRect(-r*.08,-r*.9,r*.16,r*.9);if(s.type===1){c.fillRect(-r*.38,-r*.62,r*.32,r*.11);c.fillRect(r*.05,-r*.45,r*.34,r*.1)}else for(let i=0;i<8;i++){c.save();c.rotate(i*Math.PI/4);c.beginPath();c.moveTo(0,0);c.lineTo(-r*.1,-r*.65);c.lineTo(r*.1,-r*.65);c.closePath();c.fill();c.restore()}}c.restore()}
  atlasCell(s){if(s.id.includes('cante'))return 1;if(s.id.includes('agavoides'))return 2;if(s.id.includes('pachy'))return 3;return 0}
  entity(c,e){
    const p=this.project(e),r=(e.kind==='rock'?34:e.data.isBig?54:34)*p.scale;c.save();c.globalAlpha=clamp(e.z*5,0,1);
    c.fillStyle='#24170f88';c.filter='blur(1px)';c.beginPath();c.ellipse(p.x,p.y+r*.38,r*.82,r*.2,0,0,7);c.fill();c.filter='none';
    if(e.kind==='rock')this.drawRock(c,p.x,p.y,r,e.rot);else this.drawPlant(c,e,p,r);c.restore();
  }
  drawRock(c,x,y,r,rot){c.save();c.translate(x,y-r*.14);c.rotate(rot*.09);const g=c.createRadialGradient(-r*.3,-r*.35,r*.05,0,0,r);g.addColorStop(0,'#d5a37a');g.addColorStop(.35,'#8a5d43');g.addColorStop(1,'#39281f');c.fillStyle=g;c.beginPath();for(let i=0;i<9;i++){const a=i/9*Math.PI*2,rr=r*(.75+Math.sin(i*7)*.13);c.lineTo(Math.cos(a)*rr,Math.sin(a)*rr)}c.closePath();c.fill();c.strokeStyle='#f2c89b55';c.lineWidth=Math.max(1,r*.04);c.stroke();c.restore()}
  drawPlant(c,e,p,r){const a=this.assets.atlas;if(a.complete&&a.naturalWidth){const cell=this.atlasCell(e.data),sx=(cell%2)*a.width/2,sy=Math.floor(cell/2)*a.height/2,sw=a.width/2,sh=a.height/2,scale=e.data.isBig?2.35:1.65;const size=r*scale;c.save();c.translate(p.x,p.y-r*.42);c.rotate(Math.sin(e.rot)*.025);if(e.data.isBig||e.data.rarity!=='Normal'){c.shadowColor=e.data.isBig?'#fff2a0':'#ffe0a0';c.shadowBlur=r*(e.data.isBig?1.2:.65)}c.drawImage(a,sx,sy,sw,sh,-size/2,-size*.54,size,size);c.restore();if(e.data.isBig){c.strokeStyle='#fff1a9aa';c.lineWidth=Math.max(1,r*.04);for(let i=0;i<3;i++){c.beginPath();c.arc(p.x,p.y-r*.42,r*(1+i*.18)+(Math.sin(this.t*5+i)+1)*3,0,7);c.stroke()}}}else drawSucculent(c,p.x,p.y-r*.2,r,e.data,e.rot*.08)}
  drawDust(c){for(const p of this.particles||[]){c.globalAlpha=Math.min(1,p.life)*(p.dust?.34:1);c.fillStyle=p.color;c.beginPath();c.arc(p.x,p.y,(p.dust?8:2)+p.life*(p.dust?18:4),0,7);c.fill()}c.globalAlpha=1}
  drawJeep(c,w,h){const j=this.assets.jeep;if(!j.complete||!j.naturalWidth)return;const steer=this.targetX-this.playerX,vibe=this.speed-1,bob=Math.sin(this.t*(11+vibe*3))*(1.8+vibe)+Math.sin(this.t*5)*1.1,sway=Math.sin(this.t*3.2)*(1.1+vibe*.5),lean=clamp(steer*-.085,-.09,.09),x=w/2+this.playerX*w*.25+sway,y=h*.755+bob,iw=Math.min(w*.4,190),ih=iw*j.height/j.width;c.save();c.translate(x,y);c.rotate(lean);c.fillStyle='#2d1b1190';c.filter='blur(4px)';c.beginPath();c.ellipse(0,ih*.29,iw*.48,ih*.13,0,0,7);c.fill();c.filter='sepia(.16) saturate(.82) brightness(.94) drop-shadow(0 7px 5px #40240f99)';c.drawImage(j,-iw/2,-ih*.54,iw,ih);c.filter='none';c.restore()}
}
