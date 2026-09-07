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
# ============================================================
# 8. TF-IDF VISUALIZATION
# ============================================================

# Keep the most relevant terms according to TF-IDF

tfidf_top_terms <- tfidf_frequency %>%
  select(feature, frequency) %>%
  arrange(desc(frequency)) %>%
  slice_head(n = 30)

# Display the most relevant terms
tfidf_top_terms
# ============================================================
# 9. CO-OCCURRENCE NETWORK
# ============================================================

# Select the most frequent terms for the network analysis

top_terms_network <- names(
  sort(
    featfreq(topic_dfm),
    decreasing = TRUE
  )
)[1:100]

# Keep only the selected terms

network_dfm <- dfm_select(
  topic_dfm,
  pattern = top_terms_network,
  selection = "keep"
)

# Build the feature co-occurrence matrix

network_fcm <- fcm(
  network_dfm,
  context = "document",
  tri = FALSE
)

# Inspect the co-occurrence matrix

network_fcm
# ============================================================
# 10. NETWORK GRAPH
# ============================================================

# Convert the co-occurrence matrix into an undirected graph

network_graph <- graph_from_adjacency_matrix(
  as.matrix(network_fcm),
  mode = "undirected",
  weighted = TRUE,
  diag = FALSE
)

# Remove edges with very low co-occurrence

network_graph <- delete_edges(
  network_graph,
  E(network_graph)[weight < 100]
)

# Calculate node degree

V(network_graph)$degree <- degree(network_graph)

# Inspect the network

network_graph
# ============================================================
# 11. COMMUNITY DETECTION - LOUVAIN
# ============================================================

# Detect communities of strongly connected terms

communities <- cluster_louvain(
  network_graph,
  weights = E(network_graph)$weight
)

# Assign community membership to each node

V(network_graph)$community <- membership(communities)

# Number of communities detected

length(unique(V(network_graph)$community))

# Community membership of each term

community_table <- tibble(
  term = V(network_graph)$name,
  degree = V(network_graph)$degree,
  community = V(network_graph)$community
) %>%
  arrange(community, desc(degree))

community_table
# ============================================================
# 12. CO-OCCURRENCE NETWORK VISUALIZATION
# ============================================================

# Create a data frame with node information

network_nodes <- as_tibble(network_graph, active = "nodes")

# Plot the co-occurrence network

network_plot <- ggraph(network_graph, layout = "fr") +
  geom_edge_link(
    aes(width = weight),
    alpha = 0.3
  ) +
  geom_node_point(
    aes(size = degree)
  ) +
  geom_node_text(
    aes(label = name),
    repel = TRUE,
    size = 3
  ) +
  theme_void() +
  labs(
    title = "Co-occurrence Network of Scientific Terms",
    subtitle = "Argentine Sociology Publications"
  )

network_plot
# ============================================================
# 13. TOPIC MODELING - LDA
# ============================================================

# Fit an LDA model with four topics

set.seed(1234)

lda_model <- textmodel_lda(
  topic_dfm,
  k = 4
)

# Extract the 15 most representative terms for each topic

lda_top_terms <- terms(
  lda_model,
  15
)

lda_top_terms
# ============================================================
# 14. DOCUMENT-TOPIC DISTRIBUTION
# ============================================================

# Extract the document-topic probability matrix

theta <- lda_model$theta

# Inspect the dimensions of the matrix

dim(theta)

# Display the first documents

head(theta)
# ============================================================
# 15. TOPIC MODEL VISUALIZATION
# ============================================================

# Convert the LDA results into a tidy format

topic_terms <- tidy(lda_model, matrix = "beta")

# Keep the 10 most representative terms for each topic

top_topic_terms <- topic_terms %>%
  group_by(topic) %>%
  slice_max(beta, n = 10) %>%
  ungroup()

# Visualize the most representative terms

topic_plot <- ggplot(
  top_topic_terms,
  aes(
    x = reorder_within(term, beta, topic),
    y = beta
  )
) +
  geom_col() +
  facet_wrap(~ topic, scales = "free") +
  scale_x_reordered() +
  coord_flip() +
  labs(
    title = "Top Terms by Topic",
    subtitle = "LDA Topic Modeling",
    x = "Term",
    y = "Probability"
  ) +
  theme_minimal()

topic_plot

