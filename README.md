Hello!  Welcome to my research project! 

This repository contains the R code for my analysis of the **2023 CDC Youth Risk Behavior Survey (YRBS)**. I wanted to better understand how school experiences differ between transgender and non-transgender students, particularly when it comes to safety, bullying, and feeling connected to others at school.

For this project, I use the YRBS to better understand students' experiences and contribute to research that can inform policies and make schools safer and more supportive.

## What does this project look at?

The analysis examines four school experiences:

* **School safety:** Missing school because of feeling unsafe.
* **School bullying:** Experiencing bullying at school.
* **Cyberbullying:** Experiencing bullying electronically.
* **School belonging:** Not reporting feeling close to people at school.

These experiences are compared across four groups: female, non-transgender students; male, non-transgender students; female, transgender students; and male, transgender students.

## What's in here?

* `yrbs_analysis.R`: the main analysis!
* `yrbs_supplementary_analyses.R`: the supplement, with extra analyses added after my reviewers asked some really great questions.
* `YRBS_2023_National.rda`: the prepared 2023 YRBS data.
* `data/README.md`: where the data came from and what each variable means.

## How does the analysis work?

Using R, the main script (`yrbs_analysis.R`):

* Calculates survey-weighted percentages and 95% confidence intervals.
* Estimates percentage-point differences between groups.
* Uses logistic regression to calculate odds ratios.
* Conducts survey-adjusted Rao–Scott tests to compare groups.
* Applies the Holm adjustment to account for multiple statistical tests.
* Compares selected results with unweighted analyses.

The analysis accounts for the YRBS's complex survey design, including sampling weights, strata, and primary sampling units.

### Supplement

My reviewers' biggest question was: *does it actually matter that I split transgender students by their answer to the sex question?* The supplement (`yrbs_supplementary_analyses.R`) was built to answer that, plus a few other things they asked about. It uses the exact same data, survey design, groups, and outcomes as the main script, and it checks that it reproduces the main results before it does anything new. It:

* Tests whether the gap between transgender and non-transgender students is different for students who answered "female" versus "male" to the sex question. This is the sex × transgender interaction, on both the percentage-point and odds scales.
* Describes the sample by grade, age, race and ethnicity, and sexual identity.
* Adds 95% confidence intervals to the percentage-point differences, and Holm-adjusted p-values to the odds ratios.
* Re-runs the models adjusting for grade, race and ethnicity, and sexual identity.
* Calculates prevalence ratios, which are easier to read than odds ratios when an experience is common.
* Repeats the comparisons with male, non-transgender students as the reference group.
* Runs a few extra checks:
  * the all-transgender vs. all-non-transgender comparison, using only the students in the main analysis;
  * adding students who answered "not sure" to the transgender question as a fifth group;
  * looking at students who answered the transgender question but skipped the sex question;
  * screening out students whose answers might not be accurate. For example, saying they ate carrots 4+ times a day on several food questions!
* Checks who did and didn't get the "feeling close to people at school" question, since not every student was asked it.

## What do I need to run the code?

You'll need:

* [R](https://cran.r-project.org/)
* [RStudio](https://posit.co/download/rstudio-desktop/)
* The 2023 National YRBS dataset, available through the [CDC YRBS website](https://www.cdc.gov/yrbs/data/index.html)

Both scripts use the same three R packages: `tidyverse`, `survey`, and `broom`. No extra packages are needed for the supplement!

Install them by running:

```r
install.packages(c("tidyverse", "survey", "broom"))
```

## How do I run it?

1. Download or clone this repository.
2. Open the project in RStudio.
3. Open `yrbs_analysis.R` and run the script from the project root.
4. Then open `yrbs_supplementary_analyses.R` and run it too. If you skip step 3, the supplement will run the main script for you first, so either way works!

The prepared dataset, `YRBS_2023_National.rda`, is included in the repository. The script looks for it in the `data/` folder first and then in the project root, so no setup is needed. It also checks that the file matches the version used in the paper and warns you if it doesn't. See `data/README.md` for where the data came from.

Both scripts save everything to an `output/` folder:

* **Main script:** tables `01`–`08` (CSV files), `figures/figure1.png`, and `session_info.txt`.
* **Supplement:** tables `S01`–`S13` (CSV files) and `session_info_supplementary.txt`.

Here's where each table in the supplement file is in the main paper. 
| Supplement file | In the paper |
|---|---|
| `S01a`, `S01b` (who was excluded) | Data section text |
| `S02` (sample characteristics) | Table 2 |
| `S13a`, `S13b` (closeness question) | Tables 3 and 4 |
| `S03` (percentage-point differences with CIs) | Table 6 |
| `S04` (odds ratios with Holm-adjusted p-values) | Table 7 |
| `S07` (prevalence ratios) | Table 8 |
| `S08` (male, non-transgender reference group) | Table 9 |
| `S05` (sex × transgender interaction) | Table 11 |
| `S06a`, `S06b` (adjusted models) | Tables 12 and 13 |
| `S09` (Check 2 on the main sample) | Table 16 |
| `S10` (Check 3: "not sure" students) | Table 17 |
| `S11` (Check 4: sex question skipped) | Table 18 |
| `S12a`, `S12b` (Check 5: response screening) | Tables 19 and 20 |


## A note on interpretation

These analyses describe associations and differences between groups; they do not establish causation. Results should also be interpreted carefully and responsibly. 

The sex variable used in this analysis reflects students' self-reported sex and does not specifically ask about sex assigned at birth. The comparison groups should  be understood in the context of how the original survey collected these responses.

This matters for the supplement, too! The interaction results show that the transgender groups look different depending on how students answered the sex question. But those groups describe how students answered the survey, not their gender identities. Some of the supplement's groups are also very small (for example, the 43 transgender students who skipped the sex question), so those estimates are shared for transparency and should be read with extra care.

## Why this research matters 

Behind every percentage is a student navigating school, friendships, and a sense of belonging. Transgender students are not an abstract concept; they are part of everyday life. Drawing on my own experiences navigating my transgender identity in my youth, I believe careful research examining existing policies and social structures can help us better understand and support the health and well-being of transgender youth.

Thank you for stopping by and taking an interest in this work! If you are reading this as part of my PhD application package, I hope to continue this meaningful work with your program next fall. 

