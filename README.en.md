![GitHub License](https://img.shields.io/github/license/len4m/gtfolenam?style=flat-square)
[![es](https://img.shields.io/badge/README-es-red.svg?style=flat-square)](https://github.com/len4m/gtfolenam/)
[![en](https://img.shields.io/badge/README-en-yellow.svg?style=flat-square)](https://github.com/Len4m/gtfolenam/blob/main/README.en.md)

# GTFOLenam v2.0

<img src="image.png" width="500" alt="GTFOLenam scanner" style="margin-left:auto;margin-right:auto">

```bash
./gtfolenam.sh [-v] [-h] [-t=sudo,suid,capabilities] [-u]
```

**What it does**: Scans binaries with `sudo`, `SUID`, or `capabilities` and checks them against [GTFOBins](https://gtfobins.org/). If the binary is exploitable, it shows the link to the technique. Designed for CTFs and Linux audits.

**How it works**: The GTFOBins database is embedded in the script. Run `./gtfolenam.sh -u` on your machine (with internet) to update it; the script **modifies itself** with the new data. Then transfer the script to the target and scan without network access.

> The script has been almost entirely reprogrammed due to the GTFOBins website update.

## Features

- **Offline**: unlike the previous script, scanning requires no internet connection
- **Self-updatable**: `-u` downloads the latest database and embeds it in the script
- **Minimal dependencies**: awk, sed (and grep only if using sudo)
- **Sudo**: indicates whether each command requires a password (NOPASSWD) or not

## Help

```
$ ./gtfolenam.sh -h
Usage: ./gtfolenam.sh [-v] [-h] [-t=type1,type2,...] [-u]

Options:
  -v    Verbose mode.
  -h    Show this help.
  -t    Types: sudo, suid, capabilities (default: all)
  -u    Update embedded GTFOBins data from gtfobins.org/api.json

GTFOBins data is embedded for offline use.
```

## Dependencies

For **scanning**, the script looks for alternatives (busybox, common paths) when a tool is not in PATH, so you typically don't need to install dependencies; it also requires no internet connection. With **-u** (update) it also uses busybox for curl/wget and sed, but **jq or python3** are required (no alternative) to parse the JSON, plus internet access.

| Use | Tools |
|-----|-------|
| **Scanning** | awk, sed, find, getcap (grep only if using sudo) |
| **Update (-u)** | curl or wget, jq or python3, internet connection |

## Installation

**With wget:**

```bash
wget https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**With curl:**

```bash
curl -O https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**With busybox wget:**

```bash
busybox wget -O gtfolenam.sh https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**With busybox curl:**

```bash
busybox curl -o gtfolenam.sh https://raw.githubusercontent.com/Len4m/gtfolenam/main/gtfolenam.sh && chmod +x gtfolenam.sh
```

**Without download tools:** transfer the script via SCP, SFTP, netcat, etc. then run:

```bash
chmod +x gtfolenam.sh
```

## Examples

**Update embedded DB** (best: run on your machine, then transfer):

```bash
./gtfolenam.sh -u
```

**Full scan:**

```bash
./gtfolenam.sh
```

**SUID only:**

```bash
./gtfolenam.sh -t suid
```

**Sudo + capabilities:**

```bash
./gtfolenam.sh -t=sudo,capabilities
```

**Verbose** (shows all binaries; non-vulnerable in green):

```bash
./gtfolenam.sh -v
```

## Excluded binaries

Legitimate SUID/capabilities that are not exploitable in GTFOBins are filtered: passwd, sudo, su, chsh, chfn, gpasswd, newgrp, fusermount, mount, umount, ssh-keysign, ping, ping6, etc.

## Legal disclaimer

This tool is provided "as is", without warranty of any kind. It is intended exclusively for:
- **Legitimate use** on systems you own or on which you have explicit written authorization
- **CTFs** and authorized practice environments
- **Security audits** under contract or permission from the system owner

**Prohibited**: unauthorized access to computer systems is a criminal offense in most jurisdictions. The user is solely responsible for ensuring they have the necessary permissions before running this script.

The author **assumes no responsibility** for damages, legal consequences, losses, or harm arising from misuse, illegal, or unauthorized use of this tool. Use is at the user's sole responsibility.
