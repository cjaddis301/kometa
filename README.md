# Kometa

Kometa runs on Synology DSM as a Docker Compose project and manages Plex collections and overlays.

## Layout

```text
kometa/
├── compose.yml
├── .env
├── .env.example
├── .gitignore
├── README.md
├── docs/
│   ├── AUDIT.md
│   └── COLLECTION-INVENTORY.md
├── scripts/
│   └── validate.sh
└── config/
    ├── config.yml
    ├── anime/
    ├── movies/
    ├── tv/
    ├── overlays/
    ├── assets/
    └── logs/
```

`./config` is mounted into the container as `/config`.

This repository contains the complete audited **configuration**. The source audit did not include the NAS's existing JMXD PNG artwork or Plex asset artwork, so those binary files are not present here. See `config/overlays/jmxd/README.md` before treating the repository as a full disaster-recovery copy.

## Environment

Create `.env` from `.env.example` and provide the real values:

```env
KOMETA_plextoken=...
KOMETA_tmdbkey=...
KOMETA_notifiarrkey=...
```

Confirm the Plex URL is reachable from the Kometa container. Keep `.env` out of Git.

## Common commands

Run from `/volume1/docker/kometa`.

```bash
sudo docker compose up -d
sudo docker compose ps
sudo docker compose logs -f kometa
```

## Validate

Preferred:

```bash
./scripts/validate.sh
```

Or manually:

```bash
sudo docker compose config -q

sudo docker compose run --rm kometa \
  --validate \
  --validate-level full \
  --validate-schemas

sudo docker compose run --rm kometa --validate-dir /config
```

Validation returns a non-zero exit code for real validation errors. Warnings and schema gaps can still be reported without failing.

## Manual run

After validation passes:

```bash
sudo docker compose run --rm kometa --run
```

## Schedule

The persistent container is configured to run Kometa at:

```text
07:30 America/New_York
```

This is intentionally after the Plex maintenance window previously reported as 02:00–07:00.

File-level schedules still control whether individual collection files participate in a given run:

- Movie Decades: Sunday
- TV Networks: Sunday
- other collection files: daily

These schedules do not start Kometa by themselves.

## Notifications

Notifiarr receives only:

- errors
- one end-of-run summary

This intentionally avoids `run_start`, per-collection `changes`, and daily version-message noise.

Do not rely on Discord/Notifiarr as the only configuration-error detector. Run validation after changes because a sufficiently early YAML/config failure may occur before notification services are usable.

## Updating Kometa

The Compose file uses:

```yaml
image: kometateam/kometa:latest
```

`latest` is Kometa's official stable/master Docker branch. Pull upgrades deliberately:

```bash
sudo docker compose pull
sudo docker compose up -d
./scripts/validate.sh
```

If you prefer immutable release pinning, use an actually published version tag and validate it before production use.

## Backup

Back up:

```text
compose.yml
.env
config/
```

Caches and logs are disposable and excluded from Git.

## Audit details

See:

- `docs/AUDIT.md` for the complete review and remaining decisions.
- `docs/COLLECTION-INVENTORY.md` for all 185 collection definitions.


## Cross-Library Playlists

Playlists run weekly on Saturday. The MCU is split by media type to avoid one oversized mixed playlist:

- MCU Movies (Timeline Order) — `Movies` only
- MCU TV (Timeline Order) — `TV Shows` only

Kometa's maintained Playlist Default remains enabled across `Movies` and `TV Shows` for:

- Arrowverse
- DC Animated Universe
- Star Wars
- Star Wars: The Clone Wars
- Star Trek
- X-Men

The default combined MCU playlist is disabled because the two local MCU playlists replace it. Dragon Ball and Pokémon remain disabled because those defaults use MDBList and would also need the `Anime` library included.

## GitHub repository setup

This repository is safe to commit as long as `.env` remains ignored. Create the local secret file from the example:

```bash
cp .env.example .env
```

Then validate before starting the persistent container:

```bash
./scripts/validate.sh
sudo docker compose up -d
```

To initialize a new Git repository:

```bash
git init
git add .
git commit -m "Initial Kometa configuration"
git branch -M main
```

Add your GitHub remote and push when ready.

### Binary artwork

The current audited source did not include the JMXD PNG artwork referenced by the overlay configuration. The repository includes placeholder directories and `config/overlays/jmxd/README.md`; copy the working PNGs from the NAS if you want GitHub to contain a fully restorable overlay stack.
