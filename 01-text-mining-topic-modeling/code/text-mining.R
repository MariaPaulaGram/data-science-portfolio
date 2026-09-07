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
