#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# This script sets up the Agent Builder with Ollama
# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Flags from env or argv
for arg in "$@"; do
  [[ "$arg" == "--skip-ai" ]] && export SKIP_AI_MENU=1
done
NONINTERACTIVE="${NONINTERACTIVE:-}"

# ASCII symbols for visual feedback - works on all platforms
CHECK="${GREEN}[✓]${NC}"
WORKING="${BLUE}[...]${NC}"
WARN="${YELLOW}[!]${NC}"
ERROR="${RED}[X]${NC}"
PARTY="*"
BOLD='\033[1m'

# Function to show progress
show_progress() {
    echo -e "${WORKING} $1..."
}

# Function to show completion
show_done() {
    echo -e "${CHECK} $1"
}

# Function to show error with helpful message
show_error() {
    echo -e "${ERROR} $1"
    echo -e "${YELLOW}Tip: $2${NC}"
}

# Clear screen for fresh start
clear

# Welcome banner
echo -e "${BLUE}${BOLD}"
echo "================================================="
echo "                                                 "
echo "         🤖 Agent Builder - Easy Setup!          "
echo "                                                 "
echo "      Build AI agents by chatting with AI!       "
echo "                                                 "
echo "================================================="
echo -e "${NC}"
echo ""
echo -e "${GREEN}Welcome! This setup will take about 2-3 minutes.${NC}"
echo -e "${YELLOW}Don't worry - you can't break anything!${NC}"
echo ""
if [[ -z "$NONINTERACTIVE" ]]; then
  echo "Press Enter to continue..."
  read
fi

# Function to check if a package is installed globally
check_installed() {
    if npm list -g "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to update all installation status
update_installation_status() {
    CLAUDE_INSTALLED=false
    CODEX_INSTALLED=false
    GEMINI_INSTALLED=false
    
    check_installed "@anthropic-ai/claude-code" && CLAUDE_INSTALLED=true
    check_installed "@openai/codex" && CODEX_INSTALLED=true
    check_installed "@google/gemini-cli" && GEMINI_INSTALLED=true
}

# Function to check Node.js version
check_node_version() {
    if command -v node >/dev/null 2>&1; then
        REQUIRED_VERSION="18.0.0"
        node -e "process.exit(process.versions.node.localeCompare('$REQUIRED_VERSION', undefined, {numeric:true, sensitivity:'base'}) >= 0 ? 0 : 1)"
        return $?
    else
        return 1
    fi
}

# Enhanced installation function for AI tools
install_ai_tool() {
    local tool_name=$1
    local package_name=$2
    
    # Check if already installed
    if check_installed "$package_name"; then
        show_done "$tool_name is already installed"
        return 0
    fi
    
    show_progress "Installing $tool_name"
    
    # Progress indicator
    (
        while true; do
            echo -n "."
            sleep 1
        done
    ) &
    local PROGRESS_PID=$!
    
    if npm install -g "$package_name" > "/tmp/${tool_name// /-}-install.log" 2>&1; then
        kill $PROGRESS_PID 2>/dev/null
        echo ""
        show_done "$tool_name installed successfully!"
        return 0
    else
        kill $PROGRESS_PID 2>/dev/null
        echo ""
        show_error "Failed to install $tool_name" "You can try again later with: npm install -g $package_name"
        return 1
    fi
}

# Check prerequisites
echo ""
echo -e "${BLUE}${BOLD}Step 1: Checking Prerequisites${NC}"
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    show_error "Node.js is not installed" "Please visit https://nodejs.org to download and install it"
    exit 1
elif ! check_node_version; then
    show_error "Please update Node.js to version 18 or higher" "Download from https://nodejs.org"
    exit 1
else
    show_done "Node.js $(node -v) detected"
fi

# Check npm
if ! command -v npm &> /dev/null; then
    show_error "npm is not installed" "npm should come with Node.js. Please reinstall Node.js"
    exit 1
else
    show_done "npm $(npm -v) detected"
fi

echo ""
echo -e "${BLUE}${BOLD}Step 2: Checking Installed AI Assistants${NC}"
echo ""

# Check which tools are already installed
update_installation_status

if [ "$CLAUDE_INSTALLED" = true ]; then
    show_done "Claude Code - Already installed"
else
    echo -e "${YELLOW}○${NC} Claude Code - Not installed"
fi

if [ "$CODEX_INSTALLED" = true ]; then
    show_done "OpenAI Codex CLI - Already installed"
else
    echo -e "${YELLOW}○${NC} OpenAI Codex CLI - Not installed"
fi

if [ "$GEMINI_INSTALLED" = true ]; then
    show_done "Gemini CLI - Already installed"
else
    echo -e "${YELLOW}○${NC} Gemini CLI - Not installed"
fi

echo ""

if [[ -n "${SKIP_AI_MENU:-}" ]]; then
  echo -e "${YELLOW}Skipping AI assistant installation (handled by launcher).${NC}"
else
  # Always show Step 3 for consistency
  echo ""
  echo -e "${BLUE}${BOLD}Step 3: Choose Your AI Assistant${NC}"
  echo ""

# Check if all tools are already installed
if [ "$CLAUDE_INSTALLED" = true ] && [ "$CODEX_INSTALLED" = true ] && [ "$GEMINI_INSTALLED" = true ]; then
    echo -e "${GREEN}${BOLD}✓ All AI assistants are already installed!${NC}"
    echo ""
    echo "You can start using:"
    echo -e "   ${YELLOW}npx claude${NC}   # For Claude Code"
    echo -e "   ${YELLOW}npx codex${NC}    # For OpenAI Codex"
    echo -e "   ${YELLOW}npx gemini${NC}   # For Google Gemini"
    echo ""
else
    # Only show menu if not all tools are installed
    if [ "$CLAUDE_INSTALLED" = false ] || [ "$CODEX_INSTALLED" = false ] || [ "$GEMINI_INSTALLED" = false ]; then
        echo "Which AI assistant would you like to install?"
        echo ""
        
        # Build dynamic menu
        MENU_OPTIONS=()
        MENU_MAPPING=()
        OPTION_NUM=1
        
        # Add Gemini if not installed
        if [ "$GEMINI_INSTALLED" = false ]; then
            echo -e "${BOLD}$OPTION_NUM) ${YELLOW}Google Gemini${NC}"
            echo "   • Sign in with your Google account"
            echo "   • Free tier: 60 requests/min and 1,000 requests/day"
            echo ""
            MENU_OPTIONS+=("$OPTION_NUM")
            MENU_MAPPING+=("gemini")
            ((OPTION_NUM++))
        fi
        
        # Add Claude if not installed
        if [ "$CLAUDE_INSTALLED" = false ]; then
            echo -e "${BOLD}$OPTION_NUM) ${GREEN}Claude Code${NC}"
            echo "   • Sign in with your Claude.ai account (subscription plan) or use API key"
            echo "   • Subscription: Claude.ai plans (e.g., Pro)"
            echo ""
            MENU_OPTIONS+=("$OPTION_NUM")
            MENU_MAPPING+=("claude")
            ((OPTION_NUM++))
        fi
        
        # Add Codex if not installed
        if [ "$CODEX_INSTALLED" = false ]; then
            echo -e "${BOLD}$OPTION_NUM) ${BLUE}OpenAI Codex${NC}"
            echo "   • Use OpenAI Plus/Pro subscription OR API key"
            echo "   • API: Pay-as-you-go with free credits for new users"
            echo "   • Subscription: Included in OpenAI Plus"
            echo ""
            MENU_OPTIONS+=("$OPTION_NUM")
            MENU_MAPPING+=("codex")
            ((OPTION_NUM++))
        fi
        
        # Add "Install all remaining" option if more than one is not installed
        TOOLS_NOT_INSTALLED=0
        [ "$GEMINI_INSTALLED" = false ] && ((TOOLS_NOT_INSTALLED++))
        [ "$CLAUDE_INSTALLED" = false ] && ((TOOLS_NOT_INSTALLED++))
        [ "$CODEX_INSTALLED" = false ] && ((TOOLS_NOT_INSTALLED++))
        
        if [ $TOOLS_NOT_INSTALLED -gt 1 ]; then
            echo -e "${BOLD}$OPTION_NUM) Install all remaining tools${NC}"
            echo ""
            MENU_OPTIONS+=("$OPTION_NUM")
            MENU_MAPPING+=("all")
            ((OPTION_NUM++))
        fi
        
        # Always add skip option
        echo -e "${BOLD}$OPTION_NUM) Skip for now${NC}"
        echo ""
        MENU_OPTIONS+=("$OPTION_NUM")
        MENU_MAPPING+=("skip")
        ((OPTION_NUM++))
        
        # Get user choice with validation
        while true; do
            echo -n "Enter your choice (1-$((OPTION_NUM-1))): "
            read -r choice
            
            # Check if choice is valid
            if [[ " ${MENU_OPTIONS[@]} " =~ " ${choice} " ]]; then
                break
            else
                echo -e "${RED}Please enter a number between 1 and $((OPTION_NUM-1))${NC}"
            fi
        done
        
        # Map choice to action
        ACTION_INDEX=$((choice - 1))
        ACTION="${MENU_MAPPING[$ACTION_INDEX]}"
        
        # Execute based on mapped action
        case $ACTION in
            "gemini")
                install_ai_tool "Gemini CLI" "@google/gemini-cli" && GEMINI_INSTALLED=true
                ;;
            "claude")
                install_ai_tool "Claude Code" "@anthropic-ai/claude-code" && CLAUDE_INSTALLED=true
                ;;
            "codex")
                install_ai_tool "OpenAI Codex CLI" "@openai/codex" && CODEX_INSTALLED=true
                ;;
            "all")
                echo ""
                echo -e "${BLUE}Installing all remaining AI assistants...${NC}"
                echo ""
                [ "$GEMINI_INSTALLED" = false ] && install_ai_tool "Gemini CLI" "@google/gemini-cli" && GEMINI_INSTALLED=true
                [ "$CLAUDE_INSTALLED" = false ] && install_ai_tool "Claude Code" "@anthropic-ai/claude-code" && CLAUDE_INSTALLED=true
                [ "$CODEX_INSTALLED" = false ] && install_ai_tool "OpenAI Codex CLI" "@openai/codex" && CODEX_INSTALLED=true
                ;;
            "skip")
                echo ""
                echo -e "${YELLOW}Skipping AI assistant installation${NC}"
                ;;
        esac
    fi
    fi
fi

# Final status check for AI assistants
echo ""
update_installation_status  # Re-check after installations

if [ "$CLAUDE_INSTALLED" = true ] && [ "$CODEX_INSTALLED" = true ] && [ "$GEMINI_INSTALLED" = true ]; then
    echo -e "${GREEN}${BOLD}All AI assistants are installed and ready!${NC}"
elif [ "$CLAUDE_INSTALLED" = true ] || [ "$CODEX_INSTALLED" = true ] || [ "$GEMINI_INSTALLED" = true ]; then
    echo -e "${BLUE}${BOLD}Installed AI assistants:${NC}"
    [ "$CLAUDE_INSTALLED" = true ] && echo -e "   ${GREEN}✓${NC} Claude Code"
    [ "$CODEX_INSTALLED" = true ] && echo -e "   ${GREEN}✓${NC} OpenAI Codex"
    [ "$GEMINI_INSTALLED" = true ] && echo -e "   ${GREEN}✓${NC} Google Gemini"
else
    echo -e "${YELLOW}No AI assistants installed yet.${NC}"
    echo "You can run setup.sh again later to install them."
fi
echo ""

echo ""
echo -e "${BLUE}${BOLD}Step 4: Checking Ollama (Local AI for Agents)${NC}"
echo ""

OLLAMA_READY=false

# Check Ollama
if command -v ollama &> /dev/null; then
    # Check if Ollama is running
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        show_done "Ollama is installed and running"
        
        # Check for models
        # Check if any models are installed (ollama list will show models with their version tags)
        if ollama list 2>/dev/null | grep -E "mistral-small:|gpt-oss:|deepseek-r1:|qwen3:|magistral:|mistral:|llama|gemma|phi|codellama" > /dev/null; then
            show_done "Ollama models detected"
            OLLAMA_READY=true
        else
            echo -e "${YELLOW}No models found. Installing mistral-small...${NC}"
            show_progress "Pulling mistral-small model (this may take a few minutes)"
            if ollama pull mistral-small >/dev/null 2>&1; then
                show_done "Model installed successfully"
                OLLAMA_READY=true
            else
                show_error "Failed to pull model" "Try running manually: ollama pull mistral-small"
            fi
        fi
    else
        show_error "Ollama installed but not running" "Start it with: ollama serve"
        echo ""
        echo "Would you like me to start Ollama now? (y/n)"
        read start_ollama
        if [[ $start_ollama =~ ^[Yy]$ ]]; then
            echo "Starting Ollama in background..."
            ollama serve >/dev/null 2>&1 &
            sleep 3
            if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
                show_done "Ollama started successfully"
                OLLAMA_READY=true
            else
                show_error "Failed to start Ollama" "Try running manually: ollama serve"
            fi
        fi
    fi
else
    echo -e "${WARN} Ollama not installed"
    echo ""
    echo -e "${YELLOW}Ollama is needed for agents to run locally (free)${NC}"
    echo -e "To install Ollama:"
    echo "1. Visit https://ollama.ai"
    echo "2. Download for your system"
    echo "3. Run the installer"
    echo "4. Come back and run this setup again"
    echo ""
fi

echo ""
echo -e "${BLUE}${BOLD}Step 5: Setting Up Project Files${NC}"
echo ""

# Check if agent.stub exists
if [ ! -f "agent.stub" ]; then
    echo -e "${ERROR} agent.stub not found!"
    echo -e "${YELLOW}Please ensure agent.stub is in the current directory${NC}"
    echo "You can get it from: https://github.com/builtbyV/agent-builder"
else
    show_done "agent.stub template found"
fi

# Create .gitignore silently
if [ ! -f .gitignore ]; then
    cat > .gitignore << 'EOF'
node_modules/
*.log
.DS_Store
Thumbs.db
.vscode/
.idea/
*.tmp
*.temp
output/
AGENTS.md
CLAUDE.md
setup.sh
docs/
agent.stub
QUICK_REFERENCE.txt
EOF
    show_done "Created .gitignore file"
fi

# Remove template git
rm -rf .git 2>/dev/null

# Remove LICENSE
rm -rf LICENSE 2>/dev/null

# Create a quick reference file
echo ""
if [[ -z "$NONINTERACTIVE" ]]; then
  read -p "Would you like to create a QUICK_REFERENCE.txt file for reference? (y/n): " create_ref
else
  create_ref="n"
fi

if [[ $create_ref =~ ^[Yy]$ ]]; then
    # Start creating the file
    cat > QUICK_REFERENCE.txt << 'EOF'
AGENT BUILDER - QUICK REFERENCE
====================================

CREATING YOUR AGENT:
1. Start your AI assistant (see below)
2. Ask it to create an agent: "Create a research agent"
3. Run it: node your-agent.js "task" --yolo

AI COMMANDS:
EOF

    # Add only installed tools
    [ "$CLAUDE_INSTALLED" = true ] && echo "- npx claude   # Claude Code by Anthropic" >> QUICK_REFERENCE.txt
    [ "$CODEX_INSTALLED" = true ] && echo "- npx codex    # OpenAI Codex CLI" >> QUICK_REFERENCE.txt
    [ "$GEMINI_INSTALLED" = true ] && echo "- npx gemini   # Gemini CLI by Google" >> QUICK_REFERENCE.txt
    
    # If none installed
    if [ "$CLAUDE_INSTALLED" = false ] && [ "$CODEX_INSTALLED" = false ] && [ "$GEMINI_INSTALLED" = false ]; then
        echo "- No AI assistants installed yet. Run setup.sh to install one." >> QUICK_REFERENCE.txt
    fi

    # Continue with rest of content
    cat >> QUICK_REFERENCE.txt << 'EOF'

HELPFUL TERMINAL COMMANDS:
- cd folder-name   # Go into a folder
- cd ..           # Go back up one folder
- ls              # See files (Mac/Linux)
- dir             # See files (Windows)
- pwd             # See where you are
- Ctrl+C (or Command+C on Mac)  # Stop something running

COMMON REQUESTS TO YOUR AI:
- "Using agent.js, create a research agent"
- "Build an agent that can analyze code"
- "Create a data processing agent"
- "Make an agent that writes content"
- "Build an automation agent"

RUNNING YOUR AGENTS:
- node agent.js "task"        # Preview what agent will do
- node agent.js "task" --yolo # Execute immediately
- node agent.js "task" --model deepseek-r1  # Use specific model
- node agent.js "task" --cwd ./folder   # Set working directory

OLLAMA COMMANDS:
- ollama serve         # Start Ollama
- ollama list         # See installed models
- ollama pull mistral-small  # Install a model

CREATE ANOTHER AGENT:
cd ..
git clone https://github.com/builtbyV/agent-builder.git another-agent
cd another-agent
bash setup.sh

NEED HELP?
Just ask your AI assistant - they're here to help!
EOF
    show_done "Created QUICK_REFERENCE.txt for your reference"
fi

# Final success message
echo ""
echo -e "${GREEN}${BOLD}===================================================${NC}"
echo -e "${GREEN}${BOLD}     * Setup Complete! You're ready to build! *     ${NC}"
echo -e "${GREEN}${BOLD}===================================================${NC}"
echo ""
echo -e "${BLUE}${BOLD}What's Next?${NC}"
echo ""

echo "1. Start your AI assistant:"

# Show specific commands based on what was installed
if [ "$GEMINI_INSTALLED" = true ]; then
    echo -e "   ${YELLOW}npx gemini${NC}  # Sign in with your Google account"
fi
if [ "$CLAUDE_INSTALLED" = true ]; then
    echo -e "   ${YELLOW}npx claude${NC}  # Use subscription or set ANTHROPIC_AUTH_TOKEN"
fi
if [ "$CODEX_INSTALLED" = true ]; then
    echo -e "   ${YELLOW}npx codex${NC}   # Login with 'codex login' or set OPENAI_API_KEY"
fi

if [ "$CLAUDE_INSTALLED" = false ] && [ "$CODEX_INSTALLED" = false ] && [ "$GEMINI_INSTALLED" = false ]; then
    echo -e "   ${YELLOW}Run setup.sh again to install an AI assistant${NC}"
fi

echo ""
echo "2. Ask your AI to build an agent:"
echo -e "   ${GREEN}\"Create a research agent that analyzes news\"${NC}"
echo ""

if [ "$OLLAMA_READY" = true ]; then
    echo -e "${GREEN}✓ Ollama is ready for your agents to use${NC}"
else
    echo -e "${YELLOW}⚠ Remember to set up Ollama for agents to work${NC}"
fi

echo ""
echo -e "${GREEN}Need help? Check QUICK_REFERENCE.txt for commands!${NC}"
echo ""
echo -e "${BLUE}Happy building! *${NC}"
