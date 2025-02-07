{ pkgs }:
{
  shellHook = ''
    # PostgreSQL Configuration
    export PGPORT=5434
    export PGHOST="127.0.0.1"
    export PGUSER="postgres_dev"
    export PGDATABASE="postgres_dev"
    export PGDATA="$SERVICE_DIR/postgres/data"

    # Check PostgreSQL port
    export POSTGRES_AVAILABLE=0
    check_port $PGPORT
    if [ $? -eq 0 ]; then
      export POSTGRES_AVAILABLE=1
    fi

    if [ $POSTGRES_AVAILABLE -eq 1 ]; then
      echo "Starting PostgreSQL..."
      if [ ! -d "$PGDATA" ]; then
        initdb --username=postgres --auth=trust -D "$PGDATA" --no-locale --encoding=UTF8
        cat > "$PGDATA/postgresql.conf" << EOF
port = $PGPORT
unix_socket_directories = '$SERVICE_DIR/postgres'
listen_addresses = '127.0.0.1'
EOF

        pg_ctl -D "$PGDATA" -l "$SERVICE_DIR/postgres/postgresql.log" -o "-p $PGPORT" start
        
        until pg_isready -h localhost -p $PGPORT -q; do
          sleep 1
        done

        PGUSER=postgres psql -p $PGPORT -h 127.0.0.1 -d postgres << EOF
CREATE USER $PGUSER WITH SUPERUSER PASSWORD 'password';
CREATE DATABASE $PGDATABASE OWNER $PGUSER;
GRANT ALL PRIVILEGES ON DATABASE $PGDATABASE TO $PGUSER;
EOF
      else
        pg_ctl -D "$PGDATA" -l "$SERVICE_DIR/postgres/postgresql.log" -o "-p $PGPORT" start
        until pg_isready -h localhost -p $PGPORT -q; do
          sleep 1
        done
      fi
      echo "✓ PostgreSQL is ready"
    else
      echo "Warning: PostgreSQL service is skipped"
    fi

    # PostgreSQL cleanup function
    postgresql_cleanup() {
      if [ $POSTGRES_AVAILABLE -eq 1 ]; then
        echo "Stopping PostgreSQL..."
        pg_ctl -D "$PGDATA" stop || true
      fi
    }
  '';
}
