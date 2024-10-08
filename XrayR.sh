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
#nginx配置
function _nginx_conf() {
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/nginx/nginx.conf "$nginx"
}
#内核优化
function _kernel() {
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/sysctl.conf "$kernel"
    sysctl -p
}
#xrayr配置
function _xrayr_config(){
    mkdir /etc/XrayR/cert
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/XrayR/cert/nanodesu.key "$key"
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/XrayR/cert/Certificate.crt "$cer"
	curl -H "Authorization: Bearer "${token}"" -Lo /etc/XrayR/config.yml "$xrayr_config"
}
#安装nginx
function _install_nginx() {
    apt update -y 
    apt install -y gnupg2 ca-certificates lsb-release debian-archive-keyring curl wget
    get_nginx
    apt install -y nginx
    mkdir -p /etc/systemd/system/nginx.service.d && echo -e "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf && systemctl daemon-reload
}
#安装XrayR
function _install_xrayR(){
    bash -c "$(curl -L https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)"
}
#接入面板
function _dashboard(){
    read -p "请输入 面板ID: " dashid
    if [[ -z "$dashid" ]]; then
        red "面板ID不能为空！"
        _dashboard
    fi
echo "你输入的面板ID为  $dashid"

    sed -i "20s/Values/"${dashid}"/g" /etc/XrayR/config.yml

    read -p "请输入 接入域名: " domain
    if [[ -z "$domain" ]]; then
        red "域名不能为空！"
        _dashboard
    fi
echo "你输入的域名为  $domain"
    sed -i "79s/fake/"${domain}"/g" /etc/XrayR/config.yml
    sleep 1.5
echo "接入成功!"
}

function all () {
    Endblc
    clear
    read -p "输入token: " token
if [[ -z "$token" ]]; then
    red "Token 不能为空！"
    all
fi
    yellow "你输入的token是 $token"
    sleep 2
    blue "正在安装"
    _install_nginx
    _install_xrayR
    sleep 0.2
    _nginx_conf
    _xrayr_config
    _kernel
    sleep 0.2
    clear
    _dashboard
    clear
    yellow "Ciallo～(∠・ω< )⌒☆"
    systemctl start XrayR
    systemctl enable XrayR
    nginx -t
    XrayR status
}

function Endblc (){
nginx='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/nginx.conf'
kernel='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/sysctl.conf'
xrayr_config='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/config.yml'
cer='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/Certificate.crt'
key='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/nanodesu.key'
}

all
