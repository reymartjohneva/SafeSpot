"""
Firebase to Supabase Real-time Migration Webhook Service

This Python service listens to Firebase Realtime Database changes and 
instantly migrates data to Supabase, eliminating any delay.

Usage:
    python firebase_realtime_webhook.py

Requirements:
    pip install firebase-admin supabase requests python-dotenv
"""

import os
import json
import time
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import requests
from supabase import create_client, Client
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Firebase configuration
FIREBASE_HOST = "sim800l-gps-data-default-rtdb.firebaseio.com"
FIREBASE_AUTH_KEY = "9KzEmnOMRLzE0faPlxKyEc6TsHnjSmEq5me0AKs3"
FIREBASE_PATH = "/"

# Supabase configuration
SUPABASE_URL = "https://zbnnusmjpwvtsigvvlha.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inpibm51c21qcHd2dHNpZ3Z2bGhhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3NTgwODQsImV4cCI6MjA2OTMzNDA4NH0.GWG-9PLnpYU2-foc8wI7fzPza746TGVgmMgab2geZvk"

# Initialize Supabase client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Track processed records
processed_records = set()


def parse_firebase_timestamp(timestamp_str: str) -> Optional[str]:
    """
    Parse Firebase timestamp format to ISO 8601.
    
    Args:
        timestamp_str: Timestamp in format "YYYY-MM-DD HH:MM:SS"
        
    Returns:
        ISO 8601 formatted timestamp or None if invalid
    """
    try:
        # Parse format: "2025-10-06 01:18:13"
        dt = datetime.strptime(timestamp_str, "%Y-%m-%d %H:%M:%S")
        return dt.isoformat()
    except Exception as e:
        logger.error(f"Error parsing timestamp '{timestamp_str}': {e}")
        return None


def device_exists(device_id: str) -> bool:
    """
    Check if device exists in Supabase devices table.
    
    Args:
        device_id: The device ID to check
        
    Returns:
        True if device exists, False otherwise
    """
    try:
        response = supabase.table('devices').select('device_id').eq('device_id', device_id).execute()
        return len(response.data) > 0
    except Exception as e:
        logger.error(f"Error checking device existence for {device_id}: {e}")
        return False


def location_exists(device_id: str, latitude: float, longitude: float, timestamp: str) -> bool:
    """
    Check if location record already exists in Supabase.
    
    Args:
        device_id: Device ID
        latitude: Latitude
        longitude: Longitude
        timestamp: ISO 8601 timestamp
        
    Returns:
        True if exists, False otherwise
    """
    try:
        response = (supabase.table('location_history')
                    .select('id')
                    .eq('device_id', device_id)
                    .eq('latitude', latitude)
                    .eq('longitude', longitude)
                    .eq('timestamp', timestamp)
                    .execute())
        return len(response.data) > 0
    except Exception as e:
        logger.error(f"Error checking location existence: {e}")
        return False


def insert_location_data(
    device_id: str,
    latitude: float,
    longitude: float,
    speed: Optional[float],
    timestamp: str,
    firebase_key: str
) -> bool:
    """
    Insert location data into Supabase.
    
    Args:
        device_id: Device ID
        latitude: Latitude
        longitude: Longitude
        speed: Speed (optional)
        timestamp: ISO 8601 timestamp
        firebase_key: Original Firebase key
        
    Returns:
        True if inserted, False if skipped or error
    """
    try:
        # Check if already exists
        if location_exists(device_id, latitude, longitude, timestamp):
            logger.debug(f"Record {firebase_key} already exists, skipping")
            return False
        
        # Insert into Supabase
        data = {
            'device_id': device_id,
            'latitude': latitude,
            'longitude': longitude,
            'speed': speed,
            'timestamp': timestamp,
            'source': 'firebase'
        }
        
        supabase.table('location_history').insert(data).execute()
        logger.info(f"✅ Migrated record {firebase_key} to Supabase")
        return True
        
    except Exception as e:
        logger.error(f"Error inserting location data for {firebase_key}: {e}")
        return False


def process_firebase_record(firebase_key: str, record: Dict[str, Any]) -> bool:
    """
    Process a single Firebase record.
    
    Args:
        firebase_key: Firebase record key
        record: Firebase record data
        
    Returns:
        True if successfully processed, False otherwise
    """
    try:
        # Extract data
        device_id = record.get('childID')
        lat = record.get('lat')
        long = record.get('long')
        speed = record.get('speed')
        timestamp_str = record.get('timestamp')
        
        # Validate required fields
        if not all([device_id, lat is not None, long is not None, timestamp_str]):
            logger.warning(f"Record {firebase_key}: Missing required fields")
            return False
        
        # Parse timestamp
        timestamp = parse_firebase_timestamp(timestamp_str)
        if not timestamp:
            logger.warning(f"Record {firebase_key}: Invalid timestamp format")
            return False
        
        # Check if device exists
        if not device_exists(device_id):
            logger.warning(f"Record {firebase_key}: Device {device_id} not found")
            return False
        
        # Insert into Supabase
        return insert_location_data(
            device_id=device_id,
            latitude=float(lat),
            longitude=float(long),
            speed=float(speed) if speed is not None else None,
            timestamp=timestamp,
            firebase_key=firebase_key
        )
        
    except Exception as e:
        logger.error(f"Error processing record {firebase_key}: {e}")
        return False


def fetch_firebase_data() -> Optional[Dict[str, Any]]:
    """
    Fetch all data from Firebase Realtime Database.
    
    Returns:
        Firebase data dictionary or None if error
    """
    try:
        url = f"https://{FIREBASE_HOST}{FIREBASE_PATH}.json?auth={FIREBASE_AUTH_KEY}"
        response = requests.get(url, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            return data if data else {}
        else:
            logger.error(f"Firebase fetch failed: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        logger.error(f"Error fetching Firebase data: {e}")
        return None


def delete_firebase_record(firebase_key: str) -> bool:
    """
    Delete a record from Firebase (optional cleanup).
    
    Args:
        firebase_key: Firebase record key
        
    Returns:
        True if deleted, False otherwise
    """
    try:
        url = f"https://{FIREBASE_HOST}/{firebase_key}.json?auth={FIREBASE_AUTH_KEY}"
        response = requests.delete(url, timeout=10)
        return response.status_code == 200
    except Exception as e:
        logger.error(f"Error deleting Firebase record {firebase_key}: {e}")
        return False


def sync_loop(poll_interval: int = 2, cleanup: bool = True):
    """
    Main sync loop that continuously polls Firebase for new data.
    
    Args:
        poll_interval: Seconds between polls (default: 2)
        cleanup: Whether to delete records from Firebase after migration (default: False)
    """
    logger.info(f"🚀 Starting CONTINUOUS Firebase to Supabase sync (every {poll_interval}s)")
    logger.info(f"📊 This will check for new data constantly with minimal delay")
    logger.info(f"Cleanup mode: {'ENABLED' if cleanup else 'DISABLED'}")
    
    consecutive_errors = 0
    max_errors = 5
    
    while True:
        try:
            logger.debug("Polling Firebase for new data...")
            
            # Fetch data from Firebase
            firebase_data = fetch_firebase_data()
            
            if firebase_data is None:
                consecutive_errors += 1
                if consecutive_errors >= max_errors:
                    logger.error(f"Too many consecutive errors ({consecutive_errors}), stopping")
                    break
                time.sleep(poll_interval * 2)
                continue
            
            # Reset error counter on success
            consecutive_errors = 0
            
            if not firebase_data:
                logger.debug("No data in Firebase")
                time.sleep(poll_interval)
                continue
            
            # Process each record
            records_processed = 0
            records_migrated = 0
            
            for firebase_key, record in firebase_data.items():
                if firebase_key in processed_records:
                    continue
                    
                records_processed += 1
                
                if isinstance(record, dict):
                    if process_firebase_record(firebase_key, record):
                        records_migrated += 1
                        processed_records.add(firebase_key)
                        
                        # Optional: Delete from Firebase after successful migration
                        if cleanup:
                            if delete_firebase_record(firebase_key):
                                logger.info(f"🗑️ Deleted record {firebase_key} from Firebase")
            
            if records_migrated > 0:
                logger.info(f"📊 Batch complete: {records_migrated}/{records_processed} records migrated")
            
            # Wait before next poll
            time.sleep(poll_interval)
            
        except KeyboardInterrupt:
            logger.info("⏹️ Stopping sync service (Ctrl+C)")
            break
        except Exception as e:
            logger.error(f"Error in sync loop: {e}")
            consecutive_errors += 1
            if consecutive_errors >= max_errors:
                logger.error(f"Too many consecutive errors ({consecutive_errors}), stopping")
                break
            time.sleep(poll_interval * 2)


def main():
    """Main entry point."""
    print("""
    ╔═══════════════════════════════════════════════════════════╗
    ║   Firebase → Supabase Realtime Migration Service         ║
    ║   SafeSpot GPS Tracking System                           ║
    ╚═══════════════════════════════════════════════════════════╝
    """)
    
    # Test connection to Supabase
    try:
        logger.info("Testing Supabase connection...")
        response = supabase.table('devices').select('device_id').limit(1).execute()
        logger.info("✅ Supabase connection successful")
    except Exception as e:
        logger.error(f"❌ Failed to connect to Supabase: {e}")
        return
    
    # Test connection to Firebase
    try:
        logger.info("Testing Firebase connection...")
        test_data = fetch_firebase_data()
        if test_data is not None:
            logger.info(f"✅ Firebase connection successful ({len(test_data)} records found)")
        else:
            logger.error("❌ Failed to connect to Firebase")
            return
    except Exception as e:
        logger.error(f"❌ Failed to connect to Firebase: {e}")
        return
    
    # Start sync loop
    try:
        # Poll every 2 seconds with auto-cleanup (Firebase as queue)
        # cleanup=True deletes records from Firebase after successful migration
        sync_loop(poll_interval=2, cleanup=True)
    except Exception as e:
        logger.error(f"Fatal error: {e}")


if __name__ == "__main__":
    main()
