"""Submit instructions to the OpenAI completions endpoint

https://platform.openai.com/docs/api-reference/completions
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

    params = {
        'code': {
            'engine': 'code-davinci-002',
            'temperature': 0.05,
            'max_tokens': 512,
            'top_p': 1,
        },
        'text': {
            'engine': 'text-davinci-003',
            'temperature': 0.2,
            'max_tokens': 512,
            'top_p': 1,
        }
    }[args.engine]

    response = openai.Completion.create(
        prompt=args.instructions,
        **params,
    )

    response_text = response.choices[0].text
    sys.stdout.write(response_text)


if __name__ == '__main__':
    main()
