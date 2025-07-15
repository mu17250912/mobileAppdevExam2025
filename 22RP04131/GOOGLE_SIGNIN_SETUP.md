# Google Sign-In Setup Guide for QuickDocs

This guide will help you set up Google Sign-In for your QuickDocs Flutter app.

## Prerequisites

1. A Firebase project (you already have this)
2. Google Cloud Console access
3. Android/iOS development environment

## Step 1: Configure Google Sign-In in Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `quickdocs-7000f`
3. Navigate to **Authentication** > **Sign-in method**
4. Click on **Google** provider
5. Enable Google Sign-In by toggling the switch
6. Add your support email
7. Click **Save**

## Step 2: Configure OAuth 2.0 Client IDs

### For Android:

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Select your Firebase project
3. Navigate to **APIs & Services** > **Credentials**
4. Click **+ CREATE CREDENTIALS** > **OAuth 2.0 Client IDs**
5. Choose **Android** as application type
6. Fill in the details:
   - **Package name**: `com.example.quickdocs`
   - **SHA-1 certificate fingerprint**: Get this from your debug keystore

### Get SHA-1 Certificate Fingerprint:

Run this command in your project directory:

```bash
# For Windows
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

# For macOS/Linux
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the SHA1 fingerprint in the output.

### For iOS (if needed):

1. In Google Cloud Console, create another OAuth 2.0 Client ID
2. Choose **iOS** as application type
3. Fill in your Bundle ID (e.g., `com.example.quickdocs`)

## Step 3: Update google-services.json

After creating the OAuth client IDs, download the updated `google-services.json` file from Firebase Console:

1. Go to Firebase Console > Project Settings
2. Scroll down to **Your apps** section
3. Click on your Android app
4. Click **Download google-services.json**
5. Replace the existing file in `android/app/google-services.json`

The new file should contain OAuth client information in the `oauth_client` array.

## Step 4: iOS Configuration (if building for iOS)

1. Add the following to your `ios/Runner/Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

Replace `YOUR_REVERSED_CLIENT_ID` with the value from your `GoogleService-Info.plist` file.

## Step 5: Test Google Sign-In

1. Run `flutter pub get` to install dependencies
2. Build and run your app
3. Try signing in with Google from the login screen

## Troubleshooting

### Common Issues:

1. **"Sign in failed" error**: Make sure OAuth client IDs are properly configured
2. **"Network error"**: Check internet connection and Firebase project settings
3. **"Invalid package name"**: Verify the package name matches in all configurations

### Debug Steps:

1. Check Firebase Console > Authentication > Users to see if users are being created
2. Verify OAuth client IDs in Google Cloud Console
3. Check that `google-services.json` contains OAuth client information
4. Ensure SHA-1 fingerprint is correct for your keystore

## Security Notes

- Keep your `google-services.json` file secure and don't commit it to public repositories
- Use different OAuth client IDs for debug and release builds
- Consider implementing additional security measures for production apps

## Next Steps

Once Google Sign-In is working:

1. Test the premium features with Google users
2. Consider adding additional OAuth providers (Apple, Facebook, etc.)
3. Implement proper error handling for different sign-in scenarios
4. Add user profile management for Google users

## Support

If you encounter issues:

1. Check the [Google Sign-In Flutter documentation](https://pub.dev/packages/google_sign_in)
2. Review [Firebase Authentication documentation](https://firebase.google.com/docs/auth)
3. Check the [Google Cloud Console documentation](https://cloud.google.com/apis/docs/overview)
