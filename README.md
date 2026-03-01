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
4. Run `docker compose up -d`
5. Done! You can now connect to your Minecraft server. The next step is usually to adjust your `server.properties` file.
6. If you wish to access the server console, you can do so by running `docker attach minecraft`.
7. You can shut the server down by running `docker compose down` or restart it by running `docker compose restart`. Whenever the server starts up, the latest update (respecting the selected Minecraft version) is automatically installed.
