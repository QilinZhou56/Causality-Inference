***
**Data Description
**The dataset comes from Angrist & Lavy (1999, QJE). It contains 2019 observations of 5th grade classes in 1,002 public schools in Israel. There are 6 variables with description in order **as follows: schlcode, school code; enrollment, number of registered students; classize, number of students in class; avgmath, average math score of the class; avgverb, average grammar **score of the class; disadv, percentage of disadvantaged pupils.
**
**From Angrist & Lavy (1999), we know in Israel schools face a rule that requires classes cannot be larger than 40 pupils, also known as the Maimonides' rule. When enrollment is 41, schools need to open another class; then a third class if enrollment hits 81; and so on. This causes discontinuous drops of class size at multiples of 40.
**
**The authors are interested in whether small class size will increase students' scores.
***


*** Housekeeping ***

	set more off
	clear all




*** Read in the raw data ***

	use "/Users/qilinzhou/Desktop/StataDemo9/lec4_grade.dta", clear



*** OLS regression ***

//add additional control variables step by step 
	reg avgmath classize,r

	reg avgmath classize disadv ,r

	gen esquare=enrollment^2
	reg avgmath classize disadv enrollment esquare,r
    est store OLS
//Limit the sample to schools with enrollment between 20 and 60 students
	drop if enrollment>60
	drop if enrollment<20
	reg avgmath classize disadv enrollment esquare,r



*** fuzzy RD-Manual estimation ***

	gen largeclass=.
	replace largeclass=1 if enrollment<=40
	replace largeclass=0 if enrollment>40
    
	//left side regression
	reg avgmath largeclass disadv enrollment esquare if enrollment<40&enrollment>=35
	est store RD_Manual_Left
	matrix coef_left=e(b)
	local intercept_left=coef_left[1,5]

   
	//right side regression
	reg avgmath largeclass disadv enrollment esquare if enrollment<=45&enrollment>=40
	 est store RD_Manual_Right
	matrix coef_right=e(b)
	local intercept_right=coef_right[1,5]

	//get intercept difference
	local difference =`intercept_right'-`intercept_left'
		display coef_left[1,5] - coef_right[1,5]
	macro list



*** fuzzy RD-2SLS estimation ***

	gen func= enrollment/(int((enrollment-1)/40)+1)  //IV
	ivregress 2sls avgmath disadv enrollment esquare (largeclass=func), vce(robust) first
	est store RD_2SLS
	

	outreg2 [ OLS RD_Manual_Left  RD_Manual_Right RD_2SLS ]  ///
		using choice.xls, stat(coef se) bdec(4) sdec(3) replace label

*** fuzzy RD-Automatic estimation ***

//ssc install rdrobust first
	rdrobust avgmath classize,c(40) p(1) q(2) covs(disadv) kernel(triangular) level(95) h(5) all

//graph
	rdplot avgmath classize,c(40) p(1) graph_options(title(Figure) xtitle(enrollment) ytitle(avgmath))

//Manipulate tests
	
	DCdensity classize, breakpoint(40) generate(Xj Yj r0 fhat se_fhat)
	
	// or
	ssc install rddensity
	ssc install lpdensity
	help rddensity



*** Housekeeping ***

	clear all
