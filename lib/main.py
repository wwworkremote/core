import string
import json
import glob
import re

import pandas as pd

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from sklearn.metrics import adjusted_rand_score
import nltk
from nltk.corpus import stopwords
import bs4

# nltk.download('stopwords')

def load_data(file):
    with open(file, "r", encoding="utf-8") as f:
        data = json.load(f)
    return(data)

def write_data(file, data):
    with open(file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)

def remove_stops(text, stops):
    soup = bs4.BeautifulSoup(text, "html.parser")

    for data in soup(['style', 'script']):
        print(data.decompose())

    text = ' '.join(soup.stripped_strings)

    words = text.split()
    final = []
    for word in words:
        if word not in stops:
            final.append(word)
    final = " ".join(final)
    final = final.translate(str.maketrans("", "", string.punctuation))
    final = re.sub(r"\s+", " ", final)
    final = "".join([i for i in final if not i.isdigit()])
    return(final)

def clean_docs(docs):
    stops = stopwords.words("english")
    final = []
    for doc in docs:
        clean_doc = remove_stops(doc, stops)
        final.append(clean_doc)
    return(final)

def run_td_idf_example():
    descriptions = load_data("/Users/mike/projects/outlier_jobs/core/lib/corpus.json")["descriptions"]
    descriptions = clean_docs(descriptions)

    names = load_data("/Users/mike/projects/outlier_jobs/core/lib/corpus.json")["names"]
    names = clean_docs(names)

    td_idf_example(descriptions, names)

def td_idf_example(descriptions, names):
    vectorizer = TfidfVectorizer(
        lowercase=True,
        max_features=100,
        max_df=0.8,
        min_df=5,
        ngram_range=(1,3),
        stop_words="english"
    )

    vectors = vectorizer.fit_transform(descriptions)

    feature_names = vectorizer.get_feature_names()

    dense = vectors.todense()
    denselist = dense.tolist()

    all_keywords = []

    for description in denselist:
        idx = 0
        keywords = []
        for word in description:
            if word > 0:
                keywords.append(feature_names[idx])
                idx = idx + 1
        all_keywords.append(keywords)

    # basically number of clusters
    true_k = 5

    model = KMeans(n_clusters=true_k, init="k-means++", max_iter=100, n_init=1)
    model.fit(vectors)

    order_centroids = model.cluster_centers_.argsort()[:, ::-1]
    terms = vectorizer.get_feature_names()

    for i in range(true_k):
        print(f"Cluster {i}")
        for ind in order_centroids[i, :10]:
            print('  %s' % terms[ind],)
        print("")

    from matplotlib import rcParams
    rcParams['font.family'] = 'sans'
    rcParams['font.sans-serif'] = ['FiraCode Nerd Font Mono', 'Fira Code', 'Menlo']

    import matplotlib.pyplot as plt
    from sklearn.decomposition import PCA

    kmean_indices = model.fit_predict(vectors)

    pca = PCA(n_components=2)
    scatter_plot_points = pca.fit_transform(vectors.toarray())
    colors = ["r", "b", "c", "y", "m"]

    x_axis = [o[0] for o in scatter_plot_points]
    y_axis = [o[1] for o in scatter_plot_points]

    fig, ax = plt.subplots(figsize=(50, 50))

    print(kmean_indices)
    ax.scatter(x_axis, y_axis, c=[colors[d] for d in kmean_indices])

    for i, txt in enumerate(names):
        ax.annotate(txt[0:20], (x_axis[i], y_axis[i]))

    plt.savefig("data.png")

if __name__ == '__main__':
    run_td_idf_example()

# with open("/Users/mike/Desktop/results.txt", "w", encoding="utf-8") as file:
#     for i in range(true_k):
#         file.write(f"Cluster {i}")
#         file.write("\n")
#         for ind in order_centroids[i, :10]:
#             file.write('  %s' % terms[ind],)
#             file.write("\n")
#         file.write("\n")
#         file.write("\n")
