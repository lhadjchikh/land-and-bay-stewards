# Coalition Builder Documentation

This directory contains the complete documentation for Coalition Builder, built with MkDocs and deployed to GitHub Pages.

## 🌐 Live Documentation

The documentation is automatically deployed to GitHub Pages at:
**[your-org.github.io/coalition-builder](https://your-org.github.io/coalition-builder/)**

## 🛠️ Local Development

### Prerequisites

- Python 3.11+
- pip

### Setup and Serve

```bash
# Install dependencies
pip install -r docs/requirements.txt

# Serve locally with live reload
mkdocs serve

# Or use the convenience script
./docs/serve.sh
```

The documentation will be available at `http://localhost:8000` with live reload when you make changes.

### Building

```bash
# Build static site
mkdocs build

# Build with strict mode (fails on warnings)
mkdocs build --strict
```

## 📁 Documentation Structure

```
docs/
├── index.md                    # Main documentation hub
├── getting-started.md          # Quick start guide
├── user-guides/               # User-focused guides
│   ├── content-management.md  # Django admin usage
│   ├── api-usage.md          # API integration guide
│   └── homepage.md           # Homepage customization
├── development/              # Developer guides
│   ├── setup.md             # Development environment
│   ├── backend.md           # Django backend development
│   ├── frontend.md          # React frontend development
│   ├── ssr.md              # Next.js SSR development
│   └── testing.md          # Testing guidelines
├── deployment/              # Deployment guides
│   ├── aws.md              # AWS deployment with Terraform
│   ├── docker.md           # Container deployment
│   └── health.md           # Health monitoring
├── architecture/           # System architecture
│   ├── overview.md         # High-level system design
│   ├── api.md             # API design patterns
│   └── database.md        # Database schema
├── admin/                 # Administration guides
│   ├── terraform.md       # Infrastructure management
│   ├── cicd.md           # CI/CD workflows
│   └── troubleshooting.md # Common issues
├── contributing/          # Contribution guidelines
│   ├── guide.md          # How to contribute
│   └── style.md          # Code style guidelines
├── reference/            # Reference documentation
│   ├── environment.md    # Environment variables
│   ├── cli.md           # CLI commands
│   └── changelog.md     # Version history
└── api/                 # API documentation
    └── index.md         # Complete API reference
```

## 🔧 Configuration

### MkDocs Configuration

The documentation is configured in `mkdocs.yml` in the project root. Key features:

- **Material Theme**: Modern, responsive design
- **Navigation**: Organized sections with clear hierarchy
- **Search**: Full-text search functionality
- **Code Highlighting**: Syntax highlighting for multiple languages
- **Mobile Support**: Responsive design for all devices

### GitHub Actions

Documentation is automatically built and deployed via GitHub Actions (`.github/workflows/docs.yml`):

- **Triggers**: Changes to `docs/` or `mkdocs.yml`
- **Build**: MkDocs builds the static site
- **Deploy**: Automatically deploys to GitHub Pages on main branch

## ✍️ Writing Documentation

### Markdown Extensions

The documentation supports several Markdown extensions:

- **Admonitions**: Notes, warnings, tips
- **Code Blocks**: Syntax highlighting with copy buttons
- **Tables**: GitHub-flavored tables
- **Links**: Internal cross-references
- **Footnotes**: Reference-style footnotes

### Style Guidelines

1. **Use clear headings**: Structure content with H2 and H3 headings
2. **Include code examples**: Show practical usage
3. **Cross-link content**: Link to related documentation
4. **Keep it current**: Update docs when features change
5. **Be concise**: Provide clear, actionable information

### Example Admonitions

```markdown
!!! note "Important Information"
This is a note admonition.

!!! warning "Be Careful"
This is a warning admonition.

!!! tip "Pro Tip"
This is a tip admonition.
```

## 🚀 Deployment

### Automatic Deployment

Documentation is automatically deployed when:

1. Changes are pushed to the `main` branch
2. Changes affect files in `docs/` or `mkdocs.yml`
3. GitHub Actions builds and deploys to GitHub Pages

### Manual Deployment

```bash
# Build and deploy to gh-pages branch
mkdocs gh-deploy
```

## 🔍 Search

The documentation includes full-text search powered by MkDocs search plugin. All content is indexed and searchable from the documentation site.

## 📱 Mobile Support

The documentation is fully responsive and optimized for mobile devices using the Material theme.

## 🤝 Contributing

To contribute to the documentation:

1. Edit the relevant `.md` files in the `docs/` directory
2. Test locally with `mkdocs serve`
3. Submit a pull request
4. Documentation will automatically deploy after merge

For more details, see the [Contributing Guide](contributing/guide.md).
