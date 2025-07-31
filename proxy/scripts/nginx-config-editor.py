#!/usr/bin/env python3
"""
Nginx Configuration Editor - Safe way to edit nginx configs
"""
import re
import sys
import shutil
from datetime import datetime

class NginxConfigEditor:
    def __init__(self, config_file):
        self.config_file = config_file
        self.backup_file = None
        self.content = None
        self.lines = []
        
    def load(self):
        """Load the configuration file"""
        with open(self.config_file, 'r') as f:
            self.content = f.read()
            self.lines = self.content.split('\n')
        return self
        
    def backup(self):
        """Create a backup of the current config"""
        timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
        self.backup_file = f"{self.config_file}.backup-{timestamp}"
        shutil.copy2(self.config_file, self.backup_file)
        print(f"Backup created: {self.backup_file}")
        return self
        
    def find_server_block(self):
        """Find the main server block boundaries"""
        server_start = None
        server_end = None
        brace_count = 0
        in_server = False
        
        for i, line in enumerate(self.lines):
            if re.search(r'^\s*server\s*{', line):
                server_start = i
                in_server = True
                brace_count = 1
            elif in_server:
                brace_count += line.count('{')
                brace_count -= line.count('}')
                if brace_count == 0:
                    server_end = i
                    break
                    
        return server_start, server_end
        
    def add_location_block(self, location_block, before_line_pattern=None):
        """Add a location block inside the server block"""
        server_start, server_end = self.find_server_block()
        
        if server_start is None or server_end is None:
            raise ValueError("Could not find server block")
            
        # If pattern specified, find where to insert
        insert_line = server_end  # Default: before closing brace
        
        if before_line_pattern:
            for i in range(server_start, server_end):
                if re.search(before_line_pattern, self.lines[i]):
                    insert_line = i
                    break
                    
        # Insert the location block
        self.lines.insert(insert_line, location_block)
        return self
        
    def remove_lines_outside_blocks(self):
        """Remove any location directives outside of server blocks"""
        server_start, server_end = self.find_server_block()
        new_lines = []
        
        for i, line in enumerate(self.lines):
            # Keep lines inside server block or before it
            if i <= server_end:
                new_lines.append(line)
            # Skip location directives after server block
            elif not re.search(r'^\s*location\s+', line) and not re.search(r'^\s*#.*location', line):
                if not (re.search(r'^\s*add_header', line) and i > server_end):
                    new_lines.append(line)
                    
        self.lines = new_lines
        return self
        
    def save(self):
        """Save the modified configuration"""
        self.content = '\n'.join(self.lines)
        with open(self.config_file, 'w') as f:
            f.write(self.content)
        print(f"Configuration saved to: {self.config_file}")
        return self
        
    def validate(self):
        """Validate the nginx configuration"""
        import subprocess
        result = subprocess.run(['nginx', '-t'], capture_output=True, text=True)
        if result.returncode == 0:
            print("✓ Nginx configuration is valid")
            return True
        else:
            print("✗ Nginx configuration has errors:")
            print(result.stderr)
            return False

# Usage example
if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "add-mime-types":
        editor = NginxConfigEditor('/etc/nginx/sites-available/divita-proxy')
        
        # MIME type fixes for .mjs and .json files
        mime_location_block = '''
    # Fix MIME types for JavaScript modules and JSON
    location ~* \.(mjs|json)$ {
        root /var/www/html;
        
        # Set correct MIME types
        location ~ \.mjs$ {
            add_header Content-Type "application/javascript" always;
        }
        
        location ~ \.json$ {
            add_header Content-Type "application/json" always;
        }
        
        # Cache control
        add_header Cache-Control "public, max-age=31536000, immutable";
        add_header X-Content-Type-Options "nosniff";
    }'''
        
        try:
            editor.load()
            editor.backup()
            editor.remove_lines_outside_blocks()
            editor.add_location_block(mime_location_block)
            editor.save()
            
            if editor.validate():
                print("✓ Successfully added MIME type configuration")
            else:
                print("✗ Configuration has errors, restoring backup...")
                shutil.copy2(editor.backup_file, editor.config_file)
                
        except Exception as e:
            print(f"Error: {e}")
            if editor.backup_file:
                print("Restoring backup...")
                shutil.copy2(editor.backup_file, editor.config_file)
