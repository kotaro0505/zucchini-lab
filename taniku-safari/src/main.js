import{Game,drawSucculent}from'./game.js?v=infinite6';
import{AudioSystem}from'./audio.js';
import{renderCollection,loadCollection}from'./collection.js';
import{ScoreManager}from'./score-manager.js';
import{LocalLeaderboardService}from'./leaderboard.js';
const $=s=>document.querySelector(s),screens=[...document.querySelectorAll('.screen')],show=id=>screens.forEach(s=>s.classList.toggle('active',s.id===id));
const image=src=>{const i=new Image();i.src=src;return i};
const assets={jeep:image('assets/images/jeep/safari-jeep.png'),far:image('assets/images/background/mexican-trail-wide.png'),scenery:image('assets/images/background/desert-scenery-atlas.png'),atlas:image('assets/images/succulents/specimen-atlas.png')};
const audio=new AudioSystem(),scoreManager=new ScoreManager(),leaderboard=new LocalLeaderboardService();
const ui={update(g){$('#score').textContent=Math.floor(g.score).toString().padStart(5,'0');$('#rare').textContent=g.rare;const n=Math.min(7,Math.ceil(g.speed*2.7));$('#speedBars').innerHTML=Array.from({length:7},(_,i)=>`<i class="${i<n?'on':''}" style="height:${8+i*2}px"></i>`).join('')},toast(text,kind){const t=$('#toast');t.textContent=text;t.className='';void t.offsetWidth;t.classList.add('show');if(kind==='big')t.classList.add('big');if(kind!=='normal'){$('#flash').className='';void $('#flash').offsetWidth;$('#flash').className='on'}},finish(g){const run=scoreManager.buildRun(g);$('#finalScore').textContent=run.score.toLocaleString();$('#resultTitle').textContent=g.rare?'レア個体を発見！':'サファリ終了';$('#haul').innerHTML=Object.entries(g.haul).map(([id,n])=>`<span>${id.replaceAll('_',' ')} ×${n}</span>`).join('')||'<span>次はきっと出会える</span>';leaderboard.submit(run).then(r=>$('#haul').insertAdjacentHTML('beforeend',`<span>LOCAL RANK #${r.worldRank} · BEST ${r.best.toLocaleString()}</span>`));$('#hud').hidden=true;show('result')}};
const game=new Game($('#game'),ui,audio,assets);Object.values(assets).forEach(i=>i.onload=()=>game.draw());
Promise.allSettled(Object.values(assets).map(i=>i.decode())).then(()=>game.draw());
function start(){audio.init();show('');$('#hud').hidden=false;game.start()}function home(){game.running=false;$('#hud').hidden=true;show('title');$('#collectionCount').textContent=`${Object.keys(loadCollection()).length} / 7`}
$('#start').onclick=start;$('#retry').onclick=start;document.querySelectorAll('.home').forEach(b=>b.onclick=home);$('#collection').onclick=()=>{renderCollection($('#collectionGrid'),drawSucculent);show('collectionScreen')};$('#sound').onclick=()=>{$('#sound').textContent=(audio.muted=!audio.muted)?'×':'♪'};home();game.draw();
