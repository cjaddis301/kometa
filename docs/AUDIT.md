# Kometa Full Configuration Audit

Audit date: 2026-09-24

## Scope

This audit covers the sanitized Kometa project supplied for review:

- Docker Compose deployment
- global Kometa settings and service connections
- Notifiarr/webhooks
- Anime collections and studios
- Movie franchise, decade, and studio/universe collections
- TV network collections
- active overlay definitions
- schedules
- Git/runtime hygiene

The supplied archive intentionally excluded overlay PNG/JPG/WebP artwork and the main assets directory, so image file contents and dimensions could not be independently verified. Previous full Kometa validation did successfully load the active collection/overlay definitions and connect to all four Plex libraries.

## Executive result

The configuration is fundamentally sound and does **not** need a redesign. The custom Movie franchise model and JMXD overlay stack are worth preserving.

Static audit results:

- 185 collection definitions
- 185 unique collection mapping names
- 7 active collection files
- 1 active local overlay file plus Kometa default overlay files
- no duplicate collection mapping names
- no missing template names in the supplied active files
- no YAML parse failures in the final audited bundle

The deeper audit found several real issues that were not obvious from the earlier full validation:

1. The prior cleanup removed asset settings that intentionally differed from current Kometa defaults. That would have changed behavior.
2. Anime franchise searches used comma-separated strings with Plex `title` string filters. Plex string filters require multiple values as a YAML list.
3. Kometa was scheduled for 03:00 while Plex reported scheduled maintenance from 02:00 through 07:00.
4. `New & Trending Anime` had an aging fixed release cutoff.
5. The previous proposed `v2.5.1` image pin is not a currently published Docker Hub release tag. Kometa documents `latest` as the official master/stable Docker branch.

Those objective issues are corrected in this bundle.

---

# Applied corrections

## 1. Preserve the original asset strategy

The original working configuration explicitly used:

```yaml
create_asset_folders: false
prioritize_assets: false
dimensional_asset_rename: false
show_missing_season_assets: false
show_missing_episode_assets: false
save_report: false
```

Those settings are **not redundant** against current Kometa defaults. In particular, current documentation lists `create_asset_folders`, `prioritize_assets`, and `dimensional_asset_rename` as enabled by default.

The first cleanup version removed them, which could have caused Kometa to:

- create asset folders that were previously not created;
- prioritize existing local assets over explicit `url_poster` artwork;
- rename files based on image dimensions;
- emit missing season/episode asset warnings again;
- generate report files again.

The final configuration restores those intentional overrides.

The retained asset settings are:

```yaml
settings:
  cache: true
  asset_directory: config/assets
  asset_folders: true
  create_asset_folders: false
  prioritize_assets: false
  dimensional_asset_rename: false
  download_url_assets: true
  show_missing_season_assets: false
  show_missing_episode_assets: false
  save_report: false
  delete_below_minimum: true
  missing_only_released: true
  overlay_artwork_filetype: jpg
  overlay_artwork_quality: 90
```

This is substantially smaller than the old template-heavy settings block while preserving the settings that materially affect your deployment.

## 2. Fix Anime franchise title searches

The previous Anime franchise template used values such as:

```yaml
title: "naruto,boruto"
```

and:

```yaml
title: "fate/stay,fate/zero,fate/apocrypha,fate/kaleid,fate/grand order"
```

Kometa's Plex Search documentation says string filters can accept multiple values **only as a YAML list**. These have been rewritten explicitly, for example:

```yaml
Naruto Series:
  template: { name: Franchise }
  plex_search:
    any:
      title:
        - naruto
        - boruto
```

and the Fate entries are now individual list elements.

This is a correctness fix, not merely a style change.

## 3. Preserve IMDb builder ordering for Anime charts

The original shared Anime search template forced:

```yaml
collection_order: release.asc
```

That overrode the intent of collections using `sort_by: rating.desc`, `popularity.desc`, or `votes.desc`.

The shared template now uses:

```yaml
collection_order: custom
```

so the collection order follows each IMDb builder's result order.

## 4. Refresh the New & Trending Anime cutoff

`New & Trending Anime` now uses:

```yaml
release.after: "2026-01-01"
```

IMDb Search requires a concrete date or `today`; it does not provide a simple rolling "last N months" value for this field. Review this cutoff once a year.

No other Anime search semantics were changed. The existing `genre: animation` plus `country.origin: jp` logic remains intact because changing it to IMDb's Anime interest/category could alter membership.

## 5. Move Kometa outside the Plex maintenance window

The Plex validation log reported scheduled maintenance between 02:00 and 07:00. The old Compose configuration scheduled Kometa at 03:00.

The final Compose file uses:

```yaml
KOMETA_TIMES: "07:30"
```

This avoids competing with Plex maintenance while keeping the run in the morning.

If the Plex maintenance window changes later, review this time.

## 6. Keep the Plex URL explicit

The final configuration keeps the Plex URL directly under `plex:`:

```yaml
plex:
  url: http://192.168.4.193:32400
```

The URL is not a credential, and keeping it explicit avoids a silent failure when an environment-specific URL variable is omitted. Confirm that `192.168.4.193` is reserved/static and reachable from the Kometa container.

If the Plex host changes later, update this one value in `config/config.yml`.

## 7. Reduce Notifiarr/Discord noise

The original config notified on:

- error
- version
- run start
- run end
- collection changes

The final configuration keeps only:

```yaml
webhooks:
  error: notifiarr
  run_end: notifiarr
```

This retains actionable failures and one completion summary while removing start messages, per-collection change messages, and repetitive version notifications.

Important: the error webhook is useful for errors that occur after Kometa has initialized its configuration/services. A malformed YAML/config file can fail before notification services are fully available, so CLI validation and logs remain the authoritative guardrail.

## 8. Correct the Docker image strategy

The earlier proposed bundle used:

```yaml
image: kometateam/kometa:v2.5.1
```

As of this audit, Docker Hub publishes `v2.5.0`, `latest`, `develop`, and `nightly`, but not a `v2.5.1` release tag. Your previous log reported `Version: 2.5.1 (Docker: master)`, which is consistent with running the master branch image rather than a `v2.5.1` release tag.

The final bundle therefore uses:

```yaml
image: kometateam/kometa:latest
```

Kometa's Docker documentation identifies `latest` as the official master/stable branch.

If you prefer immutable release pinning instead of tracking the stable branch, pin to an actually published release tag after validating it. At audit time, `v2.5.0` is the published versioned tag visible on Docker Hub.

---

# File-by-file audit

## `config/config.yml`

Status: **updated**

Changes:

- explicit modern `file:` blocks retained;
- Decades and TV Networks schedules remain visible at the file-block level;
- stale/default-heavy settings removed;
- original non-default asset behavior restored;
- GitHub integration removed because no active `git:` or `repo:` references exist;
- Notifiarr reduced to `error` and `run_end`;
- Plex URL moved to `<<plexurl>>`;
- blank `db_cache` removed;
- explicit JPG overlay output and quality retained.

### Scheduling

Current collection file schedule:

- Anime franchise: daily
- Anime studios: daily
- Anime chart/search collections: daily
- Movie franchises: daily
- Movie studios/universes: daily
- Movie decades: Sunday
- TV networks: Sunday

File schedules do not trigger Kometa themselves. They only decide what runs when Kometa is already executing.

The weekly schedule for Decades and TV Networks was preserved from the original configuration rather than invented by the audit.

## `config/anime/anime.yml`

Status: **updated**

Collections: 6

Changes:

- `collection_order: custom` retained from the earlier correctness fix;
- New & Trending cutoff moved to `2026-01-01`.

No automatic conversion was made from `genre: animation` + `country.origin: jp` to a different IMDb Anime selector because that can change results.

### Overlap

`Top Rated Anime`, `Most Popular Anime`, `New & Trending Anime`, and `Highly Voted Anime` can naturally overlap. This is intentional chart-style organization rather than duplicate configuration.

## `config/anime/anime-franchise.yml`

Status: **correctness fix applied**

Collections: 8

The comma-separated Plex string searches were replaced by real YAML lists under `plex_search.any`.

No collection names were changed.

## `config/anime/anime-studios.yml`

Status: **preserved**

Collections: 21

The TMDb company-driven design is compact and maintainable.

Possible cosmetic naming changes were intentionally not applied because they would rename Plex collections and potentially affect asset matching:

- `Deen Studio` → commonly styled `Studio Deen`
- `Liden Films` → commonly styled `LIDENFILMS`
- `Ufotable` → commonly styled `ufotable`
- `Wit Studio` → commonly styled `WIT Studio`

These are display choices, not configuration errors.

## `config/movies/movies.yml`

Status: **preserved**

Collections: 111

The shared template is already a good DRY design:

```yaml
tmdb_collection_details: <<collection>>
tmdb_movie: <<movie>>
```

Kometa's TMDb collection builders accept multiple IDs, so the compound franchises do not need to be expanded into separate builders.

### Intentional source overlap

The following TMDb collection IDs are used in more than one Plex collection:

- `448150`: Deadpool, X-Men
- `435259`: Fantastic Beasts, Wizarding World
- `1241`: Harry Potter, Wizarding World

This is not an error. It is the expected result of creating both specific franchises and broader universe collections.

### Kometa Default franchise migration

Kometa now has a capable built-in Franchise default, but the custom file should **not** be replaced blindly. Your file has curated compound collections and explicit extra movies, and a Defaults migration could alter names and membership. The current file is easy to understand and is worth keeping.

## `config/movies/movies-decades.yml`

Status: **preserved with schedule centralized**

Collections: 8

The file creates "Best of" collections rather than simple decade buckets, using IMDb vote/rating filters. That is a distinct design and should not be replaced with a generic Decade default unless you want different behavior.

The weekly Sunday schedule is now in `config.yml` instead of inside the template.

### External artwork

The collections rely on The Poster Database and a Wallpapercave background URL. URL assets are valid, but external hosts are a maintenance dependency. `download_url_assets: true` helps retain downloaded copies when an asset is absent locally.

For maximum resilience, eventually keep important collection posters/backgrounds in your own `config/assets` tree.

## `config/movies/movies-studios.yml`

Status: **minor text cleanup**

Collections: 12

Functional builders were preserved.

Changes:

- corrected `superheros` → `superheroes`;
- changed the MCU summary to describe movies only, since this file runs against the Movies library.

### Organization note

`DC Extended Universe` and `Marvel Cinematic Universe` are universe/list collections rather than studio collections. They work correctly where they are; moving them into a separate `movies-universes.yml` would be organizational only, so the audit did not force that restructure.

## `config/tv/tv-networks.yml`

Status: **preserved; two content decisions flagged**

Collections: 19

The grouped network IDs are valid input for the TMDb network builder.

### Disney Plus collection

The current collection is:

```yaml
Disney Plus:
  network: "2739,142,44,2991"
```

Current TMDb data identifies:

- `2739` as Disney+
- `142` as Toon Disney
- `44` as Disney XD

Therefore the mapping name `Disney Plus` is broader than its actual source IDs. This is a semantic mismatch, not a syntax error.

It was **not** auto-fixed because the right choice depends on how you want Plex organized:

1. keep the grouped IDs and rename the collection to something such as `Disney Networks`; or
2. keep `Disney Plus` as ID `2739` and create a separate legacy/Disney Channels collection.

The existing poster is also likely tied to the Disney+ name, so splitting requires an artwork decision.

### Warner Bros collection

`Warner Bros` currently maps to TMDb network ID `21`. This deserves manual verification against the live TMDb network record. The audit did not rename or change the ID without authoritative current confirmation.

### Prime

TMDb identifies network `1024` as Prime Video. `Prime` is functional but `Prime Video` would be a clearer display name. This is cosmetic and was not changed.

## Overlays

Status: **active stack preserved**

Active local overlay file:

```text
config/overlays/jmxd/gradient.yml
```

Movies use:

- JMXD gradient
- Kometa resolution/dynamic-range default with custom local PNG assets
- Kometa audio-codec default with custom local PNG assets
- second resolution default configured for edition artwork

Stand-up uses:

- JMXD gradient
- resolution/dynamic-range
- audio codec

TV Shows uses:

- network overlay

No individual overlay schedules are configured, which is correct: Kometa requires a library's overlay files to be processed together. If overlay frequency is changed later, use the library-level `schedule_overlays` setting.

No `reapply_overlays: true` or reset behavior was found. That is good because unnecessary forced reapplication can cause image bloat.

The audit archive excluded the referenced PNGs, so the following can only be verified at runtime:

- gradient image presence/dimensions;
- resolution artwork coverage;
- audio-codec artwork coverage;
- edition artwork coverage.

Your previous full validation successfully loaded the overlay definitions, which is a positive runtime signal.

---

# Collectionless helpers

Both Anime and Movies contain an `Unmatched` collection using `plex_collectionless`.

The current definitions are valid, but whether they achieve the intended Plex display behavior depends on your collection modes. Kometa's documented collectionless pattern normally uses:

```yaml
collection_mode: hide
```

for the collectionless helper and `hide_items` for the normal collections.

Your custom normal collection templates do not explicitly set `collection_mode: hide_items`, and the Unmatched collections do not explicitly set `collection_mode: hide`.

This was **not** auto-changed because it directly changes Plex library presentation. Verify what you want:

- If collections should replace/hide their member items in the library tab, adopt the documented hide-items/collectionless pattern.
- If you intentionally want collections and individual items shown together, leave the current mode behavior alone.

---

# Minimum collection size

Current global behavior defaults to `minimum_items: 1`. Your custom franchise/studio/network templates therefore can create a collection containing only one locally available item.

Kometa's built-in Franchise defaults use a minimum of 2 items, which is often a cleaner Plex experience.

This audit did **not** add `minimum_items: 2` because it would delete or suppress legitimate one-item collections and therefore changes visible behavior.

If you want to suppress one-item collections, add it selectively to the relevant templates rather than globally.

---

# Unused/dead files from the original archive

The original archive contained:

```text
config/overlays/Movies.yml
config/overlays/Movies_Overlays.yml
config/overlays/Shows.yml
config/overlays/Shows_Overlays.yml
config/overlays/imdb_rating.yml
config/overlays/jmxd/Unused/gradient_bottom.yml
```

The first four were empty.

`imdb_rating.yml` and `gradient_bottom.yml` contained configuration but were not referenced by the active `config.yml`.

Recommendation: delete the four empty files and move any examples you want to keep **outside `/config`**. This matters because `--validate-dir /config` intentionally scans every YAML file under the directory, even files that are not referenced by the live configuration.

Fonts used only by the inactive IMDb-rating overlay can be archived with that overlay if it will not be re-enabled.

---

# Runtime files / Git hygiene

Do not version-control:

```text
.env
config/config.cache*
config/logs/
config/missing/
config/UUID
**/@eaDir/
```

The original audit archive included a large `config.cache-wal`, which explained much of the tar creation time.

The final `.gitignore` covers these paths.

---

# Validation strategy

Use both Compose validation and Kometa validation.

## One-command helper

The bundle includes:

```bash
./scripts/validate.sh
```

It performs:

1. `docker compose config -q`
2. full Kometa config/API validation with JSON schemas
3. recursive schema validation of every YAML file under `/config`

## Manual equivalent

```bash
cd /volume1/docker/kometa

sudo docker compose config -q

sudo docker compose run --rm kometa \
  --validate \
  --validate-level full \
  --validate-schemas

sudo docker compose run --rm kometa --validate-dir /config
```

Kometa validation returns exit code `1` for validation errors. Warnings do not fail the main validation. Schema constraint errors fail; schema gaps are reported separately because Kometa's JSON schemas are still evolving.

After all validation passes:

```bash
sudo docker compose run --rm kometa --run
```

Then visually verify the affected Plex areas before relying on the scheduled run.

---

# Manual decisions remaining

These are not errors and were intentionally not changed automatically:

1. **Disney Plus network grouping** — split Disney+ from Toon Disney/Disney XD, or rename the grouped collection.
2. **Warner Bros network ID 21** — verify the live TMDb network identity before changing it.
3. **Prime → Prime Video** — cosmetic rename only.
4. **Collectionless display behavior** — decide whether to adopt `hide_items` + hidden collectionless helpers.
5. **Minimum items** — decide whether franchise/studio/network collections should require 2 local items.
6. **Universe organization** — optionally move MCU/DCEU out of the studios file for cleaner naming.
7. **External poster ownership** — optionally localize The Poster Database/Wallpapercave artwork into your own assets.
8. **Image pinning** — `latest` matches Kometa's documented stable/master Docker branch; use a published version tag if strict reproducibility is more important than tracking master.
9. **Anime studio display names** — cosmetic normalization only.

---

# Overall recommendation

Keep the architecture:

- one Compose project;
- secrets/environment connection data in `.env`;
- `config.yml` as the orchestrator;
- modular Anime/Movie/TV collection files;
- custom Movie franchise definitions;
- JMXD overlays;
- high-signal Notifiarr notifications.

The biggest value now is not further restructuring. It is periodically reviewing content semantics (network IDs, stale chart dates, collection usefulness) and validating after every Kometa upgrade.

## Playlist follow-up update

After the initial playlist test:

- enabled the Kometa Default `Arrowverse (Timeline Order)` playlist;
- enabled the Kometa Default `DC Animated Universe (Timeline Order)` playlist;
- disabled the default combined MCU playlist;
- added `config/playlists/marvel.yml` with separate `MCU Movies (Timeline Order)` and `MCU TV (Timeline Order)` playlists using the same IMDb timeline source as Kometa's maintained MCU Default;
- kept Dragon Ball and Pokémon disabled because the current project does not configure MDBList and those timelines would also need the Anime library.
