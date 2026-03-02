#!/bin/bash

# Script to help manage multiple website repositories
# This allows you to clone, update, and manage multiple school websites

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

# Function to display help
show_help() {
    cat << EOF
Schools Website Repository Manager

Usage: ./manage-repos.sh [COMMAND] [OPTIONS]

Commands:
    clone <repo_url> <domain_name>     Clone a website repository
                                       Example: ./manage-repos.sh clone https://github.com/school/website.git elbethelacademy.com
    
    pull [domain_name]                 Update a website (git pull)
                                       Example: ./manage-repos.sh pull elbethelacademy.com
    
    pull-all                           Update all websites
    
    add-domain <domain>                Add a new domain (updates .env)
                                       Example: ./manage-repos.sh add-domain newschool.com
    
    list                               List all configured domains
    
    status                             Show status of all websites
    
    help                               Show this help message

Examples:
    # Clone a website repository
    ./manage-repos.sh clone https://github.com/school/elbethel.git elbethelacademy.com
    
    # Update specific website
    ./manage-repos.sh pull elbethelacademy.com
    
    # Update all websites
    ./manage-repos.sh pull-all
    
    # Add new domain after cloning
    ./manage-repos.sh add-domain schoolname.com

EOF
}

# Clone a repository
clone_repo() {
    local repo_url="$1"
    local domain="$2"
    
    if [ -z "$repo_url" ] || [ -z "$domain" ]; then
        log_error "Usage: ./manage-repos.sh clone <repo_url> <domain_name>"
        exit 1
    fi
    
    if [ -d "$domain" ]; then
        log_warning "Directory '$domain' already exists"
        read -p "Overwrite? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            return
        fi
        rm -rf "$domain"
    fi
    
    log_info "Cloning repository..."
    git clone "$repo_url" "$domain" || {
        log_error "Failed to clone repository"
        exit 1
    }
    
    log_success "Repository cloned to $domain/"
    
    # Ask if user wants to add to .env
    read -p "Add domain to .env configuration? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        add_domain_to_env "$domain"
    fi
}

# Pull updates for a specific domain
pull_domain() {
    local domain="$1"
    
    if [ -z "$domain" ]; then
        log_error "Usage: ./manage-repos.sh pull <domain_name>"
        exit 1
    fi
    
    if [ ! -d "$domain" ]; then
        log_error "Directory '$domain' not found"
        exit 1
    fi
    
    log_info "Updating $domain..."
    cd "$domain"
    git pull || {
        log_error "Failed to pull updates"
        cd ..
        exit 1
    }
    cd ..
    
    log_success "$domain updated"
}

# Pull all domains
pull_all() {
    local domains_str=$(grep "^DOMAINS=" .env | cut -d'=' -f2 | tr -d '"')
    
    if [ -z "$domains_str" ]; then
        log_warning "No domains configured in .env"
        return
    fi
    
    IFS=',' read -ra domain_array <<< "$domains_str"
    for domain in "${domain_array[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -d "$domain" ] && [ -d "$domain/.git" ]; then
            log_info "Updating $domain..."
            (cd "$domain" && git pull) && log_success "$domain updated" || log_error "Failed to update $domain"
        fi
    done
}

# Add domain to .env file
add_domain_to_env() {
    local domain="$1"
    
    # Read current DOMAINS
    local current_domains=$(grep "^DOMAINS=" .env | cut -d'=' -f2 | tr -d '"')
    
    # Add new domain (avoid duplicates)
    if echo "$current_domains" | grep -q "$domain"; then
        log_warning "Domain $domain already in .env"
        return
    fi
    
    # Append with comma separator and space
    local new_domains="$current_domains, $domain"
    
    # Update .env file
    sed -i "s|^DOMAINS=.*|DOMAINS=\"$new_domains\"|" .env
    
    log_success "Domain $domain added to .env"
    log_info "Updated DOMAINS: $new_domains"
}

# List all configured domains
list_domains() {
    log_info "Configured domains in .env:"
    echo ""
    
    local domains_str=$(grep "^DOMAINS=" .env | cut -d'=' -f2 | tr -d '"')
    
    if [ -z "$domains_str" ]; then
        log_warning "No domains configured"
        return
    fi
    
    local i=1
    IFS=',' read -ra domain_array <<< "$domains_str"
    for domain in "${domain_array[@]}"; do
        domain=$(echo "$domain" | xargs)
        printf "  %d. %-30s → /var/www/%s\n" "$i" "$domain" "$domain"
        i=$((i+1))
    done
    echo ""
}

# Show status of all websites
show_status() {
    log_info "Website Repository Status:"
    echo ""
    
    local domains_str=$(grep "^DOMAINS=" .env | cut -d'=' -f2 | tr -d '"')
    
    IFS=',' read -ra domain_array <<< "$domains_str"
    for domain in "${domain_array[@]}"; do
        domain=$(echo "$domain" | xargs)
        if [ -d "$domain" ]; then
            if [ -d "$domain/.git" ]; then
                printf "  %-30s " "$domain"
                (cd "$domain" && git status --short | wc -l | xargs -I {} [ {} -eq 0 ] && echo "✓ clean" || echo "⚠ has changes")
            else
                log_warning "  $domain - Not a git repository"
            fi
        else
            log_warning "  $domain - Directory not found"
        fi
    done
    echo ""
}

# Main script logic
main() {
    cd "$SCRIPT_DIR"
    
    if [ ! -f ".env" ]; then
        log_error ".env file not found"
        exit 1
    fi
    
    case "${1:-help}" in
        clone)
            clone_repo "$2" "$3"
            ;;
        pull)
            if [ -z "$2" ]; then
                log_error "Usage: ./manage-repos.sh pull <domain_name>"
                exit 1
            fi
            pull_domain "$2"
            ;;
        pull-all)
            pull_all
            ;;
        add-domain)
            add_domain_to_env "$2"
            ;;
        list)
            list_domains
            ;;
        status)
            show_status
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "Unknown command: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
