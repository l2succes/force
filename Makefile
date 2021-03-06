#
# Make -- the OG build tool.
# Add any build tasks here and abstract complex build scripts into `lib` that
# can be run in a Makefile task like `coffee lib/build_script`.
#
# Remember to set your text editor to use 4 size non-soft tabs.
#

BIN = node_modules/.bin

# Start the server with the OSS env vars instead of the developer's `.env`
oss:
	APP_URL=http://localhost:5000 APPLICATION_NAME=force-staging $(BIN)/nf start --env .env.oss

# Start the server
s:
	APP_URL=http://localhost:5000 APPLICATION_NAME=force-development $(BIN)/nf start

# Start the server using forever
sf:
	$(BIN)/forever $(BIN)/coffee --nodejs --max_old_space_size=960 index.coffee

# Start the server using debugger mode
sd:
	$(BIN)/coffee --nodejs --debug index.coffee

# Start the server pointing to staging
ss:
	APP_URL=http://localhost:5000 METAPHYSICS_ENDPOINT=https://metaphysics-staging.artsy.net APPLICATION_NAME=force-staging API_URL=https://stagingapi.artsy.net $(BIN)/nf start

# Start the server pointing to staging with cache
ssc:
	APP_URL=http://localhost:5000 METAPHYSICS_ENDPOINT=https://metaphysics-staging.artsy.net OPENREDIS_URL=redis://127.0.0.1:6379 APPLICATION_NAME=force-staging API_URL=https://stagingapi.artsy.net $(BIN)/nf start

# Start the server pointing to production
sp:
	APP_URL=http://localhost:5000 APPLICATION_NAME=force-production API_URL=https://api.artsy.net $(BIN)/nf start

# Start the server pointing to production on artsy domain
spl:
	APP_URL=http://local.artsy.net:5000 APPLICATION_NAME=force-production API_URL=https://api.artsy.net $(BIN)/nf start

# Start server pointing to production with cache
spc:
	APP_URL=http://localhost:5000 OPENREDIS_URL=redis://127.0.0.1:6379 APPLICATION_NAME=force-production API_URL=https://api.artsy.net $(BIN)/nf start

# Start the server pointing to production with debugger
spd:
	$(BIN)/node-inspector --web-port=8081 & APP_URL=http://localhost:5000 APPLICATION_NAME=force-production API_URL=https://api.artsy.net $(BIN)/nf start -j ./Procfile.dev

# Start the server pointing to staging with debugger
ssd:
	$(BIN)/node-inspector --web-port=8081 & APP_URL=http://localhost:5000 APPLICATION_NAME=force-staging API_URL=https://stagingapi.artsy.net $(BIN)/nf start -j ./Procfile.dev

# Run all of the project-level tests, followed by app-level tests
test:
	$(BIN)/ezel-assets
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/**/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/**/*/test -name '*.coffee' -not -path 'test/helpers/*')

# Run tests sans-asset compilation
test-l:
	$(BIN)/mocha $(shell find test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find components/**/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/test -name '*.coffee' -not -path 'test/helpers/*')
	$(BIN)/mocha $(shell find apps/*/**/*/test -name '*.coffee' -not -path 'test/helpers/*')

# Start the integration server for debugging
test-s:
	$(BIN)/ezel-assets
	$(BIN)/coffee test/helpers/integration.coffee

# Runs all the necessary build tasks to push to staging or production.
# Run with `make deploy env=staging` or `make deploy env=production`.
deploy:
	$(BIN)/ezel-assets
	$(BIN)/bucket-assets --bucket force-$(env)
	heroku config:set COMMIT_HASH=$(shell git rev-parse --short HEAD) --app=force-$(env)
	git push --force git@heroku.com:force-$(env).git

# Runs all the necessary build tasks to push the currently checked out branch
# to a personal heroku app.
# Run with `make deploy_custom app=app_name`.
deploy_custom:
	$(BIN)/ezel-assets
	$(BIN)/bucket-assets --bucket $(app)
	heroku config:set COMMIT_HASH=$(shell git rev-parse --short HEAD) --app=$(app)
	git push -f git@heroku.com:$(app).git $(shell git rev-parse --symbolic-full-name --abbrev-ref HEAD):master

.PHONY: test
