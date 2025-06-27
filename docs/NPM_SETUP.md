# NPM GitHub Packages Setup

## Environment Variable Configuration

The project uses GitHub Packages for the `@thepia` scoped packages. To install dependencies, you need to set up authentication using an environment variable.

### 1. Create a GitHub Personal Access Token

1. Go to GitHub Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. Give it a descriptive name (e.g., "Thepia NPM Access")
4. Select the following scopes:
   - `read:packages` - Download packages from GitHub Package Registry
   - `repo` (if you need to access private repositories)
5. Click "Generate token"
6. **Copy the token immediately** (you won't be able to see it again)

### 2. Set the Environment Variable

#### Option A: Shell Profile (Persistent)
Add to your `~/.zshrc`, `~/.bashrc`, or `~/.bash_profile`:

```bash
export NODE_AUTH_TOKEN=ghp_your_token_here
```

Then reload your shell:
```bash
source ~/.zshrc  # or ~/.bashrc
```

#### Option B: .env File (Project-specific)
Create a `.env` file in the project root:

```bash
NODE_AUTH_TOKEN=ghp_your_token_here
```

**⚠️ Important: Never commit the .env file to git!**

The `.env` file is already in `.gitignore` to prevent accidental commits.

#### Option C: Command Line (Temporary)
For one-time use:

```bash
export NODE_AUTH_TOKEN=ghp_your_token_here
npm install
```

### 3. Verify Installation

After setting the environment variable, run:

```bash
npm install
```

If successful, you should see the `@thepia` packages installing without authentication errors.

### 4. CI/CD Setup

For automated builds, set the `NODE_AUTH_TOKEN` environment variable in your CI/CD system:

- **GitHub Actions**: Add as a repository secret
- **Vercel**: Add in project settings → Environment Variables
- **Other platforms**: Follow their documentation for environment variables

### Troubleshooting

#### "Unable to authenticate" error
- Verify your token has the correct scopes
- Check that the token hasn't expired
- Ensure the environment variable is set correctly:
  ```bash
  echo $NODE_AUTH_TOKEN
  ```

#### "Package not found" error
- Verify you have access to the `@thepia` organization
- Check that the package exists in GitHub Packages
- Ensure your token has `read:packages` scope

### Security Notes

- Never commit tokens to git repositories
- Use environment variables or secure secret management
- Rotate tokens regularly
- Use the minimum required scopes
- Consider using fine-grained personal access tokens for better security