{ pkgs }:
{
  shellHook = ''
    # Redis Configuration
    export REDIS_PORT=6380
    export REDIS_USER="dev_user"
    export REDIS_PASS="dev_password"
    export REDISCLI_AUTH=$REDIS_PASS

    # Check Redis availability
    export REDIS_AVAILABLE=0
    check_port $REDIS_PORT
    if [ $? -eq 0 ]; then
      export REDIS_AVAILABLE=1
    fi

    if [ $REDIS_AVAILABLE -eq 1 ]; then
      echo "Starting Redis..."
      (
        mkdir -p $SERVICE_DIR/redis/{data,logs}
        
        cat > $SERVICE_DIR/redis/redis.conf << EOF
port $REDIS_PORT
pidfile $SERVICE_DIR/redis/redis.pid
dir $SERVICE_DIR/redis/data
logfile $SERVICE_DIR/redis/logs/redis.log
daemonize yes
bind 127.0.0.1
databases 16
maxmemory 100mb
maxmemory-policy allkeys-lru
stop-writes-on-bgsave-error no
appendonly yes
appendfilename "appendonly.aof"

# Authentication
requirepass $REDIS_PASS
user default off
user $REDIS_USER on >$REDIS_PASS ~* &* +@all
EOF

        redis-server $SERVICE_DIR/redis/redis.conf --loglevel notice
      ) &

      # Wait for Redis
      echo "Waiting for Redis to start..."
      for i in {1..30}; do
        if redis-cli -p $REDIS_PORT ping >/dev/null 2>&1; then
          echo "✓ Redis is ready"
          break
        fi
        echo -n "."
        sleep 1
        if [ $i -eq 30 ]; then
          echo "❌ Redis failed to start. Check logs at $SERVICE_DIR/redis/logs/redis.log"
        fi
      done
    else
      echo "Warning: Redis service is skipped"
    fi

    # Redis cleanup function
    redis_cleanup() {
      if [ $REDIS_AVAILABLE -eq 1 ]; then
        echo "Stopping Redis..."
	redis-cli -p 6380 -u redis://$REDIS_USER:$REDIS_PASS@localhost:$REDIS_PORT shutdown
      fi
    }
  '';
}
