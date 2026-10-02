# WWAN-WG

Android cellular WAN gateway using WireGuard.

WWAN-WG turns an Android phone into a cellular upstream gateway for another device, such as an OpenWrt router. The phone provides the mobile-data connection and forwards traffic from the WireGuard client through the cellular interface.

Designed to run as a **KernelSU module** with automatic state reconciliation and recovery.

## Features

- WireGuard gateway on Android
- Cellular interface auto-detection
- Optional cellular interface pinning
- IPv4 forwarding
- Policy routing for WireGuard traffic
- NAT/MASQUERADE through the cellular interface
- Automatic configuration repair when network state changes
- WireGuard kernel support detection
- Peer handshake watchdog
- Automatic peer reset/recovery
- Daemon heartbeat and PID tracking
- Log rotation
- Human-readable and JSON status output
- Health checks
- Safe teardown of routes, rules, firewall chains, and WireGuard
- Persistent configuration under `/data/adb/wwan-wg`

## Architecture

```text
                 Cellular Network
                       │
                  Android Phone
                       │
                cellular interface
                       │
                ┌──────▼──────┐
                │   WWAN-WG   │
                │   WireGuard │
                │    wg0      │
                └──────┬──────┘
                       │
                 LAN / Wi-Fi
                       │
                 OpenWrt Router
                       │
                    LAN/WAN
```

The Android phone acts as the **WireGuard server/gateway**.

The OpenWrt router connects as the WireGuard peer and sends its traffic through the phone's cellular connection.

## Requirements

- Rooted Android device
- KernelSU
- WireGuard kernel support
- `ip`, `iptables`, `ping`, and standard Android shell utilities
- Cellular interface with IPv4 connectivity
- LAN connection to the downstream router
- WireGuard peer configuration

The module includes its own `wg` and `wg-quick` binaries when available, but will also use system binaries.

## Configuration

Configuration file:

```text
/data/adb/wwan-wg/config.conf
```

Example:

```sh
WG_IF="wg0"
WG_ADDR="10.200.0.1/24"
WG_NET="10.200.0.0/24"
WG_PORT="51820"

PRIVATE_KEY="/data/local/wireguard/phone_private.key"

PI_PUBLIC_KEY="YOUR_OPENWRT_PUBLIC_KEY"
PI_ALLOWED_IPS="10.200.0.2/32"

LAN_IF="wlan0"
LAN_IP="10.4.2.2"
PI_IP="10.4.2.1"
LAN_NET="10.4.2.0/24"

ROUTE_TABLE="200"
ROUTE_PREF="100"
LAN_RULE_PREF="50"
WG_RULE_PREF="51"

TEST_IP="1.1.1.1"

UPSTREAM_GLOBS="rmnet_data* v4-rmnet_data* ccmni* v4-ccmni*"
UPSTREAM_IF=""

RECONCILE_INTERVAL="5"
HEALTH_INTERVAL="30"
HANDSHAKE_TIMEOUT="180"

PEER_WATCHDOG="1"
PEER_RESET_AFTER="90"
PEER_CHECK_EVERY="10"
```

Only values that need to be changed have to be placed in `config.conf`; built-in defaults are used for everything else.

## Commands

The controller is located at:

`<module>/bin/controller`

| Command | Description |
|---|---|
| `controller start` | Starts the background monitoring daemon. |
| `controller stop` | Stops the daemon and completely removes the WireGuard interface, policy-routing rules, custom routes, firewall rules, and NAT rules. |
| `controller restart` | Restarts only the daemon while keeping the existing network state. |
| `controller reconcile` | Immediately checks and repairs the complete gateway configuration. |
| `controller status` | Displays human-readable status. |
| `controller status --json` | Displays machine-readable status in JSON format. |
| `controller health` | Performs an active connectivity test through the WireGuard source address and cellular interface. |
| `controller logs` | Shows the last 100 log lines. |
| `controller logs 200` | Shows the last 200 log lines. |
| `controller check-kernel` | Checks whether the Android kernel supports WireGuard. |
| `controller clear-log` | Clears the log file. |
| `controller teardown` | Removes the network configuration without stopping the daemon. |

### Log File

`/data/adb/wwan-wg/log/wwan-wg.log`

## Automatic Recovery

The daemon continuously monitors the gateway.

Every reconciliation cycle it checks:

```text
WireGuard
Forwarding
LAN route
Policy rules
Cellular upstream
Forwarding firewall
NAT
```

If a component disappears or changes, WWAN-WG attempts to repair it automatically.

The daemon also monitors the WireGuard peer handshake.

If the downstream router is reachable but the handshake remains stale, the watchdog progressively:

1. Resets the WireGuard peer
2. Recreates `wg0`
3. Stops taking further recovery actions until the peer leaves and returns

This helps recover from issues such as a downstream router reboot with an incorrect system clock.

## State and Runtime Files

```text
/data/adb/wwan-wg/
├── config.conf
├── log/
│   └── wwan-wg.log
└── run/
    ├── controller.pid
    ├── heartbeat
    ├── status
    └── kernel_support
```

## Status

The controller exposes information about:

- Kernel WireGuard support
- WireGuard interface state
- WireGuard address
- Peer handshake age
- RX/TX traffic
- Cellular interface
- Cellular IP and gateway
- Default network
- Daemon state
- Daemon heartbeat
- Last reconciliation result
- `wg` / `wg-quick` binaries

JSON output is intended for integration with WebUI or other monitoring tools.

## Firewall

WWAN-WG creates dedicated chains:

```text
WWAN_WG_FORWARD
WWAN_WG_NAT
```

The chains are linked into the Android forwarding/NAT path and are removed during teardown.

## Logging

All state-changing operations are logged.

Example:

```text
2026-10-02 12:00:00 [INFO] [daemon] state: init -> wg=1 lan=1 up=rmnet_data1
2026-10-02 12:00:00 [INFO] [ctl] step upstream: repaired
2026-10-02 12:00:00 [INFO] [ctl] reconcile: HEALTHY
```

Logs are automatically rotated when they exceed the configured limit.

## License

