# Setup.php Verification Checklist

Use this checklist to verify your `setup.php` file has all the necessary components for masters menus.

## ✅ Required Components Checklist

### 1. Database Connection
- [ ] Database connection is established
- [ ] Uses Laravel's DB facade or PDO connection
- [ ] Connection credentials are correct

### 2. Table Existence Check
- [ ] Checks if `menus` table exists
- [ ] Creates table if it doesn't exist (optional)
- [ ] Table has required columns: `id`, `name`, `slug`, `icon`, `route`, `parent_id`, `order`, `is_active`, `menu_type`, `created_at`, `updated_at`

### 3. Masters Menu Items
- [ ] **Main Masters Menu** entry exists (slug: 'masters')
- [ ] **Users** menu item (slug: 'masters.users')
- [ ] **Departments** menu item (slug: 'masters.departments')
- [ ] **Categories** menu item (slug: 'masters.categories')
- [ ] **Priorities** menu item (slug: 'masters.priorities')
- [ ] **Status** menu item (slug: 'masters.status')
- [ ] **Locations** menu item (slug: 'masters.locations')
- [ ] **Companies** menu item (slug: 'masters.companies')

### 4. Menu Properties
For each menu item, verify:
- [ ] `name` is set (display name)
- [ ] `slug` is unique and follows pattern
- [ ] `icon` is set (for UI display)
- [ ] `route` is set (for navigation, null for parent)
- [ ] `order` is set (for sorting)
- [ ] `is_active` is set to 1 (true)
- [ ] `menu_type` is set to 'masters'
- [ ] `created_at` and `updated_at` timestamps are set

### 5. Data Insertion Logic
- [ ] Uses `insert()` or `updateOrInsert()` to avoid duplicates
- [ ] Checks for existing menus before inserting
- [ ] Handles errors gracefully
- [ ] Provides feedback/output messages

### 6. Parent-Child Relationships (if hierarchical)
- [ ] Sets `parent_id` for sub-menu items
- [ ] Updates parent_id after parent menu is inserted
- [ ] Maintains correct hierarchy

### 7. Error Handling
- [ ] Try-catch blocks for database operations
- [ ] Error messages are displayed
- [ ] Script doesn't crash on errors

### 8. Verification Output
- [ ] Shows count of inserted menus
- [ ] Lists inserted menu names
- [ ] Confirms successful completion

## 🔍 Quick Verification Script

Add this to the end of your `setup.php` to verify:

```php
// Verification
$mastersCount = DB::table('menus')
    ->where('menu_type', 'masters')
    ->where('is_active', 1)
    ->count();

echo "\n=== Verification ===\n";
echo "Total active masters menus: {$mastersCount}\n";

if ($mastersCount < 7) {
    echo "⚠️  WARNING: Expected at least 7 masters menus, found {$mastersCount}\n";
    echo "Missing menus:\n";
    
    $expected = ['masters', 'masters.users', 'masters.departments', 'masters.categories', 
                 'masters.priorities', 'masters.status', 'masters.locations', 'masters.companies'];
    
    foreach ($expected as $slug) {
        $exists = DB::table('menus')
            ->where('slug', $slug)
            ->where('menu_type', 'masters')
            ->exists();
        
        if (!$exists) {
            echo "  - Missing: {$slug}\n";
        }
    }
} else {
    echo "✅ All masters menus are present!\n";
}

// List all masters menus
$menus = DB::table('menus')
    ->where('menu_type', 'masters')
    ->where('is_active', 1)
    ->orderBy('order')
    ->get(['name', 'slug', 'route', 'order']);

echo "\nMasters Menus:\n";
foreach ($menus as $menu) {
    echo "  [{$menu->order}] {$menu->name} ({$menu->slug}) -> {$menu->route}\n";
}
```

## 🐛 Common Missing Items

### If menus are not showing, check:

1. **Missing `menu_type` column or value:**
   ```php
   // ❌ Wrong
   DB::table('menus')->insert(['name' => 'Users', ...]);
   
   // ✅ Correct
   DB::table('menus')->insert(['name' => 'Users', 'menu_type' => 'masters', ...]);
   ```

2. **Missing `is_active` flag:**
   ```php
   // ❌ Wrong
   ['is_active' => 0] // or missing
   
   // ✅ Correct
   ['is_active' => 1]
   ```

3. **Wrong table name:**
   ```php
   // ❌ Wrong
   DB::table('menu')->insert(...);
   
   // ✅ Correct
   DB::table('menus')->insert(...);
   ```

4. **Not checking for duplicates:**
   ```php
   // ❌ Wrong - creates duplicates
   DB::table('menus')->insert($menu);
   
   // ✅ Correct - updates if exists
   DB::table('menus')->updateOrInsert(
       ['slug' => $menu['slug'], 'menu_type' => 'masters'],
       $menu
   );
   ```

5. **Missing timestamps:**
   ```php
   // ❌ Wrong
   ['name' => 'Users', ...] // missing timestamps
   
   // ✅ Correct
   ['name' => 'Users', 'created_at' => now(), 'updated_at' => now(), ...]
   ```

## 📝 Sample Complete Setup.php Structure

```php
<?php
// 1. Bootstrap Laravel
require __DIR__ . '/vendor/autoload.php';
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// 2. Define menus array
$mastersMenus = [/* ... */];

// 3. Insert/Update menus
foreach ($mastersMenus as $menu) {
    DB::table('menus')->updateOrInsert(
        ['slug' => $menu['slug'], 'menu_type' => 'masters'],
        $menu
    );
}

// 4. Update relationships (if needed)
// ...

// 5. Verification
// ...
```

## 🚀 Running Setup.php

```bash
# From Laravel root directory
php setup.php

# Or if in public directory
php ../setup.php
```

## 📊 Expected Output

When setup.php runs successfully, you should see:

```
Inserted menu: Masters
Inserted menu: Users
Inserted menu: Departments
Inserted menu: Categories
Inserted menu: Priorities
Inserted menu: Status
Inserted menu: Locations
Inserted menu: Companies

✅ Masters menus setup completed!
Total masters menus: 8

=== Verification ===
Total active masters menus: 8
✅ All masters menus are present!

Masters Menus:
  [2] Masters (masters) -> 
  [1] Users (masters.users) -> /masters/users
  [2] Departments (masters.departments) -> /masters/departments
  ...
```

If you see errors or missing menus, refer to the troubleshooting section in `SETUP_PHP_MENUS_GUIDE.md`.

