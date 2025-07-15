# Firebase Security Rules Deployment Guide

## Issue
The app is experiencing permission denied errors when users try to edit, update, or deactivate their skills. This is because Firebase Firestore security rules need to be deployed to the Firebase project.

## Solution

### Option 1: Deploy via Firebase CLI (Recommended)

1. **Install Firebase CLI** (if not already installed):
   ```bash
   npm install -g firebase-tools
   ```

2. **Login to Firebase**:
   ```bash
   firebase login
   ```

3. **Initialize Firebase in the project** (if not already done):
   ```bash
   firebase init firestore
   ```

4. **Deploy the security rules**:
   ```bash
   firebase deploy --only firestore:rules
   ```

### Option 2: Deploy via Firebase Console

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `skillswap-8cdb3`
3. Go to Firestore Database
4. Click on the "Rules" tab
5. Copy the content from `firestore.rules` file
6. Paste it into the rules editor
7. Click "Publish"

### Option 3: Use FlutterFire CLI

1. **Install FlutterFire CLI**:
   ```bash
   dart pub global activate flutterfire_cli
   ```

2. **Deploy rules**:
   ```bash
   flutterfire firestore:rules
   ```

## Security Rules Overview

The current security rules allow:
- Users to read and write their own user documents
- Users to read all skills, but only create/update/delete their own skills
- Users to manage sessions they're part of
- Users to manage their own notifications and messages

## Testing the Rules

After deploying the rules, test the following functionality:
1. Adding a new skill
2. Editing an existing skill
3. Deactivating/activating a skill
4. Deleting a skill
5. Viewing skills in the profile screen

## Troubleshooting

If you still experience permission issues:

1. **Check Firebase Console** for any rule syntax errors
2. **Verify the user is authenticated** before performing operations
3. **Check the data structure** matches the rules expectations
4. **Clear app cache** and restart the app

## Current Rules Status

The `firestore.rules` file contains comprehensive security rules that should resolve the permission issues. Make sure to deploy these rules to your Firebase project. 