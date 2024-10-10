#! /bin/bash
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
    }
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}

#获取最新nginx
function get_nginx() {
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx
}

#内核优化
function _kernel() {
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/sysctl.conf "$kernel"
    sysctl -p
}

#安装nginx
function _install_nginx() {
    apt update -y 
    apt install -y gnupg2 ca-certificates lsb-release debian-archive-keyring curl wget
    get_nginx
    apt install -y nginx
    mkdir -p /etc/systemd/system/nginx.service.d
    echo -e "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/nginx/nginx.conf "$nginx"
    systemctl daemon-reload
}
#安装Xray
function _install_xray(){
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta
    curl -H "Authorization: Bearer "${token}"" -Lo /usr/local/etc/xray/config.json "$xray_config"
}

#安装全套
function all () {
    Sone
    clear
    read -p "输入token: " token
if [[ -z "$token" ]]; then
    red "Token 不能为空！"
    all
fi
    yellow "你输入的token是 $token"
    sleep 2
    blue "正在安装"
    check_install_nginx
    sleep 0.2
    _install_xray
    sleep 0.2
    _kernel
    ini_xray
    systemctl restart xray
    systemctl restart nginx
    sleep 0.2
    clear
    yellow "xray.service"
    systemctl status xray |grep Active
    yellow "nginx.service"
    systemctl status nginx |grep Active
    nginx -t
    output

}

function Sone (){
nginx='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/nginx.conf'
kernel='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/sysctl.conf'
xray_config='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/config_server.json'
}

 #适配宝塔
 function check_install_nginx(){
if [[ -d "/www" ]]; then
    curl -H "Authorization: Bearer "${token}"" -Lo /www/server/nginx/conf/nginx.conf.bak https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/BtPanel_nginx.conf
    mv /www/server/nginx/conf/nginx.conf.bak /www/server/nginx/conf/nginx.conf
    systemctl restart nginx
else
    _install_nginx
    fi
 }

#xray生成
function ini_xray (){
uuid=$(xray uuid)
sed -i "2s/xray/$uuid/" /usr/local/etc/xray/config.json
sleep 0.2
key=$(xray x25519)
pkey=$(echo "$key" | grep "Public key:" | cut -d' ' -f3-)
skey=$(echo "$key" | grep "Private key:" | cut -d' ' -f3-)
sed -i "59s/key/$skey/" /usr/local/etc/xray/config.json
sleep 0.2
shortid=$(openssl rand -hex 4)
sed -i "65s/sid/$shortid/" /usr/local/etc/xray/config.json
#定义
if command -v ifconfig >/dev/null 2>&1; then
ip=$(ifconfig -a|grep inet|grep -v 127.0.0.1|grep -v inet6|awk '{print $2}'|tr -d "addr:")
else
ip=$(ip addr show eth0 | grep inet | awk '{print $2}' | cut -d'/' -f1)
fi
port=$(awk 'NR==35 {print $2}' /usr/local/etc/xray/config.json)
flow=$(awk 'NR==41 {print $2}' /usr/local/etc/xray/config.json)
tls=$(awk 'NR==49 {print $2}' /usr/local/etc/xray/config.json)
sni=$(sed -n '53p' /usr/local/etc/xray/config.json | cut -d':' -f2 | cut -d':' -f1 | tr -d ' "')
fingerprint=$(awk 'NR==51 {print $2}' /usr/local/etc/xray/config.json)
}

#输出
function output(){
echo "IP=$ip"
echo "端口=$port"
echo "UUID=$uuid"
echo "flow=$flow"
echo "tls=$tls"
echo "SNI=$sni"
echo "fingerprint=$fingerprint"
echo "Public key=$pkey"
echo "shortid=$shortid"
}

all
