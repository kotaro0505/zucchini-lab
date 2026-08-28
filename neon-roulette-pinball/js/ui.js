export class GameUI{
 constructor(){this.score=document.querySelector('#score');this.high=document.querySelector('#high-score');this.multi=document.querySelector('#multiplier');this.balls=document.querySelector('#balls');this.lcd=document.querySelector('#lcd');this.lcdMain=document.querySelector('#lcd-main');this.lcdSub=document.querySelector('#lcd-sub');this.msg=document.querySelector('#message');this.overlay=document.querySelector('#start-overlay');this.start=document.querySelector('#start-button');this.left=document.querySelector('#left-control');this.right=document.querySelector('#right-control');this.nudge=document.querySelector('#nudge-control');this.table=document.querySelector('#table-wrap')}
 sync(state){this.score.textContent=Math.floor(state.score).toString().padStart(7,'0');this.high.textContent=Math.floor(state.high).toString().padStart(7,'0');this.multi.textContent=`×${state.multiplier}`;this.balls.textContent=Array(Math.max(0,state.balls)).fill('●').join(' ')}
 setLcd(main,sub,color=''){this.lcdMain.textContent=main;if(sub!==undefined)this.lcdSub.textContent=sub;this.lcdMain.style.color=color}
 spin(on){this.lcd.classList.toggle('spin',on)}
 message(text){this.msg.textContent=text;this.msg.classList.remove('show');void this.msg.offsetWidth;this.msg.classList.add('show')}
 control(which,on){this[which].classList.toggle('active',on)}
 nudgeBoard(direction,tilted=false){this.table.style.setProperty('--nudge-dir',String(direction||1));this.table.classList.remove('nudging','tilt-shock');void this.table.offsetWidth;this.table.classList.add(tilted?'tilt-shock':'nudging')}
 tilt(active){document.body.classList.toggle('tilted',active);this.nudge.setAttribute('aria-disabled',String(active))}
 startGame(){this.overlay.classList.add('hidden');this.overlay.inert=true;this.start.disabled=true}
 gameOver(score){this.overlay.inert=false;this.start.disabled=false;this.overlay.classList.remove('hidden');this.start.textContent='PLAY AGAIN';this.overlay.querySelector('p').innerHTML=`GAME OVER<br><strong>${Math.floor(score).toLocaleString()} pts</strong>`;this.setLcd('GAME OVER','PRESS PLAY AGAIN')}
 lighting(light){const s=light.snapshot();document.documentElement.style.setProperty('--awake',s.energy.toFixed(3));document.documentElement.style.setProperty('--pulse',Math.max(s.pulse,s.reward,s.roulette,s.jackpot).toFixed(3));document.documentElement.style.setProperty('--jackpot',s.jackpot.toFixed(3));document.body.dataset.lightStage=String(s.stage)}
}
