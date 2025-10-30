#!/bin/bash
################################################################################
# OpenShift Container Log Generator - Payment App Simulator
#
# Simulates realistic OpenShift container logs for payment-app pod
# Generates JSON-formatted logs with connection errors, OOM warnings, crashes
# Auto-cleanup: Deletes logs older than 3 hours
################################################################################

# Configuration
LOG_FILE="/var/log/containers/payment-app-pod123-container.log"
CLEANUP_HOURS=3
MIN_SLEEP=1
MAX_SLEEP=5
CYCLE_COUNT=0

# Ensure log directory exists
mkdir -p "$(dirname "$LOG_FILE")"

# Container metadata
POD_NAME="payment-app-pod123"
CONTAINER_NAME="payment-app"
NAMESPACE="payment-prod"

# Error message templates (OpenShift/Kubernetes style)
ERROR_MESSAGES=(
    '{"timestamp":"TIMESTAMP","level":"ERROR","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Database connection pool exhausted: 0/50 connections available","thread":"http-nio-8080-exec-42"}'
    '{"timestamp":"TIMESTAMP","level":"ERROR","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Connection refused: tcp://postgres-payment-db:5432","connection_attempts":15}'
    '{"timestamp":"TIMESTAMP","level":"ERROR","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"HTTP 500 Internal Server Error on /api/v1/payments","endpoint":"/api/v1/payments","method":"POST","duration_ms":2458}'
    '{"timestamp":"TIMESTAMP","level":"ERROR","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Payment processing failed: timeout waiting for database","transaction_id":"txn-89abc123"}'
    '{"timestamp":"TIMESTAMP","level":"ERROR","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Liveness probe failed: Connection timed out to localhost:8080/healthz"}'
)

CRITICAL_MESSAGES=(
    '{"timestamp":"TIMESTAMP","level":"CRITICAL","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Container memory threshold exceeded: 1.8GB/2GB (90%)","memory_pressure":true}'
    '{"timestamp":"TIMESTAMP","level":"CRITICAL","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"OOMKill candidate: memory usage consistently above 95%"}'
    '{"timestamp":"TIMESTAMP","level":"CRITICAL","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Readiness probe failed 3 consecutive times - pod marked not ready"}'
    '{"timestamp":"TIMESTAMP","level":"CRITICAL","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Fatal: Unable to connect to payment database after 30 retries","error":"FATAL: too many connections for role \\"payment_app\\""}'
    '{"timestamp":"TIMESTAMP","level":"CRITICAL","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Container will be terminated: exit code 137 (OOMKilled)"}'
)

WARNING_MESSAGES=(
    '{"timestamp":"TIMESTAMP","level":"WARN","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Slow database query detected: 3.2s for payment lookup","query":"SELECT * FROM payments WHERE id=?","duration_ms":3245}'
    '{"timestamp":"TIMESTAMP","level":"WARN","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Connection pool approaching limit: 45/50 connections in use"}'
    '{"timestamp":"TIMESTAMP","level":"WARN","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Retry attempt 5/10 for database connection"}'
    '{"timestamp":"TIMESTAMP","level":"WARN","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"High memory usage: 1.5GB/2GB (75%)","gc_duration_ms":234}'
    '{"timestamp":"TIMESTAMP","level":"WARN","pod":"'$POD_NAME'","container":"'$CONTAINER_NAME'","namespace":"'$NAMESPACE'","msg":"Payment API latency spike: p95=2.1s (normal: 150ms)"}'
)

# Get current timestamp in ISO8601 format
get_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%S.%3NZ"
}

# Get random message from array
get_random_message() {
    local -n arr=$1
    local size=${#arr[@]}
    local index=$((RANDOM % size))
    local msg="${arr[$index]}"
    local timestamp=$(get_timestamp)
    echo "$msg" | sed "s/TIMESTAMP/$timestamp/"
}

# Cleanup old logs
cleanup_old_logs() {
    if [ -f "$LOG_FILE" ]; then
        # Find timestamp from N hours ago
        if command -v gdate &> /dev/null; then
            # macOS with GNU date installed
            CUTOFF_TIME=$(gdate -d "$CLEANUP_HOURS hours ago" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null)
        else
            # Linux date
            CUTOFF_TIME=$(date -d "$CLEANUP_HOURS hours ago" '+%Y-%m-%dT%H:%M:%S' 2>/dev/null || date -v-${CLEANUP_HOURS}H '+%Y-%m-%dT%H:%M:%S')
        fi

        # Create temp file with recent logs only
        TEMP_FILE="${LOG_FILE}.tmp"
        if grep -F "$CUTOFF_TIME" "$LOG_FILE" > /dev/null 2>&1; then
            awk -v cutoff="$CUTOFF_TIME" '$0 >= cutoff' "$LOG_FILE" > "$TEMP_FILE" 2>/dev/null || cat "$LOG_FILE" > "$TEMP_FILE"
            mv "$TEMP_FILE" "$LOG_FILE"
        fi
    fi
}

# Main loop
echo "Starting OpenShift Container Log Generator..."
echo "Pod: $POD_NAME"
echo "Container: $CONTAINER_NAME"
echo "Log file: $LOG_FILE"
echo "Cleanup threshold: $CLEANUP_HOURS hours"

while true; do
    # Simulate realistic error escalation pattern
    # 60% warnings, 30% errors, 10% critical
    RAND=$((RANDOM % 100))

    if [ $RAND -lt 60 ]; then
        MESSAGE=$(get_random_message WARNING_MESSAGES)
    elif [ $RAND -lt 90 ]; then
        MESSAGE=$(get_random_message ERROR_MESSAGES)
    else
        MESSAGE=$(get_random_message CRITICAL_MESSAGES)
    fi

    echo "$MESSAGE" >> "$LOG_FILE"

    # Cleanup every 100 cycles (~8-10 minutes)
    CYCLE_COUNT=$((CYCLE_COUNT + 1))
    if [ $CYCLE_COUNT -ge 100 ]; then
        cleanup_old_logs
        CYCLE_COUNT=0
    fi

    # Random sleep between messages
    SLEEP_TIME=$((RANDOM % (MAX_SLEEP - MIN_SLEEP + 1) + MIN_SLEEP))
    sleep $SLEEP_TIME
done
