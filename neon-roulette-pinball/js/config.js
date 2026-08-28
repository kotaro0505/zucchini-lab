export const W=800,H=1200;

// Ball feel stays deliberately heavy and fast. Layout, not slow motion, creates breathing room.
export const table={gravity:1180,ballRadius:14,maxSpeed:1850,restitution:.7,friction:.9985,drainY:1176};

export const rewards=[
 {id:'JACKPOT',label:'JACKPOT COIN RAIN',color:'#ffd56a'},
 {id:'MULTI',label:'2× MULTIPLIER',color:'#4ef6ff'},
 {id:'FRENZY',label:'BUMPER FRENZY',color:'#ff4cab'},
 {id:'SAVE',label:'BALL SAVE',color:'#8dffb0'},
 {id:'BONUS',label:'BONUS BALL',color:'#f7fbff'},
 {id:'MAGNET',label:'NEON MAGNET',color:'#b995ff'}
];

export const palette={
 playfield:'#0a1020',rail:'#c7d2df',cyan:'#45f4ff',pink:'#ff43a7',amber:'#ffd56a',
 violet:'#a978ff',green:'#7dffa8',chromeDark:'#27303c',glass:'#b9eaff'
};
