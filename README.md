# Viver Arroios

A Jekyll site featuring an interactive full-screen map powered by MapLibre GL JS, using the Carto Positron basemap and Bootstrap framework.

## Features

- 🗺️ Full-screen interactive map using MapLibre GL JS
- 🎨 Carto Positron basemap hosted on Carto's servers
- 📱 Responsive design with Bootstrap 5.3.2
- ⚡ Jekyll 4.4.1 for static site generation
- 🎨 CDN-based CSS (no Sass compilation needed)
- 🚀 GitHub Pages deployment ready
- 🔧 StandardRB for Ruby code linting

## Prerequisites

- Ruby 3.0+ (recommended: 3.1+)
- Bundler
- Git

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd viver-arroios
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Start the development server**
   ```bash
   bundle exec jekyll serve
   ```

4. **Open your browser**
   Navigate to `http://localhost:4000`

## Development

### Local Development

The site will automatically reload when you make changes to your files. The Jekyll development server watches for changes and rebuilds the site.

### Code Quality

This project uses StandardRB for Ruby code linting:

```bash
# Run the linter
bundle exec standardrb

# Auto-fix issues
bundle exec standardrb --fix
```

### Map Configuration

The map is centered on Lisbon, Portugal by default. You can modify the map settings in `_layouts/default.html`:

- **Center coordinates**: Change the `center` property
- **Zoom level**: Modify the `zoom` property  
- **Basemap**: The Carto Positron style is configured in the `style` object

### Customization

- **Site information**: Edit `_config.yml`
- **Styles**: Modify the `<style>` section in `_layouts/default.html`
- **Content**: Edit `index.markdown`
- **Layout**: Modify `_layouts/default.html`

## Deployment

### GitHub Pages

This site is configured for automatic deployment to GitHub Pages using Jekyll 4.4.1:

1. Enable GitHub Pages in your repository settings
2. Set the source to "GitHub Actions"
3. Push your code to the `main` branch
4. GitHub Actions will automatically build and deploy your site
5. Your site will be available at `https://yourusername.github.io/repository-name`

### Manual Build

To build the site manually:

```bash
# Build for production
JEKYLL_ENV=production bundle exec jekyll build

# The built site will be in the _site directory
```

## Map Features

- **Navigation controls**: Zoom in/out buttons
- **Geolocation**: Find user's current location
- **Scale indicator**: Shows map scale
- **Responsive overlay**: Site title and description with glass-morphism effect

## Browser Support

- Modern browsers supporting ES6+
- WebGL support required for MapLibre GL JS
- Responsive design works on mobile and desktop

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run StandardRB linting
5. Test locally
6. Submit a pull request

## License

This project is open source. Please check the LICENSE file for details.

## Tech Stack

- **Static Site Generator**: Jekyll 4.4.1 (standalone, no github-pages gem)
- **CSS Framework**: Bootstrap 5.3.2 (CDN)
- **Map Library**: MapLibre GL JS 3.6.2 (CDN)
- **Basemap**: Carto Positron (hosted on Carto servers)
- **Code Quality**: StandardRB
- **Deployment**: GitHub Pages via GitHub Actions