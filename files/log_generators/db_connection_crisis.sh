#!/bin/bash
################################################################################
# AIOps Database Connection Crisis Log Generator
#
# Generates realistic database connection pool exhaustion error logs
# - Simulates gradually escalating severity
# - Auto-cleans logs older than 3 hours
# - Runs continuously (designed for systemd service)
# - Safe for production demos (controlled disk usage)
################################################################################

# Configuration
LOG_DIR="/var/log/aiops"
LOG_FILE="${LOG_DIR}/app.log"
CLEANUP_HOURS=3
MIN_SLEEP=1
MAX_SLEEP=5

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Log message templates
declare -a WARNING_MESSAGES=(
    "WARN [ConnectionPool] Connection pool usage at 70% (70/100)"
    "WARN [Database] Slow query detected - execution time: 8.5s"
    "WARN [ConnectionPool] Connection wait time increasing: 5s"
    "WARN [Database] Active connections: 85/100"
    "WARN [API] /api/orders - Response time degraded: 2.5s"
)

declare -a ERROR_MESSAGES=(
    "ERROR [ConnectionPool] Max pool size reached (100/100)"
    "ERROR [Database] Connection timeout after 30s"
    "ERROR [API] /api/orders - Connection acquisition failed"
    "ERROR [Database] Unable to acquire connection from pool"
    "ERROR [API] /api/checkout - HTTP 503 Service Unavailable"
    "ERROR [ConnectionPool] All connections in use - requests queuing"
    "ERROR [Application] Database connection pool exhausted"
    "ERROR [API] /api/inventory - Request failed: connection timeout"
    "ERROR [Database] High connection wait time: 45s"
)

declare -a CRITICAL_MESSAGES=(
    "CRITICAL [Application] Service degraded - 85% requests failing"
    "CRITICAL [ConnectionPool] Pool deadlock detected"
    "CRITICAL [Database] Cannot establish new connections"
    "CRITICAL [Application] CASCADE FAILURE: Database → API → User Services"
    "CRITICAL [API] All endpoints returning 503 errors"
    "CRITICAL [Application] INCIDENT: Database connection pool completely exhausted"
)

# Function to get random message from array
get_random_message() {
    local -n arr=$1
    local index=$((RANDOM % ${#arr[@]}))
    echo "${arr[$index]}"
}

# Function to get timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Function to cleanup old logs
cleanup_old_logs() {
    if [ -f "$LOG_FILE" ]; then
        # Find timestamp from 3 hours ago
        CUTOFF_TIME=$(date -d "$CLEANUP_HOURS hours ago" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date -v-${CLEANUP_HOURS}H '+%Y-%m-%d %H:%M:%S')

        # Create temp file with recent logs only
        TEMP_FILE="${LOG_FILE}.tmp"
        if grep -F "$CUTOFF_TIME" "$LOG_FILE" > /dev/null 2>&1; then
            awk -v cutoff="$CUTOFF_TIME" '$0 >= cutoff' "$LOG_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$LOG_FILE"
        fi
    fi
}

# Main log generation loop
echo "$(get_timestamp) INFO [LogGenerator] AIOps log generator starting..."
echo "$(get_timestamp) INFO [LogGenerator] Log file: $LOG_FILE"
echo "$(get_timestamp) INFO [LogGenerator] Cleanup: Logs older than $CLEANUP_HOURS hours will be removed"

CYCLE_COUNT=0

while true; do
    TIMESTAMP=$(get_timestamp)

    # Simulate realistic escalation pattern
    # 60% warnings, 30% errors, 10% critical
    RAND=$((RANDOM % 100))

    if [ $RAND -lt 60 ]; then
        # Generate warning
        MESSAGE=$(get_random_message WARNING_MESSAGES)
        echo "$TIMESTAMP $MESSAGE" >> "$LOG_FILE"
    elif [ $RAND -lt 90 ]; then
        # Generate error
        MESSAGE=$(get_random_message ERROR_MESSAGES)
        echo "$TIMESTAMP $MESSAGE" >> "$LOG_FILE"
    else
        # Generate critical
        MESSAGE=$(get_random_message CRITICAL_MESSAGES)
        echo "$TIMESTAMP $MESSAGE" >> "$LOG_FILE"
    fi

    # Cleanup every 100 cycles (approximately every 5-10 minutes)
    CYCLE_COUNT=$((CYCLE_COUNT + 1))
    if [ $CYCLE_COUNT -ge 100 ]; then
        cleanup_old_logs
        CYCLE_COUNT=0
    fi

    # Random sleep between log entries (1-5 seconds)
    SLEEP_TIME=$((RANDOM % (MAX_SLEEP - MIN_SLEEP + 1) + MIN_SLEEP))
    sleep $SLEEP_TIME
done
