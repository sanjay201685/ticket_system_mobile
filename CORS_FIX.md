# CORS Error Fix Guide

## Problem
When running Flutter web app, you get this error:
```
Access to XMLHttpRequest at 'http://ticketsystem.local/api/stock-orders' 
from origin 'http://localhost:54836' has been blocked by CORS policy
```

## Solution: Configure CORS in Laravel Backend

### Step 1: Open Laravel CORS Configuration File

Navigate to your Laravel project:
```
D:\xampp\htdocs\ticketSystem\config\cors.php
```

### Step 2: Update CORS Configuration

Open `config/cors.php` and update it to allow your Flutter web origin:

```php
<?php

return [
    /*
    |--------------------------------------------------------------------------
    | Cross-Origin Resource Sharing (CORS) Configuration
    |--------------------------------------------------------------------------
    */

    'paths' => ['api/*', 'sanctum/csrf-cookie'],

    'allowed_methods' => ['*'],

    'allowed_origins' => [
        'http://localhost:*',  // Allow all localhost ports
        'http://127.0.0.1:*',  // Allow all 127.0.0.1 ports
        'http://ticketsystem.local',  // Your local domain
    ],

    // OR for development, you can allow all origins (NOT recommended for production):
    // 'allowed_origins' => ['*'],

    'allowed_origins_patterns' => [
        '/^http:\/\/localhost:\d+$/',  // Pattern for localhost with any port
        '/^http:\/\/127\.0\.0\.1:\d+$/',  // Pattern for 127.0.0.1 with any port
    ],

    'allowed_headers' => ['*'],

    'exposed_headers' => [],

    'max_age' => 0,

    'supports_credentials' => true,  // Set to true if using cookies/auth
];
```

### Step 3: Clear Laravel Config Cache

After updating the CORS config, clear the config cache:

```bash
cd D:\xampp\htdocs\ticketSystem
php artisan config:clear
php artisan cache:clear
```

### Step 4: Verify CORS Middleware is Registered

Check `bootstrap/app.php` or `app/Http/Kernel.php` to ensure CORS middleware is registered:

In `bootstrap/app.php` (Laravel 11+):
```php
->withMiddleware(function (Middleware $middleware) {
    $middleware->api(prepend: [
        \Illuminate\Http\Middleware\HandleCors::class,
    ]);
})
```

Or in `app/Http/Kernel.php` (Laravel 10 and below):
```php
protected $middleware = [
    // ...
    \Illuminate\Http\Middleware\HandleCors::class,
];
```

## Alternative: Quick Fix for Development (Allow All Origins)

**⚠️ WARNING: Only use this for local development, NOT for production!**

In `config/cors.php`:
```php
'allowed_origins' => ['*'],
```

This allows requests from any origin. Use only during development.

## Testing

After configuring CORS:

1. Restart your Laravel server (if using `php artisan serve`)
2. Refresh your Flutter web app
3. The CORS error should be resolved

## Troubleshooting

If CORS errors persist:

1. **Check if CORS middleware is applied**: Make sure `HandleCors` middleware is in the middleware stack
2. **Check browser console**: Look for the exact error message
3. **Test with curl**: 
   ```bash
   curl -H "Origin: http://localhost:54836" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: authorization" \
        -X OPTIONS \
        http://ticketsystem.local/api/stock-orders
   ```
4. **Check Laravel logs**: `storage/logs/laravel.log`

## For Production

In production, specify exact origins instead of using wildcards:

```php
'allowed_origins' => [
    'https://yourdomain.com',
    'https://www.yourdomain.com',
],
```

