---
layout: post
author: eyJhb
title:  "Editing files remotely using ssh and rsync"
date:   2018-11-17 18:00:00 +0000
categories: productivity
---
Just today I had to code in Go on a Raspberry Pi, and I needed a way of doing this easily using my favourite editor, vim.
The first thing I found, was that it could be done using:

```
vim scp://<username>@<ip>//absolute/path/to/file
```

Which worked great!..
Except that I use `vim-go` for my vim installation, which has a bug where it will just delete all the content when you save the file, if you work on `.go` files.
This is a known issue and has been open since 2015 ([Github Issue][vim-go-issue]), and there is currently no hope if it getting fixed anytime soon.

So instead I created this very simple script, which will monitor a directory of your choosing.
Then each time you change a file, delete something etc. it will fire the rsync to keep your files synced.
This way `vim-go` does not delete the content of the file!

```
#!/bin/bash
# sync.sh
DIR=$1

if [ ! -d "$DIR" ]; then
    echo "Usage: ./sync <folder-to-sync>"
    echo "Directory \"$DIR\" does not exists"
    exit
fi

DIR=$(pwd)/$DIR

echo "Syncing folder"

echo $DIR

sync_folder() {
    rsync -avz --delete $DIR pi@192.168.1.20:go/src
}

# initial sync
sync_folder

# keep pooling for data
while inotifywait -r -e modify,create,delete $DIR; do
    sync_folder
    rsync -avz --delete $DIR pi@192.168.1.20:go/src
done
```

Remember to add your ssh-key to your host, so you do not need to enter your password for each prompt.


[vim-go-issue]: https://github.com/fatih/vim-go/issues/632
