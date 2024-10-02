#!/usr/bin/python3

import sys


def parse_lines(lines):
    yield 'q', 'a'


def main():
    for q, a in parse_lines(sys.stdin):
        print(f"""
* note
** Front
{q}
** Back
{a}
""".strip())


if __name__ == "__main__":
    main()
