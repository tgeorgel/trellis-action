ARG NODE_VERSION=18.16.0
ARG ALPINE_VERSION=3.18
ARG ANSIBLE_VERSION=2.18

# Precompile script + dependencies into a single file
FROM willhallonline/ansible:${ANSIBLE_VERSION}-alpine-${ALPINE_VERSION} AS builder

COPY ./ .

RUN apk add --no-cache --virtual .build-deps \
        nodejs \
        npm \
        yarn \
    && rm -rf /var/cache/apk/* /tmp/*

RUN mkdir -p dist && yarn install --silent --non-interactive

RUN npx ncc build ./index.js

FROM node:${NODE_VERSION}-alpine AS node

# Build the image we publish
FROM willhallonline/ansible:${ANSIBLE_VERSION}-alpine-${ALPINE_VERSION}

COPY --from=node /usr/lib /usr/lib
COPY --from=node /usr/local/lib /usr/local/lib
COPY --from=node /usr/local/include /usr/local/include
COPY --from=node /usr/local/bin /usr/local/bin

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
        rsync \
    && rm -rf /var/cache/apk/* /tmp/*

RUN npm install -g yarn --force

RUN ansible-galaxy collection install community.general \
 && ansible-galaxy collection install community.crypto \
 && ansible-galaxy collection install community.mysql

# Basic smoke test
# RUN echo 'node --version' && node --version && \
#     echo 'yarn versions' && yarn versions && \
#     echo 'python --version' && python --version && \
#     echo 'ansible --version' && ansible --version && \
#     echo 'rsync --version' && rsync --version

ENTRYPOINT ["node", "/index.js"]
