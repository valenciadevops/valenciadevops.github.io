# ValenciaDevOps

Static website for the **ValenciaDevOps** meetup group, built with [Nanoc](https://nanoc.app/) and deployed to GitHub Pages.

## Stack

- **Generator:** [Nanoc](https://nanoc.app/) (Ruby)
- **Templating:** HAML
- **Styling:** SCSS compiled with Dart Sass (`nanoc-dart-sass`), then minified with Rainpress
- **Data:** YAML files under `data/`
- **JavaScript:** None — the site is 100% JavaScript-free

## Development

Build the site to `output/`:

```bash
bundle exec nanoc
```

Start the development server with live reload:

```bash
bundle exec nanoc view
```

Then open http://localhost:3000.

## Architecture

```
data/*.yml      ──┐
content/*.haml  ──┤──> Rules ──> HAML/Sass filters ──> layouts/default.haml ──> output/*.html
layouts/        ──┘                                      (wraps with header + footer partials)
```

### Key files

| Path | Purpose |
|------|---------|
| `Rules` | Nanoc compilation rules — maps file types to filters and output paths |
| `nanoc.yaml` | Nanoc config (text extensions, data source, auto-prune) |
| `content/` | Pages (`index.haml`, `event.haml`, `past.haml`) + static assets |
| `layouts/default.haml` | Base HTML shell — includes `_header` and `_footer` partials, renders `yield` |
| `lib/helpers.rb` | Ruby helpers loaded by Nanoc (`data` accessor, `is_page_selected`, rendering) |
| `data/static.yml` | All translatable strings, nav labels, social links, page copy |
| `data/default.yml` | Fallback meetup data shown when no active event |
| `data/archive.yml` | All past meetups with talks, authors, dates, YouTube links |
| `.github/workflows/publish.yml` | CI: builds site and deploys to GitHub Pages |
| `Dockerfile` | Multi-stage build: installs gems, builds site, serves via `adsf` |

## Look & Feel

The CSS is modern, lightweight, and interaction-rich **without any JavaScript**:

- Smooth scrolling (`scroll-behavior: smooth`)
- Subtle hover animations (lift on article cards, scale on buttons, zoom on partner logo)
- Accessible focus-visible rings for keyboard navigation
- Respects `prefers-reduced-motion` for users who disable animations
- Sticky footer via CSS flexbox
- Responsive breakpoints: 768px, 896px, 1024px

## Deployment

Automated via GitHub Actions on every push to `master`:

1. Sets up Ruby 3.4 with bundler cache
2. Installs gems (excluding development group)
3. Runs `bundle exec nanoc` to build the site
4. Uploads `output/` as a Pages artifact
5. Deploys to GitHub Pages

Docker alternative:

```bash
docker build -t site . && docker run -p 3000:3000 site
```

## Authors

- Jose Luis Salas
- Omar Lopez

## Contributors

- Salva Ferrando
- Cesar Saez
- Tony Camaiani ([tony.camaiani.me](http://tony.camaiani.me/))
