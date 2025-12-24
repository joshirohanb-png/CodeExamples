/*****************************************************************************
 * BIOS 511 Final Exam
 * Program: final_730435794.sas
 * Author: Rohan Joshi
 * Date: 12-05-2025
 *****************************************************************************/

%put NOTE: Program being run by 730435794;

options nofullstimer;
libname data "~/my_shared_file_links/klh52250/BIOS511/data" access=readonly;

ods pdf file="/home/u64303804/BIOS511/Output/final_730435794.pdf" style=journal;


/*Part 1: Import Monkeypox File*/

proc import datafile="~/my_shared_file_links/klh52250/BIOS511/data/Monkeypox_Research.csv"
    out=monkeypox dbms=csv replace;
    getnames=yes;
    guessingrows=max;
run;

/*Part 2: Topic FORMAT*/
title "Format: Topic Codes";
proc format;
    value topicf
        1="Vaccine"
        2="Therapeutic"
        3="Diagnostic"
        4="Lab Safety"
        5="Epidemiology"
        6="Education"
        7="Outreach"
        other="Unknown";
run;
title;

/*Part 3: FREQ agency*topic*/ |
title "Monkeypox Projects: Agency by Topic";
ods noproctitle;
proc freq data=monkeypox;
    tables agency*topic / list missing;
    format topic topicf.;
run;
title;


/*Part 4: Gulf Oil Ratios*/

title "Sorting Gulf Oil Data";
proc sort data=sashelp.gulfoil out=gulf_sorted;
    by regionname protractionname date;
run;

title "Gulf Oil & Gas First/Last Month Ratios";
data gulf_ratios;
    set gulf_sorted;
    by regionname protractionname;

    retain firstoil firstgas;

    if first.protractionname then do;
        firstoil = oil;
        firstgas = gas;
    end;

    if last.protractionname then do;
        lastoil = oil;
        lastgas = gas;

        ratio_oil = ifn(lastoil > 0, firstoil / lastoil, .);
        ratio_gas = ifn(lastgas > 0, firstgas / lastgas, .);

        output;
    end;

    keep regionname protractionname firstoil lastoil firstgas lastgas ratio_oil ratio_gas;
run;

/*Part 5: Print Gulf Oil Ratio Report*/
title "Gulf Ratio Report";
proc print data=gulf_ratios label;
    label regionname     = "Region"
          protractionname = "Protraction"
          firstoil       = "First Oil"
          lastoil        = "Last Oil"
          firstgas       = "First Gas"
          lastgas        = "Last Gas"
          ratio_oil      = "Oil Ratio"
          ratio_gas      = "Gas Ratio";
run;
title;

/*Part 6: Boxplot Diabetes Data*/
title "Glycosylated Hemoglobin by Gender & Body Frame";
proc sgplot data=data.diabetes;
    hbox glyhb / category=gender group=frame;
    label gender="Gender" frame="Body Frame";
    footnote "Glycosylated Hemoglobin by Gender and Body Frame";
run;

/*Part 7: Clear footnote*/
footnote;
title;

/*Part 8: Format for Sex*/
title "Format: Sex";
proc format;
    value sexf
        1="Male"
        0="Female";
run;
title;

/*Part 9: Means on preemies*/
title "Mean Birthweight by Infant Sex";
proc means data=data.preemies noprint nway;
    class sex;
    var bw;
    format sex sexf.;
    output out=prem_stats mean=mean_bw;
run;
title;

/*Part 10: Transpose*/
title "Transposed Birthweight Statistics (Wide Format)";
proc transpose data=prem_stats out=prem_t(drop=_name_);
    id sex;
    var mean_bw;
run;
title;

/*Part 11: Print transposed*/
title "Birthweight Means by Sex (Transposed)";
proc print data=prem_t noobs;
run;
title;

/*Part 12: Merge DIM+FACT*/
title "Customer + Order Fact Merge";
proc sort data=data.customer_dim out=customer_dim_sorted; by customer_id; run;
proc sort data=data.order_fact    out=order_fact_sorted;  by customer_id; run;

data merged;
    merge customer_dim_sorted(in=a)
          order_fact_sorted(in=b);
    by customer_id;
    if a and b;
run;
title;

/*Part 13: Macro country report*/
%macro countryrep(country=, minval=);

    data &country;
        set merged;
        where customer_country="&country";
        flag = (total_retail_price > &minval);
        days = delivery_date - order_date;
    run;

    title "Country Report: &country";
    proc report data=&country nowd;
        column flag days quantity total_retail_price;
        define flag               / group "Minimum Value";
        define days               / group "Days to Delivery";
        define quantity           / "Quantity";
        define total_retail_price / mean "Mean Price";
    run;
    title;

%mend;

/*Part 14: Tun on mprint option*/
options mprint;
%countryrep(country=DE, minval=75);
%countryrep(country=AU, minval=200);
%countryrep(country=IL, minval=150);

/*Part 15: Fish transformations*/
title "Fish Dataset with Length Shrink + Height/Weight Categories";
data fish_edit;
    set sashelp.fish;

    array lens {*} Length1 Length2 Length3;
    do i=1 to dim(lens);
        if lens{i} ne . then lens{i} = lens{i} * 0.95;
    end;

    if height = . then Hcat = "M";
    else if height < 13            then Hcat = "H1";
    else if 13 <= height < 15      then Hcat = "H2";
    else if 15 <= height < 17      then Hcat = "H3";
    else if height >= 17           then Hcat = "H4";

    if weight = . then Wcat = "M";
    else if weight < 400           then Wcat="W1";
    else if 400 <= weight < 600    then Wcat="W2";
    else if 600 <= weight < 800    then Wcat="W3";
    else if weight >= 800          then Wcat="W4";

    drop i;
run;

proc sort data=fish_edit; by species; run;

/*Part 16: PROC UNIVARIATE*/
title "Univariate Analysis: Fish Lengths (Hcat = H)";
proc univariate data=fish_edit;
    where Hcat="H";
    by species;
    class Wcat;
    var Length1 Length2 Length3;
    ods select moments extremeobs;
run;
title;

ods pdf close;
proc printto; run;