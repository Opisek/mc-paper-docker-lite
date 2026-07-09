#!/bin/bash
set -e

# Check root
if [ "$EUID" -ne 0 ]; then
  echo "This script must be ran as root user"
  exit 1
fi
 
# Add local user
if ! id minecraft >/dev/null 2>&1; then
	echo "Creating new unpriviledged user"
  USER_ID=${MC_UID:-9999}
  GROUP_ID=${MC_GID:-9999}
  echo "Using user:group $USER_ID:$GROUP_ID"
  addgroup --gid $GROUP_ID minecraft
  adduser minecraft --uid $USER_ID --ingroup minecraft --shell /bin/sh --disabled-password --gecos ""
  mkdir -p minecraft
fi

# Find appropriate binary
echo "Checking for updates"

USER_AGENT="mc-paper-docker-lite/2.0.0 (github.com/Opisek/mc-paper-docker-lite)"

PAPER_VERSIONS=`curl -sL -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper | jq '.versions | add | reverse'`

if [ "$PAPER_VERSIONS" = null ]; then
  echo "Could not connect to PaperMC API"
fi

if [ "${VERSION:=LATEST}" = LATEST ]; then
   while read VERSION; do
    PAPER_BUILDS=`curl -sL -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper/versions/${VERSION}/builds | jq '[ .[] | {build: .id, channel: .channel, download: .downloads."server:default"}]'`
    if [ "${CHANNEL:=STABLE}" == STABLE ]; then
      PAPER_BUILDS=`echo $PAPER_BUILDS | jq '[.[] | select(.channel=="STABLE")]'`
    elif [ "${CHANNEL:=STABLE}" == BETA ]; then
      PAPER_BUILDS=`echo $PAPER_BUILDS | jq '[.[] | select(.channel=="STABLE" or .channel=="BETA")]'`
    elif [ "${CHANNEL:=STABLE}" == ALPHA ]; then
      PAPER_BUILDS=`echo $PAPER_BUILDS | jq '[.[] | select(.channel=="STABLE" or .channel=="BETA" or .channel=="ALPHA")]'`
    else
      echo "Unknown channel $CHANNEL"
      exit 1
    fi
    FILENAME=`echo $PAPER_BUILDS | jq -r '.[0].download.name'`
    URL=`echo $PAPER_BUILDS | jq -r '.[0].download.url'`
    HASH=`echo $PAPER_BUILDS | jq -r '.[0].download.checksums.sha256'`
    BUILD=`echo $PAPER_BUILDS | jq -r '.[0].build'`
    if [ $BUILD != null ]; then
      break
    fi
  done <<< `echo "$PAPER_VERSIONS" | jq -r 'reverse | .[]'`
else
  if [ `echo $PAPER_VERSIONS | jq --arg version "$VERSION" 'index($version)'` = null ]; then
    echo "PaperMC does not offer binaries for version $VERSION"
    exit 1
  fi
  PAPER_BUILDS=`curl -sL -H "User-Agent: $USER_AGENT" https://fill.papermc.io/v3/projects/paper/versions/${VERSION}/builds | jq '[ .[] | {build: .id, channel: .channel, download: .downloads."server:default"}]'`
  if [ "${CHANNEL:=STABLE}" == STABLE ]; then
    PAPER_BUILDS=`echo $PAPER_BUILDS | jq '[.[] | select(.channel=="STABLE")]'`
  elif [ "${CHANNEL:=STABLE}" == BETA ]; then
    PAPER_BUILDS=`echo $PAPER_BUILDS | jq '[.[] | select(.channel=="STABLE" or .channel=="BETA")]'`
  elif [ "${CHANNEL:=STABLE}" == ALPHA ]; then
    PAPER_BUILDS=`echo $PAPER_BUILDS | jq '[.[] | select(.channel=="STABLE" or .channel=="BETA" or .channel=="ALPHA")]'`
  else
    echo "Unknown channel $CHANNEL"
    exit 1
  fi
  FILENAME=`echo $PAPER_BUILDS | jq -r '.[0].download.name'`
  URL=`echo $PAPER_BUILDS | jq -r '.[0].download.url'`
  HASH=`echo $PAPER_BUILDS | jq -r '.[0].download.checksums.sha256'`
  BUILD=`echo $PAPER_BUILDS | jq -r '.[0].build'`
fi

if [ "$VERSION" = null ]; then
  echo "Could not find any PaperMC binaries in channel $CHANNEL"
  exit 1
fi

if [ "$BUILD" = null ]; then
  echo "PaperMC does not offer binaries for version $VERSION on the selected channel $CHANNEL"
  exit 1
fi

echo "Selected version $VERSION build $BUILD"

if [ ! -f "./minecraft/${FILENAME}" ]; then
  echo "Downloading $FILENAME"
  (cd ./minecraft && rm *.jar 2> /dev/null) || true
  (cd ./minecraft && curl -OsL -H "User-Agent: $USER_AGENT" "${URL}")
else
  echo "Binary already installed, nothing to update"
fi

if [ `sha256sum ./minecraft/${FILENAME} | awk '{print $1;}'` != $HASH ]; then
  echo "The downloaded build has an incorrect sha256 hash"
  (cd ./minecraft && rm *.jar)
  exit 1
fi

# Write EULA
if [ "$EULA" = true ]; then
  echo "eula=true" > ./minecraft/eula.txt
else
  echo "eula=false" > ./minecraft/eula.txt
fi

# Fix permissions
echo "Setting up file permissions"
chown -R minecraft:minecraft ./minecraft
chmod -R 770 ./minecraft

# Start server 
echo "Starting the server"
cd ./minecraft
exec gosu minecraft:minecraft java "-Xms${XMS:=4G}" "-Xmx${XMX:=4G}" -jar $FILENAME nogui
