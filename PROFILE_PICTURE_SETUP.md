# Profile Picture Upload - Setup & Troubleshooting

## What I Fixed

1. **Better Error Handling**: Added detailed error messages to help identify the issue
2. **Fallback Storage**: If Firebase Storage fails, the app now saves images as base64 in Firestore (works for images under 1MB)
3. **Debug Logging**: Added console logs to track the upload process
4. **Support for Both Storage Methods**: Can load images from Firebase Storage URLs or base64 data

## Firebase Storage Setup (Required for large images)

### Step 1: Enable Firebase Storage
1. Go to [Firebase Console](https://console.firebase.google.com)
2. Select your project: **dailynest-35f52**
3. Click on "Storage" in the left menu
4. Click "Get Started"
5. Choose "Start in test mode" (we'll secure it next)

### Step 2: Set Security Rules
In Firebase Console → Storage → Rules tab, paste this:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Allow authenticated users to read any profile picture
    match /profile_pictures/{userId} {
      allow read: if request.auth != null;
      // Only allow users to write their own profile picture
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

Click "Publish"

### Step 3: Test the Upload

Run the app and try uploading a profile picture. You should now see detailed error messages if something goes wrong.

## How It Works Now

### Primary Method: Firebase Storage
- Uploads images to Firebase Storage
- Stores the download URL in Firestore
- Best for any image size
- Requires Firebase Storage to be enabled

### Fallback Method: Base64 in Firestore
- If Firebase Storage fails, automatically converts image to base64
- Stores directly in Firestore
- Works for images under 1MB
- No additional Firebase setup needed

## Testing Steps

1. **Clean and rebuild**:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Watch the console output** when you upload a profile picture:
   - Look for messages starting with "Starting profile picture upload..."
   - Check if it says "Upload successful!" or "Firebase Storage upload failed"
   - If using fallback, you'll see "Using base64 fallback storage"

3. **Check for error messages**:
   - Any errors will now show in a dialog with specific details
   - Common errors:
     - "Storage permission denied" → Firebase Storage rules need to be set
     - "User not authenticated" → User needs to sign in again
     - "Image too large" → Image is over 1MB and Storage isn't set up

## If You Still Have Issues

1. **Check Firebase Storage is enabled**:
   - Firebase Console → Storage
   - Should show a storage bucket, not "Get Started" button

2. **Verify you're signed in**:
   - Try signing out and signing back in
   - The user must be authenticated to upload

3. **Check image size**:
   - Without Firebase Storage enabled, images must be under 1MB
   - Try using a smaller image for testing

4. **Check Firestore rules**:
   Go to Firestore → Rules and ensure you have:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

## Error Messages Guide

- **"User not authenticated"** → Sign in first
- **"Storage permission denied"** → Enable Firebase Storage and set rules
- **"Image too large"** → Image > 1MB and Storage not enabled. Enable Storage or use smaller image
- **"Profile picture upload failed"** → Check console for detailed error
- **"Failed to get upload URL"** → Upload succeeded but couldn't get the URL (rare)

## Current Status

✅ Error handling improved
✅ Fallback storage added
✅ Debug logging enabled
✅ Base64 support added
⚠️ Firebase Storage needs to be enabled for large images

The app will work with small images (<1MB) even without Firebase Storage!
