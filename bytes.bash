#!/usr/bin/env bash

[[ "${DEBUG-}" ]] && set -eu -o pipefail
[[ "${TRACE-}" ]] && set -x

declare -r VERSION="2.0.0"

# List of known units and conversion rates
declare -A units=(
	['byte']=1
	['kilobyte']=$((10 ** 3))
	['megabyte']=$((10 ** 6))
	['gigabyte']=$((10 ** 9))
	['terabyte']=$((10 ** 12))
	['petabyte']=$((10 ** 15))

	['kibibyte']=$((2 ** 10))
	['mebibyte']=$((2 ** 20))
	['gibibyte']=$((2 ** 30))
	['tebibyte']=$((2 ** 40))
	['pebibytes']=$((2 ** 50))
)

# Aliases
units['b']="${units['byte']}"
units['k']="${units['kilobyte']}"
units['kb']="${units['kilobyte']}"
units['m']="${units['megabyte']}"
units['mb']="${units['megabyte']}"
units['g']="${units['gigabyte']}"
units['gb']="${units['gigabyte']}"
units['t']="${units['terabyte']}"
units['tb']="${units['terabyte']}"
units['p']="${units['petabyte']}"
units['pb']="${units['petabyte']}"

units['kib']="${units['kibibyte']}"
units['mib']="${units['mebibyte']}"
units['gib']="${units['gibibyte']}"
units['tib']="${units['tebibyte']}"
units['pib']="${units['pebibytes']}"

abort() {
	message="${1-}"
	printf 'Error: %s\n' "$message" >&2
	exit 1
}

bold() {
	printf '\033[1m%s\033[0m\n' "$*"
}

italic() {
	printf '\033[3m%s\033[0m\n' "$*"
}

showUsage() {
	cat <<-END
		$(italic "Convert between human-readable sizes and raw byte values")

		$(bold USAGE)
		  bytes [options] [value]

		$(bold OPTIONS)
		  -d, --decimal-places  how many digits past the decimal place to show
		  -h, --help            output usage information and exit
		  -l, --list-units      list known units and name alternatives for conversion
		  -V, --version         output the version number and exit

		$(bold EXAMPLES)
		  Convert 25 GB to bytes:
		  $ bytes 25 GB
		  # » 25000000000

		  There's aliases for units. Use --list-units to see them all.
		  $ bytes 25gb # » 25000000000
		  $ bytes 25 gigabytes # » 25000000000

		  Convert 194853247 to a readable format:
		  $ bytes 194853247
		  # » 194.85 MB

		  Read from stdin:
		  $ ls -l ~/Downloads/menu2.mov | awk '{ print \$5 }' | ./bytes.bash
		  # » 34.06 MB

		  $ bytes 32 mib | bytes
		  # » 33.55 MB
	END
}

##
# Join elements of an array with a delimiter
##
arrayJoin() {
	local IFS="$1"
	shift
	echo "$*"
}

has_stdin_data() {
	# Check if stdin (file descriptor 0) is not a terminal
	# That means we have data being piped or redirected
	[[ ! -t 0 ]]
}

toLowercase() {
	awk '{print tolower($0)}' <<<"$*"
}

toUppercase() {
	awk '{print toupper($0)}' <<<"$*"
}

##
# Convert bytes to a more readable version
##
formatBytes() {
	local -r value="$1"
	local -r decimalPlaces="${2:-2}"
	local -r absValue="${value#-}"

	local unit='b'
	local fitsInValue='0'

	# Find the largest unit that can display the value as a whole number
	for u in 'pb' 'tb' 'gb' 'mb' 'kb'; do
		fitsInValue="$(bc <<<"$absValue >= ${units["$u"]}")"
		if [[ $fitsInValue == 1 ]]; then
			unit="$u"
			break
		fi
	done

	# Use 0 decimal places for bytes, otherwise use the provided value
	local displayDecimalPlaces="$decimalPlaces"
	if [[ $unit == "b" ]]; then
		displayDecimalPlaces=0
	fi

	convertedValue="$(bc <<<"scale=${displayDecimalPlaces}; $value / ${units[$unit]}")"
	suffix="$(toUppercase "$unit")"

	printf "%'0.*f %s\n" "$displayDecimalPlaces" "$convertedValue" "$suffix"
}

##
# Parse a string and return bytes
##
parseBytes() {
	local -r value="$1"
	local -r unit="$2"
	local -r decimalPlaces="$3"

	bytes="$(bc <<<"$value * ${units[$unit]}")"
	printf '%0.*f\n' "$decimalPlaces" "$bytes"
}

##
# Convert to bytes or represent bytes in a readable way
##
bytes() {
	local decimalPlaces
	local input

	for opt in "${@}"; do
		case "$opt" in
			-d | --decimal-places)
				shift
				decimalPlaces=$(($1))
				;;
			-h | --help | help)
				showUsage
				return 0
				;;
			-l | --list-units)
				echo "${!units[@]}"
				return 0
				;;
			-V | --version)
				echo "$VERSION"
				return 0
				;;
			*)
				input="${input-} ${opt}"
				;;
		esac
	done

	if has_stdin_data; then
		read -r pipedInput </dev/stdin
		input="${input} ${pipedInput}"
	fi

	input="$(toLowercase "${input-}")"

	if [[ $input == '' ]]; then
		showUsage
		return 1
	fi

	local -r numberRegex='(-?[0-9]+\.?[0-9]*) *'
	local -r suffixes="$(arrayJoin '|' "${!units[@]}")"
	local -r numberWithSuffixRegex="${numberRegex}(${suffixes})s?$"

	if [[ $input =~ $numberWithSuffixRegex ]]; then
		local -r value="${BASH_REMATCH[1]}"
		local -r unit="${BASH_REMATCH[2]}"
		parseBytes "$value" "$unit" "${decimalPlaces:-0}"
	elif [[ $input =~ ${numberRegex}$ ]]; then
		local -r value="${BASH_REMATCH[1]}"
		formatBytes "$value" "${decimalPlaces:-2}"
	else
		abort "could not parse value: $input"
	fi
}

if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
	export -f bytes
else
	bytes "${@}"
	exit $?
fi
