#!/usr/bin/env python3
import sys
import re
from collections import Counter

def count_unique_words(text):
    """
    Given a string `text`, find all words (alphanumeric sequences),
    normalize to lowercase, and return a Counter of word frequencies.
    """
    # \b\w+\b matches word boundaries around one or more word characters
    words = re.findall(r'\b\w+\b', text.lower())
    return Counter(words)

def main():
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <filename>")
        sys.exit(1)

    filename = sys.argv[1]
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            text = f.read()
    except FileNotFoundError:
        print(f"Error: File '{filename}' not found.")
        sys.exit(1)

    counts = count_unique_words(text)
    unique_count = len(counts)

    print(f"Total unique words: {unique_count}\n")
    # print("Word frequencies:")
    # for word, freq in counts.most_common():
    #     print(f"{word}: {freq}")

if __name__ == "__main__":
    main()

