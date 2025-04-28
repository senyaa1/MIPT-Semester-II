#!/usr/bin/env python3
import argparse
import collections
import re
import sys

def get_top_words(filename, n=10):
    """
    Reads the given file, tokenizes into words, and returns the top n most common words.
    """
    counter = collections.Counter()
    word_pattern = re.compile(r"\b\w+\b")

    try:
        with open(filename, 'r', encoding='utf-8') as f:
            for line in f:
                words = word_pattern.findall(line.lower())
                counter.update(words)
    except IOError as e:
        print(f"Error opening or reading file '{filename}': {e}", file=sys.stderr)
        sys.exit(1)

    return counter.most_common(n)

def main():
    parser = argparse.ArgumentParser(
        description="Print the top-N most common words in a text file.")
    parser.add_argument('file', help="Path to the input .txt file")
    parser.add_argument('-n', '--number', type=int, default=10,
                        help="How many top words to display (default: 10)")
    args = parser.parse_args()

    top_words = get_top_words(args.file, args.number)
    print(f"Top {args.number} words in '{args.file}':")
    for rank, (word, count) in enumerate(top_words, start=1):
        print(f"{rank:2}. {word!r}: {count}")

if __name__ == "__main__":
    main()

