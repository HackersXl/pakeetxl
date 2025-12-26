#!/bin/bash

# setup.sh - Universal Setup Script for MYnyak Engsel
# Supports: Debian/Ubuntu, CentOS/RHEL, Fedora, Arch Linux, Termux

set -e

# Detect OS and Package Manager
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    elif [ -f /data/data/com.termux/files/usr/bin/pkg ]; then
        OS="termux"
    else
        OS="unknown"
    fi
}

install_packages() {
    echo "Detected OS: $OS"

    if [ "$OS" == "ubuntu" ] || [ "$OS" == "debian" ] || [ "$OS" == "kali" ] || [ "$OS" == "linuxmint" ] || [[ "$ID_LIKE" == *"debian"* ]]; then
        CMD="apt-get"
        echo "Updating package list..."
        if [ "$EUID" -ne 0 ]; then
            sudo apt-get update -y
            echo "Installing system dependencies..."
            sudo apt-get install -y python3 python3-pip python3-venv build-essential python3-dev libjpeg-dev zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev git
        else
            apt-get update -y
            echo "Installing system dependencies..."
            apt-get install -y python3 python3-pip python3-venv build-essential python3-dev libjpeg-dev zlib1g-dev libncurses5-dev libgdbm-dev libnss3-dev libssl-dev libreadline-dev libffi-dev libsqlite3-dev libbz2-dev git
        fi

    elif [ "$OS" == "centos" ] || [ "$OS" == "rhel" ] || [ "$OS" == "almalinux" ] || [ "$OS" == "rocky" ]; then
        CMD="yum"
        echo "Installing system dependencies..."
        if [ "$EUID" -ne 0 ]; then
            sudo yum install -y epel-release
            sudo yum install -y python3 python3-pip python3-devel gcc git zlib-devel libjpeg-devel openssl-devel
        else
            yum install -y epel-release
            yum install -y python3 python3-pip python3-devel gcc git zlib-devel libjpeg-devel openssl-devel
        fi

    elif [ "$OS" == "fedora" ]; then
        CMD="dnf"
        echo "Installing system dependencies..."
        if [ "$EUID" -ne 0 ]; then
            sudo dnf install -y python3 python3-pip python3-devel gcc git zlib-devel libjpeg-devel openssl-devel
        else
            dnf install -y python3 python3-pip python3-devel gcc git zlib-devel libjpeg-devel openssl-devel
        fi

    elif [ "$OS" == "arch" ] || [ "$OS" == "manjaro" ]; then
        CMD="pacman"
        echo "Installing system dependencies..."
        if [ "$EUID" -ne 0 ]; then
            sudo pacman -Sy --noconfirm python python-pip base-devel git
        else
            pacman -Sy --noconfirm python python-pip base-devel git
        fi

    elif [ "$OS" == "termux" ]; then
        CMD="pkg"
        echo "Installing system dependencies..."
        pkg update -y
        pkg install -y python build-essential git binutils
        # Termux specific dependencies for Pillow/etc
        pkg install -y libjpeg-turbo zlib

    else
        echo "Unsupported or unknown OS: $OS"
        echo "Attempting to continue with pip install..."
    fi
}

install_python_deps() {
    echo "Installing Python dependencies..."

    # Check if pip is available
    if ! command -v pip3 &> /dev/null; then
        if ! command -v pip &> /dev/null; then
             echo "Error: pip is not installed. Please install pip manually."
             exit 1
        else
             PIP_CMD="pip"
        fi
    else
        PIP_CMD="pip3"
    fi

    # Install requirements
    # Use --break-system-packages if on newer pip/python versions that require it (PEP 668),
    # but be careful. Or just use it if error occurs?
    # Safest is just running pip. If it fails due to externallly managed env, user might need venv.
    # We will try to install.

    $PIP_CMD install -r requirements.txt || {
        echo "Pip install failed. Retrying with --break-system-packages (if applicable)..."
        $PIP_CMD install -r requirements.txt --break-system-packages || {
             echo "Failed to install dependencies. You might need to use a virtual environment."
             echo "Trying to create a virtual environment..."
             python3 -m venv venv
             source venv/bin/activate
             pip install -r requirements.txt
        }
    }
}

main() {
    detect_os
    install_packages
    install_python_deps

    echo "Setup completed successfully!"
    echo "You can now run the application with: python3 main.py"
    echo "Or if a venv was created: source venv/bin/activate && python3 main.py"
}

main
