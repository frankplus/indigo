#!/bin/bash

# Copyright (c) 2026 Francesco Pham
# All rights reserved.
#
# You can use this software under the terms of 'INDIGO Astronomy open-source license'
# (see https://github.com/indigo-astronomy/indigo/blob/master/LICENSE.md).
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHORS 'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
# INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
# FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
# BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA,
# OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Run by indigo-wifi-fallback.service. Raises the INDIGO access point through
# 'rpi_ctrl_v2.sh --reset-wifi-server' when the WiFi device is not connected
# BOOT_DELAY seconds after start, or stays disconnected for LINK_LOSS_DELAY
# seconds later on. Nothing happens while Ethernet has carrier; the reset
# command checks that itself, and also waits for a client switch in progress.
#
# Settings (environment, e.g. /etc/default/indigo-wifi-fallback):
#   RPI_CTRL         management script (default /usr/bin/rpi_ctrl_v2.sh)
#   WIFI_DEV         WiFi device (default wlan0)
#   BOOT_DELAY       seconds after start (default 60)
#   LINK_LOSS_DELAY  seconds after a connection was lost (default 120)
#   INTERVAL         polling interval in seconds (default 10)

RPI_CTRL=${RPI_CTRL:-/usr/bin/rpi_ctrl_v2.sh}
WIFI_DEV=${WIFI_DEV:-wlan0}
BOOT_DELAY=${BOOT_DELAY:-60}
LINK_LOSS_DELAY=${LINK_LOSS_DELAY:-120}
INTERVAL=${INTERVAL:-10}

limit=${BOOT_DELAY}
down=0
while true; do
	state=$(nmcli -g GENERAL.STATE dev show "${WIFI_DEV}" 2>/dev/null)
	if [[ "${state%% *}" == "100" ]]; then
		down=0
		limit=${LINK_LOSS_DELAY}
	else
		down=$((down + INTERVAL))
		if [[ ${down} -ge ${limit} ]]; then
			echo "${WIFI_DEV} not connected for ${down} s, activating the access point"
			"${RPI_CTRL}" --reset-wifi-server
			down=0
			limit=${LINK_LOSS_DELAY}
		fi
	fi
	sleep "${INTERVAL}"
done
