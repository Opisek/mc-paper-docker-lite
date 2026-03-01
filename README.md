# MC Paper Docker Lite

The simplest way to host a PaperMC Minecraft server using Docker.

1. Install [Docker](https://docs.docker.com/engine/install/)
2. Create a file called `docker-compose.yml` and paste the following example:
  ```yml
services:
    minecraft:
      container_name: minecraft
      image: opisek/mc-paper-docker-lite:latest
      volumes:
        - /srv/minecraft:/app/minecraft # change /srv/minecraft to the directory you want to store minecraft files in
      network_mode: host
      environment:
        - EULA=false      # change this to true if you agree to minecraft eula https://www.minecraft.net/en-us/eula
        - VERSION=latest  # minecraft version or "latest"
        - CHANNEL=default # change this to "experimental" for preview paper builds
        - XMS=8G          # minimum amount of ram to allocate to the server
        - XMX=8G          # maximum amount of ram to allocate to the server
        - UID=9999        # minecraft files user id
        - GID=9999        # minecraft files group id
      restart: unless-stopped
      stdin_open: true
      tty: true
      build:
        context: .
        dockerfile: Dockerfile
  ```
3. Adjust the settings as needed. In particular, you can set `VERSION` to whichever you want to play on, for example `1.21.11`. Futhermore, to run a Minecraft server, you must agree to [EULA](https://www.minecraft.net/en-us/eula) and set `EULA` to `true`.

  For an explanation of the variables, consult the following table:

  Variable|Meaning
  -|-
  `EULA` | Should be `true` if you agree to [Minecraft's EULA](https://www.minecraft.net/en-us/eula)
  `VERSION` | The minecraft version that should be installed, e.g. `1.20.1` or `latest` for the most current version
  `CHANNEL` | The channel for PaperMC builds to be used: `default` for normal builds and `experimental` for potentally unstable builds
  `XMS` | The minimum amount of RAM to allocate to the minecraft server
  `XMX` | The maximum amount of RAM to allocate to the minecraft server
  `UID` | The user id to use for the server files
  `GID` | The group id to use for the server files

4. Adjust the mount point for minecraft files in the `docker-compose.yml` file.

  For example, if you want your minecraft files to be on your Desktop and you're using Windows,
  you should adjust the corresponding line to
  ```yml
  - "C:/Users/Username/Desktop/minecraft:/app/minecraft"
  ```

  If you are using Linux, adjusting the path is simple, for example:
  ```yml
  - "/home/username/minecraft:/app/minecraft"
  ```

5. Open the directory with the `docker-compose.yml` file and run
  ```bash
  docker-compose up . -d
  ```

6. Run the following command to view the server console
  ```bash
  docker attach minecraft 
  ```

7. Once the server has booted up, make sure to add yourself to the list of operators
  ```bash
  op Username 
  ```

8. Done! You can now connect to your Minecraft server. The next step is usually to adjust your `server.properties` file.
9. You can shut the server down by running
  ```bash
  docker compose down
  ```
  or restart it by running
  ```bash
  docker compose restart
  ```

  Whenever the server starts up, the latest update (respecting the selected Minecraft version) is automatically installed.
