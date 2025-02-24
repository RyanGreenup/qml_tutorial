serve:
    uv run -- mkdocs serve --dirty -a 0.0.0.0:28472
deploy:
    uv run -- mkdocs gh-deploy -b gh-pages
build:
    uv run -- mkdocs build
