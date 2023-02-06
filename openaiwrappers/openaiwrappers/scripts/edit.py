"""Submit text from stdin to the OpenAI edits api

"""

import os
import sys
import argparse

import openai

from .. import get_api_key


def main():

    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--engine', choices=['code', 'text'], default='text',
                        help='[%(default)s]')
    parser.add_argument('--instructions', default='',
                        help='Instructions to apply to input text')
    args = parser.parse_args(sys.argv[1:])

    openai.api_key = get_api_key()

    engine = {
        'code': 'code-davinci-edit-001',
        'text': 'text-davinci-edit-001',
    }[args.engine]

    response = openai.Edit.create(
        engine=engine,
        input=sys.stdin.read(),
        instruction=args.instructions,
        temperature=0,
        top_p=1
    )

    response_text = response.choices[0].text
    sys.stdout.write(response_text)


if __name__ == '__main__':
    main()
