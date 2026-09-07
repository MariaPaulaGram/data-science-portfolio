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
