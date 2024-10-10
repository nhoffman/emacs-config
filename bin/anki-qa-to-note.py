#!/usr/bin/python3

import sys


def test_parse_lines():
    lines = [
        "Q: question 1",
        "A: answer 1 line 1",
        "answer 1 line 2",
        "answer 2 line 3",
        "",
        "Q: question 2",
        "A: answer 2",
        "",
        "Q: question 3",
        "A: answer 3",
    ]
    assert list(parse_lines(lines)) == [
        ("question 1", "answer 1 line 1\nanswer 1 line 2\nanswer 2 line 3"),
        ("question 2", "answer 2"),
        ("question 3", "answer 3"),
    ]


def parse_lines(lines):
    question = None
    answer_lines = []
    for line in lines:
        if line.startswith("Q: "):
            if question is not None:
                yield (question, "\n".join(answer_lines))
            question = line[3:].strip()  # Extract question text
            answer_lines = []  # Reset the answer lines for the new question
        elif line.startswith("A: "):
            answer_lines.append(line[3:].strip())  # Extract the first line of the answer
        elif line.strip() == "":
            # This handles the case where the last question-answer pair may not have been yielded
            if question is not None and answer_lines:
                yield (question, "\n".join(answer_lines))
                question = None
                answer_lines = []
        else:
            answer_lines.append(line.strip())  # Continue collecting lines for the current answer

    if question is not None:
        yield (question, "\n".join(answer_lines))


def main():
    for q, a in parse_lines(sys.stdin):
        print(f"""
* {q}
:PROPERTIES:
:ANKI_NOTE_TYPE: Basic
:END:
** Back
{a}
""".strip() + "\n")


if __name__ == "__main__":
    main()
