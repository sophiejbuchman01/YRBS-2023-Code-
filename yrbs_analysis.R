# =============================================================================
# School Safety, Bullying, and Belonging Among Transgender and Non-Transgender
# Students: A Survey-Weighted Analysis of the 2023 Youth Risk Behavior Survey
#
# Author: Sophie J Buchman, BSW
#
# Run this script from the project root (open yrbs-analysis.Rproj in RStudio,
# or setwd() to the repository folder). It reads the YRBS data from data/ and
# writes tables, the figure, and session info to output/.
#
# =============================================================================


# 0. Setup ---------------------------------------------------------------------

# Install once if needed:
# install.packages(c("tidyverse", "survey", "broom"))

library(tidyverse)   # dplyr, tidyr, purrr, stringr, tibble, readr, ggplot2
library(survey)      # complex-survey design, weighted estimates and tests
library(broom)       # tidy() for model output

# ---- Paths (edit here if your files live somewhere else) ----
data_file <- file.path("data", "YRBS_2023_National.rda")  # must create yrbs_2023, this .rda file was created from the ASC2 file available at https://www.cdc.gov/yrbs/data/index.html
out_dir   <- "output"
fig_dir   <- file.path(out_dir, "figures")
tab_dir   <- file.path(out_dir, "tables")

for (d in c(fig_dir, tab_dir)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

# Print a table in full and save it as a CSV.
save_table <- function(tbl, name) {
  write_csv(tbl, file.path(tab_dir, paste0(name, ".csv")))
  print(tbl, n = Inf, width = Inf)
  invisible(tbl)
}


# 3. Preparing the data --------------------------------------------------------

if (!file.exists(data_file)) {
  stop("Data file not found: ", data_file,
       "\nSee data/README.md for how to obtain and place the YRBS 2023 data.",
       call. = FALSE)
}

load(data_file)                               # creates the object `yrbs_2023`
stopifnot(exists("yrbs_2023"))
names(yrbs_2023) <- tolower(names(yrbs_2023)) # make variable names consistently lowercase

# Keep the survey variables we need, plus the three survey-design variables
# (weight, stratum, psu), and give the variables readable names.
# Note: the survey's sex question does not say "at birth",
# so `birth_sex` holds the student's self-reported sex.
yrbs_2023_subset <-
  yrbs_2023 %>%
  select(sex, q65, qn14, q24, q25, qnclose2people,
         weight, stratum, psu) %>%
  rename(birth_sex = sex,
         gender = q65,
         skipped_school = qn14,
         school_bullying = q24,
         cyber_bullying = q25,
         close_to_others_yn = qnclose2people)

# Mark the students who belong to one of the four comparison groups:
#   sex = female (1) or male (2), AND
#   transgender = no (1) or yes (2).
# All other students (unsure, does not understand, missing) are marked FALSE or NA.
yrbs_marked <-
  yrbs_2023_subset %>%
  mutate(in_comparison = (birth_sex == 1 | birth_sex == 2) & (gender == 1 | gender == 2))

# Combine the sex answer and the transgender answer into one group variable.
# Adding the two answers no longer works with four groups (female + transgender and
# male + not transgender would both add up to 3), so the sex answer is multiplied by 10
# and the transgender answer is added:
#   11 = female, not transgender     12 = female, transgender
#   21 = male, not transgender       22 = male, transgender
# The code is only calculated for the marked students.
# trans_group ignores the sex answer and is used for the additional check in Section 8.
yrbs_grouped <-
  yrbs_marked %>%
  mutate(Gender_identity = as.numeric(gender),
         comb_gender_sex = if_else(in_comparison, as.numeric(birth_sex) * 10 + Gender_identity, NA_real_),
         trans_group = case_when(Gender_identity == 1 ~ "Not transgender",
                                 Gender_identity == 2 ~ "Transgender")) %>%
  # Drop the helper variables, keeping the combined group variable
  select(-birth_sex, -gender, -Gender_identity, -in_comparison)

# Replace numeric codes with readable labels
yrbs_labelled <-
  yrbs_grouped %>%
  mutate(comb_gender_sex = case_match(comb_gender_sex,
                                      11 ~ "Female, not transgender",
                                      12 ~ "Female, transgender",
                                      21 ~ "Male, not transgender",
                                      22 ~ "Male, transgender"),
         skipped_school = case_match(skipped_school,
                                     1 ~ "Missed school because felt unsafe",
                                     2 ~ "Did not miss school because felt unsafe"),
         school_bullying = case_match(school_bullying,
                                      "1" ~ "Experienced bullying",
                                      "2" ~ "Did Not Experience Bullying"),
         cyber_bullying = case_match(cyber_bullying,
                                     "1" ~ "Experienced cyberbullying",
                                     "2" ~ "Did not experience cyberbullying"),
         close_to_others_yn = case_match(close_to_others_yn,
                                         1 ~ "Reported feeling close to people at school",
                                         2 ~ "Did not report feeling close to people at school"))

# The statistics below need each outcome as a 0/1 number. In every
# case, 1 means the worse experience (for closeness, i.e. "did
# not report feeling close").

# The four comparison groups. "Female, not transgender" is listed first, so it is the
# reference group for the percentage-point differences and odds ratios.
group_levels <- c("Female, not transgender", "Male, not transgender",
                  "Female, transgender", "Male, transgender")
ref_group <- group_levels[1]

yrbs_analysis <- yrbs_labelled %>%
  mutate(
    group = factor(comb_gender_sex, levels = group_levels),
    trans_group = factor(trans_group, levels = c("Not transgender", "Transgender")),
    skipped_school_bin  = as.integer(skipped_school == "Missed school because felt unsafe"),
    school_bullying_bin = as.integer(school_bullying == "Experienced bullying"),
    cyber_bullying_bin  = as.integer(cyber_bullying == "Experienced cyberbullying"),
    not_close_bin       = as.integer(close_to_others_yn == "Did not report feeling close to people at school")
  )

bin_vars <- c("skipped_school_bin", "school_bullying_bin",
              "cyber_bullying_bin", "not_close_bin")

# Readable outcome names used in the tables and figure
outcome_names <- c(skipped_school_bin  = "Missed school because felt unsafe",
                   school_bullying_bin = "Bullied at school",
                   cyber_bullying_bin  = "Cyberbullied",
                   not_close_bin       = "Did not report feeling close to people at school")
label_outcome <- function(df) df %>% mutate(outcome = unname(outcome_names[outcome]))

# Tell R how the survey was sampled (which schools, which groups, and how much each
# student counts). The design is built on all students and then restricted to the
# groups being compared.
des <- svydesign(ids = ~psu, strata = ~stratum, weights = ~weight,
                 data = yrbs_analysis, nest = TRUE)
des_a <- subset(des, !is.na(group))


# 4. Who is in the analysis? ---------------------------------------------------

# Number of students in each group
flow <- tibble(
  step = c("All respondents",
           "Analysis sample (the four groups below)",
           paste0("   ", group_levels)),
  n = c(nrow(yrbs_analysis),
        sum(!is.na(yrbs_analysis$group)),
        map_int(group_levels, ~ sum(yrbs_analysis$group == .x, na.rm = TRUE)))
)
flow %>%
  rename(Step = step, Students = n) %>%
  save_table("01_sample_flow")

# Number of students who answered each question (missing data by group)
miss <- yrbs_analysis %>%
  filter(!is.na(group)) %>%
  select(group, all_of(bin_vars)) %>%
  pivot_longer(-group, names_to = "outcome", values_to = "y") %>%
  group_by(outcome, group) %>%
  summarise(n_group = n(),
            n_valid = sum(!is.na(y)),
            pct_missing = round(100 * mean(is.na(y)), 1),
            .groups = "drop")

miss %>%
  label_outcome() %>%
  rename(Outcome = outcome, Group = group, `Students in group` = n_group,
         `Answered the question` = n_valid, `% missing` = pct_missing) %>%
  save_table("02_missing_data")


# 5. Results -------------------------------------------------------------------

## 5.1 Percentage reporting each experience ------------------------------------
# Survey-weighted percentages with 95% confidence intervals (logit method).

prev_one <- function(v) {
  r <- svyby(as.formula(paste0("~", v)), ~group, des_a, svyciprop,
             vartype = "ci", method = "logit", na.rm = TRUE)
  tibble(outcome = v,
         group = r$group,
         pct = 100 * r[[2]],
         lo = 100 * r$ci_l,
         hi = 100 * r$ci_u)
}

prev <- map_dfr(bin_vars, prev_one) %>%
  left_join(miss %>% select(outcome, group, n_valid), by = c("outcome", "group"))

prev %>%
  label_outcome() %>%
  mutate(across(c(pct, lo, hi), ~ round(.x, 1))) %>%
  rename(Outcome = outcome, Group = group, `Percent` = pct,
         `CI lower` = lo, `CI upper` = hi, `Students who answered` = n_valid) %>%
  save_table("03_weighted_percentages")


## 5.2 Percentage-point differences and odds ratios ----------------------------

# Percentage-point difference from the reference group
rd <- prev %>%
  select(outcome, group, pct) %>%
  group_by(outcome) %>%
  mutate(ref_pct = pct[group == ref_group],
         diff_pct_points = pct - ref_pct) %>%
  ungroup() %>%
  filter(group != ref_group)

rd %>%
  label_outcome() %>%
  mutate(across(where(is.numeric), ~ round(.x, 1))) %>%
  rename(Outcome = outcome, Group = group, `Percent` = pct,
         `Reference group percent` = ref_pct,
         `Difference (percentage points)` = diff_pct_points) %>%
  save_table("04_percentage_point_differences")

# Odds ratios (survey-weighted quasibinomial regression)
fit_or <- function(v) {
  m <- svyglm(as.formula(paste(v, "~ group")),
              design = des_a, family = quasibinomial())
  tidy(m, conf.int = TRUE, exponentiate = TRUE) %>%
    filter(str_starts(term, "group")) %>%        # every group except the reference group
    transmute(outcome = v,
              group = str_remove(term, "^group"),
              OR = estimate, lo = conf.low, hi = conf.high, p = p.value)
}

or_tab <- map_dfr(bin_vars, fit_or)

or_tab %>%
  label_outcome() %>%
  mutate(across(c(OR, lo, hi), ~ round(.x, 2)), p = signif(p, 3)) %>%
  rename(Outcome = outcome, `Group (vs. Female, not transgender)` = group,
         `Odds ratio` = OR, `CI lower` = lo, `CI upper` = hi, `p-value` = p) %>%
  save_table("05_odds_ratios")


## 5.3 Rao-Scott F-test with Holm adjustment -----------------------------------
# The last column adjusts for testing four outcomes at once.

rs <- map_dfr(bin_vars, function(v) {
  t <- svychisq(as.formula(paste0("~", v, " + group")), des_a)
  tibble(outcome = v,
         F_stat = unname(t$statistic),
         ndf = unname(t$parameter[1]),
         ddf = unname(t$parameter[2]),
         p = t$p.value)
}) %>%
  mutate(p_holm = p.adjust(p, method = "holm"))

rs %>%
  label_outcome() %>%
  mutate(F_stat = round(F_stat, 1), p = signif(p, 3), p_holm = signif(p_holm, 3)) %>%
  rename(Outcome = outcome, `F statistic` = F_stat, `df 1` = ndf, `df 2` = ddf,
         `p-value` = p, `Holm-adjusted p-value` = p_holm) %>%
  save_table("06_rao_scott_tests")


## 5.4 Figure 1: weighted percentage reporting each experience -----------------

labs_out <- c(skipped_school_bin  = "Missed school\n(felt unsafe)",
              school_bullying_bin = "Bullied at school",
              cyber_bullying_bin  = "Cyberbullied",
              not_close_bin       = "Did not report feeling\nclose to people at school")

# Number of students in each group (all questions, and the closeness question only)
n_all   <- map_int(group_levels, ~ sum(yrbs_analysis$group == .x, na.rm = TRUE))
n_close <- map_int(group_levels,
                   ~ miss$n_valid[miss$outcome == "not_close_bin" & miss$group == .x])

# Turns the counts into text such as "12,345 (female, not transgender), ..."
fmt_n <- function(n) {
  paste0(formatC(n, format = "d", big.mark = ","), " (", tolower(group_levels), ")",
         collapse = ", ")
}

fig_caption <- paste0(
  "Points are survey-weighted percentages; bars are 95% confidence intervals.\n",
  "Groups are defined by answers to the survey's sex and transgender questions.\n",
  "n = ", fmt_n(n_all), ";\n",
  "closeness question: n = ", fmt_n(n_close), ".\n",
  "Source: 2023 CDC Youth Risk Behavior Survey.")

# One colour and one point shape per group (colour-blind-friendly palette)
group_cols   <- c("Female, not transgender" = "#0072B2", "Male, not transgender" = "#009E73",
                  "Female, transgender"     = "#CC79A7", "Male, transgender"     = "#D55E00")
group_shapes <- c("Female, not transgender" = 16, "Male, not transgender" = 15,
                  "Female, transgender"     = 18, "Male, transgender"     = 17)

fig_dat <- prev %>%
  mutate(outcome_lab = factor(outcome, levels = names(labs_out), labels = labs_out))

fig1 <- ggplot(fig_dat, aes(x = outcome_lab, y = pct, ymin = lo, ymax = hi,
                            colour = group, shape = group)) +
  geom_pointrange(position = position_dodge(width = 0.8)) +
  geom_text(aes(label = sprintf("%.0f%%", pct)),
            position = position_dodge(width = 0.8), hjust = -0.4, size = 3.2,
            show.legend = FALSE) +
  scale_colour_manual(values = group_cols) +
  scale_shape_manual(values = group_shapes) +
  scale_y_continuous(limits = c(0, 100)) +
  labs(x = NULL, y = "Percent reporting the experience", colour = NULL, shape = NULL,
       caption = fig_caption) +
  theme_minimal(base_size = 12) +
  theme(legend.position = "bottom",
        panel.grid.major.x = element_blank(),
        plot.caption = element_text(hjust = 0))

# In RStudio, run `fig1` to preview the plot.
ggsave(file.path(fig_dir, "figure1.png"), fig1, width = 11, height = 6, dpi = 300)


# 6. Simple percentages, without survey weights --------------------------------
# Plain percentages among the students in the survey, with no weighting. They
# describe the students who answered, not all U.S. students, and are shown for
# comparison with the weighted results above.

outcome_vars <- c("school_bullying", "skipped_school", "cyber_bullying", "close_to_others_yn")

for (var in outcome_vars) {
  cat("\n---", var, "---\n")
  tbl <- table(yrbs_analysis$comb_gender_sex, yrbs_analysis[[var]])
  print(round(prop.table(tbl, margin = 1) * 100, 1))
}


# 7. Check: does accounting for the survey design matter? ----------------------
# Compares the design-adjusted Rao-Scott test with an ordinary chi-square test.

unw <- map_dfr(bin_vars, function(v) {
  d <- yrbs_analysis %>% filter(!is.na(group), !is.na(.data[[v]]))
  t <- chisq.test(table(d[[v]], d$group))   # standard chi-square test (2 x 4 table)
  tibble(outcome = v, chisq_unweighted = unname(t$statistic), p_unweighted = t$p.value)
})

left_join(rs, unw, by = "outcome") %>%
  label_outcome() %>%
  transmute(Outcome = outcome,
            `Design-adjusted F` = round(F_stat, 1),
            `Design-adjusted p (Holm)` = signif(p_holm, 3),
            `Ordinary chi-square` = round(chisq_unweighted, 1),
            `Ordinary p` = signif(p_unweighted, 3)) %>%
  save_table("07_design_check")


# 8. Check: all transgender vs. all non-transgender students -------------------
# The sex question does not say "at birth", so this repeats the analysis without
# using the sex question at all.

print(table(yrbs_analysis$trans_group, useNA = "ifany"))

des_t <- subset(des, !is.na(trans_group))

robust <- map_dfr(bin_vars, function(v) {
  pr <- svyby(as.formula(paste0("~", v)), ~trans_group, des_t, svyciprop,
              vartype = "ci", method = "logit", na.rm = TRUE)
  m <- svyglm(as.formula(paste(v, "~ trans_group")),
              design = des_t, family = quasibinomial())
  est <- tidy(m, conf.int = TRUE, exponentiate = TRUE) %>%
    filter(term == "trans_groupTransgender")
  tibble(outcome = v,
         pct_not_transgender = 100 * pr[[2]][pr$trans_group == "Not transgender"],
         pct_transgender = 100 * pr[[2]][pr$trans_group == "Transgender"],
         OR = est$estimate, lo = est$conf.low, hi = est$conf.high, p = est$p.value)
})

robust %>%
  label_outcome() %>%
  mutate(across(c(pct_not_transgender, pct_transgender), ~ round(.x, 1)),
         across(c(OR, lo, hi), ~ round(.x, 2)),
         p = signif(p, 3)) %>%
  rename(Outcome = outcome, `% not transgender` = pct_not_transgender,
         `% transgender` = pct_transgender, `Odds ratio` = OR,
         `CI lower` = lo, `CI upper` = hi, `p-value` = p) %>%
  save_table("08_all_transgender_vs_not")


# 11. Software information -----------------------------------------------------

writeLines(capture.output(sessionInfo()), file.path(out_dir, "session_info.txt"))
message("Done. Tables, figure, and session info are in '", out_dir, "/'.")
