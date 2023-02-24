# Precompile script + dependencies into a single file
FROM willhallonline/ansible:2.13-alpine-3.16 as builder

COPY ./ .

RUN apk add --no-cache --virtual .build-deps \
        nodejs \
        npm \
        yarn \
    && rm -rf /var/cache/apk/* /tmp/*

RUN mkdir -p dist && yarn install --silent --non-interactive

RUN npx ncc build ./index.js

# Build the image we publish
FROM willhallonline/ansible:2.13-alpine-3.16

COPY --from=builder /ansible/dist/index.js /index.js

# Basic Packages + Sage
RUN apk add --no-cache --virtual .build-deps \
        autoconf \
        automake \
        g++ \
        libjpeg-turbo-dev \
        libpng-dev \
        libtool \
        make \
        nasm \
        nodejs \
        rsync \
        yarn \
    && rm -rf /var/cache/apk/* /tmp/*

RUN ansible-galaxy collection install community.general
RUN ansible-galaxy collection install community.crypto
RUN ansible-galaxy collection install community.mysql

# Basic smoke test
# RUN echo 'node --version' && node --version && \
#     echo 'yarn versions' && yarn versions && \
#     echo 'python --version' && python --version && \
#     echo 'ansible --version' && ansible --version && \
#     echo 'rsync --version' && rsync --version

ENTRYPOINT ["node", "/index.js"]
