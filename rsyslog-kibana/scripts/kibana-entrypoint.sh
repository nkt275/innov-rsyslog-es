#!/bin/sh

# Rsyslog script: kibana-entrypoint.sh
# Rsyslog script description: Start Kibana service
# Rsyslog build version: 1.0

# *********** environment variables ***************
if [[ -z "$ELASTICSEARCH_HOSTS" ]]; then
  export ELASTICSEARCH_HOSTS=http://172.18.0.2:9200
fi
echo "[INFO] Setting Elasticsearch URL to $ELASTICSEARCH_HOSTS"

if [[ -z "$SERVER_HOST" ]]; then
  export SERVER_HOST=rsyslog-kibana
fi
echo "[INFO] Setting Kibana server host to $SERVER_HOST"

if [[ -z "$SERVER_PORT" ]]; then
  export SERVER_PORT=5601
fi
echo "[INFO] Setting Kibana server port to $SERVER_PORT"

# *********** check if elasticsearch is up ***************
  echo "[INFO] Waiting for elasticsearch URI to be accessible.."
  number_of_attempts_to_try=7
  number_of_attempts=0
  until [[ "$(curl -s -o /dev/null -w "%{http_code}" $ELASTICSEARCH_HOSTS)" == "200" ]]; do
    if [[ ${number_of_attempts} -eq ${number_of_attempts_to_try} ]];then
        echo "[ERROR] Max attempts reached waiting for elasticsearch URI to become accessible.."
        sleep 10
        exit 1
    fi
    number_of_attempts=$(($number_of_attempts+1))
    sleep 3
  done
  sleep 5

echo "[INFO] Starting Kibana service..."
exec /usr/local/bin/kibana-docker &

# *********** create dashboards, visualizations and index-patterns ***************
echo "[INFO] Running kibana_setup.sh script..."
/usr/share/kibana/scripts/kibana-setup.sh

tail -f /usr/share/kibana/config/kibana_logs.log
