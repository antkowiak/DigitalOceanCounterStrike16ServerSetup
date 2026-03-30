# DigitalOceanCounterStrike16ServerSetup
Setup scripts to create and setup a Counter-Strike 1.6 dedicated server on a Digital Ocean Droplet VPS.
The script automatically takes care of all of the following:
- Setting up UFW Firewall rules
- Creating a user account for running the steam server
- Configured software package managers for non-interactive setup and adding i386 architecture
- Installs linux software updates
- Installs required linux software packages and dependencies
- Uses `steamcmd` to install HLDS cstrike with the beta steam_legacy settings. (Runs multiple times to work around steamcmd bugs)
- Downloads and installs ReHLDS patch into the cstrike server.
- Downloads and installs Metamod-R.
- Downloads and installs AMX Mod X Base Package.
- Downloads and installs AMX Mod X Counter-Strike Package.
- Downloads and installs ReGameDLL_CS patch.
- Downloads and installs ReAPI.
- Creates a convenience script `run_cstrike_server.sh` for the steam user to start running the server.
- Populates server.cfg settings
- Populates mapcycle.txt
- Populates motd.txt
- Creates empty banlist files to silence some server error messages.


INSTRUCTIONS:
1) Create a Linux DigitalOcean Droplet.  (Tested with Ubuntu 24.04)
2) Edit the `cstrike_server_setup.sh` script for desired admin steam id, host name, port, server settings, etc.
3) Upload the `cstrike_server_setup.sh` script to the droplet.
4) Set the script as executable `chmod 700 cstrike_server_setup.sh`
5) Run the `cstrike_server_setup.sh` script as root.  Only run it once.
6) Reboot the droplet.
7) Log into the droplet as the steam account.
8) As the steam account, run the `run_cstrike_server.sh` script. You may want to do this in a GNU screen or tmux session.


TODO:
- Update script to turn on unattended upgrades for Ubuntu.
- Create a systemd unit file for automatically running/re-starting the server as needed.
- For 3rd party packages that are downloaded separately, consider including them in this repo (if licences allow), so the script doesn't need to download them with curl/wget.
- Include and automatically install some additional map packages for commonly played maps.

CREATED BY:
Ryan Antkowiak
