The following readme contains the information about the data released.

### LLM
This folder contains the corpus of LLM-Assisted Paraphases. There are two files: 
- human_sample_features.csv: contains the human written paraphases and the corresponding features.
- gpt_sample_features.csv: contains the gpt generated paraphases (GPT-3.5-turbo) and the corresponding features.
The files contain the feature values of the originally selected 145 features, the original, human-written text (*text*) and in case of gpt_sample_features.csv, the paraphase (*improved_text*)

### original
This folder contains the original data used for the analysis. There are two files:
- cacl_t1_reliable_features.parquet: contains the data of the 24 final features for the realistic dataset (cacl_t1). --> t1 = time period before release of chatGPT 
- cacl_t2_reliable_features.parquet: contains the data of the 24 final features for the synthetic dataset (cacl_t2). --> t2 = time period after release of chatGPT
