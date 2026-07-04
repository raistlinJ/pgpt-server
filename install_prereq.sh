#!/usr/bin/env bash
# Install Linux prerequisites for the PentestGPT Docker workflow.

set -euo pipefail

DRY_RUN="${PGPT_DRY_RUN:-false}"
DOCKER_GROUP_CHOICE="${PGPT_DOCKER_GROUP:-}"
DOCKER_GROUP_USER_CHOICE="${PGPT_DOCKER_GROUP_USER:-}"
TARGET_USER="${SUDO_USER:-${USER:-}}"

if [ -z "$TARGET_USER" ]; then
    echo "Could not determine the target user for docker group membership." >&2
    exit 1
fi

if [ "$(uname -s)" != "Linux" ]; then
    echo "This installer is for Linux. Install Docker Desktop or Docker Engine manually on this OS." >&2
    exit 1
fi

log() {
    printf '\n==> %s\n' "$*"
}

warn() {
    printf 'WARN: %s\n' "$*" >&2
}

have() {
    command -v "$1" >/dev/null 2>&1
}

is_yes() {
    case "${1,,}" in
        y | yes | true | 1) return 0 ;;
        *) return 1 ;;
    esac
}

is_no() {
    case "${1,,}" in
        n | no | false | 0) return 0 ;;
        *) return 1 ;;
    esac
}

ask_yes_no() {
    local prompt="$1"
    local default_answer="$2"
    local env_answer="${3:-}"
    local answer=""

    if [ -n "$env_answer" ]; then
        if is_yes "$env_answer"; then
            return 0
        fi
        if is_no "$env_answer"; then
            return 1
        fi
        warn "Ignoring invalid yes/no value '${env_answer}'."
    fi

    if [ ! -t 0 ]; then
        if is_yes "$default_answer"; then
            warn "No interactive input available; defaulting to yes for: ${prompt}"
            return 0
        fi
        warn "No interactive input available; defaulting to no for: ${prompt}"
        return 1
    fi

    while true; do
        if is_yes "$default_answer"; then
            read -r -p "${prompt} [Y/n] " answer
            answer="${answer:-yes}"
        else
            read -r -p "${prompt} [y/N] " answer
            answer="${answer:-no}"
        fi

        if is_yes "$answer"; then
            return 0
        fi
        if is_no "$answer"; then
            return 1
        fi
        echo "Please answer yes or no."
    done
}

run() {
    if [ "$DRY_RUN" = "true" ]; then
        printf '+'
        printf ' %q' "$@"
        printf '\n'
        return 0
    fi
    "$@"
}

sudo_run() {
    if [ "$(id -u)" -eq 0 ]; then
        run "$@"
    else
        if ! have sudo; then
            echo "sudo is required. Re-run as root or install sudo first." >&2
            exit 1
        fi
        run sudo "$@"
    fi
}

source_os_release() {
    if [ -r /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
    else
        echo "/etc/os-release not found; cannot detect Linux distribution." >&2
        exit 1
    fi
}

install_common_packages() {
    source_os_release
    case "${ID:-}" in
        ubuntu | debian | pop | linuxmint | kali)
            sudo_run apt-get update
            sudo_run apt-get install -y ca-certificates curl gnupg git make
            ;;
        fedora | rhel | centos | rocky | almalinux)
            if have dnf; then
                sudo_run dnf install -y ca-certificates curl git make
            else
                sudo_run yum install -y ca-certificates curl git make
            fi
            ;;
        arch | manjaro)
            sudo_run pacman -Sy --needed --noconfirm ca-certificates curl git make
            ;;
        opensuse* | sles)
            sudo_run zypper --non-interactive install ca-certificates curl git make
            ;;
        *)
            if [[ "${ID_LIKE:-}" == *debian* ]]; then
                sudo_run apt-get update
                sudo_run apt-get install -y ca-certificates curl gnupg git make
            else
                warn "Unsupported distro '${ID:-unknown}'. Install curl, git, make, Docker Engine, and Docker Compose plugin manually."
            fi
            ;;
    esac
}

docker_apt_repo_family() {
    source_os_release

    local repo_id=""
    local codename="${VERSION_CODENAME:-}"

    case "${ID:-}" in
        ubuntu)
            repo_id="ubuntu"
            ;;
        debian)
            repo_id="debian"
            ;;
        pop | linuxmint)
            repo_id="ubuntu"
            codename="${UBUNTU_CODENAME:-$codename}"
            ;;
        *)
            if [[ "${ID_LIKE:-}" == *ubuntu* ]]; then
                repo_id="ubuntu"
                codename="${UBUNTU_CODENAME:-$codename}"
            elif [[ "${ID_LIKE:-}" == *debian* ]]; then
                repo_id="debian"
            fi
            ;;
    esac

    if [ -z "$repo_id" ] || [ -z "$codename" ]; then
        return 1
    fi

    sudo_run install -m 0755 -d /etc/apt/keyrings
    if [ ! -f "/etc/apt/keyrings/docker-${repo_id}.gpg" ]; then
        run curl -fsSL "https://download.docker.com/linux/${repo_id}/gpg" -o /tmp/docker.gpg
        sudo_run gpg --dearmor -o "/etc/apt/keyrings/docker-${repo_id}.gpg" /tmp/docker.gpg
        sudo_run chmod a+r "/etc/apt/keyrings/docker-${repo_id}.gpg"
        run rm -f /tmp/docker.gpg
    fi

    local arch
    arch="$(dpkg --print-architecture)"
    local repo_line
    repo_line="deb [arch=${arch} signed-by=/etc/apt/keyrings/docker-${repo_id}.gpg] https://download.docker.com/linux/${repo_id} ${codename} stable"
    printf '%s\n' "$repo_line" | sudo_run tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo_run apt-get update
    sudo_run apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
}

install_docker_with_native_packages() {
    source_os_release
    case "${ID:-}" in
        ubuntu | debian | pop | linuxmint | kali)
            sudo_run apt-get update
            sudo_run apt-get install -y docker.io docker-compose-plugin || sudo_run apt-get install -y docker.io docker-compose
            ;;
        fedora)
            sudo_run dnf install -y moby-engine docker-compose-plugin
            ;;
        rhel | centos | rocky | almalinux)
            if have dnf; then
                sudo_run dnf install -y docker docker-compose-plugin || sudo_run dnf install -y docker
            else
                sudo_run yum install -y docker
            fi
            ;;
        arch | manjaro)
            sudo_run pacman -Sy --needed --noconfirm docker docker-compose
            ;;
        opensuse* | sles)
            sudo_run zypper --non-interactive install docker docker-compose
            ;;
        *)
            return 1
            ;;
    esac
}

install_docker() {
    if have docker && docker compose version >/dev/null 2>&1; then
        log "Docker and Docker Compose plugin are already installed"
        return
    fi

    log "Installing Docker Engine and Docker Compose plugin"
    source_os_release
    if [[ "${ID:-}" =~ ^(ubuntu|debian|pop|linuxmint)$ ]] || [[ "${ID_LIKE:-}" == *ubuntu* ]] || [[ "${ID_LIKE:-}" == *debian* ]]; then
        if docker_apt_repo_family; then
            return
        fi
        warn "Could not configure Docker's apt repository; falling back to native packages."
    fi

    if ! install_docker_with_native_packages; then
        echo "Could not install Docker automatically for '${ID:-unknown}'." >&2
        echo "Install Docker Engine and the Docker Compose plugin, then re-run this script." >&2
        exit 1
    fi
}

ensure_docker_group() {
    log "Docker group setup"
    if ! getent group docker >/dev/null 2>&1; then
        if ask_yes_no "Create the docker group?" "yes" "$DOCKER_GROUP_CHOICE"; then
            sudo_run groupadd docker
        else
            warn "Skipped docker group creation. You may need sudo for Docker commands."
            return
        fi
    fi

    if id -nG "$TARGET_USER" | tr ' ' '\n' | grep -qx docker; then
        log "${TARGET_USER} is already in the docker group"
    else
        if ask_yes_no "Add ${TARGET_USER} to the docker group?" "yes" "$DOCKER_GROUP_USER_CHOICE"; then
            sudo_run usermod -aG docker "$TARGET_USER"
            warn "Added ${TARGET_USER} to docker group. Log out/in, run 'newgrp docker', or reconnect SSH before running Docker without sudo."
        else
            warn "Skipped adding ${TARGET_USER} to docker group. You may need sudo for Docker commands."
        fi
    fi
}

start_docker_service() {
    log "Starting Docker service"
    if have systemctl && [ -d /run/systemd/system ]; then
        sudo_run systemctl enable --now docker
    elif have service; then
        sudo_run service docker start || warn "Could not start Docker with service command."
    else
        warn "No system service manager detected. Start Docker manually if it is not running."
    fi
}

verify_install() {
    log "Verifying Docker install"
    if docker info >/dev/null 2>&1; then
        docker --version
        if ! docker compose version; then
            echo "Docker is running, but 'docker compose' is not available." >&2
            echo "Install the Docker Compose plugin, then re-run this script." >&2
            exit 1
        fi
        return
    fi

    if [ "$(id -u)" -ne 0 ] && have sudo && sudo docker info >/dev/null 2>&1; then
        sudo docker --version
        if ! sudo docker compose version; then
            echo "Docker is running with sudo, but 'docker compose' is not available." >&2
            echo "Install the Docker Compose plugin, then re-run this script." >&2
            exit 1
        fi
        warn "Docker works with sudo, but your current shell does not have docker group access yet."
        warn "Run 'newgrp docker' or log out/in, then try: docker compose version"
        return
    fi

    echo "Docker was installed, but the daemon is not reachable yet." >&2
    echo "Check service status with: sudo systemctl status docker" >&2
    exit 1
}

main() {
    log "Installing PentestGPT host prerequisites"
    install_common_packages
    install_docker
    ensure_docker_group
    start_docker_service
    verify_install

    log "Done"
    echo "Next steps:"
    echo "  newgrp docker    # if this shell still cannot run docker without sudo"
    echo "  docker compose build"
    echo "  docker compose up -d"
}

main "$@"
