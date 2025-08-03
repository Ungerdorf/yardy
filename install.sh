#!/bin/bash

# Color Transition Input App - Ubuntu Install Script
# This script sets up a Node.js server on port 7788

set -e

echo "🚀 Starting installation of Color Transition Input App..."

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    echo "❌ Please don't run this script as root. Run as a regular user with sudo privileges."
    exit 1
fi

# Update system
echo "📦 Updating system packages..."
sudo apt update

# Install Node.js and npm
echo "📦 Installing Node.js and npm..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify installation
echo "✅ Node.js version: $(node --version)"
echo "✅ npm version: $(npm --version)"

# Create application directory
APP_DIR="$HOME/color-input-app"
echo "📁 Creating application directory at $APP_DIR..."
mkdir -p "$APP_DIR"
cd "$APP_DIR"

# Create package.json
echo "📝 Creating package.json..."
cat > package.json << 'EOF'
{
  "name": "color-input-app",
  "version": "1.0.0",
  "description": "Color transition input app with backend storage",
  "main": "server.js",
  "scripts": {
    "start": "node server.js",
    "dev": "node server.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5",
    "body-parser": "^1.20.2"
  },
  "keywords": ["input", "color", "transition"],
  "author": "Color Input App",
  "license": "MIT"
}
EOF

# Install dependencies
echo "📦 Installing npm dependencies..."
npm install

# Create server.js
echo "📝 Creating server.js..."
cat > server.js << 'EOF'
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
const fs = require('fs').promises;
const path = require('path');

const app = express();
const PORT = 7788;
const DATA_FILE = path.join(__dirname, 'prompts.json');

// Middleware
app.use(cors());
app.use(bodyParser.json());
app.use(express.static('public'));

// Initialize data file if it doesn't exist
async function initializeDataFile() {
    try {
        await fs.access(DATA_FILE);
    } catch (error) {
        await fs.writeFile(DATA_FILE, JSON.stringify([], null, 2));
        console.log('📁 Created prompts.json file');
    }
}

// Load existing data
async function loadData() {
    try {
        const data = await fs.readFile(DATA_FILE, 'utf8');
        return JSON.parse(data);
    } catch (error) {
        console.error('Error loading data:', error);
        return [];
    }
}

// Save data
async function saveData(data) {
    try {
        await fs.writeFile(DATA_FILE, JSON.stringify(data, null, 2));
        return true;
    } catch (error) {
        console.error('Error saving data:', error);
        return false;
    }
}

// Routes
app.get('/api/prompts', async (req, res) => {
    try {
        const data = await loadData();
        res.json(data);
    } catch (error) {
        res.status(500).json({ error: 'Failed to load prompts' });
    }
});

app.post('/api/prompts', async (req, res) => {
    try {
        const { text } = req.body;
        
        if (!text || text.trim() === '') {
            return res.status(400).json({ error: 'Text is required' });
        }

        const data = await loadData();
        const newEntry = {
            id: Date.now(),
            text: text.trim(),
            length: text.trim().length,
            timestamp: new Date().toISOString(),
            ip: req.ip || req.connection.remoteAddress
        };

        data.push(newEntry);
        const saved = await saveData(data);

        if (saved) {
            console.log(`💾 Saved prompt: "${text.trim()}" (${text.trim().length} chars)`);
            res.json({ success: true, entry: newEntry });
        } else {
            res.status(500).json({ error: 'Failed to save prompt' });
        }
    } catch (error) {
        console.error('Error saving prompt:', error);
        res.status(500).json({ error: 'Internal server error' });
    }
});

app.delete('/api/prompts', async (req, res) => {
    try {
        await saveData([]);
        console.log('🗑️ Cleared all prompts');
        res.json({ success: true, message: 'All prompts cleared' });
    } catch (error) {
        res.status(500).json({ error: 'Failed to clear prompts' });
    }
});

// Serve the main page
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// Error handling
app.use((err, req, res, next) => {
    console.error(err.stack);
    res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
    res.status(404).json({ error: 'Not found' });
});

// Start server
async function startServer() {
    await initializeDataFile();
    
    app.listen(PORT, '0.0.0.0', () => {
        console.log('🎨 Color Transition Input App');
        console.log('================================');
        console.log(`🌐 Server running on http://localhost:${PORT}`);
        console.log(`🌐 Access from network: http://YOUR_SERVER_IP:${PORT}`);
        console.log(`📁 Data stored in: ${DATA_FILE}`);
        console.log('================================');
        console.log('Press Ctrl+C to stop the server');
    });
}

startServer().catch(console.error);
EOF

# Create public directory
echo "📁 Creating public directory..."
mkdir -p public

# Create index.html
echo "📝 Creating index.html..."
cat > public/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Color Transition Input</title>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            min-height: 100vh;
            display: flex;
            flex-direction: column;
            align-items: center;
            justify-content: center;
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: #ff4444;
            transition: background-color 0.3s ease;
            padding: 20px;
        }

        .container {
            background: rgba(255, 255, 255, 0.95);
            backdrop-filter: blur(10px);
            border-radius: 16px;
            padding: 40px;
            box-shadow: 0 20px 40px rgba(0, 0, 0, 0.1);
            width: 100%;
            max-width: 600px;
            text-align: center;
        }

        .dark .container {
            background: rgba(24, 24, 24, 0.95);
            color: white;
        }

        h1 {
            margin-bottom: 24px;
            font-size: 28px;
            font-weight: 700;
            color: #333;
        }

        .dark h1 {
            color: white;
        }

        .input-container {
            position: relative;
            margin-bottom: 24px;
        }

        #textInput {
            width: 100%;
            padding: 16px 20px;
            font-size: 16px;
            border: 2px solid #e0e0e0;
            border-radius: 12px;
            outline: none;
            transition: all 0.3s ease;
            background: white;
        }

        .dark #textInput {
            background: #2a2a2a;
            border-color: #444;
            color: white;
        }

        #textInput:focus {
            border-color: #5D5CDE;
            box-shadow: 0 0 0 3px rgba(93, 92, 222, 0.1);
        }

        .character-counter {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            background: #5D5CDE;
            color: white;
            padding: 4px 8px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 600;
        }

        .instructions {
            color: #666;
            margin-bottom: 20px;
            font-size: 14px;
        }

        .dark .instructions {
            color: #ccc;
        }

        .controls {
            display: flex;
            gap: 12px;
            justify-content: center;
            margin-bottom: 20px;
            flex-wrap: wrap;
        }

        .btn {
            padding: 10px 20px;
            border: none;
            border-radius: 8px;
            cursor: pointer;
            font-size: 14px;
            font-weight: 600;
            transition: all 0.3s ease;
        }

        .btn-primary {
            background: #5D5CDE;
            color: white;
        }

        .btn-primary:hover {
            background: #4a49c7;
        }

        .btn-secondary {
            background: #6b7280;
            color: white;
        }

        .btn-secondary:hover {
            background: #4b5563;
        }

        .btn-danger {
            background: #ef4444;
            color: white;
        }

        .btn-danger:hover {
            background: #dc2626;
        }

        .btn:disabled {
            background: #ccc;
            cursor: not-allowed;
        }

        .data-display {
            margin-top: 20px;
            padding: 16px;
            background: #f5f5f5;
            border-radius: 8px;
            text-align: left;
            max-height: 300px;
            overflow-y: auto;
        }

        .dark .data-display {
            background: #1a1a1a;
            color: #ccc;
        }

        .data-display h3 {
            margin-bottom: 12px;
            color: #333;
        }

        .dark .data-display h3 {
            color: white;
        }

        .prompt-item {
            background: white;
            padding: 12px;
            margin-bottom: 8px;
            border-radius: 6px;
            border-left: 4px solid #5D5CDE;
        }

        .dark .prompt-item {
            background: #2a2a2a;
        }

        .prompt-text {
            font-weight: 600;
            margin-bottom: 4px;
        }

        .prompt-meta {
            font-size: 12px;
            color: #666;
        }

        .dark .prompt-meta {
            color: #999;
        }

        .status {
            position: fixed;
            top: 20px;
            right: 20px;
            padding: 12px 20px;
            border-radius: 8px;
            font-weight: 600;
            z-index: 1000;
            animation: slideIn 0.3s ease;
        }

        .status.success {
            background: #22c55e;
            color: white;
        }

        .status.error {
            background: #ef4444;
            color: white;
        }

        @keyframes slideIn {
            from { transform: translateX(100%); opacity: 0; }
            to { transform: translateX(0); opacity: 1; }
        }

        @media (max-width: 480px) {
            .container {
                padding: 24px;
            }
            
            h1 {
                font-size: 24px;
            }

            .controls {
                flex-direction: column;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>Color Transition Input</h1>
        <p class="instructions">
            Type in the input field below. The background will transition from red to green as you approach 20 characters. Press Enter to save your input to the server.
        </p>
        
        <div class="input-container">
            <input 
                type="text" 
                id="textInput" 
                placeholder="Start typing..." 
                maxlength="20"
            >
            <div class="character-counter" id="charCounter">0/20</div>
        </div>

        <div class="controls">
            <button class="btn btn-primary" id="loadBtn">Load Saved Prompts</button>
            <button class="btn btn-secondary" id="downloadBtn" disabled>Download JSON</button>
            <button class="btn btn-danger" id="clearBtn" disabled>Clear All</button>
        </div>

        <div class="data-display" id="dataDisplay" style="display: none;">
            <h3>Saved Prompts (<span id="promptCount">0</span>):</h3>
            <div id="promptsList"></div>
        </div>
    </div>

    <script>
        // Dark mode detection
        if (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) {
            document.documentElement.classList.add('dark');
        }
        window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', event => {
            if (event.matches) {
                document.documentElement.classList.add('dark');
            } else {
                document.documentElement.classList.remove('dark');
            }
        });

        const textInput = document.getElementById('textInput');
        const charCounter = document.getElementById('charCounter');
        const dataDisplay = document.getElementById('dataDisplay');
        const promptsList = document.getElementById('promptsList');
        const promptCount = document.getElementById('promptCount');
        const loadBtn = document.getElementById('loadBtn');
        const downloadBtn = document.getElementById('downloadBtn');
        const clearBtn = document.getElementById('clearBtn');
        
        let savedEntries = [];

        // Update background color based on input length
        function updateBackground(length) {
            const progress = Math.min(length / 20, 1);
            
            // Interpolate between red (255, 68, 68) and green (34, 197, 94)
            const red = Math.round(255 - (255 - 34) * progress);
            const green = Math.round(68 + (197 - 68) * progress);
            const blue = Math.round(68 + (94 - 68) * progress);
            
            document.body.style.backgroundColor = `rgb(${red}, ${green}, ${blue})`;
        }

        // Handle input changes
        textInput.addEventListener('input', function() {
            const length = this.value.length;
            charCounter.textContent = `${length}/20`;
            updateBackground(length);
        });

        // Handle Enter key press
        textInput.addEventListener('keypress', async function(e) {
            if (e.key === 'Enter') {
                const inputText = this.value.trim();
                
                if (inputText) {
                    try {
                        const response = await fetch('/api/prompts', {
                            method: 'POST',
                            headers: {
                                'Content-Type': 'application/json',
                            },
                            body: JSON.stringify({ text: inputText })
                        });

                        const result = await response.json();

                        if (result.success) {
                            showStatus('Prompt saved successfully!', 'success');
                            this.value = '';
                            charCounter.textContent = '0/20';
                            updateBackground(0);
                            
                            // Auto-reload if data is currently displayed
                            if (dataDisplay.style.display !== 'none') {
                                loadPrompts();
                            }
                        } else {
                            showStatus('Error: ' + result.error, 'error');
                        }
                    } catch (error) {
                        showStatus('Failed to save prompt', 'error');
                        console.error('Error:', error);
                    }
                }
            }
        });

        // Load prompts from server
        async function loadPrompts() {
            try {
                const response = await fetch('/api/prompts');
                const data = await response.json();
                savedEntries = data;
                updateDataDisplay();
                showStatus('Prompts loaded successfully!', 'success');
            } catch (error) {
                showStatus('Failed to load prompts', 'error');
                console.error('Error:', error);
            }
        }

        // Update data display
        function updateDataDisplay() {
            if (savedEntries.length > 0) {
                dataDisplay.style.display = 'block';
                promptCount.textContent = savedEntries.length;
                
                promptsList.innerHTML = savedEntries
                    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
                    .map(entry => `
                        <div class="prompt-item">
                            <div class="prompt-text">"${entry.text}"</div>
                            <div class="prompt-meta">
                                ${entry.length} chars • ${new Date(entry.timestamp).toLocaleString()}
                            </div>
                        </div>
                    `).join('');
                
                downloadBtn.disabled = false;
                clearBtn.disabled = false;
            } else {
                promptCount.textContent = '0';
                promptsList.innerHTML = '<p>No prompts saved yet.</p>';
                downloadBtn.disabled = true;
                clearBtn.disabled = true;
            }
        }

        // Clear all prompts
        async function clearAllPrompts() {
            if (savedEntries.length === 0) return;
            
            try {
                const response = await fetch('/api/prompts', {
                    method: 'DELETE'
                });
                const result = await response.json();
                
                if (result.success) {
                    savedEntries = [];
                    updateDataDisplay();
                    showStatus('All prompts cleared!', 'success');
                } else {
                    showStatus('Error: ' + result.error, 'error');
                }
            } catch (error) {
                showStatus('Failed to clear prompts', 'error');
                console.error('Error:', error);
            }
        }

        // Download JSON file
        function downloadJSON() {
            if (savedEntries.length === 0) return;
            
            const dataStr = JSON.stringify(savedEntries, null, 2);
            const blob = new Blob([dataStr], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = `prompts-${new Date().toISOString().split('T')[0]}.json`;
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);
        }

        // Show status message
        function showStatus(message, type) {
            const status = document.createElement('div');
            status.textContent = message;
            status.className = `status ${type}`;
            
            document.body.appendChild(status);
            
            setTimeout(() => {
                status.remove();
            }, 3000);
        }

        // Event listeners
        loadBtn.addEventListener('click', loadPrompts);
        downloadBtn.addEventListener('click', downloadJSON);
        clearBtn.addEventListener('click', clearAllPrompts);

        // Initialize
        updateBackground(0);
    </script>
</body>
</html>
EOF

# Create systemd service file
echo "📝 Creating systemd service..."
sudo tee /etc/systemd/system/color-input-app.service > /dev/null << EOF
[Unit]
Description=Color Transition Input App
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/node server.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production

[Install]
WantedBy=multi-user.target
EOF

# Set proper permissions
echo "🔐 Setting permissions..."
chmod +x "$APP_DIR/server.js"

# Reload systemd and enable service
echo "⚙️ Configuring systemd service..."
sudo systemctl daemon-reload
sudo systemctl enable color-input-app

# Start the service
echo "🚀 Starting the application..."
sudo systemctl start color-input-app

# Check service status
sleep 2
if sudo systemctl is-active --quiet color-input-app; then
    echo "✅ Application started successfully!"
    echo ""
    echo "🎉 Installation Complete!"
    echo "================================"
    echo "🌐 Application URL: http://localhost:7788"
    echo "🌐 Network Access: http://$(hostname -I | awk '{print $1}'):7788"
    echo "📁 App Directory: $APP_DIR"
    echo "📄 Data File: $APP_DIR/prompts.json"
    echo ""
    echo "📋 Useful Commands:"
    echo "  View logs: sudo journalctl -u color-input-app -f"
    echo "  Restart:   sudo systemctl restart color-input-app"
    echo "  Stop:      sudo systemctl stop color-input-app"
    echo "  Status:    sudo systemctl status color-input-app"
    echo ""
    echo "🔥 The app will automatically start on system boot!"
else
    echo "❌ Failed to start the application. Check logs with:"
    echo "sudo journalctl -u color-input-app"
fi
EOF

Now let me create a simpler manual start script as well:
```code_edit_tool
tool_use_id=toolu_vrtx_01MPdwsAaztc3TrUwoKub7ZQ
tool_name=replace_code
input={"old_str": "EOF", "new_str": "EOF\n\n# Create manual start script\necho \"📝 Creating manual start script...\"\ncat > start.sh << 'EOF'\n#!/bin/bash\necho \"🎨 Starting Color Transition Input App...\"\necho \"🌐 Server will be available at http://localhost:7788\"\necho \"Press Ctrl+C to stop\"\nnode server.js\nEOF\n\nchmod +x start.sh\n\necho \"\"\necho \"📝 Created additional files:\"\necho \"  - start.sh (manual start script)\"\necho \"  - Use ./start.sh to run without systemd\""}
