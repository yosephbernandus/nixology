{ pkgs, enabledServices ? "all" }:
let
  redis = import ./services/redis.nix { inherit pkgs; };
  rabbitmq = import ./services/rabbitmq.nix { inherit pkgs; };
  postgresql = import ./services/postgresql.nix { inherit pkgs; };

  utils = {
    shellHook = ''
      # Set up environment
      export DEV_ENV_ID="dev"
      export SERVICE_DIR="$PWD/.services/$DEV_ENV_ID"
      mkdir -p $SERVICE_DIR

      # Set ENABLED_SERVICES from input parameter
      export ENABLED_SERVICES="${enabledServices}"

      check_port() {
        nc -zv localhost $1 2>/dev/null
        if [ $? -eq 0 ]; then
          echo "Warning: Port $1 is already in use - service on this port will be skipped"
          return 1
        fi
        return 0
      }

      # Function to check if service is enabled
      is_service_enabled() {
        if [ "$ENABLED_SERVICES" = "all" ]; then
          return 0
        fi
        echo "$ENABLED_SERVICES" | grep -q "$1"
        return $?
      }

      # Print available services help
      print_services_help() {
        echo "Available services:"
        echo "  - redis"
        echo "  - rabbitmq"
        echo "  - postgres"
        echo ""
        echo "Usage examples:"
        echo "  Run all services:"
        echo "    nix develop"
        echo ""
        echo "  Run specific services:"
        echo "    nix develop .#postgres"
        echo "    nix develop .#redis"
        echo "    nix develop .#database (postgres + redis)"
        echo ""
        echo "  Or using environment variables:"
        echo "    ENABLED_SERVICES='postgres redis' nix develop"
        echo "    ENABLED_SERVICES='postgres' nix develop"
      }
    '';
  };
in
pkgs.mkShell {
  buildInputs = with pkgs; [
    pkgs.redis
    pkgs.rabbitmq-server
    pkgs.postgresql
    pkgs.netcat
    pkgs.glibcLocales
  ];

  shellHook = ''
    # Set up locale
    export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    # Initialize environment
    ${utils.shellHook}

    echo "Starting selected services..."
    echo "----------------------------------------"

    # Start services based on ENABLED_SERVICES
    if is_service_enabled "redis"; then
      ${redis.shellHook}
    fi

    if is_service_enabled "rabbitmq"; then
      ${rabbitmq.shellHook}
    fi

    if is_service_enabled "postgres"; then
      ${postgresql.shellHook}
    fi

    # Setup main cleanup function
    cleanup() {
      echo "Cleaning up all services..."
      if is_service_enabled "redis"; then
        redis_cleanup
      fi
      if is_service_enabled "rabbitmq"; then
        rabbitmq_cleanup
      fi
      if is_service_enabled "postgres"; then
        postgresql_cleanup
      fi
      echo "All services stopped"
    }

    cleanup_service() {
      echo "Cleaning up services..."
      if [ $REDIS_AVAILABLE -eq 1 ] && is_service_enabled "redis"; then
        redis_cleanup
      fi
      if [ $RABBITMQ_AVAILABLE -eq 1 ] && is_service_enabled "rabbitmq"; then
        rabbitmq_cleanup
      fi
      if [ $POSTGRES_AVAILABLE -eq 1 ] && is_service_enabled "postgres"; then
        postgresql_cleanup
      fi
      echo "All services stopped"
    }

    # Trap handlers
    trap cleanup SIGTERM SIGINT SIGHUP
    trap cleanup_service EXIT

    # Print service URLs
    echo ""
    echo "🚀 Development Environment Ready!"
    echo "----------------------------------------"
    if [ $REDIS_AVAILABLE -eq 1 ] && is_service_enabled "redis"; then
      echo "Redis:"
      echo "  URL: redis://$REDIS_USER:$REDIS_PASS@localhost:$REDIS_PORT/0"
      echo "  Test: redis-cli -p $REDIS_PORT ping"
      echo ""
    fi

    if [ $RABBITMQ_AVAILABLE -eq 1 ] && is_service_enabled "rabbitmq"; then
      echo "RabbitMQ:"
      echo "  AMQP URL: amqp://$RABBITMQ_USER:$RABBITMQ_PASS@localhost:$RABBITMQ_NODE_PORT/"
      echo "  Management UI: http://localhost:$RABBITMQ_MANAGEMENT_PORT"
      echo "  Username: $RABBITMQ_USER"
      echo "  Password: $RABBITMQ_PASS"
      echo ""
    fi

    if [ $POSTGRES_AVAILABLE -eq 1 ] && is_service_enabled "postgres"; then
      echo "PostgreSQL:"
      echo "  URL: postgresql://$PGUSER:password@localhost:$PGPORT/$PGDATABASE"
      echo "  Test: psql -h localhost -p $PGPORT -U $PGUSER $PGDATABASE"
      echo ""
    fi
    echo "----------------------------------------"
    echo "Service data directory: $SERVICE_DIR"
    echo ""
    echo "Type 'print_services_help' to see available services and usage"
    echo ""
  '';
}
