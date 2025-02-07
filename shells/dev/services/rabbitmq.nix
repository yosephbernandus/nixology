{ pkgs }:
{
  shellHook = ''
    # RabbitMQ Configuration
    export RABBITMQ_NODE_PORT=5673
    export RABBITMQ_MANAGEMENT_PORT=15673
    export RABBITMQ_DIST_PORT=25673
    export RABBITMQ_USER="dev_user"
    export RABBITMQ_PASS="dev_password"

    # Check RabbitMQ ports
    export RABBITMQ_AVAILABLE=0
    check_port $RABBITMQ_NODE_PORT
    RABBITMQ_NODE_OK=$?
    check_port $RABBITMQ_MANAGEMENT_PORT
    RABBITMQ_MGMT_OK=$?
    check_port $RABBITMQ_DIST_PORT
    RABBITMQ_DIST_OK=$?
    if [ $RABBITMQ_NODE_OK -eq 0 ] && [ $RABBITMQ_MGMT_OK -eq 0 ] && [ $RABBITMQ_DIST_OK -eq 0 ]; then
      export RABBITMQ_AVAILABLE=1
    fi

    if [ $RABBITMQ_AVAILABLE -eq 1 ]; then
      echo "Starting RabbitMQ..."
      (
        export RABBITMQ_NODENAME="rabbit_$DEV_ENV_ID@localhost"
        export RABBITMQ_BASE="$SERVICE_DIR/rabbitmq"
        export RABBITMQ_MNESIA_BASE="$SERVICE_DIR/rabbitmq/mnesia"
        export RABBITMQ_LOG_BASE="$SERVICE_DIR/rabbitmq/logs"
        export RABBITMQ_PID_FILE="$SERVICE_DIR/rabbitmq/pid"
        export RABBITMQ_CONFIG_FILE="$SERVICE_DIR/rabbitmq/rabbitmq"
        export RABBITMQ_ENABLED_PLUGINS_FILE="$SERVICE_DIR/rabbitmq/enabled_plugins"
        export RABBITMQ_NODE_IP_ADDRESS=127.0.0.1

        mkdir -p $RABBITMQ_MNESIA_BASE $RABBITMQ_LOG_BASE

        echo "DEVELOPMENT_COOKIE" > "$SERVICE_DIR/rabbitmq/.erlang.cookie"
        chmod 400 "$SERVICE_DIR/rabbitmq/.erlang.cookie"
        export RABBITMQ_ERLANG_COOKIE="DEVELOPMENT_COOKIE"

        cat > $SERVICE_DIR/rabbitmq/rabbitmq.conf << EOF
listeners.tcp.default = $RABBITMQ_NODE_PORT
management.listener.port = $RABBITMQ_MANAGEMENT_PORT
management.listener.ip = 127.0.0.1
management.listener.ssl = false

default_user = $RABBITMQ_USER
default_pass = $RABBITMQ_PASS
default_vhost = /
default_user_tags.administrator = true

default_permissions.configure = .*
default_permissions.read = .*
default_permissions.write = .*
EOF

        cat > "$RABBITMQ_ENABLED_PLUGINS_FILE" << EOF
[rabbitmq_management].
EOF

        HOME="$SERVICE_DIR/rabbitmq" RABBITMQ_HOME="$SERVICE_DIR/rabbitmq" \
        rabbitmq-server > $SERVICE_DIR/rabbitmq/startup.log 2>&1
      ) &

      echo "Waiting for RabbitMQ..."
      export RABBITMQ_ERLANG_COOKIE="DEVELOPMENT_COOKIE"
      for i in {1..60}; do
        if HOME="$SERVICE_DIR/rabbitmq" rabbitmqctl -n "rabbit_$DEV_ENV_ID@localhost" await_startup >/dev/null 2>&1; then
          echo "✓ RabbitMQ is ready"
          HOME="$SERVICE_DIR/rabbitmq" rabbitmq-plugins -n "rabbit_$DEV_ENV_ID@localhost" enable rabbitmq_management >/dev/null 2>&1
          break
        fi
        echo -n "."
        sleep 1
        if [ $i -eq 60 ]; then
          echo "❌ RabbitMQ failed to start. Check logs at $SERVICE_DIR/rabbitmq/startup.log"
        fi
      done
    else
      echo "Warning: RabbitMQ service is skipped"
    fi

    # RabbitMQ cleanup function
    rabbitmq_cleanup() {
      if [ $RABBITMQ_AVAILABLE -eq 1 ]; then
        echo "Stopping RabbitMQ..."
        HOME="$SERVICE_DIR/rabbitmq" rabbitmqctl -n "rabbit_$DEV_ENV_ID@localhost" stop || true
      fi
    }
  '';
}
