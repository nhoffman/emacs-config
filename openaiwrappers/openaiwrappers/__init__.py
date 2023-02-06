import netrc
import os


def get_api_key():
    try:
        __, __, api_key = netrc.netrc().hosts['openai']
    except KeyError:
        api_key = os.getenv("OPENAI_API_KEY")

    return api_key


