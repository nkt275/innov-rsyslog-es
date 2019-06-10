#!/bin/bash

# Rsyslog script: kibana-setup.sh
# Rsyslog script description: Create Kibana index patterns, dashboards, and visualizations.
# Rsyslog build version: 1.0

# *********** set variables ***************
KIBANA_URL=http://$SERVER_HOST:$SERVER_PORT
TIME_FIELD="@timestamp"
DEFAULT_INDEX="syslog-*"
DIR=/usr/share/kibana/dashboards

# *********** Waiting for Kibana port to be up ***************
echo "[INFO] Checking to see if kibana port is up..."
until curl -s $KIBANA_URL -o /dev/null; do
    sleep 1
done

# *********** wait for kibana to initialize ***************
until $(curl --output /dev/null --silent --head --fail "$KIBANA_URL"); do
  echo "[INFO] Waiting for kibana server..."
  sleep 1
done

# *********** set syslog-* as the default index ***************
  echo "[INFO] Setting syslog-* as the default index..."
  until curl -X POST -H "Content-Type: application/json" -H "kbn-xsrf: true" \
  "$KIBANA_URL/api/kibana/settings/defaultIndex" \
  -d"{\"value\":\"$DEFAULT_INDEX\"}"
  do
    sleep 1
  done

  # *********** Set URL session store *********************
  echo "[INFO] Setting URL session store"
  curl -X POST "$KIBANA_URL/api/kibana/settings" -H 'Content-Type: application/json' -H 'kbn-xsrf: true' -d"
  {
    \"changes\":{
        \"state:storeInSessionStorage\": true
      }
  }
  "

# *********** load dashboards ***************
  echo "[INFO] Loading dashboards..."
  for file in ${DIR}/*.json
  do
      echo "[INFO] Loading dashboard file ${file}"
      until curl -X POST "$KIBANA_URL/api/kibana/dashboards/import" -H 'kbn-xsrf: true' \
      -H 'Content-type:application/json' -d @${file}
      do
        sleep 1
      done
  done

# *********** create kibana index-patterns ***************
  declare -a index_patterns=("syslog-*")

  echo "[INFO] Creating kibana index patterns..."
  for index in ${!index_patterns[@]}; do
      echo "[INFO] Creating kibana index ${index_patterns[${index}]}"
      until curl -X POST "$KIBANA_URL/api/saved_objects/index-pattern/${index_patterns[${index}]}" \
      -H "Content-Type: application/json" -H "kbn-xsrf: true" \
      -d"{\"attributes\":{\"title\":\"${index_patterns[${index}]}\",\"timeFieldName\":\"$TIME_FIELD\"}}"
      do
          sleep 1
      done
  done