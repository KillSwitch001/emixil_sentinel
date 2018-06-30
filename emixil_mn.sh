echo "==================================================================" 
echo "Emixil Masternode Install"
echo "=================================================================="

echo "Installing packages and updates..."
sudo add-apt-repository ppa:bitcoin/bitcoin -y
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get dist-upgrade -y
sudo apt-get install git -y
sudo apt-get install nano -y
sudo apt-get install pwgen -y
sudo apt-get install dnsutils -y
sudo apt-get install wget -y
sudo apt-get install build-essential libtool autotools-dev automake pkg-config libssl-dev libevent-dev bsdmainutils -y
sudo apt-get install libboost-system-dev libboost-filesystem-dev libboost-chrono-dev libboost-program-options-dev libboost-test-dev libboost-thread-dev -y
sudo apt-get install libboost-all-dev -y
sudo apt-get install software-properties-common -y
sudo apt-get update -y
sudo apt-get install libdb4.8-dev libdb4.8++-dev -y
sudo apt-get install libminiupnpc-dev -y
sudo apt-get install libzmq3-dev -y

echo "Packages complete"

WALLET_VERSION='1.0.0'
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
PASSWORD=`pwgen -1 20 -n`

echo "Setting up disk swap..."
free -h
sudo fallocate -l 4G /swapfile
ls -lh /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab sudo bash -c "
echo 'vm.swappiness = 10' >> /etc/sysctl.conf"
free -h
echo "SWAP setup complete"

wget https://github.com/emixil/emixil/releases/download/v${WALLET_VERSION}/ubuntu-16.04.tar.xz

rm -rf emixil
mkdir emixil
tar xf ubuntu-16.04.tar.xz -C emixil

echo "Loading and syncing wallet"

echo "If you see *error: Could not locate RPC credentials* message, do not worry"
~/emixil/emixil-cli stop
sleep 10
echo ""
echo "=================================================================="
echo "DO NOT CLOSE THIS WINDOW OR TRY TO FINISH THIS PROCESS "
echo "PLEASE WAIT 5 MINUTES UNTIL YOU SEE THE RELOADING WALLET MESSAGE"
echo "=================================================================="
echo ""
~/emixil/emixild -daemon
sleep 250
~/emixil/emixil-cli stop
sleep 20

echo "Reloading wallet..."
~/emixil/emixild -daemon
sleep 30

echo -n "Enter your masternode genkey: "
read GENKEY

~/emixil/emixil-cli stop

echo "Creating final config..."

cat <<EOF > ~/.emixilcore/emixil.conf
rpcuser=emixiluser
rpcpassword=$PASSWORD
rpcallowip=127.0.0.1
server=1
daemon=1
listen=1
rpcport=43435
port=43434
externalip=$WANIP
maxconnections=256
masternode=1
masternodeprivkey=$GENKEY
addnode=207.246.82.117
addnode=149.28.56.85
addnode=149.28.163.173
addnode=95.179.162.157
addnode=202.182.122.129
EOF

sleep 61

echo "Restarting wallet with new configs, 30 seconds..."
~/emixil/emixild -daemon
sleep 30

echo "Installing sentinel..."
cd /root/.emixilcore
sudo apt-get install -y git python-virtualenv

sudo git clone https://github.com/emixil/emixil_sentinel.git

cd emixil_sentinel

export LC_ALL=C
sudo apt-get install -y virtualenv

virtualenv ./venv
./venv/bin/pip install -r requirements.txt

echo "emixil_conf=/root/.emixilcore/emixil.conf" >> /root/.emixilcore/emixil_sentinel/sentinel.conf

echo "Adding crontab jobs..."
crontab -l > tempcron
#echo new cron into cron file
echo "* * * * * cd /root/.emixilcore/emixil_sentinel && ./venv/bin/python bin/sentinel.py >/dev/null 2>&1" >> tempcron
echo "@reboot /bin/sleep 20 ; /root/emixil/emixild -daemon &" >> tempcron

#install new cron file
crontab tempcron
rm tempcron

SENTINEL_DEBUG=1 ./venv/bin/python bin/sentinel.py
echo "Sentinel Installed"
sleep 15


echo "Masternode status:"
~/emixil/emixil-cli masternode status

echo "If you get \"Masternode not in masternode list\" status, don't worry, you just have to start your MN from your local wallet and the status will change"
echo ""
echo "INSTALLED WITH VPS IP: $WANIP:43434"
sleep 1
echo "INSTALLED WITH MASTERNODE PRIVATE GENKEY: $GENKEY"
sleep 1
echo "rpcuser=emixiluser"
echo "rpcpassword=$PASSWORD"
