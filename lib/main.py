import pandas as pd

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.cluster import KMeans
from sklearn.metrics import adjusted_rand_score
import string
import nltk
nltk.download('stopwords')
from nltk.corpus import stopwords
import json
import glob
import re
import bs4

def load_data(file):
    with open(file, "r", encoding="utf-8") as f:
        data = json.load(f)
    return(data)

def write_data(file, data):
    with open(file, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=4)

def remove_stops(text, stops):
    # clean = re.compile('<.*?>')
    text = bs4.BeautifulSoup(text).get_text()
    words = text.split()

    final = []

    for word in words:
        if word not in stops:
            final.append(word)

    final = " ".join(final)

    final = re.sub(r"[[:space:]]+", " ", final)

    final = "".join([i for i in final if not i.isdigit()])
    
    return(final)

def clean_docs(docs):
    stops = stopwords.words("english")

    final = []

    for doc in docs:
        clean_doc = remove_stops(doc, stops)
        final.append(clean_doc)
    return(final)


def print_hi(name):
    descriptions = load_data("/Users/mike/projects/outlier_jobs/core/lib/corpus.json")["descriptions"][:100]

    cleaned_docs = clean_docs(descriptions)

    print(cleaned_docs)
    print(f'Hi, {name}')

if __name__ == '__main__':
    print_hi('PyCharm')
