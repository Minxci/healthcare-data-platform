#!/usr/bin/env bash
# Generates synthetic patients with Synthea.
# -p 200 : 200 living patients (Synthea also adds some deceased ones)
# -s 42 : fixed seed, so the same patients come out every run
set -euo pipefail

java -jar synthea-with-dependencies.jar \
    -p 200 \
    -s 42 \
    --exporter.baseDirectory=./data/raw \
    Illinois
