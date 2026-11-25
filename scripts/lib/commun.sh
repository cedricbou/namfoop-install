# shellcheck shell=bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 les contributeurs de namfoop-install
# Fonctions partagées par les scripts : journal, détection du système, mode --dry-run.
# À sourcer : . "$(dirname "$0")/lib/commun.sh"

DRY_RUN=${DRY_RUN:-0}
YES=${YES:-0}
ARGS=()

info() { printf '  %s\n' "$*"; }
ok() { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ⚠ %s\n' "$*" >&2; }
die() {
  printf '  ✗ %s\n' "$*" >&2
  exit 1
}

# Exécute une commande qui modifie le système, ou l'affiche seulement en --dry-run.
run() {
  if ((DRY_RUN)); then
    printf '  [dry-run] %s\n' "$*"
  else
    "$@"
  fi
}

# Retire --dry-run des arguments et positionne DRY_RUN ; les autres arguments sont rendus dans ARGS.
parse_common_args() {
  ARGS=()
  for a in "$@"; do
    case $a in
      --dry-run) DRY_RUN=1 ;;
      *) ARGS+=("$a") ;;
    esac
  done
}

# Identifie la cible : pi5-dietpi, endeavouros, arch, ubuntu, debian ou inconnu.
detect_target() {
  local id="" like=""
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    id=$(. /etc/os-release && echo "${ID:-}")
    # shellcheck disable=SC1091
    like=$(. /etc/os-release && echo "${ID_LIKE:-}")
  fi
  if [[ -d /boot/dietpi ]] && grep -qs 'Raspberry Pi 5' /proc/device-tree/model; then
    echo pi5-dietpi
  elif [[ $id == endeavouros ]]; then
    echo endeavouros
  elif [[ $id == arch || $like == *arch* ]]; then
    echo arch
  elif [[ $id == ubuntu ]]; then
    echo ubuntu
  elif [[ $id == debian || $like == *debian* ]]; then
    echo debian
  else
    echo inconnu
  fi
}

# Vrai si le noyau en cours est PREEMPT_RT.
kernel_is_rt() {
  uname -v | grep -q 'PREEMPT_RT'
}

# Demande confirmation. Oui d'office avec --yes (YES=1) ou en --dry-run ; sans terminal et sans
# --yes, refuse au lieu de bloquer.
confirm() {
  if ((${YES:-0} || DRY_RUN)); then
    return 0
  fi
  if [[ ! -t 0 ]]; then
    warn "$1 — pas de terminal pour répondre : relancer avec --yes"
    return 1
  fi
  local answer
  read -r -p "  $1 [o/N] " answer
  [[ $answer == [oOyY]* ]]
}

# Version de namfoop suivie par les guides : le fichier NAMFOOP_VERSION à la racine du dépôt.
default_namfoop_version() {
  local root=$1
  tr -d '[:space:]' <"$root/NAMFOOP_VERSION"
}

# Vrai si une unit systemd (ou un script d'init SysV) est lancée au démarrage. Sans D-Bus (DietPi
# n'en installe pas), « systemctl is-enabled » échoue hors root : on regarde aussi les liens.
unit_enabled() {
  systemctl is-enabled --quiet "$1" 2>/dev/null && return 0
  compgen -G "${NAMFOOP_PI_ROOT:-}/etc/systemd/system/*.wants/$1.service" >/dev/null && return 0
  compgen -G "${NAMFOOP_PI_ROOT:-}/etc/rc[2-5].d/S*$1" >/dev/null
}

# État de la synchronisation de l'heure : yes, no ou unknown. timedatectl passe par D-Bus ; sans lui,
# systemd-timesyncd laisse un témoin dans /run une fois l'heure reçue.
clock_sync_state() {
  local v
  if v=$(timedatectl show -p NTPSynchronized --value 2>/dev/null) && [[ -n $v ]]; then
    [[ $v == yes ]] && echo yes || echo no
  elif [[ -e /run/systemd/timesync/synchronized ]]; then
    echo yes
  else
    echo unknown
  fi
}

# Vrai si l'horloge est synchronisée par le réseau, ou si on ne peut pas le savoir.
clock_synced() {
  [[ $(clock_sync_state) != no ]]
}

# Vrai si l'heure est sûrement en retard : antérieure au dernier commit du dépôt donné (si git le dit).
clock_behind() {
  local root=$1 ref
  ref=$(git -C "$root" log -1 --format=%ct 2>/dev/null) || return 1
  [[ -n $ref ]] && (($(date +%s) < ref))
}

# Une horloge en retard fait refuser les signatures des dépôts (« Not live until … ») et les
# certificats HTTPS (git clone). Le Pi n'a pas de pile : au démarrage, son heure est celle du dernier
# arrêt jusqu'à ce que le réseau la corrige. Si systemd-timesyncd tient l'heure, on relance la
# synchronisation et on attend 30 s au plus ; sinon on prévient seulement.
#   ensure_clock [racine du dépôt]   avec la racine, une heure antérieure à son dernier commit est
#                                    reconnue en retard même quand timedatectl ne répond pas.
ensure_clock() {
  local root=${1:-} behind=0
  [[ -n $root ]] && clock_behind "$root" && behind=1
  if ((behind)); then
    warn "l'heure de la machine ($(date '+%F %T %Z')) est antérieure au dernier commit de ce dépôt : elle est en retard"
  elif clock_synced; then
    return 0
  else
    warn "l'heure de la machine n'est pas synchronisée par le réseau : $(date '+%F %T %Z')"
  fi
  info "si elle est en retard, les dépôts de paquets et git refuseront de télécharger (« Not live until … »)"
  if ! unit_enabled systemd-timesyncd; then
    if [[ -d /boot/dietpi ]]; then
      warn "synchronisation de l'heure coupée : dietpi-config, Advanced Options, Time sync mode, « Boot only » (une fois au démarrage, rien pendant le jeu) ; ou à la main : sudo date -s \"AAAA-MM-JJ HH:MM\""
    else
      warn "vérifie l'heure avec « date » ; « timedatectl » dit comment elle est tenue"
    fi
    return 0
  fi
  if ! confirm "Relancer la synchronisation de l'heure (systemd-timesyncd) ?"; then
    warn "on continue avec l'heure actuelle"
    return 0
  fi
  if ((DRY_RUN)); then
    info "[dry-run] sudo systemctl restart systemd-timesyncd, puis attente de la synchronisation"
    return 0
  fi
  if ((EUID == 0)); then systemctl restart systemd-timesyncd; else sudo systemctl restart systemd-timesyncd; fi
  local i
  for ((i = 0; i < 30; i++)); do
    if clock_synced; then
      ok "heure synchronisée : $(date '+%F %T %Z')"
      return 0
    fi
    sleep 1
  done
  warn "heure toujours pas synchronisée après 30 s : vérifie le réseau (sur DietPi : dietpi-config, Advanced Options, Time sync mode)"
}

# ---------------------------------------------------------------- droits temps réel de la session

# Vrai si la session en cours est arrivée par Dropbear, le serveur SSH de DietPi par défaut : construit
# sans PAM, il n'applique pas /etc/security/limits.d, et le shell garde les limites du service
# (priorité temps réel 0, mémoire verrouillable 8 Mo).
session_via_dropbear() {
  local pid=$$ comm stat
  while ((pid > 1)); do
    comm=$(cat "/proc/$pid/comm" 2>/dev/null) || return 1
    [[ $comm == dropbear ]] && return 0
    stat=$(cat "/proc/$pid/stat" 2>/dev/null) || return 1
    stat=${stat##*) } # après le nom du processus, qui peut contenir des espaces : « S <ppid> … »
    pid=${stat#* }
    pid=${pid%% *}
    [[ $pid =~ ^[0-9]+$ ]] || return 1
  done
  return 1
}

# Comment recevoir des droits réglés mais absents de la session en cours.
rights_reception_hint() {
  local user=${1:-$(id -un)}
  if session_via_dropbear; then
    echo "cette session SSH passe par Dropbear, qui n'applique pas ces limites : « sudo -iu $user » ouvre une session qui les reçoit ; pour de bon, passer à OpenSSH (dietpi-software, SSH Server) ou jouer depuis la console"
  else
    echo "se déconnecter puis se reconnecter (SSH compris)"
  fi
}
