claude_dir := env("HOME") / ".claude"

# Install agents and skills to ~/.claude
install:
    cp agents/*.md "{{claude_dir}}/agents/"
    @# Copy each skill directory (preserving structure)
    @for dir in skills/*/; do \
        name=$(basename "$dir"); \
        mkdir -p "{{claude_dir}}/skills/$name"; \
        cp "$dir"*.md "{{claude_dir}}/skills/$name/"; \
    done
    cp notify.sh "{{claude_dir}}/notify.sh"
    chmod +x "{{claude_dir}}/notify.sh"
    @echo "Installed agents, skills, and notify.sh to {{claude_dir}}"
