#!/bin/bash

# Wishare Database Backup Script
# Usage: ./scripts/backup_db.sh [environment]
# Environment: staging or production (default: production)

ENVIRONMENT=${1:-production}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./db_backups"
BACKUP_FILE="wishare_${ENVIRONMENT}_${TIMESTAMP}.sql"

echo "🔄 Starting backup for ${ENVIRONMENT} environment..."

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Railway backup (recommended - managed by Railway)
echo "📦 Creating Railway managed backup..."
railway db backup --environment $ENVIRONMENT

if [ $? -eq 0 ]; then
    echo "✅ Railway managed backup created successfully"
else
    echo "❌ Railway managed backup failed"
fi

# Manual backup (extra safety)
echo "💾 Creating manual backup..."
if command -v railway &> /dev/null; then
    # Get database URL from Railway
    DB_URL=$(railway vars get DATABASE_URL --environment $ENVIRONMENT)
    
    if [ ! -z "$DB_URL" ]; then
        pg_dump "$DB_URL" > "$BACKUP_DIR/$BACKUP_FILE"
        
        if [ $? -eq 0 ]; then
            echo "✅ Manual backup saved to: $BACKUP_DIR/$BACKUP_FILE"
            
            # Compress the backup
            gzip "$BACKUP_DIR/$BACKUP_FILE"
            echo "🗜️  Backup compressed to: $BACKUP_DIR/$BACKUP_FILE.gz"
            
            # Show backup size
            ls -lh "$BACKUP_DIR/$BACKUP_FILE.gz"
        else
            echo "❌ Manual backup failed"
        fi
    else
        echo "❌ Could not retrieve DATABASE_URL"
    fi
else
    echo "⚠️  Railway CLI not found. Install with: npm install -g @railway/cli"
fi

echo "🎉 Backup process completed!"
echo ""
echo "📋 Next steps:"
echo "1. Verify backup integrity if needed"
echo "2. Store backup in secure location"
echo "3. Test restore process in development"
echo ""
echo "🔄 To restore this backup:"
echo "   psql \$DATABASE_URL < $BACKUP_DIR/$BACKUP_FILE"