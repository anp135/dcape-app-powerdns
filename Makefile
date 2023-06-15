# dcape-app-powerdns Makefile

SHELL               = /bin/sh
CFG                ?= .env

# Stats site host
APP_SITE           ?= ns.dev.lan

# App names (db/user name etc)
APP_NAME           ?= pdns

# PgSQL used as DB
USE_DB = yes

# Powerdns API key for DNS-01 ACME challenges
API_KEY            ?= $(shell openssl rand -hex 16; echo)

# Docker image name
IMAGE              ?= ghcr.io/dopos/powerdns-alpine
# Docker image tag
IMAGE_VER          ?= v4.8.0

# DNS tcp/udp port
SERVICE_PORT       ?= 127.0.0.2:53

# Bootstrap new database
DB_INIT_SQL        ?= schema.pgsql.sql
# User who runs bootstrap code
PG_ADMIN           ?= $(PGUSER)

define CONFIG_CUSTOM
# ------------------------------------------------------------------------------
# app custom config, generated by make config
# db:$(USE_DB) user:$(ADD_USER)

# DNS server port
SERVICE_PORT=$(SERVICE_PORT)

# Powerdns API key for DNS-01 ACME challenges
API_KEY=$(API_KEY)

endef

# ------------------------------------------------------------------------------
# Find and include DCAPE/apps/drone/dcape-app/Makefile
DCAPE_COMPOSE   ?= dcape-compose
DCAPE_MAKEFILE  ?= $(shell docker inspect -f "{{.Config.Labels.dcape_app_makefile}}" $(DCAPE_COMPOSE))
ifeq ($(shell test -e $(DCAPE_MAKEFILE) && echo -n yes),yes)
  include $(DCAPE_MAKEFILE)
else
  include /opt/dcape-app/Makefile
endif


define PGUP_4_8_0
ALTER TABLE domains ALTER COLUMN type TYPE text;
ALTER TABLE domains ADD COLUMN options TEXT DEFAULT NULL,
  ADD COLUMN catalog TEXT DEFAULT NULL;

CREATE INDEX catalog_idx ON domains(catalog);
endef

up-4.8.0:
	@echo "$${PGUP_4_8_0}" | docker exec -i $$PG_CONTAINER psql -U $$PGUSER $$PGDATABASE

test:
	curl -s -H 'X-API-Key: $(API_KEY)' http://$(APP_SITE)/api/v1/servers/localhost/zones/vivo.dev. | jq '.'

