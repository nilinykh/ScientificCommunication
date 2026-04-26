## ACL Anthology Corpus Update

This directory contains the scripts to update the ACL Anthology Corpus.


Our starting point is the ACL-OCL corpus released by Rohatgi et al. (EMNLP 2023).
It is publicly available 
[here](https://huggingface.co/datasets/WINGNUS/ACL-OCL),
with further details in the original 
[paper](https://aclanthology.org/2023.emnlp-main.640/)
and [repository](https://github.com/shauryr/ACL-anthology-corpus).

In our paper, the purpose of the update was to bring the existing corpus closer 
to the present-day. Analogously, the corpus version we release can be updated 
in future to incorporate papers that have since appeared in the ACL Anthology.

### How to run the pipeline
The entire pipeline can be run from `run_corpus_update.sh`.
The script executes the following steps:
* Download the current ACL Anthology BibTeX file.
* Comparing against the available version of the corpus, check which papers are
  * **missing:** in the Anthology, but not in the corpus (e.g., published recently);
  * **empty:** in the corpus, but without text content (e.g., early papers for which
  metadata is available but PDFs are missing or defective).
* Download the PDFs of the missing papers.
* Optionally: try to download the PDFs of the empty papers (uncomment in script).
* Convert PDFs into XMLs using GROBID.
* Parse the XMLs into a single dataframe.
* Tidy up the metadata and output the final dataframe.

⚠️ Make sure to define the file names at the top of the script before running it.

### GROBID setup
Our PDF extraction process relies on GROBID, which we run using a Docker container.
To use the same process, you first need to set up the Docker image
as explained [here](https://grobid.readthedocs.io/en/latest/Grobid-docker/).

We used the `lfoppiano/grobid:0.8.1` image (lightweight), but note that further
versions have been released since our experiments. If you decide to use a
different image, **make sure to update the corresponding line** in the pipeline
script.

### Topic labels
We are also releasing the BERTopic model trained for our study.
This model may be used to label further papers consistently with the topics in 
our analyses. For more details, see `prep_data` directory.