#!/usr/bin/env python3
"""
Douyin Video Monitor - Monitor video statistics
"""

import time
import json
import re
import subprocess
import sys
from pathlib import Path


def check_and_install_dependencies():
    """Check and install required dependencies"""
    try:
        from DrissionPage import ChromiumPage, ChromiumOptions
        return ChromiumPage, ChromiumOptions
    except ImportError:
        print("Installing DrissionPage...")
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "DrissionPage", "-q"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL
        )
        print("Installation complete!\n")
        from DrissionPage import ChromiumPage, ChromiumOptions
        return ChromiumPage, ChromiumOptions


ChromiumPage, ChromiumOptions = check_and_install_dependencies()


# --- Configuration ---
VIDEO_URL = "https://www.douyin.com/video/7591799636210371890"
OUTPUT_FILE = Path(__file__).parent / "output.txt"
REFRESH_INTERVAL = 60  # seconds


def extract_video_id(url: str) -> str:
    """Extract video ID from Douyin URL"""
    match = re.search(r'/video/(\d+)', url)
    return match.group(1) if match else ""


def get_video_stats(page: ChromiumPage, video_id: str) -> dict:
    """Fetch video statistics using browser"""
    url = f"https://www.douyin.com/video/{video_id}"
    
    # Start listening for API response
    page.listen.start('aweme/v1/web/aweme/detail')
    page.get(url)
    
    # Wait for API response
    packet = page.listen.wait(timeout=20)
    
    if not packet:
        return None
    
    resp = packet.response
    data = resp.body if isinstance(resp.body, dict) else json.loads(resp.body)
    
    aweme = data.get('aweme_detail', {})
    if not aweme:
        return None
    
    stats = aweme.get('statistics', {})
    return {
        'digg': stats.get('digg_count', 0),
        'comment': stats.get('comment_count', 0),
        'collect': stats.get('collect_count', 0),
        'share': stats.get('share_count', 0),
    }


def format_output(stats: dict) -> str:
    """Format statistics for display"""
    if not stats:
        return "Failed to fetch data"
    
    return (
        f"点赞: {stats['digg']} "
        f"评论: {stats['comment']} "
        f"收藏: {stats['collect']} "
        f"转发: {stats['share']}"
    )


def main():
    video_id = extract_video_id(VIDEO_URL)
    if not video_id:
        print("Invalid video URL")
        return
    
    print("Douyin Video Monitor")
    print(f"Video ID: {video_id}")
    print(f"Output: {OUTPUT_FILE}")
    print("Press Ctrl+C to stop\n")
    
    # Configure browser
    co = ChromiumOptions()
    co.headless()
    co.set_argument('--no-sandbox')
    co.set_argument('--disable-gpu')
    co.set_argument('--disable-dev-shm-usage')
    
    page = ChromiumPage(co)
    
    try:
        while True:
            try:
                stats = get_video_stats(page, video_id)
                output = format_output(stats)
                
                # Clear screen and display
                print("\033[2J\033[H", end="")
                print(output)
                print(f"\nUpdated: {time.strftime('%H:%M:%S')}")
                
                # Write to file
                OUTPUT_FILE.write_text(output, encoding='utf-8')
                
            except Exception as e:
                print(f"Error: {e}")
            
            time.sleep(REFRESH_INTERVAL)
            
    except KeyboardInterrupt:
        print("\n\nStopped")
    finally:
        page.quit()


if __name__ == "__main__":
    main()
