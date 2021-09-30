#!/bin/bash
set -e

exec python3 events.py & 
exec python3 pod_log.py
