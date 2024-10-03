#! /bin/bash
# Write By Sone
#https://github.com/ch3rr1ne

#定义Github token
OAUTHTOKEN='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'

#定义地址
nginx='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/nginx.conf'
kernel='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/sysctl.conf'
xray_config='https://raw.githubusercontent.com/ch3rr1ne/reality/refs/heads/main/config_server.json'

#颜色
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
    }
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
    }
white(){
    echo -e "\033[37m\033[01m$1\033[0m"
    }

#最新nginx
function get_nginx() {
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor > /usr/share/keyrings/nginx-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] http://nginx.org/packages/mainline/debian `lsb_release -cs` nginx" > /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" > /etc/apt/preferences.d/99nginx
}

#nginx
function _nginx() {
    curl -H "Authorization: Bearer "${OAUTHTOKEN}"" -Lo /etc/nginx/nginx.conf "$nginx"
}

#内核
function _kernel() {
    curl -H "Authorization: Bearer "${OAUTHTOKEN}"" -Lo /etc/sysctl.conf "$kernel"
}

#xray config
function xray_config() {
    curl -H "Authorization: Bearer "${OAUTHTOKEN}"" -Lo /usr/local/etc/xray/config.json "$xray_config"
}

#环境
function _os() {
  local os=""
  [[ -f "/etc/debian_version" ]] && source /etc/os-release && os="${ID}" && printf -- "%s" "${os}" && return
  [[ -f "/etc/redhat-release" ]] && os="centos" && printf -- "%s" "${os}" && return
}

function _install() {
  local packages_name="$@"
  case "$(_os)" in
  centos)
    if _exists "dnf"; then
      dnf update -y
      dnf install -y dnf-plugins-core
      dnf update -y
      dnf install -y gnupg2 ca-certificates lsb-release debian-archive-keyring curl wget
      get_nginx
      dnf install -y nginx
      for package_name in ${packages_name}; do
        dnf install -y ${package_name}
      done
    else
      yum update -y
      yum install -y epel-release yum-utils
      yum update -y
      yum install -y gnupg2 ca-certificates lsb-release debian-archive-keyring curl wget
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
}
function all () {
    _install
    sleep 1
    _kernel
    sleep 1
    xray_config
    sleep 1
    _nginx
    clear
    echo "安装完成"
}


#开始
function menu() 
{
clear
green " 1. 安装环境"
green " 2. 配置nginx"
green " 3. 配置xray"
green " 4. 内核调优"
green " 5. 安装Xray"
green " 6. 安装XrayR"
red " 9. 我全都要"
white " 0. 我不要了"
echo
read -p "请输入数字:" NumberInput
 case "$NumberInput" in
    1 )
        _install
;;
    2 )
        _nginx
;;
    3 )
        xray_config
;;
    4 )
        _kernel
;;
    9 )
        all
;;
    0 )
        exit 0
;;
        * )
        clear
        red "吗的，输入数字啊"
        menu
        ;;
 esac
}

menu