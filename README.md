# Kometa Docker Compose Project

Runs **Kometa** on Synology DSM using Docker Compose / Synology Container Manager.

Kometa manages Plex collections, metadata, and overlays while keeping deployment configuration, persistent Kometa configuration, and secrets separate.

## Project Structure

```text
/volume1/docker/kometa/
├── compose.yaml
├── .env
├── README.md
└── config/
    ├── config.yml
    ├── config.cache
    ├── anime/
    ├── movies/
    ├── tv/
    ├── overlays/
    ├── assets/
    └── logs/
```

The host directory:

```text
/volume1/docker/kometa/config
```

is mounted inside the container as:

```text
/config
```

For example:

```text
Host:
  /volume1/docker/kometa/config/movies/movies.yml

Container:
  /config/movies/movies.yml
```

Use container-visible paths in Kometa configuration files.

## Docker Compose

```yaml
name: kometa

services:
  kometa:
    image: kometateam/kometa:latest
    container_name: kometa

    env_file:
      - .env

    environment:
      TZ: America/New_York
      KOMETA_TIMES: "03:00"

    volumes:
      - ./config:/config:rw

    restart: unless-stopped
```

Do not permanently configure:

```yaml
KOMETA_RUN: "true"
```

Use a manual Compose run instead when Kometa should execute immediately.

## Secrets

Secrets are stored in `.env` rather than directly in `config.yml`.

```env
KOMETA_plextoken=YOUR_PLEX_TOKEN
KOMETA_tmdbkey=YOUR_TMDB_API_KEY
KOMETA_githubtoken=YOUR_GITHUB_TOKEN
KOMETA_notifiarrkey=YOUR_NOTIFIARR_API_KEY
```

Reference them from `config/config.yml`:

```yaml
plex:
  url: http://PLEX_SERVER_IP:32400
  token: <<plextoken>>

tmdb:
  apikey: <<tmdbkey>>

github:
  token: <<githubtoken>>

notifiarr:
  apikey: <<notifiarrkey>>
```

Keep Kometa secret names simple and avoid additional underscores after `KOMETA_`.

### Git Ignore

If this project is version controlled:

```gitignore
.env
config/config.cache
config/logs/
*.log
```

Never commit `.env`.

## Current Plex Libraries

Kometa currently manages:

* Anime
* Movies
* Stand-up
* TV Shows

Custom configuration includes:

```text
config/anime/
config/movies/
config/tv/
config/overlays/jmxd/
```

The YAML files in those directories are the source of truth for individual collections and overlays.

## Common Commands

Run commands from:

```bash
cd /volume1/docker/kometa
```

### Start or Recreate

```bash
sudo docker compose up -d
```

To fully recreate the persistent container:

```bash
sudo docker compose down
sudo docker compose up -d
```

### Status

```bash
sudo docker compose ps
```

### Logs

```bash
sudo docker compose logs -f kometa
```

### Structure Validation

```bash
sudo docker compose run --rm kometa \
  --validate \
  --validate-level structure
```

### Full Validation

```bash
sudo docker compose run --rm kometa \
  --validate \
  --validate-level full
```

A successful validation ends with:

```text
Result: PASSED
```

### Manual Run

```bash
sudo docker compose run --rm kometa --run
```

### Update Image

```bash
sudo docker compose pull
sudo docker compose up -d
```

Run full validation after upgrading Kometa.

## Deployment

The project can be deployed from SSH:

```bash
cd /volume1/docker/kometa
sudo docker compose up -d
```

or from Synology:

```text
DSM
→ Container Manager
→ Project
→ Create
```

Use:

```text
Project Name: kometa
Project Path: /volume1/docker/kometa
Compose File: compose.yaml
```

The container uses:

```yaml
restart: unless-stopped
```

so Kometa should return automatically after DSM or Container Manager restarts unless it was intentionally stopped.

After DSM upgrades or NAS reboots, verify the project with:

```bash
sudo docker compose ps
```

## Schedule

Kometa currently runs at:

```text
03:00 America/New_York
```

Configured by:

```yaml
environment:
  TZ: America/New_York
  KOMETA_TIMES: "03:00"
```

The persistent container remains running between scheduled executions.

## Configuration Changes

Configuration files live under:

```text
/volume1/docker/kometa/config/
```

Normal YAML changes do not require rebuilding the container.

Recommended workflow:

```text
Edit configuration
        ↓
Full validation
        ↓
Manual Kometa run
        ↓
Verify Plex
        ↓
Allow scheduled runs to continue
```

Use the commands from **Common Commands** rather than recreating the container for normal YAML changes.

## Secret Changes

Edit:

```text
/volume1/docker/kometa/.env
```

Environment changes require recreating the persistent container:

```bash
sudo docker compose down
sudo docker compose up -d
```

Then run full validation.

### Verify Secret Injection

Display only Kometa environment variable names:

```bash
sudo docker compose run --rm --entrypoint env kometa \
  | grep '^KOMETA_' \
  | cut -d= -f1
```

Expected values include:

```text
KOMETA_plextoken
KOMETA_tmdbkey
KOMETA_githubtoken
KOMETA_notifiarrkey
KOMETA_TIMES
```

To verify one variable without exposing its value:

```bash
sudo docker compose run --rm --entrypoint sh kometa -c \
  'test -n "$KOMETA_githubtoken" && echo "GitHub token is set" || echo "GitHub token is EMPTY"'
```

## Updating Kometa

Pull and recreate:

```bash
sudo docker compose pull
sudo docker compose up -d
```

Then run full validation.

For controlled upgrades, replace:

```yaml
image: kometateam/kometa:latest
```

with a specific known-good Kometa image tag.

## Known Configuration Notes

### Overlay Artwork Quality

Kometa may report:

```text
settings sub-attribute overlay_artwork_quality is blank using 90 as default
```

This is not fatal.

It can be made explicit with:

```yaml
settings:
  overlay_artwork_quality: 90
```

### GitHub Authentication

If Kometa reports:

```text
GitHub Error: The GitHub token specified could not be validated.
Response: 401 - Unauthorized
```

verify that `KOMETA_githubtoken` exists using the secret verification command above.

If the variable exists, replace the GitHub Personal Access Token in `.env`, recreate the container, and run full validation.

## Backup

The important state is the project configuration, not the container.

Back up:

```text
compose.yaml
.env
config/
```

Example manual backup:

```bash
sudo cp -a \
  /volume1/docker/kometa \
  /volume1/docker/kometa-backup
```

Protect backups containing `.env` because they contain API credentials.

## Maintenance Workflow

For normal changes:

```text
Config change
    ↓
Full validation
    ↓
Manual run
    ↓
Verify Plex
```

For `.env` changes:

```text
Secret change
    ↓
Recreate container
    ↓
Full validation
    ↓
Manual run if needed
```

For Kometa upgrades:

```text
Pull image
    ↓
Recreate container
    ↓
Full validation
    ↓
Manual run if needed
```
