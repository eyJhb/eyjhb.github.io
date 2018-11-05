FROM alpine:3.8

RUN apk add --no-cache \
        ruby ruby-rdoc ruby-dev alpine-sdk \ 
        ruby-bigdecimal ruby-webrick ruby-etc && \
    gem install jekyll bundler && \
    apk del ruby-dev alpine-sdk

RUN \
    printf "#!/bin/sh\ncd /src\nbundle install\nbundle exec jekyll serve --watch --drafts --future -H 0.0.0.0" > /init.sh && \
    chmod +x /init.sh

ENTRYPOINT ["/init.sh"]
