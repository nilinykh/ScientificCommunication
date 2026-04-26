## Data preparation

This directory contains the code used to prepare corpus data for subsequent 
analyses. 
The purpose of the individual scripts is summarized below.
They are grouped by topic and broadly by order of execution.

### Metadata and sampling
* `map_volumes_to_venues.py`: maps Anthology volumes to unified venue names
* `volume2venue.parquet`: produced volume-to-venue mapping
* `make_samples.py`: based on the venue mapping (and the corresponding dates), 
  splits corpus into T1/T2 papers
* `make_samples_from_windows.py`: repackages existing dataframes based on T1/T2
  split
* `utils.py`: includes a format-robust function to read Pandas dataframes

### Text preprocessing and utilities
* `easy_pipeline.py`: segments paper text into sentences and paragraphs, runs 
  basic quality filters (lang ID), outputs a dataframe
* `make_one_sentence_per_line.py`: runs spacy over the dataframe, outputs
  one-sentence-per-line text files
* `lowercase_one_sentence_per_line.py`: lowercases files which are already in 
one-sentence-per-line format

### Frequency information
* `make_frequency_count.py`: creates word (ngram) frequency counts
* `make_frequency_count_posonly.py`: creates POS-tag (ngram) frequency counts
* `make_frequency_loglikelihood.py`: computes log-likelihood scores from two sets
of frequency counts

### Topic modeling
* `topic_prep_data.py`: prepares data for topic model training, in our case
  by concatenating the title and abstract for each paper
* `topic_model_train.py`: runs BERTopic over the prepared data

### Word2vec models
* `w2v_train.py`: trains a word2vec model over a one-sentence-per-line corpus
* `w2v_average_runs_samecorpus.py`: computes a vocabulary-level similarity
  matrix for multiple models trained over *the same* corpus by averaging the
  similarities across the runs
* `w2v_average_runs_twocorpora.py`: computes a vocabulary-level similarity
  matrix for multiple models trained over *different* corpora by first aligning
  a pair of corpus-specific models from the same run, computing the similarities
  for that run, and then averaging the similarities for all runs
* `w2v_orthogonal_procrustes.py`: utility script used for model alignment
* `w2v_neighb_density.py`: computes neighborhood density from similarity matrix
* `w2v_neighb_density_compare.py`: compares neighborhood densities for the same
  word across two corpora

### Contextualized embeddings
* `tokenlevel_clustering_targetselection.py`: utility script providing different
  criteria to select the most relevant words for clustering
* `tokenlevel_clustering.py`: for each target word, encodes a set of examples
  with a BERT-like model, and runs k-means clustering over it