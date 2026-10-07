# Dynamic Host-Based Firewall

## Overview

**Dynamic Host-Based Firewall** is a security feature designed to dynamically control network access on a Linux endpoint based on the execution state of authorized processes.

The host firewall operates with a **Default Deny (DROP)** policy. Therefore, network communication is not permitted unless it is explicitly authorized.

Instead of keeping firewall rules permanently active, the required network access rules are dynamically activated only when an authorized process is running.

This approach follows **Zero Trust Architecture (ZTA)** principles by providing network access only when it is required and removing that access when it is no longer needed.

---

## How It Works

The Dynamic Host-Based Firewall monitors the execution state of predefined and authorized processes.

Each authorized process can be associated with one or more predefined firewall rules.

The basic workflow is:

```text
Authorized Process Starts
        |
        v
Process Identity / Authorization Validation
        |
        v
Load Predefined Firewall Rules
        |
        v
Required Network Access Becomes Available
        |
        v
Process Is Running
        |
        v
Process Terminates
        |
        v
Remove Associated Firewall Rules
        |
        v
Return to Default Deny State
```

When an authorized process starts:

1. The process is detected.
2. The process is validated as an authorized application.
3. The firewall rules associated with that process are identified.
4. The required rules are dynamically added to the Linux host firewall.
5. Only the network access required by that process becomes available.

When the process terminates:

1. Process termination is detected.
2. The firewall rules associated with the process are identified.
3. The dynamically created rules are removed.
4. The firewall returns to its original **Default Deny** state.

---

## Default Deny Policy

The host firewall is configured with a restrictive policy by default:

```text
Default Policy: DROP
```

This means that network access is denied unless an active and authorized process requires a specific connection.

For example:

```text
No Authorized Process Running

Host
 |
 +-- SSH ---------> BLOCKED
 +-- HTTP --------> BLOCKED
 +-- HTTPS -------> BLOCKED
 +-- Other Traffic -> BLOCKED
```

If an authorized application requires HTTPS access:

```text
Authorized Application Starts
        |
        v
Dynamic Rule Activated
        |
        v
HTTPS Access -> ALLOWED
```

After the application terminates:

```text
Authorized Application Stops
        |
        v
Dynamic Rule Removed
        |
        v
HTTPS Access -> BLOCKED
```

Therefore, firewall permissions exist only during the lifetime of the authorized process.

---

## Process-to-Firewall Policy Mapping

Each authorized process can have its own predefined network access policy.

Example:

| Process | Destination | Protocol | Port | Action |
|---|---|---|---|---|
| `firefox` | Internet | TCP | 443 | Allow |
| `backup-agent` | Backup Server | TCP | 443 | Allow |
| `monitoring-agent` | Monitoring Server | TCP | 10051 | Allow |
| `update-agent` | Update Repository | TCP | 443 | Allow |

These rules are not permanently enabled.

They are activated only while the corresponding authorized process is running.

---

## Zero Trust Principles

The Dynamic Host-Based Firewall is designed according to several fundamental **Zero Trust Architecture** principles.

### Default Deny

No network access is implicitly trusted or permanently allowed.

### Least Privilege

Each application receives only the minimum network access required to perform its function.

### Just-In-Time Access

Firewall permissions are activated only when they are required.

### Dynamic Authorization

Network access is dynamically granted and revoked according to the runtime state of authorized processes.

### Reduced Attack Surface

Unused network access paths remain closed when the associated application is not running.

### Continuous Enforcement

Authorization is not treated as a permanent decision. Access exists only while the conditions that justified the access remain valid.

---

## Security Objective

The primary objective of this feature is to transform the Linux host firewall from a static network filtering mechanism into a **runtime-aware security enforcement mechanism**.

Traditional firewall configuration can leave network permissions permanently active even when the application requiring those permissions is not running.

Dynamic Host-Based Firewall reduces this exposure by binding network permissions to the lifecycle of authorized processes:

```text
Process Authorization
        +
Process Runtime State
        +
Predefined Network Policy
        |
        v
Dynamic Firewall Enforcement
```

The resulting security model can be summarized as:

> **No authorized process, no associated network access.**

This provides a more restrictive and context-aware network security model aligned with Zero Trust principles.
