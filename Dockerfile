# -------- node binary -------- #

FROM node:16.13.1-slim as node


# -------- build dependencies and assets --------#

FROM ruby:3.0.3-slim as build

ENV RAILS_ENV production

# These environment variables are required in boot process
ENV GOOGLE_CLOUD_PROJECT dummy
ENV SPANNER_INSTANCE dummy
ENV SPANNER_DATABASE dummy
ENV SECRET_KEY_BASE dummy
ENV RAILS_MASTER_KEY dummy

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    g++ \
    gcc \
    make

COPY --from=node /usr/local/lib/node_modules /usr/local/lib/node_modules
COPY --from=node /usr/local/bin/node /usr/local/bin/node

RUN ln -s /usr/local/lib/node_modules/npm/bin/npm-cli.js /usr/local/bin/npm \
  && npm i -g yarn

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY package.json /usr/src/app
COPY yarn.lock /usr/src/app

WORKDIR /usr/src/app

RUN bundle config set frozen true \
  && bundle config set with production \
  && bundle install --no-cache \
  && yarn install

COPY . /usr/src/app

RUN bin/rails assets:precompile


# -------- runtime --------#

FROM ruby:3.0.3-slim as runtime

ENV RAILS_ENV production
ENV RAILS_LOG_TO_STDOUT true
ENV RAILS_SERVE_STATIC_FILES true

WORKDIR /usr/src/app

RUN groupadd -g 61000 appuser \
  && useradd -g 61000 -l -m -s /bin/false -u 61000 appuser \
  && mkdir -p /usr/src/app/tmp/pids \
  && chown -R appuser:appuser /usr/src/app

USER appuser

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /usr/src/app/public/assets /usr/src/app/public/assets
COPY --from=build /usr/src/app/public/packs /usr/src/app/public/packs

COPY --chown=appuser:appuser . /usr/src/app
