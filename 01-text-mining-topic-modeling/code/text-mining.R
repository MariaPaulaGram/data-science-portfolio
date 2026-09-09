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
# 2. DATA ACQUISITION - OPENALEX
# ============================================================

# Retrieve scientific works related to sociology
# and associated with institutions in Argentina.

socio_ar <- oa_fetch(
  entity = "works",
  abstract.search = "sociología OR sociology OR sociologie OR soziologie OR sociologia",
  authorships.institutions.country_code = "AR"
)


# ============================================================
# 3. DATA SELECTION AND CLEANING
# ============================================================

# Keep the variables needed for the analysis.

socio_ar_selec <- socio_ar %>%
  select(
    id,
    title,
    abstract,
    topics,
    language,
    publication_year
  )


# Remove records without an abstract.

socio_text <- socio_ar_selec %>%
  filter(!is.na(abstract))


# Clean the abstracts.

socio_text <- socio_text %>%
  mutate(
    abstract_clean = abstract %>%
      str_to_lower() %>%
      str_replace_all("[[:punct:]]", " ")
  )


# ============================================================
# 4. TEXT CORPUS AND TOKENIZATION
# ============================================================

# Create a Quanteda corpus.

topic_corpus <- corpus(
  socio_text$abstract_clean
)


# Tokenize the abstracts.

topic_tok <- tokens(
  topic_corpus
)
# Eliminar stopwords en varios idiomas

stopwords_multi <- c(
  stopwords("spanish"),
  stopwords("english"),
  stopwords("french"),
  stopwords("german"),
  stopwords("italian"),
  stopwords("portuguese")
)

topic_tok <- tokens_remove(
  topic_tok,
  pattern = stopwords_multi
)
# Remove numeric tokens
topic_tok <- tokens_remove(
  topic_tok,
  pattern = "^[0-9]+$",
  valuetype = "regex"
)
# Remove irrelevant and overly generic tokens
custom_stopwords <- c(
  "buenos",
  "aires",
  "través",
  "sociais",
  "anos",
  "artigo",
  "artigos",
  "articulo",
  "articulos",
  "ser",
  "puede",
  "new",
  "one",
  "public"
)


topic_tok <- tokens_remove(
  topic_tok,
  pattern = custom_stopwords
)

# Remove single-letter tokens
topic_tok <- tokens_remove(
  topic_tok,
  pattern = "^[[:alpha:]]$",
  valuetype = "regex"
)


# ============================================================
# 5. DOCUMENT-FEATURE MATRIX
# ============================================================

# Create the document-feature matrix.

topic_dfm <- dfm(
  topic_tok
)


# Remove extremely rare and extremely common terms.
# This follows the trimming strategy used for the topic model.

topic_dfm_lda <- topic_dfm %>%
  dfm_trim(
    min_termfreq = 0.8,
    termfreq_type = "quantile",
    max_docfreq = 0.1,
    docfreq_type = "prop"
  )


# ============================================================
# 6. TF-IDF ANALYSIS
# ============================================================

# Calculate TF-IDF weights.

tfidf_dfm <- dfm_tfidf(
  topic_dfm
)


# Identify the 30 most important terms.

tfidf_frequency <- textstat_frequency(
  tfidf_dfm,
  n = 30,
  force = TRUE
)


# Keep the main variables.

tfidf_top_terms <- tfidf_frequency %>%
  select(
    feature,
    frequency
  ) %>%
  arrange(
    desc(frequency)
  )


tfidf_top_terms
# ============================================================
# 6.1 TF-IDF VISUALIZATION
# ============================================================

tfidf_plot <- ggplot(
  tfidf_top_terms,
  aes(
    x = reorder(feature, frequency),
    y = frequency
  )
) +
  geom_col() +
  coord_flip() +
  labs(
    title = "Most Relevant Terms by TF-IDF",
    subtitle = "Argentine Sociology Publications",
    x = "Term",
    y = "TF-IDF"
  ) +
  theme_minimal()

tfidf_plot


# ============================================================
# 7. CO-OCCURRENCE NETWORK
# ============================================================

# Select the 100 most frequent terms.

top_terms_network <- names(
  sort(
    featfreq(topic_dfm),
    decreasing = TRUE
  )
)[1:100]


# Keep only these terms.

network_dfm <- dfm_select(
  topic_dfm,
  pattern = top_terms_network,
  selection = "keep"
)


# Create the document-level co-occurrence matrix.

network_fcm <- fcm(
  network_dfm,
  context = "document",
  tri = FALSE
)


# ============================================================
# 8. NETWORK GRAPH
# ============================================================

# Convert the co-occurrence matrix into a graph.

network_graph <- graph_from_adjacency_matrix(
  as.matrix(network_fcm),
  mode = "undirected",
  weighted = TRUE,
  diag = FALSE
)


# Remove weak connections.

network_graph <- delete_edges(
  network_graph,
  E(network_graph)[weight < 100]
)


# Calculate node degree.

V(network_graph)$degree <- degree(
  network_graph
)


# ============================================================
# 9. COMMUNITY DETECTION - LOUVAIN
# ============================================================

# Detect communities of strongly connected terms.

communities <- cluster_louvain(
  network_graph,
  weights = E(network_graph)$weight
)


# Assign each term to a community.

V(network_graph)$community <- membership(
  communities
)


# Create a table of communities.

community_table <- tibble(
  term = V(network_graph)$name,
  degree = V(network_graph)$degree,
  community = V(network_graph)$community
) %>%
  arrange(
    community,
    desc(degree)
  )


community_table


# ============================================================
# 10. CO-OCCURRENCE NETWORK VISUALIZATION
# ============================================================

network_plot <- ggraph(
  network_graph,
  layout = "fr"
) +
  geom_edge_link(
    aes(width = weight),
    alpha = 0.15,
    color = "grey70"
  ) +
  geom_node_point(
    aes(
      size = degree,
      color = factor(community)
    )
  ) +
  geom_node_text(
    aes(label = name),
    repel = TRUE,
    size = 2.8,
    color = "grey20"
  ) +
  scale_color_manual(
    values = c(
      "1" = "#D95F59",
      "2" = "#66A061",
      "3" = "#4F81BD"
    ),
    labels = c(
      "1" = "Community 1",
      "2" = "Community 2",
      "3" = "Community 3"
    ),
    name = "Community"
  ) +
  scale_edge_width(
    range = c(0.2, 1.5)
  ) +
  scale_size(
    range = c(2, 8)
  ) +
  theme_void() +
  labs(
    title = "Co-occurrence Network of Scientific Terms",
    subtitle = "Louvain Communities in Argentine Sociology Publications"
  )

network_plot

# ============================================================
# 11. TOPIC MODELING - LDA
# ============================================================

# Fit an LDA model with four topics.

set.seed(1234)

lda_model <- textmodel_lda(
  topic_dfm_lda,
  k = 4
)


# Extract the 15 most representative terms
# for each topic.

lda_top_terms <- terms(
  lda_model,
  15
)


lda_top_terms


# ============================================================
# 12. DOCUMENT-TOPIC DISTRIBUTION
# ============================================================

# Extract the document-topic probability matrix.

theta <- lda_model$theta


# Inspect the dimensions.

dim(theta)


# Display the first documents.

head(theta)


# ============================================================
# 13. MOST LIKELY TOPIC FOR EACH DOCUMENT
# ============================================================

document_topics <- topics(
  lda_model
)


head(document_topics)


# ============================================================
# 14. TOPIC MODEL RESULTS
# ============================================================

# Create a table with the topic assignment
# for each document.

topic_assignment <- tibble(
  document = rownames(theta),
  topic = document_topics
)


topic_assignment
# Add publication year to each document

topic_temporal <- socio_text %>%
  mutate(
    document = paste0("text", row_number())
  ) %>%
  select(
    document,
    publication_year
  ) %>%
  left_join(
    topic_assignment,
    by = "document"
  )
# ============================================================
# 15. TEMPORAL EVOLUTION OF TOPICS
# ============================================================

topic_evolution <- topic_temporal %>%
  filter(
    !is.na(publication_year),
    !is.na(topic)
  ) %>%
  count(publication_year, topic) %>%
  arrange(publication_year, topic)

topic_evolution


# ============================================================
# 16. TEMPORAL EVOLUTION VISUALIZATION
# ============================================================

topic_evolution_plot <- ggplot(
  topic_evolution,
  aes(
    x = publication_year,
    y = n,
    group = topic
  )
) +
  geom_line(
    aes(linetype = topic),
    linewidth = 1
  ) +
  geom_point() +
  labs(
    title = "Evolution of Sociology Research Topics",
    subtitle = "Argentine Sociology Publications",
    x = "Publication Year",
    y = "Number of Publications",
    linetype = "Topic"
  ) +
  theme_minimal()

topic_evolution_plot
# ============================================================
# DASHBOARD DATA
# Save lightweight analysis results for the interactive dashboard
# ============================================================

dashboard_data <- list(
  n_publications = nrow(socio_ar),
  n_abstracts = nrow(socio_text),
  tfidf_top_terms = tfidf_top_terms,
  lda_terms = lda_terms,
  topic_evolution = topic_evolution,
  network_graph = network_graph,
  community_table = community_table
)

saveRDS(
  dashboard_data,
  "01-text-mining-topic-modeling/dashboard/dashboard_data.rds"
)
# ============================================================
# END OF ANALYSIS
# ============================================================
