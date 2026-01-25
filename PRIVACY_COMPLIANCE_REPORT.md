# Privacy & App Store Compliance Report
## The Magic Collection iOS App

**Report Date:** January 21, 2026
**App Version:** 1.0
**Analysis Scope:** Complete codebase review for data handling, network usage, and privacy compliance

---

## Executive Summary

✅ **Overall Status:** Your app is privacy-friendly with minimal data collection and mostly local storage.

⚠️ **Action Required:** You need to add network usage permission disclosure for image loading.

---

## Data Storage Analysis

### ✅ Local Data Storage (100% On-Device)

**SwiftData Storage:**
- All user data is stored locally using SwiftData (Apple's modern persistence framework)
- Database files remain on the user's device
- No automatic cloud synchronization
- No data transmission to external servers

**What's Stored Locally:**
1. **Card Database** - Imported from Scryfall JSON file (user-initiated, local file)
2. **Collection Entries** - User's card collection with quantities
3. **Deck Lists** - All user-created decks and lists
4. **Deck Entries** - Cards in decks with quantities
5. **Notes** - User notes on cards and decks

**Storage Location:** iOS app container (sandboxed, protected by iOS security)

---

## Network Usage Analysis

### ⚠️ Image Loading (Read-Only, External CDN)

**What Connects to the Internet:**
- `AsyncImage` views load card images from Scryfall's CDN servers
- Image URLs format: `https://cards.scryfall.io/*`
- **Purpose:** Display card artwork in the UI
- **Frequency:** Only when viewing cards with images
- **Data Sent:** Standard HTTP GET requests (no user data, just image requests)
- **Cached:** iOS automatically caches images in URLCache

**Locations in Code:**
- CollectionView.swift:193, 240
- CollectionEntryDetailView.swift:24
- ManualCardEntryView.swift:151
- CardScannerView.swift:247-249
- DeckDetailView.swift:247

### ✅ No Other Network Activity

**What Does NOT Connect:**
- ❌ No analytics services
- ❌ No tracking pixels or beacons
- ❌ No crash reporting services
- ❌ No advertising networks
- ❌ No user authentication servers
- ❌ No cloud backup/sync
- ❌ No API calls (except image loading)
- ❌ No third-party SDKs

**Link to External Website:**
- Settings view has a Link to `https://scryfall.com` (opens in Safari, not in-app)
- User-initiated only
- Attribution/credit to Scryfall for card data

---

## Permissions Analysis

### ✅ Currently Declared Permissions

**Info.plist:**
```xml
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan your Magic: The Gathering cards
and add them to your collection.</string>
```
- **Purpose:** Card scanning with VisionKit
- **Usage:** Only when user taps "Scan Cards" button
- **Never accessed in background**
- **No photos are saved or transmitted**

**Entitlements:**
```xml
<key>com.apple.security.files.user-selected.read-only</key>
<true/>
```
- **Purpose:** Import Scryfall JSON database file
- **Usage:** Only when user selects file via file picker
- **Read-only access (no file writing)**
- **Sandboxed access**

### ⚠️ Missing: Network Usage Declaration

**Required for App Store Submission:**

Since your app loads images from external servers, you need to add App Transport Security configuration to Info.plist.

**Recommended Addition:**
```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>scryfall.io</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
        <key>cards.scryfall.io</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSExceptionRequiresForwardSecrecy</key>
            <true/>
        </dict>
    </dict>
</dict>
```

**Why This is Safe:**
- Scryfall uses HTTPS (secure connections)
- Only loading images, not sending user data
- Explicitly listing domains (no arbitrary loads)

---

## App Store Privacy Questionnaire

When submitting to App Store, you'll fill out Apple's privacy questionnaire. Here's what to answer:

### Data Collection: **NO**

Your app does NOT collect:
- ❌ Contact Info
- ❌ Health & Fitness
- ❌ Financial Info
- ❌ Location
- ❌ Sensitive Info
- ❌ Contacts
- ❌ User Content (that leaves the device)
- ❌ Browsing History
- ❌ Search History
- ❌ Identifiers
- ❌ Purchases
- ❌ Usage Data
- ❌ Diagnostics
- ❌ Other Data

### Data Used to Track: **NO**

Your app does NOT track users across apps/websites.

### Network Usage: **YES**

You should disclose:
- **Purpose:** "Loading card images for display"
- **Data Type:** Image URLs (not user-generated)
- **Linked to User:** No
- **Used for Tracking:** No
- **Third Party:** Scryfall (card image hosting)

---

## App Store Review Considerations

### ✅ Strengths
1. **Privacy-First Design** - All user data stays local
2. **No Tracking** - Zero analytics or user tracking
3. **Transparent** - Clear camera permission description
4. **Secure** - Sandboxed app with minimal permissions
5. **No Ads** - No advertising networks
6. **Offline-Capable** - Works without internet (except images)

### ⚠️ Things to Note in Review Notes

**Scryfall Database Import:**
- Explain that users must download Scryfall JSON file separately
- Link: https://scryfall.com/docs/api/bulk-data
- This is user-initiated, not automatic
- File stays local after import

**Image Loading:**
- Card images load from Scryfall's CDN
- Standard practice for TCG apps
- Reduces app size significantly
- Cached for offline viewing after first load

**Camera Usage:**
- Optional feature (not required to use app)
- Only captures text (card names), not photos
- No images saved to Photo Library
- Scanning happens on-device with VisionKit

---

## Required Updates for App Store Submission

### 1. Update Info.plist ⚠️ **REQUIRED**

Add App Transport Security settings (see XML above in "Missing: Network Usage Declaration" section)

### 2. Privacy Policy 📄 **RECOMMENDED**

While not required for apps that don't collect data, having a simple privacy policy builds trust:

**Suggested Content:**
```
Privacy Policy - The Magic Collection

Data Storage:
All your card collection data is stored locally on your device.
We do not collect, transmit, or store any of your personal information.

Card Images:
Card images are loaded from Scryfall's servers when viewing your collection.
These are standard HTTP requests and do not contain any personal information.

Camera:
The app uses your camera only to scan card names. No photos are saved or transmitted.

Third-Party Services:
- Scryfall: Card database and images (https://scryfall.com)

Contact:
[Your contact email]

Last updated: January 21, 2026
```

### 3. App Review Notes 📝 **RECOMMENDED**

Include this in your App Store submission:

```
Review Notes:

SCRYFALL DATA IMPORT:
1. To fully test the app, download the Scryfall bulk data file:
   https://scryfall.com/docs/api/bulk-data
2. In the app, go to Settings > Import Scryfall Database
3. Select the downloaded JSON file
4. Wait 2-3 minutes for import to complete

CAMERA SCANNING (iOS 16+ required):
1. Requires physical device with camera
2. Point camera at physical Magic card name
3. Text recognition happens on-device via VisionKit

SAMPLE DATA:
Use "Manual Entry" to add cards without database import.

PRIVACY:
- All data stored locally (SwiftData)
- Card images loaded from Scryfall CDN (read-only)
- No user tracking or analytics
- Camera used only for text recognition (no photos saved)
```

---

## Compliance Checklist

### Privacy & Data
- ✅ No data collection
- ✅ No user tracking
- ✅ Local-only storage
- ✅ No third-party analytics
- ✅ No cloud sync
- ✅ No persistent identifiers
- ✅ No advertising

### Permissions
- ✅ Camera permission properly described
- ✅ File access sandboxed (read-only)
- ⚠️ Need to add ATS exception for image loading

### Documentation
- ✅ Clear camera usage description
- ⚠️ Add App Transport Security config
- 📄 Consider adding privacy policy URL

### App Store Readiness
- ✅ Version 1.0 set in Info.plist
- ✅ Display name set
- ✅ No embedded credentials or API keys
- ✅ No placeholder content
- ⚠️ Need app icon
- ⚠️ Need screenshots

---

## Recommendations for Enhanced Privacy

### Already Implemented ✅
1. Local-first architecture
2. No analytics tracking
3. Sandboxed storage
4. Clear permission descriptions
5. User-initiated network requests only

### Optional Enhancements
1. **Image Caching Policy** - Consider adding settings to clear cached images
2. **Offline Mode Indicator** - Show when images can't load (no connection)
3. **Data Export** - Already have CSV export ✅
4. **Data Deletion** - Already have "Delete All Data" ✅

---

## Summary for App Store Submission

### What to Tell Apple

**App Description (Privacy Section):**
```
Privacy First:
• All your collection data stays on your device
• No account required
• No data collection or tracking
• Works offline (card images require internet)
• Your data belongs to you
```

**Privacy Declarations:**
- Data Collection: None
- Tracking: None
- Network Usage: Image loading only (Scryfall CDN)
- Camera: Optional card scanning (on-device processing)

### What NOT to Worry About
- ✅ You're not collecting user data
- ✅ You're not tracking users
- ✅ You're not sending data to third parties
- ✅ You're not storing data in the cloud
- ✅ You have no ads or analytics

---

## Conclusion

Your app has **excellent privacy characteristics**. The only network activity is loading card images from Scryfall, which is standard practice and doesn't involve user data.

**Before App Store Submission:**
1. ✅ Camera permission - Already added
2. ⚠️ Add App Transport Security config to Info.plist
3. 📄 Consider adding a privacy policy (optional but recommended)
4. 🎨 Add app icon
5. 📸 Prepare screenshots

**No privacy concerns or red flags.** Your app respects user privacy and keeps all personal data on-device.

---

**Generated:** 2026-01-21
**App Version:** 1.0
**Compliance Status:** Ready (after ATS config added)
