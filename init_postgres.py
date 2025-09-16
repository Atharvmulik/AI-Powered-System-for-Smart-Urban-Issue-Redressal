# init_postgres.py
import time
import psycopg2
from psycopg2 import sql
import os
from dotenv import load_dotenv

load_dotenv()

def wait_for_postgres():
    """Wait for PostgreSQL to become available"""
    max_retries = 10
    for i in range(max_retries):
        try:
            conn = psycopg2.connect(
                host="localhost",
                port=5432,
                user="postgres",
                password="postgres",
                connect_timeout=3
            )
            conn.close()
            print("✅ PostgreSQL is ready!")
            return True
        except Exception as e:
            print(f"⏳ Waiting for PostgreSQL... (Attempt {i+1}/{max_retries})")
            time.sleep(3)
    print("❌ PostgreSQL did not become available in time")
    return False

def create_database_and_user():
    """Create database and user if they don't exist"""
    try:
        # Connect to default postgres database
        conn = psycopg2.connect(
            host="localhost",
            port=5432,
            user="postgres",
            password="postgres"
        )
        conn.autocommit = True
        cursor = conn.cursor()
        
        # Create database if it doesn't exist
        cursor.execute("SELECT 1 FROM pg_database WHERE datname = 'urban_db'")
        exists = cursor.fetchone()
        
        if not exists:
            cursor.execute("CREATE DATABASE urban_db")
            print("✅ Database 'urban_db' created successfully!")
        else:
            print("✅ Database 'urban_db' already exists!")
        
        # Create user if it doesn't exist
        cursor.execute("SELECT 1 FROM pg_roles WHERE rolname = 'urban_user'")
        user_exists = cursor.fetchone()
        
        if not user_exists:
            cursor.execute("CREATE USER urban_user WITH PASSWORD 'urban_password'")
            cursor.execute("GRANT ALL PRIVILEGES ON DATABASE urban_db TO urban_user")
            print("✅ User 'urban_user' created with privileges!")
        else:
            print("✅ User 'urban_user' already exists!")
        
        cursor.close()
        conn.close()
        return True
        
    except Exception as e:
        print(f"❌ Error creating database/user: {e}")
        
        # Try alternative connection (your docker might have different credentials)
        try:
            conn = psycopg2.connect(
                host="localhost",
                port=5432,
                user="urban_user",
                password="urban_password",
                dbname="urban_db"
            )
            print("✅ Connected successfully with urban_user credentials!")
            conn.close()
            return True
        except Exception as e2:
            print(f"❌ Could not connect with urban_user either: {e2}")
            return False

if __name__ == "__main__":
    print("🚀 Starting PostgreSQL initialization...")
    
    if wait_for_postgres():
        if create_database_and_user():
            print("🎉 PostgreSQL setup completed successfully!")
        else:
            print("❌ PostgreSQL setup failed!")
    else:
        print("❌ Could not connect to PostgreSQL!")