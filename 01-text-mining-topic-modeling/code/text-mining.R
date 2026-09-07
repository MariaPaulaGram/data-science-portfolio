# ============================================================
# TEXT MINING, NETWORK ANALYSIS & TOPIC MODELING
# Analysis of Argentine Sociology Publications
# ============================================================


# ============================================================
# 1. PACKAGES
# ============================================================

library(tidyverse)
library(quanteda)
library(quanteda.textstats)
library(quanteda.textplots)
library(igraph)
library(ggraph)
library(tidygraph)
library(seededlda)
library(tidytext)
library(openalexR)

# ============================================================
# 2. DATA PREPARATION
# ============================================================

# The analysis uses a cleaned corpus of scientific abstracts
# related to sociology and associated with Argentina.

# The main dataset used in the analysis is:
# socio_limp_2


# Check the structure of the dataset
glimpse(socio_limp_2)

# Check the number of documents
nrow(socio_limp_2)

# Check available variables
colnames(socio_limp_2)


# ============================================================
# 3. TEXT CORPUS
# ============================================================

# Create a Quanteda corpus from the cleaned abstracts

corpus_socio <- corpus(socio_limp_2$abstract)

# Inspect the corpus
summary(corpus_socio)
# ============================================================
# 4. DATA ACQUISITION - OPENALEX
# ============================================================

# Retrieve scientific publications related to sociology
# and associated with institutions in Argentina.

sociology_data <- oa_fetch(
  entity = "works",
  abstract.search = "sociología OR sociology OR sociologie OR soziologie OR sociologia",
  authorships.institutions.country_code = "AR"
)

# Inspect the retrieved data
glimpse(sociology_data)

# Number of publications retrieved
nrow(sociology_data)
# ============================================================
# 5. TEXT PREPROCESSING
# ============================================================

# The abstracts used in the analysis were previously cleaned,
# normalized and processed, including stopword removal.

# Create the text corpus from the cleaned abstracts
topic_corpus <- corpus(socio_limp_2$abstract)

# Tokenize the corpus
topic_tok <- tokens(topic_corpus)

# Inspect the tokenized corpus
topic_tok


# ============================================================
# 6. DOCUMENT-FEATURE MATRIX
# ============================================================

topic_dfm <- dfm(topic_tok) %>%
  dfm_trim(
    min_termfreq = 0.8,
    termfreq_type = "quantile",
    max_docfreq = 0.1,
    docfreq_type = "prop"
  )

# Inspect the resulting matrix
topic_dfm
# ============================================================
# 7. TF-IDF ANALYSIS
# ============================================================

# Calculate TF-IDF weights for the document-feature matrix

tfidf_dfm <- dfm_tfidf(topic_dfm)

# Identify the most important terms according to TF-IDF

tfidf_frequency <- textstat_frequency(
  tfidf_dfm,
  n = 30
)

# Display the top 30 terms
tfidf_frequency
