#!/usr/bin/env bash
source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
# Copyright (c) 2021-2025 tteck
# Author: tteck (tteckster) | Co-Author: remz1337
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Combined installer for FlareSolverr + Prowlarr

APP="FlareSolverr-Prowlarr-Wireguard"
var_tags="${var_tags:-arr,proxy,vpn}"
var_cpu="${var_cpu:-2}"
var_ram="${var_ram:-2048}"
var_disk="${var_disk:-8}"
var_os="${var_os:-debian}"
var_version="${var_version:-13}"
var_unprivileged="${var_unprivileged:-1}"

header_info "$APP"
variables
color
catch_errors

function update_script() {
  header_info
  check_container_storage
  check_container_resources

  # Check if applications are installed
  FLARESOLVERR_INSTALLED=false
  PROWLARR_INSTALLED=false
  WIREGUARD_INSTALLED=false
  
  if [[ -f /etc/systemd/system/flaresolverr.service ]]; then
    FLARESOLVERR_INSTALLED=true
  fi
  
  if [[ -d /var/lib/prowlarr/ ]]; then
    PROWLARR_INSTALLED=true
  fi
  
  if [[ -f /etc/wireguard/wg0.conf ]] || command -v wg &> /dev/null; then
    WIREGUARD_INSTALLED=true
  fi
  
  if [[ "$FLARESOLVERR_INSTALLED" == false && "$PROWLARR_INSTALLED" == false && "$WIREGUARD_INSTALLED" == false ]]; then
    msg_error "No FlareSolverr, Prowlarr, or Wireguard Installation Found!"
    exit
  fi
  
  if [[ $(grep -E '^VERSION_ID=' /etc/os-release) == *"12"* ]]; then
    msg_error "Wrong Debian version detected!"
    msg_error "You must upgrade your LXC to Debian Trixie before updating."
    exit
  fi
  
  # Update FlareSolverr if installed
  if [[ "$FLARESOLVERR_INSTALLED" == true ]]; then
    if check_for_gh_release "flaresolverr" "FlareSolverr/FlareSolverr"; then
      msg_info "Updating FlareSolverr - Stopping service"
      systemctl stop flaresolverr
      msg_ok "Stopped FlareSolverr service"

      rm -rf /opt/flaresolverr
      fetch_and_deploy_gh_release "flaresolverr" "FlareSolverr/FlareSolverr" "prebuild" "latest" "/opt/flaresolverr" "flaresolverr_linux_x64.tar.gz"

      msg_info "Starting FlareSolverr service"
      systemctl start flaresolverr
      msg_ok "Started FlareSolverr service"
      msg_ok "FlareSolverr updated successfully!"
    fi
  fi
  
  # Update Prowlarr if installed
  if [[ "$PROWLARR_INSTALLED" == true ]]; then
    if check_for_gh_release "prowlarr" "Prowlarr/Prowlarr"; then
      msg_info "Updating Prowlarr - Stopping service"
      systemctl stop prowlarr
      msg_ok "Stopped Prowlarr service"

      rm -rf /opt/Prowlarr
      fetch_and_deploy_gh_release "prowlarr" "Prowlarr/Prowlarr" "prebuild" "latest" "/opt/Prowlarr" "Prowlarr.master*linux-core-x64.tar.gz"
      chmod 775 /opt/Prowlarr

      msg_info "Starting Prowlarr service"
      systemctl start prowlarr
      msg_ok "Started Prowlarr service"
      msg_ok "Prowlarr updated successfully!"
    fi
  fi
  
  exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access the services using the following URLs:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}FlareSolverr: http://${IP}:8191${CL}"
echo -e "${TAB}${GATEWAY}${BGN}Prowlarr: http://${IP}:9696${CL}"
