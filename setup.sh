#!/bin/bash

set -e
set -u
set -o pipefail

LOG_FILE="/var/log/install_script.log"
ROLLBACK_FILE="/var/log/install_script_rollback.log"

log() {
  printf "%s - %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1" | tee -a "$LOG_FILE"
}

rollback_log() {
  printf "%s\n" "$1" | tee -a "$ROLLBACK_FILE"
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

package_installed() {
  dpkg -l | grep -q "$1"
}

commands=("ftp" "pftp" "sh" "apache2" "telnetd" "nginx" "mysql" "sshd" "postgresql" "redis-server" "docker")

pre_flight_checks() {
  if ! command_exists "sudo"; then
    log "Error: This script requires 'sudo' to run. Please install 'sudo' and try again." >&2
    exit 1
  fi
}

detect_os() {
  if [[ -f /etc/debian_version ]]; then
    if grep -q "Ubuntu" /etc/os-release; then
      printf "ubuntu\n"
    else
      printf "debian\n"
    fi
  elif [[ -f /etc/redhat-release ]]; then
    if grep -q "CentOS" /etc/redhat-release; then
      printf "centos\n"
    elif grep -q "Fedora" /etc/redhat-release; then
      printf "fedora\n"
    else
      printf "redhat\n"
    fi
  elif [[ -f /etc/arch-release ]]; then
    printf "arch\n"
  elif [[ -f /etc/SuSE-release ]]; then
    printf "suse\n"
  elif [[ -f /etc/freebsd-update.conf ]]; then
    printf "freebsd\n"
  elif [[ "$(uname)" == "Darwin" ]]; then
    printf "darwin\n"
  else
    printf "unsupported\n"
  fi
}

prompt_user() {
  read -p "$1 (y/n): " -n 1 -r
  printf "\n"
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log "Operation aborted by user." >&2
    exit 1
  fi
}

install_packages() {
  local os="$1"
  case "$os" in
    debian | ubuntu)
      sudo apt-get update
      for cmd in "${missing[@]}"; do
        if ! package_installed "$cmd"; then
          if sudo apt-get install -y "$cmd"; then
            rollback_log "sudo apt-get remove -y $cmd"
          else
            log "Error: Failed to install $cmd." >&2
            exit 1
          fi
        fi
      done
      ;;
    redhat | centos)
      for cmd in "${missing[@]}"; do
        if sudo yum install -y "$cmd"; then
          rollback_log "sudo yum remove -y $cmd"
        else
          log "Error: Failed to install $cmd." >&2
          exit 1
        fi
      done
      ;;
    fedora)
      for cmd in "${missing[@]}"; do
        if sudo dnf install -y "$cmd"; then
          rollback_log "sudo dnf remove -y $cmd"
        else
          log "Error: Failed to install $cmd." >&2
          exit 1
        fi
      done
      ;;
    arch)
      for cmd in "${missing[@]}"; do
        if sudo pacman -S --noconfirm "$cmd"; then
          rollback_log "sudo pacman -R --noconfirm $cmd"
        else
          log "Error: Failed to install $cmd." >&2
          exit 1
        fi
      done
      ;;
    suse)
      for cmd in "${missing[@]}"; do
        if sudo zypper install -y "$cmd"; then
          rollback_log "sudo zypper remove -y $cmd"
        else
          log "Error: Failed to install $cmd." >&2
          exit 1
        fi
      done
      ;;
    freebsd)
      for cmd in "${missing[@]}"; do
        if sudo pkg install -y "$cmd"; then
          rollback_log "sudo pkg delete -y $cmd"
        else
          log "Error: Failed to install $cmd." >&2
          exit 1
        fi
      done
      ;;
    darwin)
      for cmd in "${missing[@]}"]; do
        if brew install "$cmd"; then
          rollback_log "brew uninstall $cmd"
        else
          log "Error: Failed to install $cmd." >&2
          exit 1
        fi
      done
      ;;
    *)
      log "Error: Unsupported OS. Please install the missing packages manually." >&2
      exit 1
      ;;
  esac
  wait
}

set_permissions() {
  for cmd in "${commands[@]}"; do
    local path; path=$(command -v "$cmd")
    if [[ -n "$path" ]]; then
      log "Setting correct permissions for $path"
      if ! sudo chmod u+rwx "$path"; then
        log "Error: Failed to set permissions for $path." >&2
        exit 1
      fi
    fi
  done
}

configure_services() {
  local os="$1"
  case "$os" in
    debian | ubuntu)
      command_exists "apache2" && sudo systemctl enable apache2 && sudo systemctl start apache2 && rollback_log "sudo systemctl disable apache2 && sudo systemctl stop apache2"
      command_exists "telnetd" && sudo systemctl enable inetd && sudo systemctl start inetd && rollback_log "sudo systemctl disable inetd && sudo systemctl stop inetd"
      command_exists "nginx" && sudo systemctl enable nginx && sudo systemctl start nginx && rollback_log "sudo systemctl disable nginx && sudo systemctl stop nginx"
      command_exists "mysql" && sudo systemctl enable mysql && sudo systemctl start mysql && rollback_log "sudo systemctl disable mysql && sudo systemctl stop mysql"
      command_exists "sshd" && sudo systemctl enable ssh && sudo systemctl start ssh && rollback_log "sudo systemctl disable ssh && sudo systemctl stop ssh"
      command_exists "postgresql" && sudo systemctl enable postgresql && sudo systemctl start postgresql && rollback_log "sudo systemctl disable postgresql && sudo systemctl stop postgresql"
      command_exists "redis-server" && sudo systemctl enable redis-server && sudo systemctl start redis-server && rollback_log "sudo systemctl disable redis-server && sudo systemctl stop redis-server"
      command_exists "docker" && sudo systemctl enable docker && sudo systemctl start docker && rollback_log "sudo systemctl disable docker && sudo systemctl stop docker"
      ;;
    redhat | centos | fedora)
      command_exists "httpd" && sudo systemctl enable httpd && sudo systemctl start httpd && rollback_log "sudo systemctl disable httpd && sudo systemctl stop httpd"
      command_exists "telnetd" && sudo systemctl enable telnet.socket && sudo systemctl start telnet.socket && rollback_log "sudo systemctl disable telnet.socket && sudo systemctl stop telnet.socket"
      command_exists "nginx" && sudo systemctl enable nginx && sudo systemctl start nginx && rollback_log "sudo systemctl disable nginx && sudo systemctl stop nginx"
      command_exists "mysqld" && sudo systemctl enable mysqld && sudo systemctl start mysqld && rollback_log "sudo systemctl disable mysqld && sudo systemctl stop mysqld"
      command_exists "sshd" && sudo systemctl enable sshd && sudo systemctl start sshd && rollback_log "sudo systemctl disable sshd && sudo systemctl stop sshd"
      command_exists "postgresql" && sudo systemctl enable postgresql && sudo systemctl start postgresql && rollback_log "sudo systemctl disable postgresql && sudo systemctl stop postgresql"
      command_exists "redis" && sudo systemctl enable redis && sudo systemctl start redis && rollback_log "sudo systemctl disable redis && sudo systemctl stop redis"
      command_exists "docker" && sudo systemctl enable docker && sudo systemctl start docker && rollback_log "sudo systemctl disable docker && sudo systemctl stop docker"
      ;;
    arch | suse)
      command_exists "httpd" && sudo systemctl enable httpd && sudo systemctl start httpd && rollback_log "sudo systemctl disable httpd && sudo systemctl stop httpd"
      command_exists "telnetd" && sudo systemctl enable telnetd && sudo systemctl start telnetd && rollback_log "sudo systemctl disable telnetd && sudo systemctl stop telnetd"
      command_exists "nginx" && sudo systemctl enable nginx && sudo systemctl start nginx && rollback_log "sudo systemctl disable nginx && sudo systemctl stop nginx"
      command_exists "mysqld" && sudo systemctl enable mysqld && sudo systemctl start mysqld && rollback_log "sudo systemctl disable mysqld && sudo systemctl stop mysqld"
      command_exists "sshd" && sudo systemctl enable sshd && sudo systemctl start sshd && rollback_log "sudo systemctl disable sshd && sudo systemctl stop sshd"
      command_exists "postgresql" && sudo systemctl enable postgresql && sudo systemctl start postgresql && rollback_log "sudo systemctl disable postgresql && sudo systemctl stop postgresql"
      command_exists "redis" && sudo systemctl enable redis && sudo systemctl start redis && rollback_log "sudo systemctl disable redis && sudo systemctl stop redis"
      command_exists "docker" && sudo systemctl enable docker && sudo systemctl start docker && rollback_log "sudo systemctl disable docker && sudo systemctl stop docker"
      ;;
    freebsd)
      command_exists "apache24" && sudo sysrc apache24_enable="YES" && sudo service apache24 start && rollback_log "sudo sysrc apache24_enable=\"NO\" && sudo service apache24 stop"
      command_exists "nginx" && sudo sysrc nginx_enable="YES" && sudo service nginx start && rollback_log "sudo sysrc nginx_enable=\"NO\" && sudo service nginx stop"
      command_exists "mysql-server" && sudo sysrc mysql_enable="YES" && sudo service mysql-server start && rollback_log "sudo sysrc mysql_enable=\"NO\" && sudo service mysql-server stop"
      command_exists "openssh" && sudo sysrc sshd_enable="YES" && sudo service sshd start && rollback_log "sudo sysrc sshd_enable=\"NO\" && sudo service sshd stop"
      command_exists "postgresql" && sudo sysrc postgresql_enable="YES" && sudo service postgresql start && rollback_log "sudo sysrc postgresql_enable=\"NO\" && sudo service postgresql stop"
      command_exists "redis" && sudo sysrc redis_enable="YES" && sudo service redis start && rollback_log "sudo sysrc redis_enable=\"NO\" && sudo service redis stop"
      command_exists "docker" && sudo sysrc docker_enable="YES" && sudo service docker start && rollback_log "sudo sysrc docker_enable=\"NO\" && sudo service docker stop"
      ;;
  esac
}

handle_edge_cases() {
  local disk_usage; disk_usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')
  if [[ -n "$disk_usage" && "$disk_usage" -gt 90 ]]; then
    log "Error: Insufficient disk space. Please free up some space and try again." >&2
    exit 1
  fi
  if ! ping -c 1 google.com >/dev/null 2>&1; then
    log "Error: Network is unreachable. Please check your internet connection and try again." >&2
    exit 1
  fi
}

rollback() {
  log "Rolling back changes..."
  tac "$ROLLBACK_FILE" | while read -r line; do
    eval "$line"
  done
  log "Rollback completed."
}

trap rollback ERR

main() {
  log "Starting script execution"

  pre_flight_checks
  handle_edge_cases

  local os; os=$(detect_os)
  if [[ "$os" == "unsupported" ]]; then
    log "Error: Unsupported OS. Exiting." >&2
    exit 1
  fi

  log "Detected OS: $os"

  missing=()
  for cmd in "${commands[@]}"; do
    if ! command_exists "$cmd"; then
      missing+=("$cmd")
    fi
  done

  if [[ ${#missing[@]} -ne 0 ]]; then
    log "Missing commands: ${missing[*]}"
    prompt_user "Do you want to attempt to install the missing packages?"
    install_packages "$os"
  else
    log "All required commands are installed."
  fi

  set_permissions

  prompt_user "Do you want to configure specific services?"
  configure_services "$os"

  log "Script execution completed successfully."
}

main "$@"