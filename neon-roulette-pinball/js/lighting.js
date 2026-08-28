export class LightingController{
 constructor(){this.reset()}
 reset(){this.energy=.06;this.pulse=0;this.roulette=0;this.combo=0;this.reward=0;this.jackpot=0;this.bumpers=new Set;this.targets=new Set;this.lanes=new Set}
 update(dt){this.pulse=Math.max(0,this.pulse-dt*2.8);this.roulette=Math.max(0,this.roulette-dt*.32);this.combo=Math.max(0,this.combo-dt*.5);this.reward=Math.max(0,this.reward-dt*.8);this.jackpot=Math.max(0,this.jackpot-dt*.065)}
 add(amount){this.energy=Math.min(1,this.energy+amount);this.pulse=1}
 hitBumper(id){this.bumpers.add(id);this.add(.075)}
 hitTarget(id){this.targets.add(id);this.add(.105)}
 hitLane(id){this.lanes.add(id);this.add(.09)}
 hitCombo(count){this.combo=Math.min(1,count/8);if(count>2)this.add(.025)}
 setMultiplier(value){this.energy=Math.min(1,Math.max(this.energy,.18*value));this.reward=1}
 startRoulette(){this.roulette=1;this.add(.16)}
 startJackpot(){this.jackpot=1;this.energy=1;this.pulse=1}
 hitCoin(){this.jackpot=Math.max(this.jackpot,.55);this.reward=1;this.add(.035)}
 award(){this.reward=1;this.add(.13)}
 get stage(){return this.energy>=.82?4:this.energy>=.58?3:this.energy>=.34?2:this.energy>=.14?1:0}
 bumperLit(id){return this.bumpers.has(id)}
 targetLit(id){return this.targets.has(id)}
 laneLit(id){return this.lanes.has(id)}
 clearTargetBank(){this.targets.clear()}
 clearLanes(){this.lanes.clear()}
 snapshot(){return{energy:this.energy,stage:this.stage,pulse:this.pulse,roulette:this.roulette,combo:this.combo,reward:this.reward,jackpot:this.jackpot}}
}
