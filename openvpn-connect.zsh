#!/bin/zsh

# =============================================================================
# Proton Pass + OpenVPN3 Connection Script
# Uses pass-cli to retrieve credentials and pipes them to openvpn3
# No temp files, no environment variable leakage
# =============================================================================

set -euo pipefail

# Configuration
VAULT_NAME="Work"
ITEM_NAME="OpenVPN"
CONFIG_NAME="agonzalez-ovpn3-config"

# Color output helpers
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup handler
cleanup() {
    echo -e "\n${GREEN}Connection terminated.${NC}"
}

trap cleanup EXIT INT TERM

# Check prerequisites
check_dependencies() {
    local deps=("pass-cli" "openvpn3")
    for cmd in ${deps}; do
        if ! command -v "$cmd" &> /dev/null; then
            echo -e "${RED}Error: $cmd not found in PATH${NC}" >&2
            exit 1
        fi
    done
}

# Check pass-cli session status
check_pass_session() {
    # Attempt to list vaults as a lightweight session check
    pass-cli vault list &> /dev/null

    local exit_code=$?

    # echo -e "${YELLOW}Error code is $exit_code${NC}" >&2

    case $exit_code in
        0)
            ;;
        1)
            echo -e "${RED}Error: pass-cli session is locked.${NC}" >&2
            ;;
        *)
            echo -e "${RED}Error: unsupported pass-cli exit code $exit_code${NC}" >&2
            ;;
    esac

    return $exit_code
}

# Get credential field with error handling
check_credential() {
    # Capture stderr to detect specific pass-cli errors
    pass-cli item view --vault-name "$VAULT_NAME" --item-title "$ITEM_NAME" --field username &>/dev/null

    local exit_code=$?

    case $exit_code in
        0)
            ;;
        1)
            echo -e "${RED}Error: Item '$ITEM_NAME' not found in vault '$VAULT_NAME'.${NC}" >&2
            ;;
        *)
            echo -e "${RED}Error retrieving username (exit code: $exit_code).${NC}" >&2
            ;;
    esac

    return $exit_code
}

# Main execution
main() {
    check_dependencies

    echo -e "${YELLOW}Starting OpenVPN3 connection...${NC}"

    # Pre-flight session check (catches locked session before attempting credential retrieval)
    echo -e "${BLUE}Checking pass-cli session...${NC}"
    if ! check_pass_session; then
        return 1
    fi

    echo -e "${BLUE}Checking pass-cli credential...${NC}"
    if ! check_credential; then
        return 1
	fi

    # Stream credentials directly to openvpn3 via pipe
    # No credentials ever touch disk or env vars
    printf "%s\n%s\n" \
        "$(pass-cli item view --vault-name "$VAULT_NAME" --item-title "$ITEM_NAME" --field username)" \
        "$(pass-cli item view --vault-name "$VAULT_NAME" --item-title "$ITEM_NAME" --field password)" \
        | openvpn3 session-start --config "$CONFIG_NAME"

    local exit_code=$?

    if [[ $exit_code -eq 0 ]]; then
        echo -e "${GREEN}Connection established successfully.${NC}"
    else
        echo -e "${RED}Connection failed with exit code: $exit_code${NC}" >&2
        echo -e "${BLUE}Troubleshooting:${NC}" >&2
        echo -e "  • Verify the config '$CONFIG_NAME' exists: openvpn3 config-list" >&2
        echo -e "  • Check for existing sessions: openvpn3 sessions-list" >&2
        echo -e "  • Ensure pass-cli session is unlocked: pass-cli status" >&2
    fi

    return $exit_code
}

# Run main
main "$@"
