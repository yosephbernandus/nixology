# Nixology
This is my personal configuration using nix flakes [https://nixos.wiki/wiki/Flakes](https://nixos.wiki/wiki/Flakes).

## Nix
Nix is a powerful package manager and build system that allows you to define environments for your projects in a way that avoids dependency conflicts. Unlike traditional package managers (like apt or brew), Nix installs software in isolated environments, making sure every project has the exact tools it needs without affecting your system setup [https://nixos.org/](https://nixos.org/)

## Why Use Nix:
I use Nix because it saves me from dealing with headaches, especially when working on Linux. For example, when installing Rust on an older Ubuntu version, I ran into issues where the system's default libraries (like libc) weren’t compatible with Rust’s requirements. Normally, I’d have to manually compile and tweak things to make it work.

With Nix, I don't have to worry about that. I can easily create an environment that has everything I need, without having to mess with the system configuration or compile things manually. It’s fast, consistent, and portable.

A Nix flake that provides isolated development services (Redis, RabbitMQ, PostgreSQL) with flexible configuration options.

## Prerequisites

- Install Nix with flakes enabled
To install you can go to this page https://nixos.org/download/ 
Or can installing use this
````bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
````
If your not familiar can start from this https://zero-to-nix.com/start/install/

## Service
- Redis
- Rabbit MQ
- Postgress

## Directory Structure

```plaintext
.
├── flake.nix               # Main flake configuration
├── flake.lock              # Lock file for dependencies
└── shells/                 # Development shells directory
    └── dev/               # Development environment
        ├── default.nix     # Main shell configuration
        └── services/       # Service configurations
            ├── postgresql.nix  # PostgreSQL service
            ├── rabbitmq.nix    # RabbitMQ service
            └── redis.nix       # Redis service
```

## Usage
There is to way for use first you can clone this repo or direct to this github url

### Clone this repo

```bash
# Run with environment variable
ENABLED_SERVICES="postgres redis" nix develop

# Run all services
nix develop .#dev

# Or just
nix develop

# Run specific service
nix develop .#postgres
nix develop .#redis
nix develop .#rabbitmq

# Run combination
nix develop .#database

```

### Direct Github URL
```bash
# Run all services
nix develop github:yosephbernandus/nix

# Run specific service
nix develop github:yosephbernandus/nix#postgres
nix develop github:yosephbernandus/nix#redis
nix develop github:yosephbernandus/nix#rabbitmq

# Run combined services
nix develop github:yosephbernandus/nix#database

# Or use environment variables
ENABLED_SERVICES="postgres redis" nix develop github:yosephbernandus/nix
```
### Cleanup
Services are automatically cleaned up when you exit the shell. Data is stored in **.services/** directory.

### Development
To modify service configurations, edit the respective files in **shells/dev/services/.**

