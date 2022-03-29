# dcape-app-powerdns Makefile

SHELL               = /bin/sh
CFG                ?= .env

# Database name
PGDATABASE         ?= pdns
# Database user name
PGUSER             ?= pdns
# Database user password
PGPASSWORD         ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)

# Stats site host
APP_SITE           ?= ns.dev.lan

# Powerdns API key for DNS-01 ACME challenges
API_KEY            ?= $(shell < /dev/urandom tr -dc A-Za-z0-9 | head -c14; echo)

# Docker image name
IMAGE              ?= ghcr.io/dopos/powerdns-alpine
# Docker image tag
IMAGE_VER          ?= master
# dcape container name prefix
DCAPE_TAG          ?= dcape
# dcape network attach to
DCAPE_NET          ?= $(DCAPE_TAG)
USE_DB        ?= yes

DCAPE_DC_USED ?= no
USE_TLS ?= yes
# DNS tcp/udp port
PORTS       ?= 127.0.0.2:53
ADMIN_IMAGE ?= ngoduykhanh/powerdns-admin
ADMIN_IMAGE_VER ?= v0.2.4
# Relative path to library sources from DCAPE/var
PERSIST_FILES ?= *.sql
APP_TAG ?= pdns
IP_WHITELIST ?= 10.0.0.0/8,192.168.0.0/16
define CONFIG_CUSTOM
# ------------------------------------------------------------------------------
# PowerDNS settings DC_USED:$(DCAPE_DC_USED)


# DNS server port
PORTS=$(PORTS)

# Stats site host
APP_SITE=$(APP_SITE)

# Powerdns API key for DNS-01 ACME challenges
API_KEY=$(API_KEY)

# dcape container name prefix
DCAPE_TAG=$(DCAPE_TAG)

# dcape network attach to
DCAPE_NET=$(DCAPE_NET)

# dcape postgresql container name
PG_CONTAINER=$(PG_CONTAINER)

ADMIN_IMAGE=$(ADMIN_IMAGE)
ADMIN_IMAGE_VER=$(ADMIN_IMAGE_VER)
# Relative path to library sources from DCAPE/var
#LIB_PATH=$(LIB_PATH)
PERSIST_FILES=$(PERSIST_FILES)
# Path to /opt/dcape/var. Used only outside drone
DCAPE_ROOT=$(DCAPE_ROOT)
APP_ROOT=$(APP_ROOT)
IP_WHITELIST=$(IP_WHITELIST)

endef


# create user, db and load sql
# ------------------------------------------------------------------------------
# Find and include DCAPE/apps/drone/dcape-app/Makefile
DCAPE_COMPOSE   ?= dcape-compose
DCAPE_MAKEFILE  ?= $(shell docker inspect -f "{{.Config.Labels.dcape_app_makefile}}" $(DCAPE_COMPOSE))
ifeq ($(shell test -e $(DCAPE_MAKEFILE) && echo -n yes),yes)
  include $(DCAPE_MAKEFILE)
else
  include /opt/dcape-app/Makefile
endif

db-init: db-create
	@echo "*** $@ ***" ; \
	if [ "$$db_created" = "1" ] ; then \
	  echo "*** db data load" ; \
	  cat schema.pgsql.sql | docker exec -i $$PG_CONTAINER psql -U $$PGUSER -d $$PGDATABASE -f - ; \
	fi
