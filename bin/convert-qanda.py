#!/usr/bin/python3

import sys


def parse_lines(lines):
    q, a = "", ""
    for line in lines:
        if line.startswith("Q:"):
            q = line[2:].strip()
        elif line.startswith("A:"):
            a = line[2:].strip()
        elif line.strip() == "":
            yield q, a
            q, a = "", ""
    if q or a:
        yield q, a


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
