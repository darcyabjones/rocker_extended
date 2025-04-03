#!/usr/bin/env bash

set -euo pipefail

# Generate a random password
PASSWORD=$(echo "${RANDOM}" | md5sum | head -c 10 ; echo)
PORT=$(python3 -c "import socket; s = socket.socket(); s.bind(('', 0)); print(s.getsockname()[1]); s.close()")
SIF="${RSTUDIO_APPTAINER_DEFAULT_IMAGE:-${RSTUDIO_SINGULARITY_DEFAULT_IMAGE:-}}"

SESSIONDIR_="${RSTUDIO_APPTAINER_DEFAULT_SESSIONDIR:-${RSTUDIO_SINGULARITY_DEFAULT_SESSIONDIR:-}}"
SESSIONDIR=

NOCLEANUP=

usage() {
   echo -e 'USAGE:
rstudio_session.sh --port 8788 --password helpme --sif path/to/image.sif
'
}


while [[ $# -gt 0 ]]
do
  key="$1"

  case $key in
    -h|--help)
      usage
      help
      exit 0
      ;;
    --password)
      PASSWORD="$2"
      shift 2
      ;;
    -p|--port)
      PORT="$2"
      shift 2
      ;;
    --sif)
      SIF="$2"
      shift 2
      ;;
    --session-dir)
      SESSIONDIR="$2"
      shift 2
      ;;
    --no-cleanup)
      NOCLEANUP=true
      shift
      ;;
    *)
      echo "ERROR: invalid parameter ${key}" 1>&2
      usage 1>&2
      exit 1
  esac
done

USER_="$(whoami)"

PORTS_IN_USE=$(ss -tulw | awk 'NR > 1 {print gensub(/.*:([^:]+)$/, "\\1", "g", $5)}')

if echo "${PORTS_IN_USE}" | grep -x "${PORT}" > /dev/null
then
  echo "ERROR: can't use the specified port ${PORT}. It's already being used. Try again." 1>&2
  exit 1
fi


if [ -z "${SESSIONDIR}" & -z "${SESSIONDIR_}"]
then
    echo "ERROR: please either specify a --session-dir to store the files necessary for rstudio on apptainer/singularity." 1>&2
    echo "       OR specify a base directory to store all sessions with the RSTUDIO_APPTAINER_DEFAULT_SESSIONDIR environment variable." 1>&2
    ERROR=true
fi

if [ -z "${SIF}" ]
then
    echo "ERROR: please either specify the apptainer/singularity image to use with --sif " 1>&2
    echo "       OR specify a default image to use with the RSTUDIO_APPTAINER_DEFAULT_IMAGE environment variable. " 1>&2
    ERROR=true
elif [ ! -s "${SIF}" ]
then
    echo "ERROR: the singularity image file you specified '${SIF}' does not exist." 1>&2
    ERROR=true
fi

if [ ! -z "${ERROR:-}" ]
then
    exit 1
fi


if [ -z "${SESSIONDIR:-}" ]
then
  SESSIONDIR="${SESSIONDIR_}/${USER_}-${PORT}"
fi

SESSIONDIR=$(realpath "${SESSIONDIR}")


if [ -z "${NOCLEANUP:-}" ]
then
  trap "rm -rf -- ${SESSIONDIR}" EXIT
fi

mkdir -p "${SESSIONDIR}" 
cd "${SESSIONDIR}"

mkdir -p run var-lib-rstudio-server
printf 'provider=sqlite\ndirectory=/var/lib/rstudio-server\n' > database.conf

HOST_IP="$(hostname -i)"
HOST_URL="$(dig +short -x "${HOST_IP}" | head -n 1 | sed 's/\.$//')"
#HOST_URL="$(uname -n).$(awk '/^domain/ {print $2}' /etc/resolv.conf)"
#echo $SSH_CONNECTION | cut -d ' ' -f3
#HOST_URL="lipm-calcul.toulouse.inrae.fr"

if [ -z "${HOST_URL}" ]
then
  HOST_URL="${HOST_IP}"
fi

echo "Running Rstudio server on port: ${PORT}."
echo
echo "To connect on your local machine, forward the port via SSH like this:"

if [ -z "${HOST_URL}" ]
then
    echo "  ssh -N -L 8787:localhost:${PORT}" "${USER}@MYSERVERURL.com"
    echo ""
    echo "Where MYSERVERURL.com is the url or IP address you use to SSH into the server."
else
    echo "  ssh -N -L 8787:localhost:${PORT}" "${USER}@${HOST_URL}"
fi
echo
echo "Then point your favourite web browser to: http://localhost:8787"
echo
echo "username: $(whoami)"
echo "password: ${PASSWORD}"
echo
echo "To shutdown your server just type Ctrl-C or close the window."
echo "Note that nothing will be lost as long as you create files in /mnt/data or the network drives (Labo etc)."


export PASSWORD
export SINGULARITYENV_PASSWORD="${PASSWORD}"
export APPTAINERENV_PASSWORD="${PASSWORD}"

if command -v apptainer >> /dev/null
then
    CMD="apptainer"
else
    CMD="singularity"
fi

"${CMD}" exec \
  --bind run:/run,var-lib-rstudio-server:/var/lib/rstudio-server,database.conf:/etc/rstudio/database.conf \
   "${SIF}" \
   /usr/lib/rstudio-server/bin/rserver --auth-none=0 --auth-pam-helper-path=pam-helper --www-port "${PORT}" --server-user=$(whoami) --auth-timeout-minutes=0 --auth-stay-signed-in-days=30
