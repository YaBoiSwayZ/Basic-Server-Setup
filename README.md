# Basic Server Setup Script

## Overview

This Bash script is designed to automate the setup and configuration of basic server components across various Linux and Unix-like operating systems. The script performs the following key functions:

1. Pre-flight checks to ensure the script runs with the necessary permissions.
2. Detects the operating system and installs any missing essential packages.
3. Configures permissions for installed commands and services.
4. Enables and starts various services such as `apache2`, `nginx`, `mysql`, `sshd`, and others based on the operating system.
5. Provides rollback functionality to undo any changes made if the script encounters an error.
6. Handles common edge cases, such as low disk space or network connectivity issues.

## Features

- **Cross-platform support**: Detects and works on Debian, Ubuntu, Red Hat, CentOS, Fedora, Arch, SUSE, FreeBSD, and macOS.
- **Package installation**: Automatically installs missing packages based on the detected operating system.
- **Service management**: Enables and starts critical services for web hosting, databases, and networking.
- **Rollback mechanism**: In case of an error, the script rolls back any installed packages and reverts system changes.
- **Logging**: Detailed logging of script execution and rollback steps.
- **User prompts**: Asks for user confirmation before performing critical tasks, ensuring that no unintentional changes are made.

## Prerequisites

Before running the script, ensure the following prerequisites are met:

- The script must be run with **sudo** or root privileges.
- Ensure that the system has a stable internet connection for installing packages and performing OS detection.
- Disk space must be sufficient for installing required packages (90% or less disk usage recommended).

## Supported Operating Systems

The script automatically detects and supports the following operating systems:

- **Debian** (and Ubuntu)
- **Red Hat**, **CentOS**, **Fedora**
- **Arch Linux**
- **SUSE Linux**
- **FreeBSD**
- **macOS (Darwin)**

If the OS is unsupported, the script will terminate.

## Script Breakdown

### Pre-flight Checks

The script checks if **sudo** is installed and verifies essential conditions like disk space and network connectivity:

```bash
pre_flight_checks
handle_edge_cases
```

### OS Detection

The script uses `/etc/*-release` files to detect the OS and its flavor (e.g., Ubuntu, CentOS):

```bash
detect_os
```

### Package Installation

If any of the following essential commands are missing, the script will attempt to install them:

- `ftp`, `pftp`, `sh`, `apache2`, `telnetd`, `nginx`, `mysql`, `sshd`, `postgresql`, `redis-server`, `docker`

The list of missing commands is printed, and the user is prompted to install them.

### Permissions and Service Configuration

Permissions are set for the installed commands, and services such as `apache2`, `nginx`, `mysql`, `sshd`, and others are enabled and started:

```bash
set_permissions
configure_services
```

### Rollback

In the event of an error during installation or service configuration, the rollback function will uninstall the packages and revert any changes made:

```bash
rollback
```

## Usage

### Running the Script

1. Download the script and ensure it's executable:
   ```bash
   chmod +x basic_server_setup.sh
   ```

2. Run the script with `sudo`:
   ```bash
   sudo ./setup.sh
   ```

3. Follow the prompts for confirming the installation of missing packages and configuring services.

### Rollback Process

If any error occurs during the script execution, it automatically triggers the rollback process. The rollback logs are saved to `/var/log/install_script_rollback.log`.

## Logs

- The script logs all its operations in `/var/log/install_script.log`.
- Rollback logs are stored in `/var/log/install_script_rollback.log`.

To view logs:
```bash
cat /var/log/install_script.log
cat /var/log/install_script_rollback.log
```

## Edge Case Handling

The script handles these common edge cases:
- **Disk space**: The script checks if the root filesystem has more than 90% usage before proceeding.
- **Network connectivity**: The script verifies internet connectivity by pinging `google.com`.

If any of these checks fail, the script will log the error and terminate.

## Customization

You can modify the list of commands or services to install by updating the following arrays:

```bash
commands=("ftp" "pftp" "sh" "apache2" "telnetd" "nginx" "mysql" "sshd" "postgresql" "redis-server" "docker")
```

You can also add or remove services from the `configure_services` function depending on your specific setup needs.

## Error Handling

The script is designed with robust error handling:
- Any error encountered will trigger an immediate rollback of changes.
- Errors are logged to `/var/log/install_script.log` for later review.

## Contributions

If you wish to contribute or report issues, feel free to submit a pull request or issue on GitHub.

---

Enjoy automating your server setup!
```
