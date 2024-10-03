#! /bin/bash
# Write By Sone
#https://github.com/ch3rr1ne

#颜色
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
    }
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
    }
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
white(){
    echo -e "\033[37m\033[01m$1\033[0m"
    }
#错误
function _wrongNumber() {
  red "吗的。填上面的数字啊"
  exit 0
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
#xrayr配置
function _xrayr_config(){
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/XrayR/cert/nanodesu.key "$key"
    curl -H "Authorization: Bearer "${token}"" -Lo /etc/XrayR/cert/Certificate.crt "$cer"
white " 1. VISION-TLS"
white " 2. VISION-REALITY"
read -p "请选择: [默认:VISION-TLS]" conf
[ -z "${conf}" ] && conf="1"
	if [[ $conf == [1] ]]; then
		curl -H "Authorization: Bearer "${token}"" -Lo etc/XrayR/config.json "$xrayr_config"
	elif  [[ "$conf" == "2" ]]; then
        curl -H "Authorization: Bearer "${token}"" -Lo /etc/XrayR/config.yml "$reality_config"
    else 
echo "吗的,选1或者2啊"
    fi   
}

#环境
function _os() {
  local os=""
  [[ -f "/etc/debian_version" ]] && source /etc/os-release && os="${ID}" && printf -- "%s" "${os}" && return
  [[ -f "/etc/redhat-release" ]] && os="centos" && printf -- "%s" "${os}" && return
}
function _egg(){
red "我"; green "要"; yellow "打";blue "OSU";white "!"   
}
function _install_nginx() {
  local packages_name="$@"
  case "$(_os)" in
  centos)
    if _exists "dnf"; then
      dnf update -y
      dnf install -y dnf-plugins-core
      dnf update -y
      dnf install -y gnupg2 ca-certificates curl wget
      get_nginx
      dnf install -y nginx
      for package_name in ${packages_name}; do
        dnf install -y ${package_name}
      done
    else
      yum update -y
      yum install -y epel-release yum-utils
      yum update -y
      yum install -y gnupg2 ca-certificates curl wget
      get_nginx
      yum install -y nginx
      for package_name in ${packages_name}; do
        yum install -y ${package_name}
      done
    fi
    ;;
  ubuntu | debian)
    apt update -y 
    apt install -y gnupg2 ca-certificates lsb-release debian-archive-keyring curl wget
    get_nginx
    apt install -y nginx
    for package_name in ${packages_name}; do
    apt install -y ${package_name}
    done
    ;;
  esac
    mkdir -p /etc/systemd/system/nginx.service.d && echo -e "[Service]\nExecStartPost=/bin/sleep 0.1" > /etc/systemd/system/nginx.service.d/override.conf && systemctl daemon-reload
}

#安装Xray
function _install_xray(){
if [[ -z "${xray_config}" ]]; then
echo "你装错了"
    exit 0
fi
if [[ -z "${xrayr_config}" ]]; then
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install --beta
systemctl restart xray && systemctl restart nginx && sleep 0.2 && systemctl status xray && systemctl status nginx
fi
}

#安装XrayR
function _install_xrayR(){
    if [[ -z "${xray_config}" ]]; then
    bash -c "$(curl -L https://raw.githubusercontent.com/XrayR-project/XrayR-release/master/install.sh)"
fi
if [[ -z "${xrayr_config}" ]]; then
echo "你装错了"
    exit 0
    fi
}

#接入面板
function _dashboard(){
    read -p "请输入 面板ID: " dashid
    if [[ -z "$dashid" ]]; then
        red "面板ID不能为空！"
        _dashboard
    fi
echo "你输入的面板ID为 $dashid"

    sed -i "20s/Values/${dashid}/g" /etc/XrayR/config.yml

    read -p "请输入 接入域名: " domain
    if [[ -z "$domain" ]]; then
        red "域名不能为空！"
        _dashboard
    fi
echo "你输入的域名为 $domain"
    sed -i "79s/fake/${domain}/g" /etc/XrayR/config.yml
echo "接入成功!"
}

function all () {
    _install_nginx
    sleep 0.5
if [[ -z "${xray_config}" ]]; then
    _install_xrayR
    _xrayr_config
fi
if [[ -z "${xrayr_config}" ]]; then
    _install_xray
    _xray_config
fi
    sleep 0.5
    _kernel
    sleep 0.5
    _nginx_conf
    clear
    echo "安装完成！"
    systemctl restart xray && systemctl restart nginx && sleep 0.2 && systemctl status xray && systemctl status nginx && nginx -t
}

#卸载
function _uninstall (){
 echo "卸载xray"
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
    systemctl stop nginx && apt purge -y nginx && rm -r /etc/systemd/system/nginx.service.d/
  echo "卸载xrayR"
    xrayr uninstall
    rm /usr/bin/XrayR -f
}
#下载配置
function _config(){
    # 下载 nginx 和内核优化配置
    _nginx_conf
    _kernel
if [[ -z "${xray_config}" ]]; then
    _xrayr_config
fi
if [[ -z "${xrayr_config}" ]]; then
     _xray_config
fi
}
function Sone (){
nginx='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/nginx.conf'
kernel='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/sysctl.conf'
xray_config='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/config_server.json'
}
function Endblc (){
nginx='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/nginx.conf'
kernel='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/sysctl.conf'
xrayr_config='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/config.yml'
reality_config='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/reality.yml'
cer='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/Certificate.crt'
key='https://raw.githubusercontent.com/Endblc/xcfg/refs/heads/main/nanodesu.key'
}

#更改配置
function _change (){
echo "持续更新中..."
exit 0
}

#开始
function menu() 
{
clear
read -p "请先填入你的token: " token
blue "-----请先选择你的英雄-----"
white " 1. Sone"
white " 2. Endblc"
read -p "请选择:" hero
 case "$hero" in
    1 )
        Sone
;;
    2 )
        Endblc
;;
    * )
    _wrongNumber
;;
esac
clear

green " 1. 安装nginx"
green " 2. 安装Xray"
green " 3. 安装XrayR"
green " 4. 内核调优"
green " 5. 下载配置"
green " 6. 接入面板"
green " 7. 更改配置" 
green " 8. 介是嘛呀"
yellow " =================================================="
blue " 9.  我全都要安装"
red " 00. 全给我卸载了"
white " 0.  退出脚本"
echo
read -p "请输入数字:" NumberInput
 case "$NumberInput" in
    1 )
        _install_nginx
;;
    2 )
        _install_xray
;;
    3 )
        _install_xrayR
;;
    4 )
        _kernel
;;
    5 )
        _config
;;
    6 )
        _dashboard
;;
    7 )
        _change
;;
    8 )
        _egg
;;
    9 )
        all
;;
    00 )
        _uninstall
;;
    0 )
        exit 0
;;
        *)
    _wrongNumber
        ;;
 esac
}
[[ $EUID -ne 0 ]] && echo "请以root用户运行"
menu