# Student Guide: Database Migrations with Flyway

## Table of Contents
- [What is Flyway?](#what-is-flyway)
- [Quick Start](#quick-start)
- [Creating Migration Files](#creating-migration-files)
- [Running Migrations](#running-migrations)
- [Git Integration](#git-integration)
- [Example Workflow](#example-workflow)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## What is Flyway?

Flyway is a **database migration tool** that helps you:
- Version control your database schema
- Track what changes have been applied
- Apply database changes in a consistent, repeatable way
- Collaborate with others on database changes

Think of it like **Git for your database structure** - but instead of tracking code changes, it tracks changes to your database tables, columns, and other schema elements.

### What Flyway Does:
✅ Reads migration SQL files you create  
✅ Tracks which migrations have been applied to your database  
✅ Executes new migrations in the correct order  
✅ Prevents the same migration from running twice  

### What Flyway Does NOT Do:
❌ Auto-generate migration files for you  
❌ Detect changes to your database automatically  
❌ Back up your data  
❌ Sync your actual database data to Git  

---

## Quick Start

### 1. Create Your Database

First, create your own database for your project:

```bash
# Connect to MySQL
mysql -h mysqlServer -u fakeAirbnbUser -p
```

Enter password: `apples11Million`

```sql
-- Create your database (use your name to avoid conflicts)
CREATE DATABASE student_yourname_project;

-- Verify it was created
SHOW DATABASES;

-- Exit MySQL
EXIT;
```

**Naming Convention:** Use `student_yourname_projectname` to keep databases organized.

### 2. Create a Migrations Folder

Create a dedicated folder for your migration files:

```bash
mkdir -p /workspace/sql/student_migrations/yourname_project
```

This keeps your migrations separate from:
- The main teaching database (`fakeAirbnb`)
- Other students' migrations

### 3. Create Your First Migration

Migration files must follow this naming pattern:

```
V{version}__{description}.sql
```

**Rules:**
- Starts with `V` (uppercase)
- Version number: `1`, `2`, `3`... or `1.1`, `1.2`...
- **Two underscores** `__` before the description
- Description uses **single underscores** between words
- File extension is `.sql`

**Examples:**
- ✅ `V1__create_users_table.sql`
- ✅ `V2__add_email_column.sql`
- ✅ `V3__create_posts_table.sql`
- ✅ `V1.1__add_index_to_users.sql`
- ❌ `v1__create_table.sql` (lowercase v)
- ❌ `V1_create_table.sql` (only one underscore)
- ❌ `create_users.sql` (no version number)

Create your first migration:

```bash
nano /workspace/sql/student_migrations/yourname_project/V1__create_users_table.sql
```

Write your SQL:

```sql
-- V1__create_users_table.sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

Save and exit (Ctrl+X, then Y, then Enter).

### 4. Run Your Migration

Execute Flyway to apply the migration:

```bash
flyway -url=jdbc:mysql://mysqlServer/student_yourname_project \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/student_migrations/yourname_project \
       migrate
```

**What this command does:**
- `-url`: Connects to your database
- `-user` and `-password`: Authenticates as the database user
- `-locations`: Points to your migration files folder
- `migrate`: Tells Flyway to run any pending migrations

**Output you'll see:**
```
Flyway Community Edition 8.0.0-beta1 by Redgate
Database: jdbc:mysql://mysqlServer/student_yourname_project (MySQL 8.0)
Successfully validated 1 migration (execution time 00:00.008s)
Creating Schema History table `student_yourname_project`.`flyway_schema_history` ...
Current version of schema `student_yourname_project`: << Empty Schema >>
Migrating schema `student_yourname_project` to version "1 - create users table"
Successfully applied 1 migration to schema `student_yourname_project` (execution time 00:00.023s)
```

### 5. Verify Your Table Was Created

```bash
mysql -h mysqlServer -u fakeAirbnbUser -p student_yourname_project
```

```sql
SHOW TABLES;
DESCRIBE users;
EXIT;
```

You should see:
- `users` table (your table)
- `flyway_schema_history` table (Flyway's tracking table)

---

## Creating Migration Files

### Every Schema Change = New Migration File

**The Golden Rule:** Once a migration has been applied, **NEVER** edit it. Always create a new migration.

### Common Migration Types

#### Adding a New Table

**File:** `V2__create_posts_table.sql`
```sql
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### Adding a Column

**File:** `V3__add_bio_to_users.sql`
```sql
ALTER TABLE users 
ADD COLUMN bio TEXT;
```

#### Creating an Index

**File:** `V4__add_email_index.sql`
```sql
CREATE INDEX idx_users_email ON users(email);
```

#### Adding a Foreign Key

**File:** `V5__create_comments_table.sql`
```sql
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_text TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);
```

#### Modifying a Column

**File:** `V6__increase_username_length.sql`
```sql
ALTER TABLE users 
MODIFY COLUMN username VARCHAR(100) NOT NULL;
```

### Keep Migrations Focused

✅ **Good - One change per migration:**
- `V2__add_email_column.sql`
- `V3__add_phone_column.sql`

❌ **Bad - Multiple unrelated changes:**
```sql
-- V2__various_changes.sql
ALTER TABLE users ADD COLUMN email VARCHAR(100);
CREATE TABLE posts (...);
ALTER TABLE comments ADD COLUMN likes INT;
```

### Testing Your SQL Before Creating a Migration

Always test your SQL manually first:

```bash
mysql -h mysqlServer -u fakeAirbnbUser -p student_yourname_project
```

```sql
-- Test your ALTER TABLE or CREATE TABLE statement
ALTER TABLE users ADD COLUMN test_column VARCHAR(50);

-- If it works, remove the test
ALTER TABLE users DROP COLUMN test_column;

-- Exit
EXIT;
```

Now create the migration file with your tested SQL.

---

## Running Migrations

### Basic Migration Command

```bash
flyway -url=jdbc:mysql://mysqlServer/student_yourname_project \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/student_migrations/yourname_project \
       migrate
```

**Tip:** Save this as a script to avoid retyping!

Create a file: `migrate.sh`
```bash
#!/bin/bash
flyway -url=jdbc:mysql://mysqlServer/student_yourname_project \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/student_migrations/yourname_project \
       migrate
```

Make it executable and run it:
```bash
chmod +x migrate.sh
./migrate.sh
```

### Checking Migration Status

See which migrations have been applied:

```bash
flyway -url=jdbc:mysql://mysqlServer/student_yourname_project \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/student_migrations/yourname_project \
       info
```

**Output:**
```
+-----------+---------+------------------------+------+---------------------+---------+
| Category  | Version | Description            | Type | Installed On        | State   |
+-----------+---------+------------------------+------+---------------------+---------+
| Versioned | 1       | create users table     | SQL  | 2025-01-29 10:15:23 | Success |
| Versioned | 2       | create posts table     | SQL  | 2025-01-29 10:20:45 | Success |
| Versioned | 3       | add bio to users       | SQL  |                     | Pending |
+-----------+---------+------------------------+------+---------------------+---------+
```

### Validating Migrations

Check if your migration files match what's in the database:

```bash
flyway -url=jdbc:mysql://mysqlServer/student_yourname_project \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/student_migrations/yourname_project \
       validate
```

---

## Git Integration

### What Gets Committed to Git?

| Item | Store in Git? | Why |
|------|---------------|-----|
| Migration files (`V1__*.sql`) | ✅ **YES** | These define your database structure |
| PHP code | ✅ **YES** | Your application code |
| Configuration files | ✅ **YES** | Needed to run your project |
| Actual database data | ❌ **NO** | This lives in the database, not Git |
| `flyway_schema_history` table | ❌ **NO** | Generated automatically by Flyway |

### Understanding the Separation

```
┌─────────────────────────────────────────┐
│  Git Repository (Code)                  │
│  ✅ Migration files (structure)         │
│  ✅ PHP application code                │
│  ✅ Config files                        │
└─────────────────────────────────────────┘
              ↓ (migrations define)
┌─────────────────────────────────────────┐
│  Database (Data)                        │
│  📊 Actual tables                       │
│  📊 Actual data (rows)                  │
│  📊 flyway_schema_history               │
└─────────────────────────────────────────┘
```

### Why This Matters

**Scenario:** You're working on a blog project with a partner.

1. **You create a migration:**
   - File: `V5__add_published_column.sql`
   - Commit and push to Git
   - Run Flyway to apply it to your database

2. **Your partner pulls from Git:**
   - Gets your migration file
   - Runs Flyway on their database
   - Now both databases have the same structure

3. **But the data is different:**
   - Your database has your test blog posts
   - Partner's database has their test blog posts
   - This is expected and correct!

### Git Workflow with Migrations

#### Initial Setup (First Time)

```bash
# Clone the repository
git clone <your-repo-url>
cd <repo-name>

# Rebuild devcontainer (it will run existing migrations automatically)
# OR manually create your database and run migrations:

mysql -h mysqlServer -u fakeAirbnbUser -p
# CREATE DATABASE student_yourname_project;
# EXIT;

flyway -url=jdbc:mysql://mysqlServer/student_yourname_project \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/student_migrations/yourname_project \
       migrate
```

#### Making a Database Change

```bash
# 1. Create your migration file
nano sql/student_migrations/yourname_project/V6__add_tags_table.sql

# 2. Test it locally
flyway ... migrate

# 3. Verify it works
mysql -h mysqlServer -u fakeAirbnbUser -p student_yourname_project
# SHOW TABLES;
# EXIT;

# 4. Commit the migration file
git add sql/student_migrations/yourname_project/V6__add_tags_table.sql
git commit -m "Add tags table for categorizing posts"
git push
```

#### Pulling Changes from Others

```bash
# 1. Pull the latest code
git pull

# 2. Run migrations to update your database structure
flyway ... migrate

# 3. Your database structure is now up to date
#    (but your data is still yours)
```

### Team Collaboration Best Practices

#### Avoiding Migration Conflicts

**Problem:** Two people create `V5__` migrations at the same time.

**Solution:**
1. **Communicate:** "I'm creating a migration for X"
2. **Pull before creating:** Always `git pull` before creating a new migration
3. **Rename if needed:** If you pull and someone else created V5, rename yours to V6

#### Version Numbering Strategies

**Strategy 1: Sequential (Simple)**
- V1, V2, V3, V4...
- Works well for small teams or solo projects

**Strategy 2: Timestamp-based (Better for teams)**
- V20250129_1015__create_users.sql
- V20250129_1145__add_email.sql
- Format: YYYYMMDD_HHMM
- Prevents conflicts

**Strategy 3: Feature branches**
- V5.1__feature_comments.sql
- V5.2__feature_comments_add_likes.sql
- Merge to main as V6, V7 later

---

## Example Workflow

Let's build a simple blog from scratch.

### Step 1: Setup

```bash
# Create database
mysql -h mysqlServer -u fakeAirbnbUser -p
```
```sql
CREATE DATABASE student_john_blog;
EXIT;
```

```bash
# Create migrations folder
mkdir -p /workspace/sql/student_migrations/john_blog
```

### Step 2: Create Users Table

**File:** `V1__create_users_table.sql`
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    email VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

```bash
# Apply migration
flyway -url=jdbc:mysql://mysqlServer/student_john_blog \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/student_migrations/john_blog \
       migrate
```

### Step 3: Create Posts Table

**File:** `V2__create_posts_table.sql`
```sql
CREATE TABLE posts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

```bash
# Apply migration
flyway ... migrate
```

### Step 4: Add Comments Feature

**File:** `V3__create_comments_table.sql`
```sql
CREATE TABLE comments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    post_id INT NOT NULL,
    user_id INT NOT NULL,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (post_id) REFERENCES posts(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
```

```bash
flyway ... migrate
```

### Step 5: Realize We Need Post Slugs

**File:** `V4__add_slug_to_posts.sql`
```sql
ALTER TABLE posts 
ADD COLUMN slug VARCHAR(255) NOT NULL AFTER title,
ADD UNIQUE INDEX idx_posts_slug (slug);
```

```bash
flyway ... migrate
```

### Step 6: Add User Profiles

**File:** `V5__add_profile_fields_to_users.sql`
```sql
ALTER TABLE users
ADD COLUMN bio TEXT,
ADD COLUMN avatar_url VARCHAR(500),
ADD COLUMN website VARCHAR(255);
```

```bash
flyway ... migrate
```

### Step 7: Check Status

```bash
flyway ... info
```

**Output:**
```
+-----------+---------+--------------------------------+------+---------------------+---------+
| Category  | Version | Description                    | Type | Installed On        | State   |
+-----------+---------+--------------------------------+------+---------------------+---------+
| Versioned | 1       | create users table             | SQL  | 2025-01-29 10:00:00 | Success |
| Versioned | 2       | create posts table             | SQL  | 2025-01-29 10:05:00 | Success |
| Versioned | 3       | create comments table          | SQL  | 2025-01-29 10:10:00 | Success |
| Versioned | 4       | add slug to posts              | SQL  | 2025-01-29 10:15:00 | Success |
| Versioned | 5       | add profile fields to users    | SQL  | 2025-01-29 10:20:00 | Success |
+-----------+---------+--------------------------------+------+---------------------+---------+
```

### Step 8: Commit to Git

```bash
git add sql/student_migrations/john_blog/
git commit -m "Add complete database schema for blog project"
git push
```

---

## Best Practices

### ✅ DO:

1. **Always create new migrations for changes**
   - Never edit existing migration files after they've been run

2. **Use descriptive names**
   - ✅ `V5__add_email_verification_to_users.sql`
   - ❌ `V5__update.sql`

3. **Test before committing**
   - Run the migration locally first
   - Verify it works as expected

4. **Keep migrations small and focused**
   - One logical change per migration
   - Easier to understand and debug

5. **Version your migrations in Git**
   - Commit migration files to your repository
   - Include them in pull requests

6. **Write idempotent migrations when possible**
   ```sql
   -- Good: Won't fail if column exists
   ALTER TABLE users 
   ADD COLUMN IF NOT EXISTS email VARCHAR(100);
   ```

7. **Include comments in complex migrations**
   ```sql
   -- Adding email verification fields for two-factor authentication
   -- See issue #42 for requirements
   ALTER TABLE users 
   ADD COLUMN email_verified BOOLEAN DEFAULT FALSE,
   ADD COLUMN verification_token VARCHAR(255);
   ```

8. **Back up before major migrations**
   ```bash
   mysqldump -h mysqlServer -u fakeAirbnbUser -p student_john_blog > backup.sql
   ```

### ❌ DON'T:

1. **Don't modify migrations after running them**
   - Causes checksum errors
   - Breaks for teammates who already ran them

2. **Don't skip version numbers**
   - Keep sequential: V1, V2, V3...

3. **Don't delete migration files**
   - Even old ones - they're your database's history

4. **Don't put data in migrations (usually)**
   - Migrations are for structure, not data
   - Exception: Reference data (like initial admin user)

5. **Don't use database-specific syntax unnecessarily**
   - Stick to standard SQL when possible
   - Makes switching databases easier

6. **Don't commit your actual database**
   - Only commit migration files
   - Data stays in the database container

### Seed Data vs Migrations

**Migrations:** Database structure (tables, columns, indexes)
```sql
-- V1__create_categories.sql
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL
);
```

**Seed Data:** Initial/reference data (optional)
```sql
-- seed_data.sql (separate file, run manually)
INSERT INTO categories (name) VALUES 
('Technology'),
('Travel'),
('Food');
```

**When to include data in migrations:**
- ✅ System configuration (like default admin role)
- ✅ Reference data needed for app to function
- ❌ Test data
- ❌ User-generated content

---

## Troubleshooting

### "Migration checksum mismatch detected"

**Problem:** You edited a migration file after it was run.

**Solution:**
```bash
# Option 1: Undo your changes to the migration file
# Option 2: Create a new migration with the changes
nano sql/student_migrations/yourname_project/V7__fix_previous_change.sql
```

**Never use:** `flyway repair` unless you understand the consequences.

### "Command not found: flyway"

**Problem:** You're not in the development container.

**Solution:**
- Make sure you're in the VS Code terminal (not your local machine)
- Try opening a new terminal

### "Access denied for user"

**Problem:** Wrong credentials or database name.

**Solution:**
- Check database name: `student_yourname_project`
- Check username: `fakeAirbnbUser`
- Check password: `apples11Million`
- Verify database exists:
  ```bash
  mysql -h mysqlServer -u fakeAirbnbUser -p
  SHOW DATABASES;
  ```

### "Table doesn't exist" after creating it

**Problem:** You created the table manually, not via migration.

**Solution:**
- Drop the table
- Create a proper migration file
- Run Flyway

```bash
mysql -h mysqlServer -u fakeAirbnbUser -p student_yourname_project
```
```sql
DROP TABLE tablename;
EXIT;
```

Then create `V#__create_tablename.sql` and run Flyway.

### "Cannot add foreign key constraint"

**Problem:** Referenced table doesn't exist or column types don't match.

**Solution:**
- Make sure the referenced table exists (created in earlier migration)
- Check that data types match exactly:
  ```sql
  -- Both must be INT
  user_id INT NOT NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
  ```

### Migrations Applied in Wrong Order

**Problem:** Created V5 before teammate's V5 was pulled.

**Solution:**
- Rename your file to the next available number:
  ```bash
  mv V5__my_change.sql V6__my_change.sql
  ```
- Run Flyway again

### Need to Start Over

**Problem:** Made a mess and want to reset.

**Solution:**
```bash
mysql -h mysqlServer -u fakeAirbnbUser -p
```
```sql
DROP DATABASE student_yourname_project;
CREATE DATABASE student_yourname_project;
EXIT;
```

```bash
# Run all migrations from scratch
flyway ... migrate
```

---

## Quick Reference

### File Naming
```
V{version}__{description}.sql

Examples:
V1__create_users_table.sql
V2__add_email_to_users.sql
V10__create_posts_table.sql
V1.1__hotfix_user_email.sql
```

### Commands

**Run migrations:**
```bash
flyway -url=jdbc:mysql://mysqlServer/yourdb \
       -user=fakeAirbnbUser \
       -password=apples11Million \
       -locations=filesystem:/workspace/sql/yourfolder \
       migrate
```

**Check status:**
```bash
flyway ... info
```

**Validate:**
```bash
flyway ... validate
```

### Common SQL Patterns

**Create table:**
```sql
CREATE TABLE tablename (
    id INT AUTO_INCREMENT PRIMARY KEY,
    column_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**Add column:**
```sql
ALTER TABLE tablename 
ADD COLUMN new_column VARCHAR(100);
```

**Add foreign key:**
```sql
ALTER TABLE child_table
ADD CONSTRAINT fk_parent
FOREIGN KEY (parent_id) REFERENCES parent_table(id);
```

**Create index:**
```sql
CREATE INDEX idx_tablename_column ON tablename(column_name);
```

---

## Additional Resources

- **Flyway Documentation:** https://flywaydb.org/documentation/
- **MySQL Documentation:** https://dev.mysql.com/doc/
- **SQL Tutorial:** https://www.w3schools.com/sql/

## Getting Help

1. Check this guide first
2. Review the error message carefully
3. Test your SQL manually in MySQL before creating a migration
4. Ask your instructor
5. Check Flyway docs for specific error messages

---

## Summary

**Remember:**
1. Migrations are for **database structure**, not data
2. **Never edit** a migration after running it
3. Always **commit migrations to Git**
4. Actual database **data does NOT go to Git**
5. Use `flyway migrate` to apply new changes
6. Use `flyway info` to check status
7. Test your SQL before creating migration files

**Workflow:**
1. Create migration file: `V#__description.sql`
2. Write SQL to change structure
3. Run `flyway migrate`
4. Test that it worked
5. Commit the migration file to Git
6. Push to your repository

Good luck with your database migrations! 🚀
