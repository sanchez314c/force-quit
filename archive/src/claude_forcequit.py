#!/usr/bin/env python3
"""
Claude ForceQUIT - Python GUI Version
A simple utility to clean up system resources by closing unnecessary applications.
"""

import tkinter as tk
from tkinter import messagebox, ttk
import subprocess
import threading
import sys
import os
from PIL import Image, ImageDraw
import pystray
from pystray import MenuItem as item
import io

class ClaudeForceQUIT:
    def __init__(self):
        self.root = tk.Tk()
        self.root.title("Claude ForceQUIT")
        self.root.geometry("400x200")
        self.root.resizable(False, False)
        
        # Center the window
        self.center_window()
        
        # Essential processes that should never be killed
        self.essential_processes = {
            'kernel_task', 'launchd', 'kextcookied', 'UserEventAgent',
            'com.apple.WebKit', 'systemuiserver', 'Dock', 'Finder',
            'WindowServer', 'loginwindow', 'cfprefsd', 'distnoted',
            'coreaudiod', 'bluetoothd', 'WiFiAgent', 'airportd',
            'networkd', 'configd', 'mDNSResponder', 'syslogd',
            'Claude Code', 'Terminal', 'iTerm2'  # Keep development tools
        }
        
        self.setup_gui()
        self.setup_system_tray()
        
    def center_window(self):
        """Center the window on the screen"""
        self.root.update_idletasks()
        width = self.root.winfo_width()
        height = self.root.winfo_height()
        x = (self.root.winfo_screenwidth() // 2) - (width // 2)
        y = (self.root.winfo_screenheight() // 2) - (height // 2)
        self.root.geometry(f'{width}x{height}+{x}+{y}')
        
    def setup_gui(self):
        """Setup the main GUI window"""
        # Main frame
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.grid(row=0, column=0, sticky=(tk.W, tk.E, tk.N, tk.S))
        
        # Title label
        title_label = ttk.Label(main_frame, text="Claude ForceQUIT", 
                               font=('SF Pro Display', 16, 'bold'))
        title_label.grid(row=0, column=0, columnspan=2, pady=(0, 20))
        
        # Description
        desc_label = ttk.Label(main_frame, 
                              text="Force quit all non-essential applications and processes",
                              font=('SF Pro Display', 10))
        desc_label.grid(row=1, column=0, columnspan=2, pady=(0, 30))
        
        # Force Quit button
        self.force_quit_btn = ttk.Button(main_frame, 
                                        text="Force Quit All Non-Essential Applications & Processes",
                                        command=self.force_quit_applications,
                                        width=50)
        self.force_quit_btn.grid(row=2, column=0, columnspan=2, pady=(0, 20))
        
        # Button frame for OK button
        button_frame = ttk.Frame(main_frame)
        button_frame.grid(row=3, column=0, columnspan=2)
        
        # OK button
        ok_btn = ttk.Button(button_frame, text="OK", command=self.close_application)
        ok_btn.pack(side=tk.RIGHT)
        
        # Configure grid weights
        self.root.columnconfigure(0, weight=1)
        self.root.rowconfigure(0, weight=1)
        main_frame.columnconfigure(0, weight=1)
        
    def create_icon(self):
        """Create the system tray icon - X with circle around it"""
        # Create a 64x64 image
        image = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(image)
        
        # Draw circle
        circle_color = (220, 53, 69, 255)  # Red color
        draw.ellipse([8, 8, 56, 56], outline=circle_color, width=4)
        
        # Draw X
        x_color = (220, 53, 69, 255)  # Red color
        # First line of X (top-left to bottom-right)
        draw.line([20, 20, 44, 44], fill=x_color, width=4)
        # Second line of X (top-right to bottom-left)
        draw.line([44, 20, 20, 44], fill=x_color, width=4)
        
        return image
        
    def setup_system_tray(self):
        """Setup system tray icon and menu"""
        icon_image = self.create_icon()
        
        menu = pystray.Menu(
            item("ForceQuit", self.force_quit_from_tray),
            item("Exit ForceQuit", self.quit_application)
        )
        
        self.tray_icon = pystray.Icon("ClaudeForceQUIT", icon_image, "Claude ForceQUIT", menu)
        
        # Start tray icon in separate thread
        self.tray_thread = threading.Thread(target=self.tray_icon.run, daemon=True)
        self.tray_thread.start()
        
    def get_running_applications(self):
        """Get list of running applications"""
        try:
            # Get running applications using osascript
            result = subprocess.run([
                'osascript', '-e',
                'tell application "System Events" to get name of every process whose background only is false'
            ], capture_output=True, text=True)
            
            if result.returncode == 0:
                # Parse the result
                app_list = result.stdout.strip()
                if app_list:
                    # Remove the surrounding braces and split by comma
                    app_list = app_list.strip('{}')
                    apps = [app.strip().strip('"') for app in app_list.split(',')]
                    return apps
            return []
        except Exception as e:
            print(f"Error getting applications: {e}")
            return []
            
    def is_essential_process(self, process_name):
        """Check if a process is essential and should not be killed"""
        process_lower = process_name.lower()
        
        # Check against essential processes
        for essential in self.essential_processes:
            if essential.lower() in process_lower:
                return True
                
        # Additional checks for system processes
        if any(keyword in process_lower for keyword in [
            'system', 'kernel', 'apple', 'com.apple', 'security',
            'audio', 'bluetooth', 'wifi', 'network', 'login',
            'window', 'dock', 'finder', 'spotlight', 'notification'
        ]):
            return True
            
        return False
        
    def force_quit_applications(self):
        """Force quit all non-essential applications"""
        try:
            # Show confirmation dialog
            result = messagebox.askyesno(
                "Confirm Force Quit",
                "This will force quit all non-essential applications and processes.\n\n"
                "Essential system processes and development tools will be preserved.\n\n"
                "Continue?",
                icon="warning"
            )
            
            if not result:
                return
                
            # Disable button during operation
            self.force_quit_btn.config(state='disabled', text="Force Quitting...")
            self.root.update()
            
            # Get running applications
            running_apps = self.get_running_applications()
            
            quit_count = 0
            preserved_count = 0
            
            for app in running_apps:
                if not self.is_essential_process(app):
                    try:
                        # Force quit the application
                        subprocess.run([
                            'osascript', '-e',
                            f'tell application "{app}" to quit'
                        ], capture_output=True, timeout=5)
                        
                        # If graceful quit fails, force kill
                        subprocess.run([
                            'pkill', '-f', app
                        ], capture_output=True)
                        
                        quit_count += 1
                        print(f"Quit: {app}")
                        
                    except Exception as e:
                        print(f"Failed to quit {app}: {e}")
                else:
                    preserved_count += 1
                    print(f"Preserved: {app}")
                    
            # Re-enable button
            self.force_quit_btn.config(state='normal', text="Force Quit All Non-Essential Applications & Processes")
            
            # Show result
            messagebox.showinfo(
                "Force Quit Complete",
                f"Force quit operation completed!\n\n"
                f"Applications quit: {quit_count}\n"
                f"Essential apps preserved: {preserved_count}"
            )
            
        except Exception as e:
            # Re-enable button on error
            self.force_quit_btn.config(state='normal', text="Force Quit All Non-Essential Applications & Processes")
            messagebox.showerror("Error", f"An error occurred: {str(e)}")
            
    def force_quit_from_tray(self):
        """Force quit applications from system tray"""
        # Show the main window and perform force quit
        self.show_window()
        self.force_quit_applications()
        
    def show_window(self):
        """Show the main window"""
        self.root.deiconify()
        self.root.lift()
        self.root.focus_force()
        
    def hide_window(self):
        """Hide the main window"""
        self.root.withdraw()
        
    def close_application(self):
        """Close the main window but keep tray icon"""
        self.hide_window()
        
    def quit_application(self):
        """Completely quit the application"""
        self.tray_icon.stop()
        self.root.quit()
        self.root.destroy()
        sys.exit(0)
        
    def on_window_close(self):
        """Handle window close event"""
        self.hide_window()
        
    def run(self):
        """Run the application"""
        # Set up window close protocol
        self.root.protocol("WM_DELETE_WINDOW", self.on_window_close)
        
        # Start the GUI
        self.root.mainloop()

def main():
    """Main function"""
    try:
        # Check if required modules are available
        import pystray
        from PIL import Image, ImageDraw
    except ImportError:
        print("Required dependencies not found. Installing...")
        subprocess.run([sys.executable, '-m', 'pip', 'install', 'pystray', 'pillow'])
        print("Dependencies installed. Please run the application again.")
        return
        
    app = ClaudeForceQUIT()
    app.run()

if __name__ == "__main__":
    main()