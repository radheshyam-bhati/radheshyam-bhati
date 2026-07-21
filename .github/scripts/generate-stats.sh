#!/bin/bash
echo "=== MINIMAL TEST ==="
mkdir -p assets
echo "test-$(date)" > assets/switchboard-test.txt
echo "test svg" > assets/switchboard-stats.svg
echo "=== DONE ==="
