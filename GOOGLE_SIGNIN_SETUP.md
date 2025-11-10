# Google Sign-In Setup Guide

## Flutter App Setup (Completed ✅)

The Flutter app has been configured with Google Sign-In. The following has been implemented:

1. ✅ Added `google_sign_in` package to `pubspec.yaml`
2. ✅ Added Google Sign-In method to `ApiService`
3. ✅ Added Google Sign-In method to `AuthService`
4. ✅ Added Google Sign-In button to login screen
5. ✅ Android configuration is ready

## Laravel Backend Setup Required

The error "signin failed providers RS not found for is" indicates that your Laravel backend needs to be configured to handle Google authentication. Follow these steps:

### 1. Install Laravel Socialite

In your Laravel project (`D:\xampp\htdocs\ticketSystem`), run:

```bash
composer require laravel/socialite
```

### 2. Configure Google OAuth in Laravel

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable Google+ API
4. Go to "Credentials" → "Create Credentials" → "OAuth 2.0 Client ID"
5. Configure OAuth consent screen:
   - Application type: Web application
   - Authorized redirect URIs: `http://ticketsystem.local/api/auth/google/callback`
6. Copy the Client ID and Client Secret

### 3. Update Laravel .env File

Add these to your Laravel `.env` file:

```env
GOOGLE_CLIENT_ID=your-google-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-google-client-secret
GOOGLE_REDIRECT_URI=http://ticketsystem.local/api/auth/google/callback
```

### 4. Update Laravel config/services.php

Add Google configuration:

```php
'google' => [
    'client_id' => env('GOOGLE_CLIENT_ID'),
    'client_secret' => env('GOOGLE_CLIENT_SECRET'),
    'redirect' => env('GOOGLE_REDIRECT_URI'),
],
```

### 5. Create Laravel Route for Google Authentication

In `routes/api.php`, add:

```php
Route::post('/auth/google', [AuthController::class, 'googleLogin']);
```

### 6. Create Google Login Method in AuthController

In your `AuthController.php`:

```php
use Laravel\Socialite\Facades\Socialite;
use Illuminate\Support\Facades\Auth;

public function googleLogin(Request $request)
{
    try {
        $idToken = $request->input('id_token');
        
        // Verify the Google ID token and get user info
        $client = new \Google_Client(['client_id' => config('services.google.client_id')]);
        $payload = $client->verifyIdToken($idToken);
        
        if ($payload) {
            $googleId = $payload['sub'];
            $email = $payload['email'];
            $name = $payload['name'];
            
            // Find or create user
            $user = User::firstOrCreate(
                ['email' => $email],
                [
                    'name' => $name,
                    'google_id' => $googleId,
                    'password' => bcrypt(Str::random(16)), // Random password
                ]
            );
            
            // Update google_id if user exists but doesn't have it
            if (!$user->google_id) {
                $user->google_id = $googleId;
                $user->save();
            }
            
            // Generate token
            $token = $user->createToken('auth_token')->plainTextToken;
            
            return response()->json([
                'success' => true,
                'message' => 'Login successful',
                'user' => $user,
                'token' => $token,
            ]);
        } else {
            return response()->json([
                'success' => false,
                'message' => 'Invalid Google token',
            ], 401);
        }
    } catch (\Exception $e) {
        return response()->json([
            'success' => false,
            'message' => 'Google login failed: ' . $e->getMessage(),
        ], 500);
    }
}
```

### 7. Update User Migration (if needed)

If you haven't already, add `google_id` column to users table:

```php
Schema::table('users', function (Blueprint $table) {
    $table->string('google_id')->nullable();
});
```

## Android SHA-1 Fingerprint (For Production)

When you're ready to publish, you'll need to:

1. Get your app's SHA-1 fingerprint:
   ```bash
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. Add this SHA-1 to your Google Cloud Console OAuth 2.0 Client ID configuration

## Testing

1. Build and run the Flutter app
2. Click "Continue with Google" button
3. Select your Google account
4. The app should authenticate and navigate to the dashboard

## Troubleshooting

- **Error: "providers RS not found"**: Laravel Socialite is not configured correctly
- **Error: "Invalid token"**: Google OAuth credentials don't match
- **Error: "Network error"**: Check that your API URL is correct in `app_config.dart`









