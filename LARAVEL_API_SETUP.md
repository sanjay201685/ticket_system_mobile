# Laravel API Integration Setup

This document explains how to integrate your Flutter app with your Laravel backend API.

## 📋 Prerequisites

1. **Laravel Backend**: Your Laravel project at `D:\xampp\htdocs\ticketSystem`
2. **XAMPP**: Running Apache and MySQL
3. **Flutter**: Flutter SDK installed

## 🔧 Laravel Backend Setup

### 1. Install Laravel Sanctum (for API authentication)

```bash
cd D:\xampp\htdocs\ticketSystem
composer require laravel/sanctum
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan migrate
```

### 2. Configure Sanctum in `config/sanctum.php`

```php
'stateful' => explode(',', env('SANCTUM_STATEFUL_DOMAINS', sprintf(
    '%s%s',
    'localhost,localhost:3000,127.0.0.1,127.0.0.1:8000,::1',
    env('APP_URL') ? ','.parse_url(env('APP_URL'), PHP_URL_HOST) : ''
))),
```

### 3. Add API Routes in `routes/api.php`

```php
<?php

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthController;

// Public routes
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/user', [AuthController::class, 'user']);
    Route::post('/logout', [AuthController::class, 'logout']);
});
```

### 4. Create AuthController

```bash
php artisan make:controller AuthController
```

Add to `app/Http/Controllers/AuthController.php`:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'required|email',
            'password' => 'required',
        ]);

        $user = User::where('email', $request->email)->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            throw ValidationException::withMessages([
                'email' => ['The provided credentials are incorrect.'],
            ]);
        }

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'message' => 'Login successful',
            'user' => $user,
            'token' => $token,
        ]);
    }

    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8|confirmed',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
        ]);

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'message' => 'Registration successful',
            'user' => $user,
            'token' => $token,
        ], 201);
    }

    public function user(Request $request)
    {
        return response()->json($request->user());
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logged out successfully',
        ]);
    }
}
```

### 5. Update User Model

Add to `app/Models/User.php`:

```php
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;
    
    // ... existing code
}
```

### 6. Enable CORS

Install CORS package:

```bash
composer require fruitcake/laravel-cors
```

Add to `config/cors.php`:

```php
'allowed_origins' => ['*'],
'allowed_origins_patterns' => [],
'allowed_headers' => ['*'],
'allowed_methods' => ['*'],
'exposed_headers' => [],
'max_age' => 0,
'supports_credentials' => false,
```

## 📱 Flutter App Configuration

### 1. Update API URL

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // For local development with XAMPP
  static const String baseUrl = 'http://localhost/ticketSystem/public/api';
  
  // For Android emulator
  static const String androidBaseUrl = 'http://10.0.2.2/ticketSystem/public/api';
  
  // For physical device, use your computer's IP
  // Example: static const String deviceBaseUrl = 'http://192.168.1.100/ticketSystem/public/api';
}
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

```bash
flutter run
```

## 🔧 Troubleshooting

### Common Issues:

1. **CORS Error**: Make sure CORS is properly configured in Laravel
2. **Connection Refused**: Check if XAMPP is running and Laravel is accessible
3. **Android Emulator**: Use `10.0.2.2` instead of `localhost`
4. **Physical Device**: Use your computer's IP address instead of `localhost`

### Testing API Endpoints:

```bash
# Test login
curl -X POST http://localhost/ticketSystem/public/api/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password"}'

# Test with token
curl -X GET http://localhost/ticketSystem/public/api/user \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/login` | User login |
| POST | `/api/register` | User registration |
| GET | `/api/user` | Get user profile |
| POST | `/api/logout` | User logout |

## 🔐 Security Notes

1. **HTTPS**: Use HTTPS in production
2. **Token Expiry**: Configure token expiry in Sanctum
3. **Rate Limiting**: Add rate limiting to API routes
4. **Validation**: Always validate input data
5. **CORS**: Configure CORS properly for production

## 📞 Support

If you encounter any issues:

1. Check Laravel logs: `storage/logs/laravel.log`
2. Check Flutter console for errors
3. Verify API endpoints are accessible
4. Ensure CORS is properly configured













