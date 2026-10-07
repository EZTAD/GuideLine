# Feature Description: Local Process Validation System (LPVS)

| Attribute | Value |
| :--- | :--- |
| **Feature Name** | Local Process Validation System |
| **Acronym** | `LPVS` |
| **Category** | Security & System Enforcement |
| **Status** | Draft / In Review |
| **Relevant Modules** | PAM, Auditd / eBPF, Systemd, Cgroup v2, DAC/File Permissions |

---

## 1. Overview

The **Local Process Validation System (LPVS)** is a Linux-based security control mechanism designed to validate process execution. It enforces security policies based on **argument allowlisting**, **call hierarchy validation**, and **Cgroup control rules**. 

LPVS acts as a gatekeeper that ensures binaries (specifically system utilities) are executed only with predefined, safe parameters. Upon detecting a policy violation—such as execution with unauthorized arguments—the system triggers automated active remediation, such as session termination and revoking filesystem execution permissions.

---

## 2. Problem Statement & Goals

### 2.1. Problem
Traditional DAC (Discretionary Access Control) and even some MAC (Mandatory Access Control) policies grant execution rights based on file ownership/permissions. Once a user has execute permission for a binary (e.g., `systemd-run`), they can invoke it with arbitrary arguments. This allows malicious actors or compromised scripts to bypass resource quotas, escape isolation boundaries, or leverage system utilities for privilege escalation.

### 2.2. Goals
1. **Strict Argument Validation:** Block process execution if arguments do not strictly match predefined allowed patterns.
2. **Process Hierarchy Enforcement (Cgroup Aggregation):** Ensure that critical processes and their descendants are aggregated into specific, monitored Cgroups.
3. **Automated Remediation:** Implement immediate defensive actions (e.g., session lockout, file permission revocation) upon detecting policy violations.

---

## 3. Reference Scenario

> **Scenario: Controlled Execution of Firefox as a Transient Service**
> 
> 1. A user or script attempts to launch Firefox via `systemd-run` to ensure the main process and all child processes (rendering, web content) are isolated within a single `Cgroup`.
> 2. The `systemd-run` binary must be invoked **exclusively** with approved parameters (e.g., specific service names, resource limits, isolation flags, and the exact path to the Firefox binary).
> 3. If a user attempts to alter the command (e.g., by executing `/bin/bash` instead of the Firefox binary, or removing the required Cgroup delegation flags):
>    * The process is blocked immediately at the point of invocation.
>    * The current user session is forcefully terminated (`loginctl`).
>    * The execution bit (`chmod -x`) is stripped from the offending binary or script to prevent re-execution.
>    * A "Critical" security event is logged to the system audit trail.

---

## 4. Functional Requirements (FR)

*   **FR-01 (Interception):** The system must intercept `execve` syscalls or D-Bus requests directed at `systemd`, verifying them against LPVS policies.
*   **FR-02 (Argument Policy):** Support for strict "Exact Match" or Regex-based allowlisting for binary arguments (e.g., matching `--unit`, `--scope`, `--slice`, `--property`).
*   **FR-03 (Cgroup Validation):** Verification that mandatory parameters for Cgroup aggregation and process tracking are present before execution is granted.
*   **FR-04 (Remediation Engine):** 
    * **Session Kill:** Terminate the user's `systemd-logind` session.
    * **Permission Revocation:** Remove the execute bit (`chmod ugo-x`) or apply immutable attributes (`chattr +i`) to the target binary.
    * **Logging:** Send detailed violation reports to `journald` or `auditd`.

---

## 5. System Architecture
```text
+-----------------------------------------------------------+
|                     User Space Execution                  |
|  $ systemd-run --unit=firefox-sandbox /usr/bin/firefox    |
+-----------------------------+-----------------------------+
|
v
+----------------------------------+
|   LPVS Enforcement Point         |
|   (eBPF Tracepoint / Fanotify /  |
|    Wrapper / Audit Dispatcher)   |
+----------------+-----------------+
|
Validate Policy?
/                \
[ YES ] /                  \ [ NO (Policy Violation) ]
/                    \
v                      v
+--------------------------+    +----------------------------------+
|  Allow Execution         |    | LPVS Remediation Engine          |
|  - Spawns in target      |    | 1. SIGKILL process               |
|    Cgroup v2 hierarchy   |    | 2. Terminate User Session        |
|  - Tracks child pids     |    |    (loginctl terminate-session)  |
+--------------------------+    | 3. Strip exec bit (chmod -x)     |
| 4. Log Alert via journald/syslog |
+----------------------------------+
