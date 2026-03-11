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
library(lme4)
library(broom.mixed)

# use this script to analyze the human and gpt paraphrased data.

human_sample <- read.csv("/Users/falkne/PycharmProjects/cacl-ocl/results_gpt/human_sample_features.csv")
gpt_sample <- read.csv("/Users/falkne/PycharmProjects/cacl-ocl/results_gpt/gpt_sample_features.csv")
nrow(human_sample)
nrow(gpt_sample)
names(human_sample)
summary(human_sample)
names(human_sample)
head(human_sample)
feature_overview <- read.csv("/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/reliable_features_odds_with_feature_groups.csv")
top30 <- head(feature_overview, 30)
top30_feats <- top30$Unnamed..0
top30_feats

features_string <- paste(top30$Unnamed..0, collapse = " + ")
print(features_string)

human_sample$model <- 0
gpt_sample$model <- 1

human_sample <- human_sample %>%
  mutate(id = 0:(n()-1))

gpt_sample <- gpt_sample %>%
  mutate(id = 0:(n()-1))

ncol(human_sample)
ncol(gpt_sample)
names(human_sample)


merged_df <- rbind(human_sample, gpt_sample)
#merged_df <- merged_df[top30$Unnamed..0]

merged_df$paper_id <- as.character(merged_df$id)


merged_df <- merged_df %>%
  mutate(across(where(is.numeric) & !c(paper_id, model), scale))


model <- glmer(class ~ . - paper_id + (1 | paper_id), 
               data = your_data, 
               family = binomial)

model_fixed_top30 <- glmer(
  model ~ (t_stopword + n_propn + n_PUNCT_PunctType_Comm + n_PUNCT_PunctType_Dash + n_PROPN_Number_Plur + n_dependency_advcl + n_PUNCT_PunctType_Brck + avg_aoa + n_part + corr_verb_var + simpsons_d + n_high_Head_sensorimotor + n_dependency_case + n_date + n_VERB_VerbForm_Fin + n_dependency_compound + n_org + entropy + mattr + n_NOUN_Number_Plur + n_dependency_conj + n_high_intensity_anger + n_aux + n_DET_Definite_Def + n_high_intensity_trust + n_dependency_neg + avg_concreteness + corr_num_var + n_high_concreteness + n_dependency_nsubjpass) + (1 | paper_id),
  data = merged_df,   family = binomial)

summ(model_fixed_top30)
plot_model(model_fixed_top30)


model_best5_from_all_fixed_synthetic <- glmer (model ~(t_stopword + avg_word_length + n_propn + n_PUNCT_PunctType_Comm + n_PUNCT_PunctType_Dash + n_PUNCT_PunctType_Brck + n_part + n_dependency_advcl + n_dependency_case + n_dependency_compound + n_dependency_conj + n_dependency_neg + avg_aoa + n_high_Head_sensorimotor + avg_concreteness + n_high_Auditory_sensorimotor + avg_prevalence + n_high_intensity_anger + n_high_intensity_trust + corr_verb_var + simpsons_d + n_date + n_org + entropy)+ (1 | paper_id), data = merged_df,   family = binomial)

summ(model_best5_from_all_fixed_synthetic)
p <- plot_model(model_best5_from_all_fixed_synthetic)

exp(fixef(model_best5_from_all_fixed_synthetic))
tidy_model <- tidy(model_best5_from_all_fixed_synthetic, conf.int = TRUE, exponentiate = TRUE)
tidy_model
write.csv(tidy_model, "/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/odds_synthetic.csv")

anova_res_synthetic <- Anova(model_best5_from_all_fixed_synthetic, test = "Chisq")
anova_res_synthetic_df <- as.data.frame(anova_res_synthetic)
anova_res_synthetic_df$Variable <- rownames(anova_res_synthetic_df)
anova_res_synthetic_df$Rel_Importance <- round(anova_res_synthetic_df$Chisq / sum(anova_res_synthetic_df$Chisq, na.rm = TRUE), 2)
anova_res_synthetic_df <- anova_res_synthetic_df[order(-anova_res_synthetic_df$Rel_Importance), ]

anova_res_synthetic_df
write.csv(anova_res_synthetic_df, "/Users/falkne/PycharmProjects/cacl-ocl/results_feature_selection_final/robust/rel_importance_synthetic.csv")

