proc format;
value yesnofmt  1='Yes' 0='No';
value rac  1='African American' 2='White' 3='Other';
value gender  0='Male' 1='Female';
value intv 0='SA' 1='PA';
value grip_bb 0="Normal+Intermediate" 1="Weak" ;
value grip_kk 0="Normal" 1="Weak+Intermediate"; /*2="Intermediate";*/
run;

proc means data=life4.life01b_activitystatus_v3_1 nmiss;run;
proc contents data=fare.act0;run;


proc print data=fare.wideact;run;


/*maximal FOLLOW-UP TIME*/


/*Reason to delete PIV is in other health event dataset there are no record for vc=PIV, and very few for CLS. But kept CLS for the follow-up time*/
data fare.longact;
set life4.life01b_activitystatus_v3_1;
/*SET TIME AS MAX OF FOLLOW-UP DAYS*/
time=checklist_days;
if alive=0 then time=deceased_days;
if withdrew_consent=1 then time=dropout_days;
if withdrew_consent=. then withdrew_consent=0;
if vc="PIV" then delete;
/*these are people whose CLsS VISIIT DAYS=. */
if maskid=17508 and vc="CLS" then delete;
if maskid=22982 and vc="CLS" then delete;
if maskid=24610 and vc="CLS" then delete;
if maskid=26264 and vc="CLS" or vc="F36" then delete;
if maskid=28200 and vc="CLS" then delete;
if maskid=44791 and vc="CLS" then delete;
keep maskid vc time ;run;

proc transpose data=fare.longact out=fare.wideact prefix=visit_;by maskid;id vc;var time;run;

/*6 month time TIME*/
data  fare.mon6_act;
set  fare.wideact;
keep maskid visit_F06 ;run; 

/*maximal FOLLOW-UP TIME*/
data  fare.lastact;
set  fare.longact;
by maskid;
if last.maskid then output;run; 

/*NON-FALLERS' FOLLOW-UP TIME*/
data fare.act_status;
merge fare.lastact fare.mon6_act;
follow_up_days=time-visit_f06+1;
label follow_up_days="Last visit days- F06 visit days  ";
drop time;
by maskid;
run;

proc print data=life4.life01b_activitystatus_v3_1 ;where maskid=17508;run;
/*INTERVENTION*/
data fare.intervention;
set life4.life01_key_v3_1;
keep maskid intervention;
run;

/*BASELINE*/
data fare.baseline;
set life4.baseline_key_variables_v3_1;
keep MaskID strata_gender age racevar recode_edu bmi hrtattk_mhah hrtfailr_mhah diabetes_mhah arthrits_mhah  
trial1_grip trial2_grip tot_scr_sppb walk_time _3mse cesdscore avesbp /*lungdis_mhah*/;
run;

/*BASE + ITVT*/
data fare.com;
merge life.intervention fare.baseline(in=ino);
by maskid;
if ino;
run;

/*MED HIST*/
data fare.medhis000;
set life4.F014_medicalhospadmhistory_v3_1;
keep MaskID hbp_mhah hrtattk_mhah hrtfailr_mhah stroke_mhah diabetes_mhah  numfall_mhah arthrits_mhah foot_mhah depress_mhah 
footulcr_mhah dizzness_mhah fallsdoc_mhah insulin_mhah depress_mhah knees_mhah hips_mhah backpain_mhah hands_mhah hbpmed_mhah;
run;

data fare.medhis00;
set fare.medhis000;
if hbp_mhah =1 then hbp=1;else if hbp_mhah=0 then hbp=0;else hbp=.;/* -7=refused  -8=don't know*/
if hbpmed_mhah =1 then hbpmed=1;else if hbpmed_mhah=0 then hbpmed=0;else hbpmed=0;
if diabetes_mhah =1 then diabetes=1;else if diabetes_mhah=0 then diabetes=0;else diabetes=.;
/*if arthrits_mhah =1 then arthrits=1;else if arthrits_mhah=0 then arthrits=0;else arthrits=.;**/
if depress_mhah =1 then depress=1;else if depress_mhah=0 then depress=0;else depress=.;
if dizzness_mhah =1 then dizzness=1;else if dizzness_mhah=0 then dizzness=0;else dizzness=.;
if footulcr_mhah =1 then footulcr=1;else if footulcr_mhah=0 then footulcr=0;else footulcr=.;
if insulin_mhah =1 then insulin=1;else if insulin_mhah=0 then insulin=0;else insulin=0;
if hrtattk_mhah =1 then hrtattk=1;else if hrtattk_mhah=0 then hrtattk=0;else hrtattk=.;
if hrtfailr_mhah =1 then hrtfailr=1;else if hrtfailr_mhah=0 then hrtfailr=0;else hrtfailr=.;
if stroke_mhah =1 then stroke=1;else if stroke_mhah=0 then stroke=0;else stroke=.;
if knees_mhah  =1 then knee=1;else if knees_mhah =0 then knee=0;else knee=0;
if hips_mhah  =1 then hip=1;else if hips_mhah =0 then hip=0;else hip=0;
if backpain_mhah  =1 then backpain=1;else if backpain_mhah =0 then backpain=0;else backpain=0;
if foot_mhah   =1 then foot=1;else if foot_mhah  =0 then foot=0;else foot=0;
if hands_mhah   =1 then hand=1;else if hands_mhah  =0 then hand=0;else hand=0;
if fallsdoc_mhah   =1 then basefallinjury=1;else if fallsdoc_mhah  =0 then basefallinjury=0;else basefallinjury=0;
label basefallinjury="At baseline, whether got injured due to falls";
label numfall_mhah="#falls in the past year";
drop hbp_mhah hbpmed_mhah hrtattk_mhah hrtfailr_mhah stroke_mhah diabetes_mhah insulin_mhah 
fallsdoc_mhah  hands_mhah knees_mhah hips_mhah backpain_mhah foot_mhah depress_mhah footulcr_mhah dizzness_mhah; 
run;

/*base+med hist**/
data fare.medhis0;
merge fare.medhis00(in=ino) fare.com(in=inm);
by maskid;
if ino and inm;
run;
data fare.med_base;
set  fare.medhis0;
if hrtattk=1 or hrtfailr=1 or stroke=1 then cvd=1; else  cvd=0;
if arthrits_mhah=1 or knee=1 or hip=1 or backpain=1 or hand=1 or foot=1 then arthrits=1; else arthrits=0;/* could be problematic*/
comorindex=sum(of depress hbp cvd diabetes arthrits);
if recode_edu<4 or recode_edu=6 then edu_college=0;else if recode_edu=4 or recode_edu=5 then edu_college=1;
if intervention='Physical Activity' then itvt=1;else if intervention='Successful Aging' then itvt=0;
label comorindex="sum(of depress hbp cvd diabetes arthrits)";
label  cvd="if hrtattk=1 or hrtfailr=1 or stroke=1";
label edu_college="Whether had college education";
if racevar = 1 then race=1;else if racevar=4 then race=2;else race=3;
/*1=Black,2=NatAm,3=Asian,4=White,5=Hawai,6=Hisp,7=Oth,8=Ref*/
drop arthrits_mhah cesdscore recode_edu racevar intervention;
run;

/*QOL-VIS-URI*/
/*qualityoflife- VIS impairment- URINARY incontinence*/
data  fare.visual_urinary;
set life4.f018_qualitywellbeing_v3_1;
keep maskid visprob0_qwbs visprob1_qwbs visprob2_qwbs visprob3_qwbs visprob4_qwbs blindboth_qwbs blndone_qwbs bladder0_qwbs 
bladder1_qwbs bladder2_qwbs bladder3_qwbs bladder4_qwbs;
run;
proc sort data=  fare.visual_urinary out =  fare.vis_uri00 nodupkey;by maskid;run;


/*VIS impairment- URINARY incontinence* #1635 obs*/
data  fare.vis_uri0;
set  fare.vis_uri00;
if visprob0_qwbs=1 and blindboth_qwbs=0 and blndone_qwbs=0 then visimp=0;
else if visprob0_qwbs=. or blindboth_qwbs=1 or blndone_qwbs=1 then visimp=1 ;
if bladder0_qwbs=. then uripbl=1;
else uripbl=0;
drop visprob0_qwbs visprob1_qwbs visprob2_qwbs visprob3_qwbs visprob4_qwbs bladder0_qwbs bladder1_qwbs bladder2_qwbs bladder3_qwbs bladder4_qwbs blindboth_qwbs blndone_qwbs;
run;


/*COMBINE med_base and vis_uri*/
data fare.com_2;
merge fare.vis_uri0 fare.med_base(in=inp);
by maskid;
if inp;run;


/*FALL INJURIES*//*Add up all fractures and if > 0 then fallfrac = 1 */
data fare.fallfrac0;
set life4.life15_fallsfractures_v3_2;
if pb_reported =1 or  pb_reported =2  then fall_injury=1 ;else fall_injury=0;
label  fall_injury="Serious falls lead to injuries";
drop  hosp_matched anyfracture_matched pb_reported
hand_matched lowerarm_matched elbow_matched facial_matched upperarm_matched rib_iffa_matched pelvis_iffa_matched hip_matched uleg_femur_iffa_matched 
knee_matched leg_tib_iffa_matched leg_ankle_iffa_matched foot_matched oth_iffa_matched spine_iffa_matched tailbone_iffa_matched OTHER_CAT_matched ;
run;

/*proc print data=life.fallfrac0 ;run;
proc  contents data=life.fallfrac0 varnum;run;
proc  freq data=life.fallinjury; table seriousfall_num;run;*/

data fare.fallinjuryonly ;set fare.fallfrac0;  where fall_injury=1;run;

/*TO GET TOTAL NUMBER OF SERIOUS FALLS*/
data fare.fallinjury;
set fare.fallinjuryonly;
by maskid;
if first.maskid then seriousfall_num=0;
seriousfall_num+1;
if last.maskid then output;
run;
/*
proc freq data=life.life.fallinjury; table seriousfall_num;run;
proc print data=life.fallfrac0;run;*/
/************************************************************************************************************
********************************************************************************************************************************
*********************************************************************************************************************
***************************************************************************************************************************************************
************************************************************************************************************
********************************************************************************************************************************/
/*COMBINE FALL AND BASELINE*/
data fare.fall_base0;
merge fare.fallinjury fare.com_2(in=iny);
by maskid;
if iny;
run;

proc contents data=life4.life10_accelerometry_v3_1 varnum;run; quit;

/*ACCELOROMETER- EXPOSURE */ /*LONG FORMAT*/
data fare.steps0;     /*5457*/
set life4.life10_accelerometry_v3_1;
if valid_days < 5 then steps_total= . ;
keep maskid vc steps_total valid_days;if vc="PIV" then delete;run;

proc transpose data=fare.steps0 out =fare.stepwide prefix=step_;
by maskid;id vc;
var steps_total;
run;

/****CALCULATE STEPSDAYS*******/
data shenmegui ;merge fare.wideact(in=inu) fare.fallinjury;by maskid;if inu ;run;
data mdzz;merge shenmegui fare.stepwide(in=inu); by maskid ;if inu;drop _name_ _lable_; run;
proc print data=mdzz;where fall_days< visit_f06 ;run;
data gaomaoa ;set mdzz; 
if  fall_days ne . and fall_days< visit_f06 then delete ;
if step_f06=. then step_f06=step_sv1;
if step_f06=. and step_sv1=. then step_f06= step_f12;
if step_f06=. and step_sv1=. and step_f12=. then step_f06= step_f18;
if step_f06=. and step_sv1=. and step_f12=. and step_f18=. then step_f06= step_f24;
run;
data gaomaoa;set gaomaoa;
if step_f12=. then step_f12=step_f06; 
run;
data gaomaoa;set gaomaoa;
if step_f18=. then step_f18=step_f12; 
run;
data gaomaoa;set gaomaoa;
if step_f24=. then step_f24=step_f18; 
run;
data gaomaoa;set gaomaoa;
if visit_CLS=. and visit_f42 ne . then visit_CLS = visit_f42;
if step_f24=. and step_f18=. and step_f12=.  and step_06=. then delete;
steptotal06=(visit_f12-visit_f06+1)*step_f06;/*'+1' is for including the day of visit 6 since it was used as baseline here*/
steptotal12=(visit_f18-visit_f12)*step_f12;
steptotal18=(visit_f24-visit_f18)*step_f18;
steptotal24=(visit_f30-visit_f24)*step_f24;/*gonna be missing if visit_f30 is missing*/
steptotal30=(visit_CLS-visit_f30)*step_f24;
run;
/*1509 obs*/
data fare.steps_days;set gaomaoa;
if fall_injury=. then fall_injury=0;
if fall_injury=1 then do;
	if fall_days<=visit_f12 then steptotal= (fall_days-visit_f06+1)*step_f06;/*'+1' is for including the day of visit 6 since it was used as baseline here*/
	else if visit_f12<fall_days<=visit_f18 then steptotal= (fall_days-visit_f12)*step_f12 + steptotal06;
	else if visit_f18<fall_days<=visit_f24 then steptotal= (fall_days-visit_f18)*step_f18 + sum(steptotal06,steptotal12);
	else if visit_f24<fall_days<=visit_f30 and visit_f30 ne . then steptotal= (fall_days-visit_f24)*step_f24 + sum(steptotal06,steptotal12,steptotal18);
	else if visit_f30<fall_days<=visit_CLS and visit_CLS ne . then steptotal= (fall_days-visit_f30)*step_f24 + sum(steptotal06,steptotal12,steptotal18,steptotal24);
end;
if fall_injury=0 then steptotal= sum(steptotal06,steptotal12,steptotal18,steptotal24,steptotal30 );
drop visit_sv2 _label_ f06_12 ;
run;
data fare.step_days;
set fare.steps_days;
keep maskid steptotal;run;


/*BASE+ ACT_STATUS*/
data fare.fall_base1;
merge fare.fall_base0(in=ino) fare.act_status(in=inm);
by maskid;
if ino and inm;run;
/*BASE_ACT + STEPS-DAYS*/
data fare.fall_base2;
merge fare.fall_base1(in=ino) fare.step_days(in=inm);
by maskid;
if ino and inm;
if fall_injury=. then fall_injury=0;
if seriousfall_num=. then seriousfall_num=0;
if fall_injury=1 then follow_up_days=fall_days-visit_f06 + 1;
format dizzness footulcr hbp hbpmed cvd arthrits diabetes depress insulin basefallinjury edu_college 
fall_injury visimp uripbl hrtattk hrtfailr stroke knee hip backpain foot hand basefallinjury yesnofmt.
	   race rac.
	   strata_gender gender.
	   itvt intv.;
run;
/*TILL HERE, WE HAVE 1505 OBS*/
/*READY FOR ANALYSIS WITHOUT GRIP_STRENGTH DATA*/


/***************************************************************************************************************************************************
************************************************************************************************************
********************************************************************************************************************************/
proc contents data=life4.f020_gripstrength_v3_1 varnum;run;

/*Get 12 month Grip Strength */
data fare.grip_strength;
set life4.f020_gripstrength_v3_1;where vc="F12"; run;

data fare.grip_strength;set fare.grip_strength;
if trial1_grip>trial2_grip then grip=trial1_grip;else grip=trial2_grip;keep maskid vc grip;run;

/* 1424 OBS AFTER DELETING MISSING*/
PROC MEANS DATA=FARE.FALL_BASE2 NMISS;RUN;
/* CATEGORIZE GRIP STRENGTH */
data fare.fall_base3;
set fare.fall_base2;
if trial1_grip=.  and trial2_grip=. then delete; /*81/82 MISSING*/
if trial1_grip>trial2_grip then grip_k=trial1_grip;
else grip_k=trial2_grip;
grip_q=grip_k/bmi;
drop trial1_grip trial2_grip;
run;
proc print data=fare.fall_base3(obs=10);VAR FOLLOW_UP_DAYS MASKID STEPTOTAL;run;


data fare.fall_base4;
set fare.fall_base3;
/*males (< 1.002kg/kg/m2) females(<0.557 Kg/kg/m2) weakness;normal (=1.002 kg/kg/m2) for men and (=.668hg/kg/m2)for females8. */
if grip_q<1.002 and strata_gender=0 then grip_bmi=1;/*weak*/
else if grip_q>=1.002 and strata_gender=0 then grip_bmi=0;/*normal*/

else if grip_q<0.557 and strata_gender=1 then grip_bmi=1;
else if grip_q>=0.557 and strata_gender=1 then grip_bmi=0;
/*else if grip_q<0.557 and strata_gender=1 then grip_bmi=1;/*weak
else if grip_q>=0.668 and strata_gender=1 then grip_bmi=0;/*normal
else if 0.557=< grip_q <0.668 and strata_gender=1 then grip_bmi=2;intermediate*/

/*grip kg cut off point 1*/
if grip_k<26 and strata_gender=0 then grip_kg=1;
else if grip_k>32 and strata_gender=0 then grip_kg=0;
else if 26<=grip_k<=32 and strata_gender=0 then grip_kg=2;

else if grip_k<16 and strata_gender=1 then grip_kg=1;
else if grip_k>20 and strata_gender=1 then grip_kg=0;
else if 16<=grip_k<=20 and strata_gender=1 then grip_kg=2;

/*grip kg cut off point 2
if grip_k<26 and strata_gender=0 then grip_kg=1;
else if grip_k>=26 and strata_gender=0 then grip_kg=0;
else if grip_k<16 and strata_gender=1 then grip_kg=1;
else if grip_k>=16 and strata_gender=1 then grip_kg=0;*/

/*grip kg cut off point 3
if grip_k<=32 and strata_gender=0 then grip_kg=1;
else if grip_k>32 and strata_gender=0 then grip_kg=0;
else if grip_k<=20 and strata_gender=1 then grip_kg=1;
else if grip_k>20 and strata_gender=1 then grip_kg=0;*/

format  grip_bmi grip_bb.
       grip_kg grip_kk.;
label grip_k="Grip Strenth KG"
	  grip_q="Grip Strenth KG/KG/M square"
	  grip_bmi="Grip Category 0=Normal+Intermediate 1=Weak "
	  grip_kg="Grip Category 0=Normal 1=Weak  "
	  itvt="Intervention";
run;

/*proc print data=fare.steps0(obs=40);run;
proc means data=fare.fall_base nmiss n;run;
proc print data=fare.fall_base;where maskid=26264;run;*/

/************************************************************************************************************
********************************************************************************************************************************
*********************************************************************************************************************
***************************************************************************************************************************************************
************************************************************************************************************
********************************************************************************************************************************/
 


/*CALCULATE INCIDENCE RATE*/
/******************************************************************************************************************************
********************************************************************************************************************/

proc means data=fare.fall_base3 median q1 q3 ;
var follow_up_days fall_injury steptotal;
class itvt;
output out=fare.descrp_itvt
sum(steptotal)=sum_exposure
sum(fall_injury)=cases
sum(follow_up_days)=person_days;
run;

/*GRAPHS*/
ods pdf;
title "Steps-days";
proc sgplot data=fare.fall_base4;
vbox steptotal/category= grip_bmi; /* VBOX for Vertical Boxplots */
run;
proc sgplot data=fare.fall_base4;
vbox steptotal/category= grip_kg; /* VBOX for Vertical Boxplots */
run;
proc sgplot data=fare.fall_base4;
vbox steptotal/category= itvt; /* VBOX for Vertical Boxplots */
run;

title "Person-days"
proc sgplot data=fare.fall_base4;
vbox follow_up_days/category=grip_bmi; /* VBOX for Vertical Boxplots */
run;
proc sgplot data=fare.fall_base4;
vbox follow_up_days/category= grip_kg; /* VBOX for Vertical Boxplots */
run;
proc sgplot data=fare.fall_base4;
vbox follow_up_days/category= itvt; /* VBOX for Vertical Boxplots */
run;
ods pdf close;

proc freq data=fare.fall_base4;
tables grip_bmi*(fall_injury strata_gender);
run;


/* Common falls */
data life.fall_rec;
set life4.F060_otherhealthevents_V3_1;
keep maskid fall_ohre result11_ohre visdays;
run;
data life.fallrescted;
set life.fall_rec;
if fall_ohre=1 and result11_ohre=1 then fallrest=1;else fallrest=0;
if fall_ohre=1 then commonfall=1;else commonfall=0;
drop fall_ohre result11_ohre;
run;
data life.commonfalls;
set life.fallrescted;
where commonfall=1;run;
data life.commonfallnum;/*993*/
set life.commonfalls;
by maskid;
if first.maskid then commonfall_num=0;
commonfall_num+1;
if last.maskid then output;run;
data fare.commonfalls;
merge life.commonfallnum ;

proc contents data=fare.fall_base4 varnum;run;


/*KM*/

proc lifetest data=fare.fall_base4 atrisk plots=survival(cb);
strata grip_kg;
time follow_up_days*fall_injury(0);
run;
proc lifetest data=fare.fall_base4 atrisk plots=survival(cb);
strata grip_kg;
time steptotal*fall_injury(0);
run;
/*Plot for Log(log(s(t)))*//*CHECK FOR PH*/
proc lifetest data=fare.fall_base4 plots=(lls);
time follow_up_days*fall_injury(0);
strata grip_kg;run;


ods pdf;
/*M1*/
proc phreg data=fare.fall_base4 /*plots=survival*/;
class grip_kg(ref="Normal");
model follow_up_days*fall_injury(0)=grip_kg/rl;
run;
/*M2*/
proc phreg data=fare.fall_base4 /*plots=survival*/;
class grip_kg(ref="Normal") itvt(ref="SA") strata_gender(ref="Male");
model follow_up_days*fall_injury(0)=grip_kg age bmi itvt strata_gender/rl;
run;
/*M3*/
proc phreg data=fare.fall_base4 /*plots=survival*/;
class grip_kg(ref="Normal") itvt(ref="SA") strata_gender(ref="Male") hbpmed uripbl visimp footulcr dizzness;
model follow_up_days*fall_injury(0)=grip_kg age bmi itvt strata_gender comorindex hbpmed uripbl visimp footulcr dizzness/rl;
run;
ods pdf close;

proc contents data = fare.fall_base4 varnum;run;
proc phreg data=fare.fall_base4 plots=survival;
class grip_kg;
model steptotal*fall_injury(0)=grip_kg/rl;
run;
ods pdf close;

proc freq data=fare.fall_base4;
tables fall_injury*grip_kg;run;
