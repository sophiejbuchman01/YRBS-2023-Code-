
# School Safety, Bullying, and Belonging Among Transgender and Non-Transgender Students

Hello!  Welcome to my research project! 

This repository contains the R code for my analysis of the **2023 CDC Youth Risk Behavior Survey (YRBS)**. I wanted to better understand how school experiences differ between transgender and non-transgender students, particularly when it comes to safety, bullying, and feeling connected to others at school.

For this project, I use data to better understand students' experiences and contribute to research that can inform policies and make schools safer and more supportive.

## What does this project look at?

The analysis examines four school experiences:

* **School safety:** Missing school because of feeling unsafe.
* **School bullying:** Experiencing bullying at school.
* **Cyberbullying:** Experiencing bullying electronically.
* **School belonging:** Not reporting feeling close to people at school.

These experiences are compared across four groups: female, non-transgender students; male, non-transgender students; female, transgender students; and male, transgender students.

## How does the analysis work?

Using R, this project:

* Calculates survey-weighted percentages and 95% confidence intervals.
* Estimates percentage-point differences between groups.
* Uses logistic regression to calculate odds ratios.
* Conducts survey-adjusted Rao–Scott tests to compare groups.
* Applies the Holm adjustment to account for multiple statistical tests.
* Compares selected results with unweighted analyses.

The analysis accounts for the YRBS's complex survey design, including sampling weights, strata, and primary sampling units.

## What do I need to run the code?

You'll need:

* [R](https://cran.r-project.org/)
* [RStudio](https://posit.co/download/rstudio-desktop/)
* The 2023 National YRBS dataset, available through the [CDC YRBS website](https://www.cdc.gov/yrbs/data/index.html)

The script uses three R packages: `tidyverse`, `survey`, and `broom`.

Install them by running:

```r
install.packages(c("tidyverse", "survey", "broom"))
```

## How do I run it?

1. Download or clone this repository.
2. Open the project in RStudio.
3. Place the prepared dataset (included in the repository), named `YRBS_2023_National.rda`, inside the `data/` folder. The file must contain an R object named `yrbs_2023`.
4. Open `yrbs_analysis.R` and run the script from the project root.

The script creates an `output/` folder containing tables saved as CSV files, a figure, and information about the R session.

## A note on interpretation

These analyses describe associations and differences between groups; they do not establish causation. Results should also be interpreted carefully and responsibly. 

The sex variable used in this analysis reflects students' self-reported sex and does not specifically ask about sex assigned at birth. The comparison groups should  be understood in the context of how the original survey collected these responses.

## Why this research matters 

Behind every percentage is a student navigating school, friendships, and a sense of belonging. Transgender students are not an abstract concept; they are part of everyday life. Drawing on my own experiences navigating my transgender identity in my youth, I believe careful research examining existing policies and social structures can help us better understand and support the health and well-being of transgender youth.

Thank you for stopping by and taking an interest in this work! If you are reading this as part of my PhD application package, I hope to continue this meaningful work with your program next fall. 

---

**Author:** Sophie J Buchman

**Data source:** [CDC Youth Risk Behavior Survey](https://www.cdc.gov/yrbs/data/index.html)
