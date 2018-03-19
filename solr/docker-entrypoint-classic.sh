#!/bin/bash

set -eo pipefail

# Make sure required env variables are set
[ -z "$SOLR_HOME" ] && { echo "[ERROR] SOLR_HOME must be set" 1>&2 ; exit 1; }
[ -z "$SOLR_SHARD" ] && { echo "[ERROR] SOLR_SHARD must be set" 1>&2 ; exit 1; }
[ -z "$SOLR_PORT" ] && { echo "[ERROR] SOLR_PORT must be set" 1>&2 ; exit 1; }


# Create SOLR_HOME directory
shard_name="$SOLR_SHARD"
shard_port="$SOLR_PORT"
shard="$shard_name-$shard_port"
mkdir -p /esg/solr-index/${shard}
chown -R solr:solr /esg/solr-index/${shard}

# create solr-home directory /usr/local/solr-home/<host>-<port>/
if [ ! -d "$SOLR_HOME/${shard}" ]; then
  echo "Installing Solr shard: $shard"

  cp -R /usr/local/src/solr-home $SOLR_HOME/${shard}
  rm -rf $SOLR_HOME/${shard}/mycore

  # configure each core
  cores=("datasets"  "files"  "aggregations")
  for core in "${cores[@]}"
  do
    echo "Installing Solr core: $core"
    cp -R /usr/local/src/solr-home/mycore $SOLR_HOME/${shard}/${core}
    sed -i 's/@mycore@/'${core}'/g' $SOLR_HOME/$shard/$core/core.properties && \
    sed -i 's/@solr_config_type@-@solr_server_port@/'${shard}'/g' $SOLR_HOME/${shard}/${core}/core.properties
    if ! [[ $shard_name == 'master' || $shard_name == 'slave' ]]; then
       sed -i '/masterUrl/ s/esgf-solr-master:8984/'${shard_name}'/' $SOLR_HOME/${shard}/${core}/conf/solrconfig.xml
    fi
  done
  chown -R solr:solr $SOLR_HOME/${shard}

fi

# Execute the Solr startup command with this script arguments
echo "[INFO] Running '$@'"
exec gosu "$SOLR_USER" /opt/docker-solr/scripts/docker-entrypoint.sh "$@"
