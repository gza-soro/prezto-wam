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
NC='\033[0m' # No Color

# Cleanup handler
cleanup() {
    # Note: Since we stream credentials via pipe, there's nothing to clean up
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

# Main execution
main() {
    check_dependencies
    
    echo -e "${YELLOW}Starting OpenVPN3 connection...${NC}"
    
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
    fi
    
    return $exit_code
}

# Run main
main "$@"
