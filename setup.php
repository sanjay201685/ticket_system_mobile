<?php

/**
 * Setup.php - Masters Menus Configuration
 * 
 * This script seeds the masters menus into the Laravel database.
 * Run this from the Laravel root directory: php setup.php
 */

require __DIR__ . '/vendor/autoload.php';

use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

// Bootstrap Laravel
try {
    $app = require_once __DIR__ . '/bootstrap/app.php';
    $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
    echo "✅ Laravel bootstrapped successfully\n\n";
} catch (Exception $e) {
    die("❌ Error bootstrapping Laravel: " . $e->getMessage() . "\n");
}

// Verify menus table exists
if (!Schema::hasTable('menus')) {
    echo "⚠️  WARNING: 'menus' table does not exist. Creating table...\n";
    
    try {
        DB::statement("
            CREATE TABLE IF NOT EXISTS `menus` (
                `id` bigint(20) UNSIGNED NOT NULL AUTO_INCREMENT,
                `name` varchar(255) NOT NULL,
                `slug` varchar(255) NOT NULL,
                `icon` varchar(255) DEFAULT NULL,
                `route` varchar(255) DEFAULT NULL,
                `parent_id` bigint(20) UNSIGNED DEFAULT NULL,
                `order` int(11) DEFAULT 0,
                `is_active` tinyint(1) DEFAULT 1,
                `menu_type` varchar(50) DEFAULT 'main',
                `created_at` timestamp NULL DEFAULT NULL,
                `updated_at` timestamp NULL DEFAULT NULL,
                PRIMARY KEY (`id`),
                KEY `parent_id` (`parent_id`),
                KEY `menu_type` (`menu_type`),
                KEY `slug` (`slug`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ");
        echo "✅ 'menus' table created successfully\n\n";
    } catch (Exception $e) {
        die("❌ Error creating 'menus' table: " . $e->getMessage() . "\n");
    }
}

// Clear existing masters menus if needed (uncomment to clear)
// DB::table('menus')->where('menu_type', 'masters')->delete();
// echo "🗑️  Cleared existing masters menus\n\n";

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

// Insert/Update menus
echo "📝 Inserting/Updating masters menus...\n";
$inserted = 0;
$updated = 0;

foreach ($mastersMenus as $menu) {
    try {
        // Check if menu already exists
        $existing = DB::table('menus')
            ->where('slug', $menu['slug'])
            ->where('menu_type', 'masters')
            ->first();
        
        if (!$existing) {
            DB::table('menus')->insert($menu);
            echo "  ✅ Inserted menu: {$menu['name']}\n";
            $inserted++;
        } else {
            // Update existing menu to ensure latest changes
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
            echo "  🔄 Updated menu: {$menu['name']}\n";
            $updated++;
        }
    } catch (Exception $e) {
        echo "  ❌ Error processing menu '{$menu['name']}': " . $e->getMessage() . "\n";
    }
}

// Update parent_id for sub-menus (hierarchical structure)
echo "\n🔗 Setting up parent-child relationships...\n";
$mastersParent = DB::table('menus')
    ->where('slug', 'masters')
    ->where('menu_type', 'masters')
    ->first();

if ($mastersParent) {
    $subMenus = [
        'masters.users', 
        'masters.departments', 
        'masters.categories', 
        'masters.priorities', 
        'masters.status', 
        'masters.locations', 
        'masters.companies'
    ];
    
    foreach ($subMenus as $slug) {
        try {
            DB::table('menus')
                ->where('slug', $slug)
                ->where('menu_type', 'masters')
                ->update(['parent_id' => $mastersParent->id]);
        } catch (Exception $e) {
            echo "  ⚠️  Error updating parent_id for {$slug}: " . $e->getMessage() . "\n";
        }
    }
    echo "  ✅ Parent-child relationships updated\n";
} else {
    echo "  ⚠️  WARNING: Masters parent menu not found!\n";
}

// Verification
echo "\n=== Verification ===\n";
$mastersCount = DB::table('menus')
    ->where('menu_type', 'masters')
    ->where('is_active', 1)
    ->count();

echo "Total active masters menus: {$mastersCount}\n";
echo "Inserted: {$inserted}, Updated: {$updated}\n\n";

if ($mastersCount < 8) {
    echo "⚠️  WARNING: Expected 8 masters menus, found {$mastersCount}\n";
    echo "Missing menus:\n";
    
    $expected = [
        'masters', 
        'masters.users', 
        'masters.departments', 
        'masters.categories', 
        'masters.priorities', 
        'masters.status', 
        'masters.locations', 
        'masters.companies'
    ];
    
    foreach ($expected as $slug) {
        $exists = DB::table('menus')
            ->where('slug', $slug)
            ->where('menu_type', 'masters')
            ->where('is_active', 1)
            ->exists();
        
        if (!$exists) {
            echo "  ❌ Missing: {$slug}\n";
        }
    }
} else {
    echo "✅ All masters menus are present!\n";
}

// List all masters menus
echo "\n📋 Masters Menus List:\n";
$menus = DB::table('menus')
    ->where('menu_type', 'masters')
    ->where('is_active', 1)
    ->orderBy('order')
    ->get(['id', 'name', 'slug', 'route', 'order', 'parent_id']);

foreach ($menus as $menu) {
    $parentInfo = $menu->parent_id ? " (parent: {$menu->parent_id})" : " (main)";
    echo "  [{$menu->order}] {$menu->name} ({$menu->slug}) -> {$menu->route}{$parentInfo}\n";
}

echo "\n✅ Masters menus setup completed!\n";
echo "Total masters menus: " . DB::table('menus')->where('menu_type', 'masters')->count() . "\n";



