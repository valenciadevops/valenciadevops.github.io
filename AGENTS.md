# AGENTS.md

## Project overview

Static website for the **ValenciaDevOps** meetup group, built with [Nanoc](https://nanoc.app/) (Ruby static site generator) and deployed to GitHub Pages.

- **Templating**: HAML
- **Styling**: SCSS compiled with Dart Sass (`nanoc-dart-sass` gem), then minified with Rainpress
- **Data**: All content lives in YAML files under `data/`
- **Output**: `output/` directory (gitignored)
- **CI/CD**: GitHub Actions builds and deploys on push to `master`

## Essential commands

```bash
bundle exec nanoc          # Build site to output/
bundle exec nanoc view     # Start dev server with live reload (http://localhost:3000)
```

There is no Makefile, Rakefile, test suite, or linter configured.

## Architecture

### Data flow

```
data/*.yml  ──┐
content/*.haml ─┤──> Rules ──> HAML/Sass filters ──> layouts/default.haml ──> output/*.html
layouts/     ──┘                                    (wraps with header + footer partials)
```

### Key files and folders

| Path | Purpose |
|------|---------|
| `Rules` | Nanoc compilation rules — maps file types to filters and output paths |
| `nanoc.yaml` | Nanoc config (text extensions, data source, auto-prune) |
| `content/` | Pages (`index.haml`, `event.haml`, `past.haml`) + static assets (images, fonts, stylesheets, robots.txt, humans.txt, favicon) |
| `layouts/default.haml` | Base HTML shell — includes `_header` and `_footer` partials, renders `yield` |
| `layouts/partials/` | Reusable HAML partials (`_header.haml`, `_footer.haml`) |
| `lib/helpers.rb` | Ruby helpers loaded by Nanoc — see [Helpers section](#helpers) |
| `data/static.yml` | All translatable strings (header text, nav labels, footer content, social links, page copy, URLs) |
| `data/default.yml` | Fallback meetup data shown when no active event |
| `data/archive.yml` | All past meetups with talks, authors, dates, YouTube links |
| `data/archive_model.yml` | Template for adding a new past meetup entry — not loaded at runtime |
| `.github/workflows/publish.yml` | CI: builds site, uploads `output/` as Pages artifact, deploys |
| `Dockerfile` | Multi-stage-ish build: installs gems, builds site, serves via `adsf` |

### Compilation rules (from `Rules`)

1. **HAML files** → filtered with `:haml`, wrapped in `layout "/default.*"`, written as `.html` (e.g., `index.haml` → `index.html`)
2. **SCSS files** under `**/stylesheets/` → filtered with `:dart_sass`, then `:rainpress` (CSS minifier). Partials (files starting with `_`) are explicitly skipped
3. **Everything else** → `passthrough` (copied verbatim to `output/`)

## Helpers

`lib/helpers.rb` is loaded by Nanoc and provides:

- **`data`** — A `YamlData` singleton. Access YAML files from `data/` with method calls:
  - `data.static` → loads `data/static.yml` (symbolize_names: true)
  - `data.archive` → loads `data/archive.yml`
  - `data.default` → loads `data/default.yml`
  - Any `.yml` file in `data/` can be accessed this way; `method_missing` maps the method name to `data/<name>.yml`
  - Files are lazy-loaded and cached on first access

- **`is_page_selected(page)`** — Returns `"selected"` if the current page matches `page` (used for nav active state styling). Page paths include leading slash, e.g., `is_page_selected("/event")`.

- **`render`** and **`image_tag`** — Built-in Nanoc helpers (from `Nanoc::Helpers::Rendering`)

## YAML data conventions

### `data/static.yml`

All user-facing text, labels, and links. Structure:

```yaml
# Header
h1_title: "DevOps Valencia"
nav_page_1: "¿Qué es?"
# ...

# Footer
participate: "Participa"
twitter_account: "valenciadevops"
# ...

# Site (used in templates — do not hardcode these values)
site_url: "https://valenciadevops.github.io"
google_analytics_id: "G-C02YHY1S14"
google_site_verification: "Ag5B31..."
youtube_channel_url: "https://www.youtube.com/@valenciadevops"
hashtag_url: "https://x.com/search?q=%23"
github_repo_url: "https://github.com/valenciadevops/valenciadevops.github.io"

# Index page
ready: false  # Toggles between "next meetup" and "join community" modes
main_paragraph_text_1: "..."
# ...

# Event page
event_title: "¿Qué es DevOps Valencia?"
# ...

# Past page
past_title: "Meetups anteriores"
meetup_url: "https://www.meetup.com/valencia-devops/"
```

### `data/archive.yml`

Past meetups nested under `meetups:`. Each entry:

```yaml
meetups:
  - meetup:
    date: "20 de Febrero de 2019"
    hangout_url: "https://youtu.be/..."  # YouTube link, optional
    type: "simple"                        # "simple" (1 talk) or "double" (2 talks)
    eventbrite: "https://..."
    talks:
      - title: "..."
        text:
          - "Paragraph 1"
          - "Paragraph 2"
        author:
          - name: "..."
            twitter: "handle"  # without @
            bio: "..."
        links:                  # optional
          - url: "..."
            label: "..."
    sponsor:                   # optional
      name: "..."
      url: "..."
      image: "filename.png"    # relative to content/images/sponsors/
```

### `data/default.yml` and active meetup pattern

When `static.yml` has `ready: true`, the index page looks for `data.new` (a file `data/new.yml`, not tracked in this repo). When `ready: false`, it falls back to `data.default`.

## Gotchas

- **`data.new` convention**: The index page references `data.new[:meetup]` when `ready: true`, but no `data/new.yml` file currently exists. Adding one is the way to set up the next meetup.

- **SCSS partials**: Files starting with `_` inside `content/stylesheets/` are explicitly skipped in the Rules compilation (line 37 of `Rules`). This prevents Nanoc from trying to compile them as standalone stylesheets. The `all.css.scss` entry point uses `@use` to import them.

- **Passthrough rule order**: The `passthrough "/**/*"` rule at the end of `Rules` catches all files not explicitly compiled. This means images, fonts, `robots.txt`, `humans.txt`, `favicon.ico` are copied as-is to `output/`.

- **Archive meetup nesting**: Each entry in `archive.yml` has an extra wrapping `meetup:` key (`meetups: → - meetup: → date/type/talks`). Don't omit this nesting when adding new entries.

- **Gemfile.lock platform**: Locked to `x86_64-linux` only. Running `bundle install` on macOS will regenerate the lockfile with darwin platform gems. The CI uses `x86_64-linux` and cache.

- **No `output/` in repo**: The build output is gitignored. The site is built during CI and deployed directly from the artifact.

- **Dart Sass**: Uses `nanoc-dart-sass` (Sass embedded via Dart), **not** the legacy `sass` gem. The `sass-embedded` gem is platform-specific and compiled natively.

- **Rainpress CSS minifier**: Applied after Sass compilation. If CSS output looks unexpected, check whether Rainpress is stripping something it shouldn't (it's a very aggressive minifier).

## Adding or editing content

### Adding a new page

1. Create `content/<name>.haml` with YAML frontmatter (`title: "..."` at top)
2. It's automatically compiled by the HAML rule in `Rules` — no rule changes needed
3. Add its strings to `data/static.yml`
4. Add navigation links in `layouts/partials/_header.haml`

### Adding a past meetup

1. Add a new entry to `data/archive.yml` under `meetups:` following the existing structure
2. If a sponsor logo is needed, place it in `content/images/sponsors/`
3. No recompilation of pages needed — the `past.haml` iterates over all entries automatically

### Changing site text

Almost all text lives in `data/static.yml`. Search there first before touching templates.

### Updating the "next meetup" status

Set `ready: true` in `data/static.yml` and create `data/new.yml` with the meetup structure (follow `data/default.yml` as a template). When the event passes, set `ready: false` and archive it.

## Styling approach

- SCSS variables in `_variables.scss` (colors, fonts)
- Mixins in `_mixins.scss` (border-radius, box-shadow, clearfix, etc.)
- `_normalize.scss` is a vendored reset
- `all.css.scss` is the compilation entry point — uses `@use` imports (Dart Sass module system)
- Responsive breakpoints: 768px, 896px, 1024px defined in `all.css.scss`
- The layout uses `flex` for the double-talk layout and for the footer on wider screens

## Deployment

Automated via `.github/workflows/publish.yml`:

1. Triggered on push to `master`
2. Sets up Ruby 3.4 with bundler cache
3. Installs gems (excluding development group)
4. Runs `bundle exec nanoc` to build the site
5. Uploads `output/` as a Pages artifact
6. Deploys to GitHub Pages

Docker alternative: `docker build -t site . && docker run -p 3000:3000 site`
