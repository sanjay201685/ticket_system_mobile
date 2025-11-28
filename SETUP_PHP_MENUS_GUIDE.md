# Setup.php - Masters Menus Configuration Guide

This guide shows what should be included in your `setup.php` file to properly seed the masters menus in your Laravel backend.

## Database Structure

Your `menus` table should have the following structure:

```sql
CREATE TABLE IF NOT EXISTS `menus` (
  `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
  `name` varchar(255) NOT NULL,
  `slug` varchar(255) NOT NULL,
  `icon` varchar(255) DEFAULT NULL,
  `route` varchar(255) DEFAULT NULL,
  `parent_id` bigint(20) UNSIGNED DEFAULT NULL,
  `order` int(11) DEFAULT 0,
  `is_active` tinyint(1) DEFAULT 1,
  `menu_type` varchar(50) DEFAULT 'main', -- 'main', 'masters', 'settings', etc.
  `created_at` timestamp NULL DEFAULT NULL,
  `updated_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `parent_id` (`parent_id`),
  KEY `menu_type` (`menu_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
```

## Setup.php Content for Masters Menus

Here's what your `setup.php` should include:

```php
<?php

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

// Bootstrap Laravel
$app = require_once __DIR__ . '/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

// Clear existing menus if needed (optional)
// DB::table('menus')->truncate();

// Insert Masters Menu Items
$mastersMenus = [
    // Main Masters Menu
    [
        'name' => 'Masters',
        'slug' => 'masters',
        'icon' => 'settings',
        'route' => null,
        'parent_id' => null,
        'order' => 2,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    
    // Sub-menu items under Masters
    [
        'name' => 'Users',
        'slug' => 'masters.users',
        'icon' => 'people',
        'route' => '/masters/users',
        'parent_id' => null, // Will be updated after parent is inserted
        'order' => 1,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'name' => 'Departments',
        'slug' => 'masters.departments',
        'icon' => 'business',
        'route' => '/masters/departments',
        'parent_id' => null,
        'order' => 2,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'name' => 'Categories',
        'slug' => 'masters.categories',
        'icon' => 'category',
        'route' => '/masters/categories',
        'parent_id' => null,
        'order' => 3,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'name' => 'Priorities',
        'slug' => 'masters.priorities',
        'icon' => 'flag',
        'route' => '/masters/priorities',
        'parent_id' => null,
        'order' => 4,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'name' => 'Status',
        'slug' => 'masters.status',
        'icon' => 'check_circle',
        'route' => '/masters/status',
        'parent_id' => null,
        'order' => 5,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'name' => 'Locations',
        'slug' => 'masters.locations',
        'icon' => 'location_on',
        'route' => '/masters/locations',
        'parent_id' => null,
        'order' => 6,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
    [
        'name' => 'Companies',
        'slug' => 'masters.companies',
        'icon' => 'corporate_fare',
        'route' => '/masters/companies',
        'parent_id' => null,
        'order' => 7,
        'is_active' => 1,
        'menu_type' => 'masters',
        'created_at' => now(),
        'updated_at' => now(),
    ],
];

// Insert menus
foreach ($mastersMenus as $menu) {
    // Check if menu already exists
    $existing = DB::table('menus')
        ->where('slug', $menu['slug'])
        ->where('menu_type', 'masters')
        ->first();
    
    if (!$existing) {
        DB::table('menus')->insert($menu);
        echo "Inserted menu: {$menu['name']}\n";
    } else {
        // Update existing menu
        DB::table('menus')
            ->where('id', $existing->id)
            ->update([
                'name' => $menu['name'],
                'icon' => $menu['icon'],
                'route' => $menu['route'],
                'order' => $menu['order'],
                'is_active' => $menu['is_active'],
                'updated_at' => now(),
            ]);
        echo "Updated menu: {$menu['name']}\n";
    }
}

// Update parent_id for sub-menus (if you want hierarchical structure)
$mastersParent = DB::table('menus')
    ->where('slug', 'masters')
    ->where('menu_type', 'masters')
    ->first();

if ($mastersParent) {
    $subMenus = ['masters.users', 'masters.departments', 'masters.categories', 
                 'masters.priorities', 'masters.status', 'masters.locations', 'masters.companies'];
    
    foreach ($subMenus as $slug) {
        DB::table('menus')
            ->where('slug', $slug)
            ->where('menu_type', 'masters')
            ->update(['parent_id' => $mastersParent->id]);
    }
}

echo "\n✅ Masters menus setup completed!\n";
echo "Total masters menus: " . DB::table('menus')->where('menu_type', 'masters')->count() . "\n";
```

## Alternative: Using Laravel Seeder

If you prefer using Laravel's seeder system, create a seeder:

```bash
php artisan make:seeder MenuSeeder
```

Then in `database/seeders/MenuSeeder.php`:

```php
<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class MenuSeeder extends Seeder
{
    public function run()
    {
        $mastersMenus = [
            [
                'name' => 'Masters',
                'slug' => 'masters',
                'icon' => 'settings',
                'route' => null,
                'parent_id' => null,
                'order' => 2,
                'is_active' => 1,
                'menu_type' => 'masters',
                'created_at' => now(),
                'updated_at' => now(),
            ],
            // ... (same array as above)
        ];

        foreach ($mastersMenus as $menu) {
            DB::table('menus')->updateOrInsert(
                ['slug' => $menu['slug'], 'menu_type' => 'masters'],
                $menu
            );
        }
    }
}
```

Run the seeder:
```bash
php artisan db:seed --class=MenuSeeder
```

## API Endpoint for Menus

Create a controller method to return menus:

```php
// In app/Http/Controllers/MenuController.php

public function index(Request $request)
{
    $menuType = $request->get('type', 'masters');
    
    $menus = DB::table('menus')
        ->where('menu_type', $menuType)
        ->where('is_active', 1)
        ->orderBy('order')
        ->get();
    
    return response()->json([
        'success' => true,
        'menus' => $menus
    ]);
}
```

Add route in `routes/api.php`:
```php
Route::middleware('auth:sanctum')->get('/menus', [MenuController::class, 'index']);
```

## Common Issues and Solutions

### Issue 1: Menus not showing after running setup.php
**Solution:**
- Check if the `menus` table exists
- Verify the table structure matches the schema above
- Check database connection in `.env`
- Run `php artisan migrate` if table doesn't exist

### Issue 2: Duplicate menu entries
**Solution:**
- Use `updateOrInsert` instead of `insert`
- Add unique constraint on `slug` and `menu_type` columns
- Clear existing menus before inserting: `DB::table('menus')->where('menu_type', 'masters')->delete();`

### Issue 3: Menus not appearing in API response
**Solution:**
- Verify `is_active` is set to 1
- Check if `menu_type` matches ('masters')
- Ensure API route is protected with `auth:sanctum` middleware
- Check API endpoint returns correct JSON structure

### Issue 4: Missing menu items
**Solution:**
- Verify all menu items are in the `$mastersMenus` array
- Check for typos in slug or menu_type
- Ensure database insert was successful (check for errors)

## Verification Steps

1. **Check Database:**
```sql
SELECT * FROM menus WHERE menu_type = 'masters' ORDER BY `order`;
```

2. **Test API Endpoint:**
```bash
curl -X GET http://your-domain/api/menus?type=masters \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Accept: application/json"
```

3. **Check Laravel Logs:**
```bash
tail -f storage/logs/laravel.log
```

## Next Steps

After setting up menus in the backend:
1. Update Flutter app to fetch menus from API
2. Display menus dynamically in the dashboard
3. Add navigation to menu items

See `FLUTTER_MENU_INTEGRATION.md` for Flutter integration details.

