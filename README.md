# bytes-bash

> Convert to bytes or represent bytes in a readable way

Use this script to convert to bytes or to display bytes in a readable way.

## Install

A simple Makefile is provided to install and uninstall the script.

```bash
# Install to /usr/local/bin (default PREFIX)
make install

# Install to a custom directory
make install PREFIX=$HOME/.local

# Uninstall
make uninstall
```

## Usage

**Parse strings to bytes:**

```bash
bytes 25 GB          # => 25000000000
bytes 3.14gib        # => 3371549327
bytes 214 kilobytes  # => 214000
```

The list of known units can be checked using `--list-units`.

**Convert bytes to a readable format:**

```bash
bytes 194853247            # => 194.85 MB
bytes 123561872361         # => 123.56 GB
bytes 9239236155359686362  # => 9,239.23 PB
```

Also, reading from stdin is possible using `-`:

```bash
ls -l ~/Downloads/menu2.mov | awk '{ print $5 }' | ./bytes.bash -  # => 34.06 MB
```

```bash
bytes 32 mib | bytes -   # => 33.55 MB
```

## API

When sourced from another script, this can add several helper functions:

### `function bytes`

The same interface as running the script directly. Passing a number without a unit is converted to a readable format. A number with a unit is parsed into numeric bytes. All the command line flags mentioned above can also be passed.

### `function parseBytes`

Parses a string and returns the number of bytes.

**Arguments:**

1. `value`: the number to convert (e.g. `23`)
2. `unit`: a unit (from `--list-units`) to convert from (e.g. `GB`)
3. `decimalPlaces`: optional number of digits to show after the decimal place (default: `0`)

### `function formatBytes`

Converts bytes to a more readable version.

**Arguments:**

1. `value`: the number to convert (e.g. `1234`)
2. `decimalPlaces`: optional number of digits to show after the decimal place (default: `0`)

## License

MIT
