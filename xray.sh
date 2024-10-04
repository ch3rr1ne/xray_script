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
#xray 配置
function _xray_config() {
    curl -H "Authorization: Bearer "${token}"" -Lo /usr/local/etc/xray/config.json "$xray_config"
}
#安装nginx
function _install_nginx() {
    apt update -y 
    apt install -y gnupg2 ca-certificates lsb-release debian-archive-keyring curl wget
    get_nginx
    apt install -y nginx
    mkdir -p /etc/systemd/system/nginx.service.d && echo -e "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf && systemctl daemon-reload
}
#安装Xray
function _install_xray(){
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta
systemctl restart xray && systemctl restart nginx && sleep 0.2 && systemctl status xray && systemctl status nginx
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
    _install_nginx
    _install_xray
    sleep 0.2
    _xray_config
    _kernel
    sleep 0.2
    systemctl restart xray
    sleep 0.2
    clear
    systemctl status xray
    systemctl status nginx && nginx -t
}

function Sone (){
nginx='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/nginx.conf'
kernel='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/sysctl.conf'
xray_config='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/config_server.json'
}

all
