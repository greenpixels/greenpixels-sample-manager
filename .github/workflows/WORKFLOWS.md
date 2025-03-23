# Build and Deploy Guide

This repository includes scripts to build the project and deploy it to [Itch.io](https://itch.io).

## Configuration

Modify the top-level variables inside `build.yml` to customize the build process:

```yaml
env:
  GODOT_VERSION: 4.4          # Specify the Godot version to use
  EXPORT_NAME: Game Name       # Name of the exported game build
  PROJECT_PATH: .              # Path to the Godot project (default: root directory)
  ITCH_GAME_NAME: game-name    # Itch.io game slug (should match your Itch.io project)
  ITCH_USER: itch-user-name    # Your Itch.io username
```

## Authentication

To enable deployment to Itch.io, set the following repository secrets:

- **`BUTLER_CREDENTIALS`** – Required for Itch.io uploads via [Butler](https://itch.io/docs/butler/)
- **`PAT`** – Personal Access Token for workflows

## Build and Deployment

Once properly configured, the build system will:

1. Export the Godot project.
2. Package the necessary files.
3. Upload the build to Itch.io using Butler.

Ensure you have set up your Itch.io project.
