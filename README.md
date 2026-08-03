# Linux System Audit Script

A small but practical Bash-based tool for auditing basic Linux system state.
Built as a learning project with a focus on **shell scripting, system inspection, and DevOps-style thinking**.

Tested on **Ubuntu 20.04**.

---

## What this project does

The script performs a lightweight system audit and outputs structured information about:

* Disk usage
* Memory usage
* CPU loads
* network (ping 8.8.8.8)
* Active users

This is **not a monitoring system**.
It is a controlled audit script designed to be:

* predictable
* readable
* safe to run
* easy to understand and extend

---

## Features

* Command-line arguments (`--disk`, `--memory`, `--cpu`, `--network`, `--users`, `--all`)
* Modular Bash functions
* Argument validation
* Conditional execution of checks
* Structured logging to a file
* Signal handling using `trap`
* Output redirection support (`stdout`, `stderr`)
* Data parsing with `awk`

---

## Project structure

```
linux-system-audit/
├── sys_audit.sh
├── README.md
├── .env.example
└── logs/
```

---

## Usage

Make the script executable:

```bash
chmod +x sys_audit.sh
```

Run specific checks:

```bash
./sys_audit.sh --disk
./sys_audit.sh --memory
./sys_audit.sh --users
./sys_audit.sh --cpu
./sys_audit.sh --network
```

Run all checks:

```bash
./sys_audit.sh --all
```

Show help:

```bash
./sys_audit.sh --help
```

---

## Logging

The script writes logs to a file inside the `logs/` directory.

Example:

```bash
./sys_audit.sh --all
```

Log file example content:

```
[2025-.. ..:..:..] [INFO] Disk usage is OK: 58%
[2025-.. ..:..:..] [INFO] Memory usage is OK: 8%
[2025-.. ..:..:..] [INFO] Active user: pchelbisson
```

---

## Why this project

This project was built to practice:

* Writing maintainable Bash scripts
* Using functions, conditions, and loops in real tasks
* Thinking in terms of **inputs → processing → output**
* Handling script termination gracefully
* Understanding how simple system audit tools are structured

---

## Notes

* Designed for Linux systems
* Not intended for production monitoring
* Focused on learning and clarity rather than feature completeness

---

## Design Decisions

### Why specifically `/proc`, and not `uptime` in CPU check?
* Speed ​​and Performance (No Fork Processes)
* Parsing simplicity (Reliability)

### Why 8.8.8.8 instead of a domain name?
* Isolating the problem (Testing the "bare" network)
* Extreme availability (Anycast)

---

## Author

Built as a personal DevOps learning project.
