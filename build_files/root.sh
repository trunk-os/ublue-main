#!/bin/sh

#
# this script is just here to make testing easier until the configuration
# system arrives.
#
# it should be removed before any production use of this system.
#

set -xeuo pipefail

echo -n trunkrules | passwd -s root
mkdir -p /root
