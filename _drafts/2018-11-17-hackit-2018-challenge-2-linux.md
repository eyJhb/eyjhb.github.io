---
layout: post
author: eyJhb
title:  "Hack IT 2018 - Challenge 2 - Crymore"
date:   2018-11-17 18:00:00 +0000
categories: ctf hackit2018
---
One of the challenges at Hack IT 2018 was about ransomware, where one was build specific for Windows and another for Linux.
I will be focusing on the one for Linux in this posts, which was called `crymore`.
Crymore consisted of the following three parts:

- crymore (binary file)
- crymore.py (python script)
- flag.important.CryMoreQQ (encrypted file containing the flag)

`crymore` is a executable binary, which calls `crymore.py <encryption-key>`
 which then looks for any files with the extension `.important` in the root directory (`/`) and encrypts them.
`flag.important.CyrMoreQQ` is the flag that we need to decrypt somehow, by exploiting whatever weakness the crymore has.

`crymore.py` looks like this
```python
#!/usr/bin/env python3
import os
from Crypto.Cipher import AES
from Crypto.Util import Counter
from time import time
from sys import argv

def find_important_files(startpath):
    for dirpath, dirs, files in os.walk(startpath):
        for f in files:
            abspath = os.path.abspath(os.path.join(dirpath, f))
            if abspath.split('.')[-1] == 'important':
                yield abspath

def encrypt_file(filename, crypto, blocksize=16, ts=0):
    with open(filename, 'r+b') as f:
        plaintext = f.read(blocksize)
        while plaintext:
            ciphertext = crypto(bytes([p ^ ord(k) for p, k in zip(plaintext, ts[blocksize // 4 + 2: blocksize // 2 + 2] * (blocksize // 4))]))
            f.seek(-len(plaintext), 1)
            f.write(ciphertext)
            plaintext = f.read(blocksize)

if __name__ == "__main__":
    if not (argv[0] == './crymore.py' and len(argv) == 2):
        exit(1)
    key = argv[1]
    if not len(key) == 32:
        exit(1)
    ctr = Counter.new(128)
    crypt = AES.new(key, AES.MODE_CTR, counter=ctr)
    key = None
    for f in find_important_files('./'):
        encrypt_file(f, crypt.encrypt, ts=str(int(time())))
        os.rename(f, f + '.CryMoreQQ')
```

Running `./crymore` yields in the following output being produced.

```bash
root@cf5dcfd7d62c:/src# ./crymore
> Python module basic integrity passed
> Self basic integrity passed
> Python module integrity passed
> Self integrity verified
Starting encryption of all important files...
Done encrypting all files!
```

My initial thought was to edit `crymore.py`, to give me the key you initialize it with.
However, this was not as easy as I had thought, as it verifies that `crymore.py` has not been tampered with.

```bash
root@cf5dcfd7d62c:/src# ./crymore
ERROR: Unable to verify integrity of application.
Terminating...
```

So not being able to edit `crymore.py`, my next thought was to edit the binary file (`crymore`), but seeing as
I do not have much experience dealing with binary files I would rather avoid this.
Instead it is possible to modify the `Crypto` library to print the key, as it does not do integrity check the `Crypto` library.
So now it was just a matter of locating the `Crypto` library.

```bash
root@cf5dcfd7d62c:/src# cd /
root@cf5dcfd7d62c:/# find . -name "*Crypto*"
./usr/local/lib/python3.7/site-packages/Crypto
```

Now just cd to the folder, and patch `Cipher/AES.py` using the following.

```diff
diff --git a/Cipher/AES.py b/Cipher/AES.py
index 14f68d8..a18ecd7 100644
--- a/Cipher/AES.py
+++ b/Cipher/AES.py
@@ -59,6 +59,9 @@ class AESCipher (blockalgo.BlockAlgo):
         blockalgo.BlockAlgo.__init__(self, _AES, key, *args, **kwargs)
 
 def new(key, *args, **kwargs):
+    print("Key: ")
+    print(key)
+    print("-----------")
     """Create a new AES cipher
 
     :Parameters:
```

Now when you initialize the Crypto with the AES key, it will print out the key for us to copy.
Running `./crymore` now results in the following output.

```bash
root@cf5dcfd7d62c:/src# ./crymore
> Python module basic integrity passed
> Self basic integrity passed
> Python module integrity passed
> Self integrity verified
Starting encryption of all important files...
Key: 
1A3DB0529D8F64E648377B40A0AEB6F2
-----------
Done encrypting all files!
```

Now that we have the key, it is time to write a function to decrypt our important flag!
The important part of the code, is located in the function `encrypt_files`.

```python
def encrypt_file(filename, crypto, blocksize=16, ts=0):
    with open(filename, 'r+b') as f:
        plaintext = f.read(blocksize)
        while plaintext:
            ciphertext = crypto(bytes([p ^ ord(k) for p, k in zip(plaintext, ts[blocksize // 4 + 2: blocksize // 2 + 2] * (blocksize // 4))]))
            f.seek(-len(plaintext), 1)
            f.write(ciphertext)
            plaintext = f.read(blocksize)
```

Looking at the code, we can see that the functions gets the `filename`, `crypto` (the encryption function passed to it), `blocksize` and `ts` (timestamp).
If we run though the code one step at a time, we see that first we open the file as read in binary mode, then read 16 bytes (our blocksize) from the file, and continue doing so (`while plaintext`).
After this the we have a long line, where the actual encryption happens 

```python
ciphertext = crypto(bytes([p ^ ord(k) for p, k in zip(plaintext, ts[blocksize // 4 + 2: blocksize // 2 + 2] * (blocksize // 4))]))
```

It can be seen, that we have some `XOR` (`p ^ ord(k)`) going on before the actual encryption happens.
Evaluating `blocksize // 4 + 2` and `blocksize // 2 + 2` in the `ts` statement, gives us `ts[6:10]`,
meaning that it uses the last 4 digits in the timestamp to XOR with the plaintext data.
When it has done it will the encrypt the XOR'ed data, and overwrite the plaintext data.

To undo this encryption, we need to rewrite the function in the reverse order.
This means first decrypt the data, and then do the XOR again.

```python
def decrypt_file(filename, crypto, blocksize=16, ts=0):
    ftext = b""
    with open(filename, 'r+b') as f:
        ciphertext = f.read(blocksize)
        while ciphertext:
            decrypted = crypto(ciphertext)
            unxor = bytes([p ^ ord(k) for p, k in zip(decrypted, ts[blocksize // 4 + 2: blocksize // 2 + 2] * (blocksize // 4))])
            ftext += unxor 
            ciphertext = f.read(blocksize)
    return ftext
```

This function read the files (binary), decrypts it using the key, undoes the XOR then adds it to our final text and returns the final text when done.

Now we are nearly ready to decrypt our flag, we only need to rewrite the main code, to try and guess the timestamp for the encryption.
As we have previously discovered it only uses the last 4 digits of the timestamp, so it is enough for us to guess 10000 times.
If it reaches a string with `HackIT` in it, we know that it is the flag, so just print and break.

```python
    key = b"1A3DB0529D8F64E648377B40A0AEB6F2"
    for x in range(10000):
        ctime = "000000"+str("{:04d}".format(x))
        ctr = Counter.new(128)
        crypt = AES.new(key, AES.MODE_CTR, counter=ctr)
        plain = decrypt_file("flag.important.CryMoreQQ", crypt.decrypt, ts=ctime)
        if b"Hack" in plain:
            print(plain)
            break
```

Finally running the code gives us the flag!

```bash
root@cf5dcfd7d62c:/src# python decrypt.py
b'There you go, take a well deserved flag:\n\n  HackIT{blackbox_whitebox_deadbox_dropbox}\n\n:-)\n'
```

# Final notes
Instead of editing the `Crypto` library files, to print out the key
it is possible to use `strace` to print our the argument, passed
to `crypto.py` when it is called.
This can be done using the following command

```
strace -s 128 -f -e execve ./crymore
```

- `-s 128` -> specifies the maximum length of the strings strace returns
- `-f` -> trace child processes (when we call `crymore.py`)
- `-e execve` -> only print information regarding `execve` (used when executing a file)
- `./crymore` -> our binary file to strace
