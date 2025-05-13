#!/bin/sh

set -euo pipefail

systemctl enable buckle.service buckle.socket gild.service hostname.service panel.service avahi-daemon.service
