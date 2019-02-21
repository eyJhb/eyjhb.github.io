#!/usr/bin/env bash
docker run --rm -it -v $(pwd):/src -p 4000:4000 blog 
