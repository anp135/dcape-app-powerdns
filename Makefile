# app custom Makefile
PGDATABASE            ?= pdns
PGUSER            ?= pdns
# Database user password
PGPASSWORD            ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)

# DNS tcp/udp port
PORTS       ?= 127.0.0.1:10053

# Stats site host
APP_SITE           ?= ns.dcape.lan
APP_TAG            ?= dns

# Docker image name
IMAGE              ?= psitrax/powerdns
# Docker image tag
IMAGE_VER          ?= v4.3
USE_DB ?= yes
ADD_USER ?= no
DCAPE_DC_USED ?= no
USE_TLS ?= yes
# ------------------------------------------------------------------------------
# app custom config
ADMIN_IMAGE              ?= ngoduykhanh/powerdns-admin
ADMIN_IMAGE_VER          ?= 0.2.3
API_KEY         ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c8; echo)

# Path to schema.pgsql.sql in PowerDNS docker image
PERSIST_FILES = schema.pgsql.sql

define CONFIG_CUSTOM
# ------------------------------------------------------------------------------
# app custom config, generated by make config
# db:$(USE_DB) user:$(ADD_USER)

# DNS server port
PORTS=$(PORTS)

# PowerDNS statistics

# Stats password
API_KEY=$(API_KEY)
PERSIST_FILES=$(PERSIST_FILES)

ADMIN_IMAGE=$(ADMIN_IMAGE)
ADMIN_IMAGE_VER=$(ADMIN_IMAGE_VER)
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

# Wait for postgresql container start
docker-wait:
	@echo -n "Checking PG is ready..." ; \
	until [[ `docker inspect -f "{{.State.Health.Status}}" $(PG_CONTAINER)` == healthy ]] ; do sleep 1 ; echo -n "." ; done
	@echo "Ok"

# create user, db and load sql
pdns-apply: docker-wait
	@echo "*** $@ ***" ; \
	docker exec -i $(PG_CONTAINER) psql -U postgres -c "CREATE USER \"$(PGUSER)\" WITH PASSWORD '$(PGPASSWORD)';" \
	&& docker exec -i $(PG_CONTAINER) psql -U postgres -c "CREATE DATABASE \"$(PGDATABASE)\" OWNER \"$(PGUSER)\";" || db_exists=1 ; \
	if [[ ! "$$db_exists" ]] ; then \
	  cat schema.pgsql.sql | docker exec -i $(PG_CONTAINER) psql -U $(PGUSER) -d $(PGDATABASE) \
	  || true ; \
	fi
