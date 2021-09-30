#!/bin/bash
set -e

exec python3 metric_log.py & 
exec python3 prometheus.py
