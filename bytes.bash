#!/usr/bin/env bash

[[ "${DEBUG-}" ]] && set -eu -o pipefail
[[ "${TRACE-}" ]] && set -x

declare -r VERSION="1.0.1"

# List of known units and conversion rates
declare -Ar units=(
	['b']=1
	['byte']=1
	['k']=1000
	['kb']=1000
	['kilobyte']=1000
	['kib']=$((2 ** 10))
	['kibibyte']=$((2 ** 10))
	['m']=$((1000 ** 2))
	['mb']=$((1000 ** 2))
	['megabyte']=$((1000 ** 2))
	['mib']=$((2 ** 20))
	['mebibyte']=$((2 ** 20))
	['g']=$((1000 ** 3))
	['gb']=$((1000 ** 3))
	['gigabyte']=$((1000 ** 3))
	['gib']=$((2 ** 30))
	['gibibyte']=$((2 ** 30))
	['t']=$((1000 ** 4))
	['tb']=$((1000 ** 4))
	['terabyte']=$((1000 ** 4))
	['tib']=$((2 ** 40))
	['tebibyte']=$((2 ** 40))
	['p']=$((1000 ** 5))
	['pb']=$((1000 ** 5))
	['petabyte']=$((1000 ** 5))
	['pib']=$((2 ** 50))
	['pebibytes']=$((2 ** 50))
)

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
		  $ ls -l ~/Downloads/menu2.mov | awk '{ print \$5 }' | ./bytes.bash -
		  # » 34.06 MB

		  $ bytes 32 mib | bytes -
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

	convertedValue="$(bc <<<"scale=${decimalPlaces}; $value / ${units[$unit]}")"
	suffix="$(toUppercase "$unit")"

	printf "%'0.*f %s\n" "$decimalPlaces" "$convertedValue" "$suffix"
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
			-h | --help)
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

	input="$(toLowercase "${input-}")"

	if [[ $input == '' ]]; then
		# Exit with usage message if still no input
		showUsage
		return 1
	fi

	# Read from stdin
	if [[ ${input# } == '-' ]]; then
		read -r input </dev/stdin
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
		abort 'could not parse value as bytes'
	fi
}

if [[ ${BASH_SOURCE[0]} != "$0" ]]; then
	export -f bytes
else
	bytes "${@}"
	exit $?
fi
