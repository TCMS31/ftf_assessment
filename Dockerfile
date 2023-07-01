# syntax=docker/dockerfile:1

# ---------- Stage 1: build gems and precompile assets ----------
FROM ruby:3.1.3-slim AS builder

ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Gems are their own layer so application edits do not invalidate the bundle.
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4 --retry 3 && \
    rm -rf "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .

# Sprockets needs a key present to boot; it is never used to sign anything that
# outlives the build, and the real key is supplied at runtime via SECRET_KEY_BASE.
RUN SECRET_KEY_BASE=precompile_placeholder bundle exec rails assets:precompile && \
    bundle exec bootsnap precompile --gemfile app/ lib/

# ---------- Stage 2: runtime ----------
FROM ruby:3.1.3-slim AS runtime

ENV BUNDLE_DEPLOYMENT=1 \
    BUNDLE_PATH=/usr/local/bundle \
    BUNDLE_WITHOUT=development:test \
    RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    PORT=3000

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libpq5 postgresql-client tzdata && \
    rm -rf /var/lib/apt/lists/*

# Non-root runtime user. The app never writes outside tmp/ and log/.
RUN groupadd --system --gid 1000 rails && \
    useradd --system --uid 1000 --gid 1000 --create-home rails

WORKDIR /app

COPY --from=builder --chown=rails:rails /usr/local/bundle /usr/local/bundle
COPY --from=builder --chown=rails:rails /app /app

USER rails:rails

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
  CMD curl -fsS "http://127.0.0.1:${PORT}/up" || exit 1

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
