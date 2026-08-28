export class ScoreManager{buildRun(game){return{score:Math.floor(game.score),maxGet:game.totalGet||0,maxSpeed:Math.round((game.maxSpeed||1)*100),rare:game.rare||0,finishedAt:Date.now()}}}
