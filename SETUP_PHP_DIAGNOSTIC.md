# Setup.php Diagnostic Guide

## 🔍 Common Issues When Masters Menus Don't Show

### Issue 1: Missing `menu_type` Column or Value
**Symptom:** Menus are inserted but not showing when filtering by `menu_type = 'masters'`

**Check:**
```php
// ❌ WRONG - Missing menu_type
DB::table('menus')->insert([
    'name' => 'Users',
    'slug' => 'masters.users',
    // ... missing 'menu_type' => 'masters'
]);

// ✅ CORRECT
DB::table('menus')->insert([
    'name' => 'Users',
    'slug' => 'masters.users',
    'menu_type' => 'masters',  // ← MUST be present
    // ...
]);
```

**Fix:** Ensure every menu item has `'menu_type' => 'masters'`

---

### Issue 2: `is_active` is 0 or Missing
**Symptom:** Menus exist in database but API returns empty array

**Check:**
```sql
-- Run this query on your database
SELECT * FROM menus WHERE menu_type = 'masters';
```

If `is_active` is 0 or NULL, that's the problem.

**Fix:**
```php
// ✅ Ensure is_active is set to 1
'is_active' => 1,  // Not 0, not null
```

---

### Issue 3: Using `insert()` Instead of `updateOrInsert()`
**Symptom:** Script runs but menus don't update, or creates duplicates

**Check:**
```php
// ❌ WRONG - Creates duplicates or doesn't update
DB::table('menus')->insert($menu);

// ✅ CORRECT - Updates if exists, inserts if not
DB::table('menus')->updateOrInsert(
    ['slug' => $menu['slug'], 'menu_type' => 'masters'],
    $menu
);
```

**Fix:** Use `updateOrInsert()` to handle existing records

---

### Issue 4: Not Checking Both `slug` AND `menu_type`
**Symptom:** Updates wrong menu items or creates duplicates

**Check:**
```php
// ❌ WRONG - Only checks slug
$existing = DB::table('menus')
    ->where('slug', $menu['slug'])
    ->first();

// ✅ CORRECT - Checks both slug and menu_type
$existing = DB::table('menus')
    ->where('slug', $menu['slug'])
    ->where('menu_type', 'masters')  // ← Important!
    ->first();
```

**Fix:** Always check both `slug` and `menu_type` together

---

### Issue 5: Missing Timestamps
**Symptom:** Database errors or NULL timestamps

**Check:**
```php
// ❌ WRONG - Missing timestamps
[
    'name' => 'Users',
    'slug' => 'masters.users',
    // ... missing created_at and updated_at
]

// ✅ CORRECT
[
    'name' => 'Users',
    'slug' => 'masters.users',
    'created_at' => now(),
    'updated_at' => now(),
]
```

**Fix:** Always include `created_at` and `updated_at` using `now()`

---

### Issue 6: Wrong Table Name
**Symptom:** Script runs without errors but nothing happens

**Check:**
```php
// ❌ WRONG
DB::table('menu')->insert(...);  // Singular

// ✅ CORRECT
DB::table('menus')->insert(...);  // Plural
```

**Fix:** Ensure table name is `menus` (plural)

---

### Issue 7: Parent-Child Relationships Not Set
**Symptom:** Menus show but hierarchy is broken

**Check:**
```php
// After inserting all menus, update parent_id
$mastersParent = DB::table('menus')
    ->where('slug', 'masters')
    ->where('menu_type', 'masters')
    ->first();

if ($mastersParent) {
    $subMenus = ['masters.users', 'masters.departments', ...];
    foreach ($subMenus as $slug) {
        DB::table('menus')
            ->where('slug', $slug)
            ->where('menu_type', 'masters')
            ->update(['parent_id' => $mastersParent->id]);
    }
}
```

**Fix:** Update `parent_id` after parent menu is inserted

---

## 🔧 Quick Diagnostic Queries

Run these SQL queries on your database to diagnose:

### 1. Check if menus table exists:
```sql
SHOW TABLES LIKE 'menus';
```

### 2. Check table structure:
```sql
DESCRIBE menus;
```

### 3. Check all masters menus:
```sql
SELECT * FROM menus WHERE menu_type = 'masters';
```

### 4. Check active masters menus:
```sql
SELECT * FROM menus 
WHERE menu_type = 'masters' 
AND is_active = 1 
ORDER BY `order`;
```

### 5. Check for missing menus:
```sql
SELECT 
    CASE 
        WHEN COUNT(*) < 8 THEN 'MISSING MENUS'
        ELSE 'ALL PRESENT'
    END as status,
    COUNT(*) as count
FROM menus 
WHERE menu_type = 'masters' AND is_active = 1;
```

### 6. Check for menus with wrong menu_type:
```sql
SELECT * FROM menus 
WHERE slug LIKE 'masters.%' 
AND menu_type != 'masters';
```

### 7. Check for inactive menus:
```sql
SELECT name, slug, is_active 
FROM menus 
WHERE menu_type = 'masters' 
AND is_active = 0;
```

---

## ✅ Verification Checklist

After running setup.php, verify:

- [ ] Script runs without errors
- [ ] Output shows "Inserted" or "Updated" for each menu
- [ ] Verification section shows "All masters menus are present!"
- [ ] Total count is 8 (1 parent + 7 children)
- [ ] All menus have `menu_type = 'masters'`
- [ ] All menus have `is_active = 1`
- [ ] All sub-menus have `parent_id` set to parent menu's ID
- [ ] Database query returns 8 rows when filtering by `menu_type = 'masters'`

---

## 🚀 Testing Your Setup.php

1. **Backup your database first!**

2. **Run setup.php:**
   ```bash
   cd /path/to/your/laravel/project
   php setup.php
   ```

3. **Check the output:**
   - Should see "Inserted" or "Updated" for each menu
   - Should see "✅ All masters menus are present!"
   - Should see list of all 8 menus

4. **Verify in database:**
   ```sql
   SELECT COUNT(*) FROM menus WHERE menu_type = 'masters' AND is_active = 1;
   -- Should return 8
   ```

5. **Test API endpoint:**
   ```bash
   curl -X GET "https://ticket.caffedesign.in/api/menus?type=masters" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -H "Accept: application/json"
   ```

---

## 📝 What to Compare

Compare your server-side `setup.php` with the provided `setup.php` file and check:

1. ✅ All 8 menu items are defined in `$mastersMenus` array
2. ✅ Each menu has `'menu_type' => 'masters'`
3. ✅ Each menu has `'is_active' => 1`
4. ✅ Uses `updateOrInsert()` or checks for existing before inserting
5. ✅ Checks both `slug` AND `menu_type` when finding existing
6. ✅ Includes `created_at` and `updated_at` timestamps
7. ✅ Updates `parent_id` for sub-menus after parent is inserted
8. ✅ Has verification section at the end
9. ✅ Uses `now()` for timestamps (not hardcoded dates)

---

## 🐛 If Still Not Working

1. **Check Laravel logs:**
   ```bash
   tail -f storage/logs/laravel.log
   ```

2. **Check database connection:**
   - Verify `.env` file has correct database credentials
   - Test connection: `php artisan tinker` then `DB::connection()->getPdo();`

3. **Check API endpoint:**
   - Verify route exists: `Route::get('/menus', [MenuController::class, 'index']);`
   - Verify controller filters by `menu_type`
   - Check if authentication is required

4. **Clear cache:**
   ```bash
   php artisan cache:clear
   php artisan config:clear
   php artisan route:clear
   ```

5. **Check API response:**
   - Use Postman or curl to test the API endpoint
   - Verify JSON structure matches what Flutter app expects



