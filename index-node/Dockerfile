#####
## Docker image for running the ESGF Search application with Tomcat
#####

## In order to modify application-context.xml before Tomcat runs, we need to
## unpack the war manually.
##
## Unpacking a war requires the jar command, which is part of the JDK. However,
## we only want the JRE in the final container.
##
## To get around this, we use a separate build stage with the full JDK to
## download and unpack the war, and copy the unpacked folder into the final container.

ARG ESGF_HUB=cedadev
ARG ESGF_VERSION=latest

# This build stage is required because COPY --from=$ARG is not supported
# https://github.com/moby/moby/issues/34482
FROM ${ESGF_HUB}/esgf-configure:${ESGF_VERSION} as configuration

#############
## Stage 1 ##
#############

FROM openjdk:8-jdk AS esg-search-unpack

# Download and unpack war
ARG ESGF_REPO=http://aims1.llnl.gov/esgf/dist
RUN mkdir /opt/esg-search && \
    cd /opt/esg-search && \
    TMPFILE=$(mktemp) && \
    curl -o $TMPFILE -fsSL $ESGF_REPO/esg-search/esg-search.war && \
    jar xvf $TMPFILE


#############
## Stage 2 ##
#############

FROM ${ESGF_HUB}/esgf-tomcat:$ESGF_VERSION

MAINTAINER Earth System Grid Federation <esgf-devel@lists.llnl.gov>

# Install jq to allow us to easily parse responses from Solr during setup
RUN apt-get update && \
    apt-get install -y jq && \
    rm -rf /var/lib/apt/lists/*

# Copy the unpacked webapp from the previous build stage
COPY --from=esg-search-unpack --chown=tomcat:tomcat /opt/esg-search $CATALINA_HOME/webapps/esg-search
# Remove all permissions from any user except tomcat on the webapp
RUN chmod -R o-rwx $CATALINA_HOME/webapps/esg-search

# Make sure esgf_shards.xml is recognised as a shards file as well as esgf_shards_static.xml
RUN sed -i \
        "s/\/esg\/config\/esgf_shards_static\.xml/\/esg\/config\/esgf_shards\.xml, \0/g" \
        $CATALINA_HOME/webapps/esg-search/WEB-INF/classes/esg/search/config/application-context.xml

# Install environment customisations
COPY --from=configuration /esg/config /esg/config
# Make sure the config interpolation runs first by giving it a low ordinal
COPY --from=configuration /opt/esgf-docker/scripts/interpolate-configs.sh /tomcat-init.d/01-interpolate.sh
COPY scripts/setenv.sh $CATALINA_HOME/bin/
# Make sure this runs after the config interpolation
COPY scripts/create-indices.sh /tomcat-init.d/02-create-indices.sh
