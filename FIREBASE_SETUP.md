# Firebase Setup Guide

## Required Firebase Services

This app requires the following Firebase services to be enabled:

### 1. Firestore Database
- **Status**: Currently DISABLED in your project
- **Action Required**: Enable Firestore Database
- **Steps**:
  1. Visit: https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=alumni-37291
  2. Click "Enable" API
  3. Wait a few minutes for the action to propagate
  4. Set up Firestore security rules in Firebase Console

### 2. Authentication
- **Required Methods**: Email/Password and Google Sign-In
- **Status**: Should be enabled
- **Verification**: Check Firebase Console → Authentication → Sign-in method

### 3. Storage (for profile images)
- **Required**: For uploading and storing profile images
- **Status**: Should be enabled

## Firestore Security Rules

Add these security rules in Firebase Console → Firestore → Rules:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
    }

    // Users can read and write their own profile
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }

    // Users can read all user profiles (for directory)
    match /users/{userId} {
      allow read: if request.auth != null;
    }

    // Events: admins can create/update/delete; normal users can update only RSVP attendees
    match /events/{eventId} {
      allow read: if request.auth != null;
      allow create, delete: if isAdmin();
      allow update: if isAdmin()
        || (request.resource.data.diff(resource.data).affectedKeys().hasOnly(['attendees']));
    }

    // Posts: admins can update/delete any post.
    // Normal users can update only fields needed for likes/comments.
    match /posts/{postId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if isAdmin();
      allow update: if isAdmin()
        || request.resource.data.diff(resource.data).affectedKeys().hasOnly(['likes', 'commentCount']);
    }

    // Post comments: users can create their own comments.
    match /posts/{postId}/comments/{commentId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }

    // Donations: admins manage campaign details; normal users can only increment collectedAmount.
    match /donations/{donationId} {
      allow read: if request.auth != null;
      allow create, delete: if isAdmin();
      allow update: if isAdmin()
        || request.resource.data.diff(resource.data).affectedKeys().hasOnly(['collectedAmount']);
    }

    // Donation contributions: users can only create their own contribution docs.
    match /donations/{donationId}/contributions/{contributionId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
    }

    // Other collections: keep existing behavior for this project
    match /{document=**} {
      allow read, write: if request.auth != null
        && !(document.path.startsWith('events/') ||
             document.path.startsWith('posts/') ||
             document.path.startsWith('donations/'));
    }
  }
}
```

## Storage Security Rules

Add these rules in Firebase Console → Storage → Rules:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Users can only upload to their own profile image folder
    match /profile_images/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Common Issues and Solutions

### 1. "Cloud Firestore API has not been used"
**Solution**: Enable Firestore API using the link above

### 2. "PigeonUserDetails type cast error"
**Solution**: This is handled in the app with retry logic and proper error handling

### 3. "Service temporarily unavailable"
**Solution**: Check internet connection and ensure all Firebase APIs are enabled

## Testing After Setup

1. Enable all required Firebase services
2. Test email sign-up
3. Test email sign-in
4. Test Google Sign-In
5. Test profile image upload

## Project Details

- **Project ID**: alumni-37291
- **App Name**: Alumni Connect
