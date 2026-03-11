library(dplyr)
library(effects)
library(relaimpo)
library(jtools)
library(tidyr)
library(car)
library(caret)
library(ggpubr)
library(sjPlot)
library(sjlabelled)
library(sjmisc)
library(ggeffects)
library(emmeans)
library(lmerTest)
library(sjPlot)
library(arrow)

surface <- c("t_stopword", "avg_word_length")
morphosyntactic <- c("n_propn", "n_PUNCT_PunctType_Comm", "n_PUNCT_PunctType_Dash", "n_PUNCT_PunctType_Brck", "n_part")
syntax <- c("n_dependency_advcl", "n_dependency_case", "n_dependency_compound", "n_dependency_conj", "n_dependency_neg")
psycholinguistic <-c("avg_aoa", "n_high_Head_sensorimotor", "avg_concreteness", "n_high_Auditory_sensorimotor", "avg_prevalence")
sentiment <- c("n_high_intensity_anger", "n_high_intensity_trust")
lexicosemantic <- c("corr_verb_var", "simpsons_d", "n_date", "n_org", "entropy")
best_feature_mixed <- c(surface, morphosyntactic, syntax, psycholinguistic, sentiment, lexicosemantic)
length(best_feature_mixed)

feature_overview <- read.csv("/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/reliable_features_odds_with_feature_groups.csv")
top30 <- head(feature_overview, 30)
top30_feats <- top30$Unnamed..0
top30_feats

# --------- load the data and select a subset of relevant columns
f = "/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/cacl_t1_reliable_features.parquet"
df_t1 <- open_dataset(f)
f2 = "/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/cacl_t2_reliable_features.parquet"
df_t2 <- open_dataset(f2)
-----------------------------------
# mixed feature set
df_t1_filtered <- df_t1 %>%  dplyr::select(all_of(best_feature_mixed))
robust_df_t1 <- df_t1_filtered %>% collect()
# mixed feature set
df_t2_filtered <- df_t2 %>% dplyr::select(all_of(best_feature_mixed))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------

# pick the features that should be predictors‚
features_string <- paste(best_feature_mixed, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))


model_best5_from_all <- glm (after ~(t_stopword + avg_word_length + n_propn + n_PUNCT_PunctType_Comm + n_PUNCT_PunctType_Dash + n_PUNCT_PunctType_Brck + n_part + n_dependency_advcl + n_dependency_case + n_dependency_compound + n_dependency_conj + n_dependency_neg + avg_aoa + n_high_Head_sensorimotor + avg_concreteness + n_high_Auditory_sensorimotor + avg_prevalence + n_high_intensity_anger + n_high_intensity_trust + corr_verb_var + simpsons_d + n_date + n_org + entropy) ,data = merged_t1_t2, family = binomial)
table(merged_t1_t2$after, merged_t1_t2$after)
summ(model_best5_from_all)



------------- # for top30feats
  
  df_t1_filtered <- df_t1 %>% 
  dplyr::select(all_of(top30_feats))
robust_df_t1 <- df_t1_filtered %>% collect()

df_t2_filtered <- df_t2 %>%
  dplyr::select(all_of(top30_feats))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------
# pick the features that should be predictors
features_string <- paste(top30_feats, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))
model_top30feats <- glm(
  after ~ (t_stopword + n_propn + n_PUNCT_PunctType_Comm + n_PUNCT_PunctType_Dash + n_PROPN_Number_Plur + n_dependency_advcl + n_PUNCT_PunctType_Brck + avg_aoa + n_part + corr_verb_var + simpsons_d + n_high_Head_sensorimotor + n_dependency_case + n_date + n_VERB_VerbForm_Fin + n_dependency_compound + n_org + entropy + mattr + n_NOUN_Number_Plur + n_dependency_conj + n_high_intensity_anger + n_aux + n_DET_Definite_Def + n_high_intensity_trust + n_dependency_neg + avg_concreteness + corr_num_var + n_high_concreteness + n_dependency_nsubjpass)
  ,data = merged_t1_t2, family = binomial)
summ(model_top30feats)


------------- # for morphosyntactic

df_t1_filtered <- df_t1 %>% 
  dplyr::select(all_of(morphosyntactic))
robust_df_t1 <- df_t1_filtered %>% collect()

df_t2_filtered <- df_t2 %>%
  dplyr::select(all_of(morphosyntactic))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------
# pick the features that should be predictors
features_string <- paste(morphosyntactic, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))
model_morphosyntacic <- glm (after ~(n_propn + n_PUNCT_PunctType_Comm + n_PUNCT_PunctType_Dash + n_PUNCT_PunctType_Brck + n_part) ,data = merged_t1_t2, family = binomial)
summ(model_morphosyntacic)

------------- # for syntax
  
  df_t1_filtered <- df_t1 %>% 
  dplyr::select(all_of(syntax))
robust_df_t1 <- df_t1_filtered %>% collect()

df_t2_filtered <- df_t2 %>%
  dplyr::select(all_of(syntax))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------
# pick the features that should be predictors
features_string <- paste(syntax, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))
model_syntax <- glm (after ~(n_dependency_advcl + n_dependency_case + n_dependency_compound + n_dependency_conj + n_dependency_neg) ,data = merged_t1_t2, family = binomial)
summ(model_syntax)

------------- # for psycholinguistic
  
  df_t1_filtered <- df_t1 %>% 
  dplyr::select(all_of(psycholinguistic))
robust_df_t1 <- df_t1_filtered %>% collect()

df_t2_filtered <- df_t2 %>%
  dplyr::select(all_of(psycholinguistic))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------
# pick the features that should be predictors
features_string <- paste(psycholinguistic, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))
model_psycholinguistic <- glm (after ~(avg_aoa + n_high_Head_sensorimotor + avg_concreteness + n_high_Auditory_sensorimotor) ,data = merged_t1_t2, family = binomial)
summ(model_psycholinguistic)

------------- # for sentiment
  
  df_t1_filtered <- df_t1 %>% 
  dplyr::select(all_of(sentiment))
robust_df_t1 <- df_t1_filtered %>% collect()

df_t2_filtered <- df_t2 %>%
  dplyr::select(all_of(sentiment))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------
# pick the features that should be predictors
features_string <- paste(sentiment, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))
model_sentiment <- glm (after ~(n_high_intensity_anger + n_high_intensity_trust + n_high_intensity_anticipation + n_high_arousal + n_positive_sentiment) ,data = merged_t1_t2, family = binomial)
summ(model_sentiment)

------------- # for lexicosemantic
  
  df_t1_filtered <- df_t1 %>% 
  dplyr::select(all_of(lexicosemantic))
robust_df_t1 <- df_t1_filtered %>% collect()

df_t2_filtered <- df_t2 %>%
  dplyr::select(all_of(lexicosemantic))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------
# pick the features that should be predictors
features_string <- paste(lexicosemantic, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))
model_lexicosemantic <- glm (after ~(corr_verb_var + simpsons_d + n_date + n_org + entropy) ,data = merged_t1_t2, family = binomial)
summ(model_lexicosemantic)

------------- # for surface
  
  df_t1_filtered <- df_t1 %>% 
  dplyr::select(all_of(surface))
robust_df_t1 <- df_t1_filtered %>% collect()

df_t2_filtered <- df_t2 %>%
  dplyr::select(all_of(surface))
robust_df_t2 <- df_t2_filtered %>% collect()
# --------------------------------------------
# pick the features that should be predictors
features_string <- paste(surface, collapse = " + ")
features_string
# add label
robust_df_t1["after"] = 0
robust_df_t2["after"] = 1
# combine them into one
merged_t1_t2 <- rbind(robust_df_t1, robust_df_t2)
# scale the features

merged_t1_t2 <- merged_t1_t2 %>%
  mutate(across(where(is.numeric) & !c(after), scale))
model_surface <- glm (after ~(t_stopword + avg_word_length) ,data = merged_t1_t2, family = binomial)
summ(model_surface)

plot_model(model_best5_from_all, show.values = FALSE, ci.lvl = NA)
library(car)
anova_res <- Anova(model_best5_from_all, test = "Wald")
anova_res_df <- as.data.frame(anova_res)
anova_res_df$Variable <- rownames(anova_res_df)
anova_res_df$Rel_Importance <- round(anova_res_df$Chisq / sum(anova_res_df$Chisq, na.rm = TRUE), 2)
anova_res_df <- anova_res_df[order(-anova_res_df$Rel_Importance), ]
summ(model_best5_from_all)
anova_res_df

or_results <- tidy(model_best5_from_all, 
                   exponentiate = TRUE, 
                   conf.int = FALSE)
or_results
write.csv(or_results, "/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/odds_realistic.csv")

se <- sqrt(diag(vcov(model_best5_from_all)))
est <- coef(model_best5_from_all)

ci_lower <- est - 1.96 * se
ci_upper <- est + 1.96 * se

odds_ratios <- exp(est)
ci_lower_or <- exp(ci_lower)
ci_upper_or <- exp(ci_upper)

results <- data.frame(term = names(est),
                      OR = odds_ratios,
                      CI_lower = ci_lower_or,
                      CI_upper = ci_upper_or)
write.csv(results, "/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/waldCIs_realistic.csv")

write.csv(anova_res_df, "/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/rel_importance_realistic.csv")
