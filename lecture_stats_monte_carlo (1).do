#delimit ;

pause on;


/*********

/* BASELINE, USING UNIFORM DISTRIBUTION */

/* CLEAR THE MEMORY TO START */
drop _all;

/* SET SAMPLE SIZE */
local sample_size = 1000;						

/* SET NUMBER OF ITERATIONS (USUALLY 10000, OR 100000 FOR MORE PRECISION) */
local num_iterations = 10000;

/* SET THE NUMBER OF OBSERVATIONS TO THE NUMBER OF ITERATIONS */
set obs `num_iterations';

/* MAKE A VARIABLE TO HOLD THE SAMPLE MEANS */
gen m  = .;

/* MAKE A VARIABLE TO HOLD THE SAMPLE STANDARD DEVIATIONS */
gen sd = .;

/* MAKE COUNTER VARIABLE */
gen i = _n;

/* THE LOOP TO MAKE THE SAMPLES. IN EACH ITERATION OF THE LOOP WE:
    (1) GENERATE THE RANDOM SAMPLE FROM THE UNIFORM DISTRIBUTION
    (2) COMPUTE THE SAMPLE MEAN AND SAMPLE STANDARD DEVIATION
    (3) STORE THE VALUES IN m AND sd, RESPECTIVELY */

quietly forvalues i = 1(1)`num_iterations' {;

     noisily display "`i' " _cont;

     /* GENERATE THE RANDOM SAMPLE FROM UNIFORM DISTRIBUTION */
     gen x = runiform() if i <= `sample_size';

     /* CALCULATE THE MEAN OF THE SAMPLE AND THE STANDARD DEVIATION OF THE SAMPLE */
     sum x;

     /* PUT THE MEAN IN THE VARIABLE m */
     replace m = r(mean) if i == `i';

     /* PUT THE STANDARD DEVIATION IN THE VARIABLE sd */
     replace sd = r(sd)  if i == `i';

*    pause;

     /* CLEAN-UP */
     drop x;

};

/* 
NOW, THE THEORETICAL VALUES FROM THE UNIFORM DISTRIBUTION ON [0,1] ARE:
     MEAN = 1/2 = 0.5
     VARIANCE = 1/12
     STANDARD DEVIATION = SQUARE ROOT OF 1/12, ABOUT 0.289
     STANDARD ERROR OF THE SAMPLE MEAN = [STANDARD DEVIATION] DIVIDED BY [SQUARE-ROOT OF SAMPLE SIZE], ABOUT 0.0289 FOR OUR SAMPLE SIZE OF 100
LET'S CHECK THAT THE RESULTS FROM THE MONTE-CARLO SIMULATIONS MATCH THESE (APPROXIMATELY)
*/

sum m;
display "THE MEAN OF m IS " r(mean) ", VERY CLOSE TO 0.5";
display "THE STANDARD DEVIATION OF m IS " r(sd) ", VERY CLOSE TO 0.0289";

/* THE DISTRIBUTION OF m SHOULD LOOK VERY CLOSE TO NORMAL IF THE SAMPLE SIZE IS "LARGE ENOUGH" */
hist m, normal;

/* MAKE THE ESTIMATED STANDARD ERROR OF THE MEAN FROM EACH SAMPLE */
gen se = sd/sqrt(`sample_size');

/* NOTE THAT THE AVERAGE OF se IS VERY CLOSE TO THE THEORETICAL VALUE, DEMONSTRATING THAT THE FORMULA IS CORRECT */
sum se;
display "THE MEAN OF se IS " r(mean), ", VERY CLOSE TO 0.0289";

/* PRINT THE CRITICAL T-VALUE FOR OUR SAMPLE SIZE FOR A 95% CONFIDENCE INTERVAL */
local crit_95 = invttail(`sample_size', 0.025);
display "`crit_95'";

/* MAKE THE 95% CONFIDENCE INTERVAL FOR EACH SAMPLE */
gen ci_lower_95 = m - `crit_95' * se;
gen ci_upper_95 = m + `crit_95' * se;

/* CHECK THAT THE CONFIDENCE INTERVAL CONTAINS THE TRUE MEAN ABOUT 95% OF THE TIME */
gen m_in_ci_95 = (1/2 > ci_lower_95 & 1/2 < ci_upper_95);		
sum m_in_ci_95;

/* DO THE SAME FOR THE 90% CONFIDENCE INTERVAL */

/* PRINT THE CRITICAL T-VALUE FOR OUR SAMPLE SIZE FOR A 90% CONFIDENCE INTERVAL */
local crit_90 = invttail(`sample_size', 0.05);
display "`crit_90'";

/* MAKE THE 90% CONFIDENCE INTERVAL FOR EACH SAMPLE */
gen ci_lower_90 = m - `crit_90' * se;
gen ci_upper_90 = m + `crit_90' * se;

/* CHECK THAT THE CONFIDENCE INTERVAL CONTAINS THE TRUE MEAN APPROXIMATELY 90% OF THE TIME */
gen m_in_ci_90 = (1/2 > ci_lower_90 & 1/2 < ci_upper_90);		
sum m_in_ci_90;


**********/



/**********

/***** NOW, WE CHANGE THE DISTRIBUTION *****/

drop _all;

local sample_size = 100;						
local num_iterations = 10000;
local show_x = 0;

set obs `num_iterations';
gen m  = .;
gen sd = .;
gen i = _n;
quietly forvalues i = 1(1)`num_iterations' {;
     noisily display "`i' " _cont;
     gen x = runiform() if i <= `sample_size';	

     /* HERE WE TRANSFORM THE DISTRIBUTION FROM WHICH WE DRAW TO SOMETHING OTHER THAN UNIFORM */
     rename x z;
     gen     x = 0 if z > 0   & z <= 1/3;
     replace x = 2 if z > 1/3 & z <= 1/2;
     replace x = 9 if z > 1/2 & z <= 1;
     drop z;

     /* HERE WE SHOW THE HISTOGRAM OF X */
     if `show_x' == 1 {;
         pause on;
         hist x;
         pause;
     };

     sum x;
     replace m = r(mean) if i == `i';
     replace sd = r(sd)  if i == `i';
     drop x;
};

sum m;
local mean_of_mhat = r(mean);
local sd_of_mhat   = r(sd);
display "THE MEAN OF m IS " `mean_of_mhat';
display "THE STANDARD DEVIATION OF mhat (THE STANDARD ERROR) IS " `sd_of_mhat';

hist m, normal;

sum sd;
display "THE STANDARD DEVIATION OF X IS ABOUT " r(mean);

gen se = sd/sqrt(`sample_size');
sum se;
display "THE MEAN OF se (THE ESTIMATED STANDARD ERROR) IS " r(mean), ", VERY CLOSE TO " `sd_of_mhat';

local crit_95 = invttail(`sample_size', 0.025);
display "`crit_95'";

gen ci_lower_95 = m - `crit_95' * se;
gen ci_upper_95 = m + `crit_95' * se;

gen m_in_ci_95 = (`mean_of_mhat' > ci_lower_95 & `mean_of_mhat' < ci_upper_95);		
sum m_in_ci_95;

local crit_90 = invttail(`sample_size', 0.05);
display "`crit_90'";

gen ci_lower_90 = m - `crit_90' * se;
gen ci_upper_90 = m + `crit_90' * se;

gen m_in_ci_90 = (`mean_of_mhat' > ci_lower_90 & `mean_of_mhat' < ci_upper_90);		
sum m_in_ci_90;

**********/


/**********/

/* REGRESSION COEFFICIENTS */

drop _all;

local sample_size = 100;						
local num_iterations = 10000;
local show_x = 0;
local df = `sample_size' - 1;

set obs `num_iterations';
gen b  = .;
gen se = .;
gen i = _n;
quietly forvalues i = 1(1)`num_iterations' {;
     noisily display "`i' " _cont;
     gen x = (runiform() - .5) if i <= `sample_size';
     gen e = (runiform() - .5) if i <= `sample_size';
     gen y = 1 * x + e;
*    noisily reg y x;
*    pause;
     reg y x;
     replace b  = _b[x]  if i == `i';
     replace se = _se[x] if i == `i';
     drop x e y;
};

sum b;
local mean_of_bhat = r(mean);
local sd_of_bhat   = r(sd);
display "THE MEAN OF b IS " `mean_of_bhat';
display "THE STANDARD DEVIATION OF bhat (THE STANDARD ERROR) IS " `sd_of_bhat';

hist b, normal;

sum se;
local se_mean = r(mean);
display "THE AVERAGE STANDARD ERROR OF b IS ABOUT " `se_mean' " WHICH IS VERY CLOSE TO " `sd_of_bhat';

local crit_95 = invttail(`df', 0.025);
display "`crit_95'";

gen ci_lower_95 = b - `crit_95' * se;
gen ci_upper_95 = b + `crit_95' * se;

gen b_in_ci_95 = (`mean_of_bhat' > ci_lower_95 & `mean_of_bhat' < ci_upper_95);		
sum b_in_ci_95;

local crit_90 = invttail(`df', 0.05);
display "`crit_90'";

gen ci_lower_90 = b - `crit_90' * se;
gen ci_upper_90 = b + `crit_90' * se;

gen b_in_ci_90 = (`mean_of_bhat' > ci_lower_90 & `mean_of_bhat' < ci_upper_90);		
sum b_in_ci_90;

