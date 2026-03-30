#!/bin/bash

##############################################################################
### CONFIGURATION BEGIN
##############################################################################
ADMIN_STEAM_ID="STEAM_0:1:204342"
CSTRIKE_PORT="27015"
CSTRIKE_RCON_PASSWORD=""
CSTRIKE_HOSTNAME="No Bots, FF On, All Classic Maps, cs.kife.net:27015"
CSTRIKE_EMAIL=""
CSTRIKE_DEFAULT_MAP="de_dust2"
CSTRIKE_MAX_PLAYERS="16"
STEAM_USER="steam"
ALL_USERNAMES="user ${STEAM_USER}"
SUDO_USERNAMES="user"
INTEACTIVE_SCRIPT="no"
##############################################################################
### CONFIGURATION END
##############################################################################


##############################################################################
prompt_user_to_continue() {
    echo
    echo "============================================"
    echo "$1"
    echo "============================================"
    if [[ "${INTERACTIVE_SCRIPT}" == "yes" ]]
    then
        echo -n "Hit ENTER to continue: "
        read blankline
        echo "============================================"
        echo
    fi
}
##############################################################################


##############################################################################
prompt_user_to_continue "Setting up UFW Firewall"
ufw allow 22/tcp
ufw allow ${CSTRIKE_PORT}/udp
ufw --force enable
##############################################################################


##############################################################################
prompt_user_to_continue "Creating user accounts"
for u in ${ALL_USERNAMES}
do
    if ! getent passwd ${u} >/dev/null 2>&1
    then
        useradd --shell /bin/bash -m ${u}
        chmod 700 /home/${u}
        mkdir -p /home/${u}/.ssh
        chown ${u}:${u} /home/${u}/.ssh
        chmod 700 /home/${u}/.ssh
        if [ -f /root/.ssh/authorized_keys ]
        then
            cp /root/.ssh/authorized_keys /home/${u}/.ssh/
            chown -R ${u}:${u} /home/${u}/.ssh
            chmod 600 /home/${u}/.ssh/authorized_keys
        fi
    fi
done
##############################################################################


##############################################################################
prompt_user_to_continue  "Adding sudo users"
for u in ${SUDO_USERNAMES}
do
    usermod -aG sudo ${u}
done
##############################################################################


##############################################################################
prompt_user_to_continue  "Setting up package settings"
export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
dpkg --add-architecture i386
apt-add-repository -y multiverse
echo steam steam/question select "I AGREE" | debconf-set-selections
echo steam steam/license note '' | debconf-set-selections
##############################################################################


##############################################################################
prompt_user_to_continue  "Installing software updates"
apt -y update
apt -y -o Dpkg::Options::="--force-confnew" -o Dpkg::Options::="--force-confdef" upgrade
apt -y -o Dpkg::Options::="--force-confnew" -o Dpkg::Options::="--force-confdef" dist-upgrade
##############################################################################


##############################################################################
prompt_user_to_continue  "Installing software packages"
apt -y install lib32gcc-s1 steamcmd software-properties-common net-tools nmap vim screen curl finger git adduser unzip whois fail2ban
apt -y install libcurl4-openssl-dev:i386
##############################################################################


##############################################################################
prompt_user_to_continue "Creating script for the steam user to run to install and setup steam"
INSTALL_SCRIPT_FILENAME="install_cstrike_server.sh"
cat > /home/${STEAM_USER}/${INSTALL_SCRIPT_FILENAME} <<EOF
#!/bin/bash
cd /home/${STEAM_USER}/
for i in {1..5}
do
    sleep 2
    /usr/games/steamcmd +force_install_dir /home/${STEAM_USER}/cstrike/ +login anonymous +app_set_config 90 mod cstrike +app_update 90 -beta steam_legacy validate +quit
done
mkdir -p /home/${STEAM_USER}/.steam/sdk32/
cp /home/${STEAM_USER}/cstrike/steamclient.so /home/${STEAM_USER}/.steam/sdk32/

# ReHLDS Setup
cd /home/${STEAM_USER}
mkdir rehlds
chmod 700 rehlds
cd rehlds
curl "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x63547829004f07716f7be4856c32c4282e60fb67" -o 63547829004f07716f7be4856c32c4282e60fb67.asc
gpg --import 63547829004f07716f7be4856c32c4282e60fb67.asc
wget https://github.com/rehlds/ReHLDS/releases/download/3.14.0.857/rehlds-bin-3.14.0.857.zip
wget https://github.com/rehlds/ReHLDS/releases/download/3.14.0.857/rehlds-bin-3.14.0.857.zip.asc
gpg --verify rehlds-bin-3.14.0.857.zip.asc rehlds-bin-3.14.0.857.zip
unzip rehlds-bin-3.14.0.857.zip
cp -a /home/${STEAM_USER}/rehlds/bin/linux32/. /home/${STEAM_USER}/cstrike/
chmod -R 700 /home/${STEAM_USER}/cstrike

# Metamod-R Setup
mkdir /home/${STEAM_USER}/metamod
chmod 700 /home/${STEAM_USER}/metamod
cd /home/${STEAM_USER}/metamod
wget "https://github.com/rehlds/Metamod-R/releases/download/1.3.0.149/metamod-bin-1.3.0.149.zip"
unzip metamod-bin-1.3.0.149.zip
chmod -R 700 addons
cp -R addons /home/${STEAM_USER}/cstrike/cstrike/
sed -i 's#^gamedll_linux.*#gamedll_linux "addons/metamod/metamod_i386.so"#' /home/${STEAM_USER}/cstrike/cstrike/liblist.gam

# AMX Mod X Setup - Base Package
mkdir /home/${STEAM_USER}/amxmodx_base
chmod 700 /home/${STEAM_USER}/amxmodx_base
cd /home/${STEAM_USER}/amxmodx_base
wget "https://www.amxmodx.org/amxxdrop/1.10/amxmodx-1.10.0-git5474-base-linux.tar.gz"
tar -xzf amxmodx-1.10.0-git5474-base-linux.tar.gz
cp -R /home/${STEAM_USER}/amxmodx_base/addons/amxmodx /home/${STEAM_USER}/cstrike/cstrike/addons/
echo "linux addons/amxmodx/dlls/amxmodx_mm_i386.so" >> /home/${STEAM_USER}/cstrike/cstrike/addons/metamod/plugins.ini
echo "\"${ADMIN_STEAM_ID}\" \"\" \"abcdefghijklmnopqrstu\" \"ce\"" >> /home/${STEAM_USER}/cstrike/cstrike/addons/amxmodx/configs/users.ini

# AMX Mod X Setup - Counter-Strike Package
mkdir /home/${STEAM_USER}/amxmodx_cs
chmod 700 /home/${STEAM_USER}/amxmodx_cs
cd /home/${STEAM_USER}/amxmodx_cs
wget "https://www.amxmodx.org/amxxdrop/1.10/amxmodx-1.10.0-git5474-cstrike-linux.tar.gz"
tar -xzf amxmodx-1.10.0-git5474-cstrike-linux.tar.gz
cp -a /home/${STEAM_USER}/amxmodx_cs/addons/amxmodx/. /home/${STEAM_USER}/cstrike/cstrike/addons/amxmodx/

# ReGameDLL_CS Setup
mkdir /home/${STEAM_USER}/regamedll_cs
chmod 700 /home/${STEAM_USER}/regamedll_cs
cd /home/${STEAM_USER}/regamedll_cs
wget "https://github.com/rehlds/ReGameDLL_CS/releases/download/5.28.0.756/regamedll-bin-5.28.0.756.zip"
unzip regamedll-bin-5.28.0.756.zip
cp /home/${STEAM_USER}/cstrike/cstrike/delta.lst /home/${STEAM_USER}/cstrike/cstrike/delta.lst_bak
cp -a /home/${STEAM_USER}/regamdll_cs/bin/linux32/. /home/${STEAM_USER}/cstrike/

# ReAPI Setup
mkdir /home/${STEAM_USER}/reapi
chmod 700 /home/${STEAM_USER}/reapi
cd /home/${STEAM_USER}/reapi
wget "https://github.com/rehlds/ReAPI/releases/download/5.26.0.338/reapi-bin-5.26.0.338.zip"
unzip reapi-bin-5.26.0.338.zip
cp -R /home/${STEAM_USER}/reapi/addons/amxmodx /home/${STEAM_USER}/cstrike/cstrike/addons/
echo "reapi" >> /home/${STEAM_USER}/cstrike/cstrike/addons/amxmodx/configs/modules.ini


EOF
chown ${STEAM_USER}:${STEAM_USER} /home/${STEAM_USER}/${INSTALL_SCRIPT_FILENAME}
chmod 700 /home/${STEAM_USER}/${INSTALL_SCRIPT_FILENAME}
##############################################################################


##############################################################################
prompt_user_to_continue  "Running the script for the steam user to install and setup steam"
sudo -u ${STEAM_USER} /home/${STEAM_USER}/${INSTALL_SCRIPT_FILENAME}
##############################################################################


##############################################################################
prompt_user_to_continue  "Creating the script for running the cstrike server"
RUN_SCRIPT_FILENAME="run_cstrike_server.sh"
cat > /home/${STEAM_USER}/${RUN_SCRIPT_FILENAME} <<EOF
#!/bin/bash
pushd /home/${STEAM_USER}/cstrike
./hlds_run -game cstrike +ip 0.0.0.0 +maxplayers ${CSTRIKE_MAX_PLAYERS} +map ${CSTRIKE_DEFAULT_MAP} +port ${CSTRIKE_PORT}
popd
EOF
chown ${STEAM_USER}:${STEAM_USER} /home/${STEAM_USER}/${RUN_SCRIPT_FILENAME}
chmod 700 /home/${STEAM_USER}/${RUN_SCRIPT_FILENAME}
##############################################################################


##############################################################################
prompt_user_to_continue  "Creating server.cfg file"
SERVER_CFG_FILENAME="server.cfg"
cat > /home/${STEAM_USER}/cstrike/cstrike/${SERVER_CFG_FILENAME} <<EOF
hostname "${CSTRIKE_HOSTNAME}"
rcon_password "${CSTRIKE_RCON_PASSWORD}"
sv_password ""
sv_contact "${CSTRIKE_EMAIL}"
mp_friendlyfire 1
mp_footsteps 1
mp_autoteambalance 1
mp_autokick 1
mp_flashlight 1
mp_tkpunish 1
mp_forcecamera 0
mp_limitteams 2
mp_hostagepenalty 0
mp_allowspectators 1
allow_spectators 1
mp_timelimit 20
mp_chattime 10
sv_cheats 0
sv_aim 0
sv_allowupload 1
sv_allowdownload 1
sv_maxspeed 320
sv_gravity 800
pausable 0
mp_freezetime 4
mp_roundtime 2
mp_buytime 0.5
mp_playerid 0
mp_fadetoblack 0
mp_forcechasecam 0
mp_forcecamera 0
mp_kickpercent 50
mp_startmoney 16000
mp_c4timer 35
mp_fraglimit 0
mp_maxrounds 0
mp_winlimit 0
sv_rate 100000
sv_minrate 25000
sv_maxrate 100000
sv_minupdaterate 100
sv_maxupdaterate 101
decalfrequency 30
log on
mp_logdetail 3
mp_logmessages 1
sv_logbans 1
sv_logecho 1
sv_logfile 1
sv_log_onefile 0
sv_lan 0
sv_region 255
setmaster add 208.64.200.52
setmaster add 208.64.200.65
setmaster add 208.64.200.117
setmaster add 208.64.200.118
setmaster add 208.64.201.242
heartbeat
EOF
chown ${STEAM_USER}:${STEAM_USER} /home/${STEAM_USER}/cstrike/cstrike/${SERVER_CFG_FILENAME}
chmod 600 /home/${STEAM_USER}/cstrike/cstrike/${SERVER_CFG_FILENAME}
##############################################################################


##############################################################################
prompt_user_to_continue  "Creating mapcycle.txt file"
MAPCYCLE_TXT_FILENAME="mapcycle.txt"
cat > /home/${STEAM_USER}/cstrike/cstrike/${MAPCYCLE_TXT_FILENAME} <<EOF
de_dust2
cs_backalley
de_prodigy
cs_estate
de_train
de_airstrip
de_aztec
cs_siege
de_storm
as_oilrig
de_nuke
cs_assault
cs_italy
de_dust
de_cbble
cs_havana
cs_747
de_vertigo
de_survivor
cs_militia
cs_office
de_piranesi
de_chateau
de_torn
de_inferno
EOF
chown ${STEAM_USER}:${STEAM_USER} /home/${STEAM_USER}/cstrike/cstrike/${MAPCYCLE_TXT_FILENAME}
chmod 600 /home/${STEAM_USER}/cstrike/cstrike/${MAPCYCLE_TXT_FILENAME}
##############################################################################


##############################################################################
prompt_user_to_continue  "Creating motd.txt file"
MOTD_TXT_FILENAME="motd.txt"
cat > /home/${STEAM_USER}/cstrike/cstrike/${MOTD_TXT_FILENAME} <<EOF
<!DOCTYPE HTML>
<html>
<head>
<meta charset="UTF-8">
<title>cs.kife.net</title>
<style type="text/css">
       body {
            background: #000;
            margin: 8px;
            color: #FFB000;
            font: normal 16px/20px Verdana, Tahoma, sans-serif;
        }

        a {
            color: #FFF;
            text-decoration: underline;
        }

        a:hover {
            color: #EEE;
            text-decoration: none;
        }
</style>
</head>
<body>
You are playing Counter-Strike v1.6<br>
Rules:<br>
No Cheating.<br>
Respect all other players and admins.<br>
</body>
</html>
EOF
chown ${STEAM_USER}:${STEAM_USER} /home/${STEAM_USER}/cstrike/cstrike/${MOTD_TXT_FILENAME}
chmod 600 /home/${STEAM_USER}/cstrike/cstrike/${MOTD_TXT_FILENAME}
##############################################################################


##############################################################################
prompt_user_to_continue  "Creating empty banlist files"
BANLIST_FILENAMES="listip.cfg banned.cfg"
for f in ${BANLIST_FILENAMES}
do
    touch /home/${STEAM_USER}/cstrike/cstrike/${f}
    chown ${STEAM_USER}:${STEAM_USER} /home/${STEAM_USER}/cstrike/cstrike/${f}
    chmod 600 /home/${STEAM_USER}/cstrike/cstrike/${f}
done
##############################################################################

