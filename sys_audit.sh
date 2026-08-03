#!/usr/bin/env bash

#==========================================
#Linux System Audit Script
#Author: Andrew Lagutin
#Description: Basic system audit and checks
#==========================================

set -o errexit
set -o nounset
set -o pipefail

cleanup() {
	log "INFO" "Script interrupted. Cleaning up and exiting."
	exit 0
}

trap cleanup SIGINT SIGTERM

ENV_FILE=".env"

if [[ -f "$ENV_FILE" ]]; then
	set -o allexport
	# shellcheck source=/dev/null
	source "$ENV_FILE"
	set +o allexport
else
	echo "Warning: .env file not found, using defaults" >&2
fi

LOG_DIR="${LOG_DIR:-./logs}"
LOG_FILE="${LOG_FILE:-sys_audit.log}"
VERBOSE="${VERBOSE:-false}"

mkdir -p "$LOG_DIR"
LOG_PATH="$LOG_DIR/$LOG_FILE"

log() {
	local level="$1"
	local message="$2"
	
	echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_PATH"
	
	if [[ "$VERBOSE" == "true" ]]; then
		echo "[$level] $message"
	fi
}

disk_usage() {
	local usage
	usage=$(df -h / | awk 'NR==2 {gsub("%",""); print $5}')

	if [[ ! "$usage" =~ ^[0-9]+$ ]]; then
		log "ERROR" "Failed to parse disk usage. Got non-numeric value: '$usage'"
		exit 1
	fi

	if [[ "$usage" -ge 80 ]]; then
		log "WARN" "Disk usage is high: ${usage}%"
	else
		log "INFO" "Disk usage is OK: ${usage}%"
	fi
}

memory_usage() {
	local used total percent
	read -r used total <<< "$(free -m | awk '/^Mem:/ {print $3, $2}')"

	if [[ ! "$used" =~ ^[0-9]+$ ]] || [[ ! "$total" =~ ^[0-9]+$ ]] || [[ "$total" -eq 0 ]]; then
		log "ERROR" "Failed to parse memory usage output (used='$used', total='$total')"
		exit 1
	fi
	percent=$(( used * 100 / total ))

	if [[ "$percent" -ge 80 ]]; then
		log "WARN" "Memory usage is high: ${percent}%"
	else
		log "INFO" "Memory usage is OK: ${percent}%"
	fi
}

cpu_load() {
	local cores
	cores=$(nproc)
	local threshold
	threshold=$(echo "$cores * 0.8" | bc -l)
	local load
	load=$(awk '{print $1}' /proc/loadavg 2>/dev/null)

	if [[ ! "$load" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
		log "ERROR" "Failed to parse CPU load. Got non-numeric value: '$load'"
		exit 1
	fi

	if (( $(echo "$load > $threshold" | bc -l) )); then
		log "WARN" "CPU load is high: $load"
	else
		log "INFO" "CPU load is OK: $load"
	fi
}

network_check() {
	if ! command -v ping &> /dev/null; then
		log "WARN" "ping command not found, skipping network check"
		return
	fi

	local target="8.8.8.8"
	if ping -c 1 -W 2 "$target" &> /dev/null; then
		log "INFO" "Network check successful: Able to reach $target"
	else
		log "WARN" "Network check failed: Unable to reach $target"
	fi
	
}
active_users() {
	local users
	local count=0

	mapfile -t users < <(who | awk '{print $1}' | sort -u)
	
	if [[ "${#users[@]}" -eq 0 ]]; then
		log "INFO" "No active users found"
		return
	fi
	for user in "${users[@]}"; do
		log "INFO" "Active user: $user"
		((++count))
	done

	log "INFO" "Total active users: $count"
}

CHECK_DISK=false
CHECK_MEMORY=false
CHECK_USERS=false
CHECK_CPU=false
CHECK_NETWORK=false



usage() {
	echo "Usage: $0 [OPTIONS]"
	echo
	echo "Options:"
	echo "  --disk   Check disk usage"
	echo "  --memory Check memory usage"
	echo "  --users  Show active users"
	echo "  --cpu    Check CPU load"
	echo "  --network Check network connectivity"
	echo "  --all    Run all checks"
	echo "  --help   Show this help message"
}

if [[ $# -eq 0 ]]; then
	echo "Error: No arguments provided" >&2
	usage
	exit 1
fi

for arg in "$@"; do
	case "$arg" in
		--disk)
			CHECK_DISK=true
			;;
		--memory)
			CHECK_MEMORY=true
			;;
		--users)
			CHECK_USERS=true
			;;
		--cpu)
			CHECK_CPU=true
			;;
		--network)
			CHECK_NETWORK=true
			;;
		--all)
			CHECK_DISK=true
			CHECK_MEMORY=true
			CHECK_USERS=true
			CHECK_CPU=true
			CHECK_NETWORK=true
			;;
		--help)
			usage
			exit 0
			;;
		*)
			echo "Unknown option: $arg" >&2
			usage
			exit 1
			;;
	esac
done

log "INFO" "System audit script started"

if $CHECK_DISK; then
	disk_usage
fi

if $CHECK_MEMORY; then
	memory_usage
fi

if $CHECK_USERS; then
	active_users
fi

if $CHECK_CPU; then
	cpu_load
fi

if $CHECK_NETWORK; then
	network_check
fi

log "INFO" "System audit script finished" 
