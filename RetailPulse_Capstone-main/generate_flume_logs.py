#!/usr/bin/env python3
"""
Flume Lab Data Generator - for use with WadyOsama/Docker-BigData-Tools.

IMPORTANT - How this fits the actual docker-compose.yml:
  The `flume` service (container_name: 06-02-flume, hostname: flume, image:
  probablyfine/flume:latest, profile: data-ingestion) only bind-mounts a single
  file by default:
      ./base/flume/flume.conf:/opt/flume-config/flume.conf:ro
  There is NO shared log directory mounted into the container, so writing files
  to a host path like /tmp does nothing for Flume - the container can't see them.

  To make SpoolDir/Taildir scenarios work you must add a second volume to the
  `flume` service in docker-compose.yml (one-time edit):
      volumes:
        - ./base/flume/flume.conf:/opt/flume-config/flume.conf:ro
        - ./base/flume/lab_data:/var/log/flume_lab

  Run this script from the root of your cloned Docker-BigData-Tools repo (the
  same folder that contains docker-compose.yml) so the relative path below
  ("./base/flume/lab_data") lands exactly on the host side of that bind mount.
  Files written here become visible inside the flume container at
  /var/log/flume_lab/... immediately (no restart needed).

  For Scenario 2 (HTTPSource) you also need to expose the HTTP port, e.g. add
  "8080:8080" to the flume service's `ports` list.
"""
import os
import sys
import time
import random
import argparse
from datetime import datetime, timezone

try:
    import requests
except ImportError:
    requests = None

# Host-side directory that must be bind-mounted to /var/log/flume_lab in the flume container
LAB_DATA_DIR = os.environ.get("FLUME_LAB_HOST_DIR", "./base/flume/lab_data")

CHECKOUT_LOG_DIR = os.path.join(LAB_DATA_DIR, "gateway")


def utcnow():
    return datetime.now(timezone.utc)


def generate_checkout_logs(num_records=2000):
    """Scenario 1: Drop a completed audit log file for the SpoolDir source to pick up."""
    os.makedirs(CHECKOUT_LOG_DIR, exist_ok=True)
    file_path = os.path.join(CHECKOUT_LOG_DIR, f"checkout_{int(time.time())}.log")
    print(f"[*] Generating {num_records} checkout audit logs in {file_path}...")

    with open(file_path, "w") as f:
        for _ in range(num_records):
            txn_id = f"TXN-{random.randint(10000000, 99999999)}"
            cust_id = random.randint(1000, 50000)
            amount = round(random.uniform(10.0, 2500.0), 2)
            status = random.choice(["SUCCESS", "SUCCESS", "SUCCESS", "DECLINED", "FRAUD_SUSPECT"])
            timestamp = utcnow().strftime("%Y-%m-%d %H:%M:%S,%f")[:-3]
            f.write(f"[{timestamp}] [AUDIT] [TXN_ID:{txn_id}] [CUST:{cust_id}] [AMOUNT:${amount}] [STATUS:{status}]\n")

    print(f"[+] Checkout audit log file ready for SpoolDir at /var/log/flume_lab/gateway/{os.path.basename(file_path)}")


def push_iot_telemetry(num_events=2000, http_url="http://localhost:8080/"):
    """Scenario 2: POST events directly to Flume's HTTPSource (JSONHandler format)."""
    if requests is None:
        print("[-] The 'requests' package is required for this scenario: pip install requests")
        sys.exit(1)

    print(f"[*] Pushing {num_events} IoT GPS telemetry events to {http_url} ...")
    batch = []
    for i in range(num_events):
        truck_id = f"TRUCK-{random.randint(1000, 5999)}"
        lat = round(random.uniform(24.0, 31.5), 6)
        lon = round(random.uniform(30.0, 34.5), 6)
        body = f"{truck_id},{lat},{lon},{utcnow().isoformat()}"
        batch.append({"headers": {"truck_id": truck_id}, "body": body})

        # Send in batches of 200 to avoid oversized single requests
        if len(batch) >= 200 or i == num_events - 1:
            try:
                resp = requests.post(http_url, json=batch, timeout=5)
                resp.raise_for_status()
            except Exception as e:
                print(f"[-] Failed to push batch to Flume HTTPSource: {e}")
                print("    Make sure port 8080 is mapped for the flume service and HTTPSource is active.")
                sys.exit(1)
            batch = []

    print("[+] IoT telemetry batch delivered successfully to Flume HTTPSource.")


def main():
    parser = argparse.ArgumentParser(description="Apache Flume Lab Data Generator")
    parser.add_argument("--scenario", choices=["1", "2", "all"], default="all",
                         help="Which scenario's data to generate (default: all)")
    parser.add_argument("--http-url", default="http://localhost:8080/",
                         help="Flume HTTPSource endpoint for Scenario 2")
    args = parser.parse_args()

    print("=== Apache Flume Lab Data Generator ===")
    print(f"[*] Writing host-side lab data under: {os.path.abspath(LAB_DATA_DIR)}")
    print("[*] Make sure this path is bind-mounted to /var/log/flume_lab in the flume service.\n")

    if args.scenario in ("1", "all"):
        generate_checkout_logs(2000)
    if args.scenario in ("2", "all"):
        push_iot_telemetry(2000, args.http_url)

    print("\n[+] Done.")


if __name__ == "__main__":
    main()
