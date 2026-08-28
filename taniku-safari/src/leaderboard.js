const KEY='taniku-safari-leaderboards-v1';
export class LeaderboardService{async submit(){throw new Error('submit() must be implemented')}async getRank(){return null}}
export class LocalLeaderboardService extends LeaderboardService{load(){try{return JSON.parse(localStorage.getItem(KEY))||{score:[],maxGet:[],maxSpeed:[]}}catch{return{score:[],maxGet:[],maxSpeed:[]}}}async submit(run){const data=this.load();for(const key of['score','maxGet','maxSpeed'])data[key]=[...data[key],run[key]].sort((a,b)=>b-a).slice(0,100);localStorage.setItem(KEY,JSON.stringify(data));return{worldRank:data.score.indexOf(run.score)+1,best:data.score[0]}}}
// iOS/Capacitor版では同じインターフェースでGameCenterLeaderboardServiceを実装する。
