// All physical and visual placement lives here so future tables and characters can swap layouts.
export const bumpers=[
 {id:'PINK',x:240,y:252,r:56,color:'#ff43a7',score:500},
 {id:'CYAN',x:560,y:252,r:56,color:'#45f4ff',score:500},
 {id:'GOLD',x:400,y:366,r:60,color:'#ffd56a',score:500}
];

export const targets=[
 {id:'A',x:280,y:630,w:86,h:26,angle:0,color:'#ff43a7'},
 {id:'B',x:400,y:630,w:86,h:26,angle:0,color:'#ffd56a'},
 {id:'C',x:520,y:630,w:86,h:26,angle:0,color:'#45f4ff'}
];

export const lanes=[{id:'L',x:180},{id:'C',x:400},{id:'R',x:620}];

// Collision posts were removed from the lower return lanes. Their old gaps overlapped
// the ball diameter and could form hard traps against the rails and shooter divider.
export const posts=[];

export const walls=[
 // Cabinet and shooter lane.
 [{x:40,y:1035},{x:40,y:132}],[{x:40,y:132},{x:136,y:44}],[{x:136,y:44},{x:664,y:44}],
 [{x:664,y:44},{x:770,y:145}],[{x:770,y:145},{x:770,y:1035}],[{x:770,y:1035},{x:680,y:1114}],
 [{x:40,y:1035},{x:120,y:1114}],[{x:724,y:205},{x:724,y:1054}],
 // Upper nest: angled guides recycle downward shots back toward the 500 bank.
 [{x:120,y:470},{x:180,y:388}],[{x:680,y:470},{x:620,y:388}],
 [{x:190,y:430},{x:280,y:500}],[{x:610,y:430},{x:520,y:500}],
 [{x:118,y:188},{x:178,y:214}],[{x:682,y:188},{x:622,y:214}],
 // Slings and broad inlane returns.
 [{x:94,y:724},{x:226,y:806}],[{x:226,y:806},{x:146,y:884}],
 [{x:706,y:724},{x:574,y:806}],[{x:574,y:806},{x:654,y:884}],
 [{x:102,y:854},{x:190,y:928}],[{x:190,y:928},{x:150,y:982}],
 [{x:698,y:854},{x:610,y:928}],[{x:610,y:928},{x:650,y:982}],
 // Apron rails leave a fair but readable center drain and soften outlane exits.
 [{x:90,y:980},{x:150,y:1062}],[{x:710,y:980},{x:650,y:1062}]
];

// Safety zones are a last-resort classic ball-search. They only activate after the
// ball has remained almost still or confined for several seconds.
export const escapeZones=[
 {id:'upper-left',x1:42,y1:310,x2:300,y2:575,vx:330,vy:-300},
 {id:'upper-right',x1:500,y1:310,x2:722,y2:575,vx:-330,vy:-300},
 {id:'upper-lanes',x1:42,y1:45,x2:722,y2:310,vx:290,vy:-250},
 {id:'center',x1:180,y1:545,x2:620,y2:850,vx:300,vy:-360},
 {id:'lower-left',x1:42,y1:800,x2:220,y2:1060,vx:390,vy:-560},
 {id:'lower-right',x1:580,y1:800,x2:722,y2:1060,vx:-390,vy:-560}
];

export const flipperSpecs={
 left:{x:214,y:1042,length:150,width:30,rest:.32,active:-.58,side:-1},
 right:{x:586,y:1042,length:150,width:30,rest:Math.PI-.32,active:Math.PI+.58,side:1}
};

export const inserts=[
 {x:85,y:782,color:'#ff43a7',stage:1},{x:715,y:782,color:'#45f4ff',stage:1},
 {x:112,y:842,color:'#ff43a7',stage:2},{x:688,y:842,color:'#45f4ff',stage:2},
 {x:165,y:954,color:'#ffd56a',stage:2},{x:635,y:954,color:'#ffd56a',stage:2},
 {x:250,y:1080,color:'#ff43a7',stage:3},{x:550,y:1080,color:'#45f4ff',stage:3},
 {x:330,y:1105,color:'#a978ff',stage:4},{x:400,y:1112,color:'#ffd56a',stage:4},{x:470,y:1105,color:'#a978ff',stage:4}
];
