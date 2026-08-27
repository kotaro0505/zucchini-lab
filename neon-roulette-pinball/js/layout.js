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

export const posts=[
 {x:104,y:918,r:19},{x:696,y:918,r:19},
 {x:158,y:1008,r:14},{x:642,y:1008,r:14}
];

export const walls=[
 // Cabinet and shooter lane.
 [{x:40,y:1035},{x:40,y:132}],[{x:40,y:132},{x:136,y:44}],[{x:136,y:44},{x:664,y:44}],
 [{x:664,y:44},{x:770,y:145}],[{x:770,y:145},{x:770,y:1035}],[{x:770,y:1035},{x:680,y:1114}],
 [{x:40,y:1035},{x:120,y:1114}],[{x:724,y:205},{x:724,y:1054}],
 // Upper nest: angled guides recycle downward shots back toward the 500 bank.
 [{x:120,y:470},{x:180,y:388}],[{x:680,y:470},{x:620,y:388}],
 [{x:146,y:452},{x:242,y:510}],[{x:654,y:452},{x:558,y:510}],
 [{x:118,y:188},{x:178,y:214}],[{x:682,y:188},{x:622,y:214}],
 // Slings and broad inlane returns.
 [{x:94,y:724},{x:226,y:806}],[{x:226,y:806},{x:146,y:884}],
 [{x:706,y:724},{x:574,y:806}],[{x:574,y:806},{x:654,y:884}],
 [{x:112,y:866},{x:190,y:928}],[{x:190,y:928},{x:150,y:982}],
 [{x:688,y:866},{x:610,y:928}],[{x:610,y:928},{x:650,y:982}],
 // Apron rails leave a fair but readable center drain and soften outlane exits.
 [{x:90,y:980},{x:150,y:1062}],[{x:710,y:980},{x:650,y:1062}]
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
