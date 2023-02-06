from setuptools import setup, find_packages
from pathlib import Path


with open("README.md", "r") as readme:
    long_description = readme.read()

scripts_dir = Path(__file__).parent / 'openaiwrappers' / 'scripts'
scripts = [fn.stem for fn in scripts_dir.iterdir()
           if not fn.stem.startswith('__')]


setup(
    name='openaiwrappers',
    version='0.1.0',
    author='Noah Hoffman',
    author_email='noah.hoffman@gmail.com',
    description='A package providing some wrappers for the OpenAI API',
    long_description=long_description,
    long_description_content_type="text/markdown",
    url='https://github.com/nhoffman/openaiwrappers',
    packages=find_packages(),
    package_dir={"openaiwrappers": "openaiwrappers"},
    install_requires=['openai'],
    classifiers=[
        "Programming Language :: Python :: 3",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
    entry_points={
        'console_scripts': [f'openai-{name} = openaiwrappers.scripts.{name}:main'
                            for name in scripts]
    }
)
