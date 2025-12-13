# Browser Feature Testing Guide

This document provides comprehensive test cases for all browser features in Kivixa. Follow each section to manually verify functionality.

---

## 1. Tab Management

### 1.1 Tab Bar Display
1. Open Browser from the sidebar
2. **Expected**: Tab bar visible at top showing current tab
3. Tab shows title (or "New Tab" if no page loaded)

### 1.2 Create New Tab
1. Click the **+** button in the tab bar (or press `Ctrl+T` on desktop)
2. **Expected**: New tab created and activated
3. **Expected**: Quick links page displayed

### 1.3 Switch Between Tabs
1. Create multiple tabs
2. Click on different tabs in the tab bar
3. **Expected**: Browser switches to clicked tab
4. Use `Ctrl+Tab` for next tab, `Ctrl+Shift+Tab` for previous (desktop)

### 1.4 Close Tab
1. Click the **X** button on a tab (or press `Ctrl+W`)
2. **Expected**: Tab closes
3. **Expected**: If last tab, it resets to new tab page instead of closing

### 1.5 Tab Persistence
1. Create multiple tabs with different URLs
2. Close and reopen the app
3. **Expected**: Tabs are restored with their URLs

---

## 2. Basic Navigation

### 2.1 URL Bar Navigation
1. Open Browser from the sidebar
2. Click on the URL bar (or press `Ctrl+L`)
3. Type `https://www.google.com` and press Enter
4. **Expected**: Page loads, URL bar shows `https://www.google.com`, lock icon appears (HTTPS)

### 2.2 Back/Forward Navigation
1. Navigate to `https://www.google.com`
2. Click on a search result or link
3. Click the **Back** button (←)
4. **Expected**: Returns to Google homepage
5. Click the **Forward** button (→)
6. **Expected**: Returns to the search result page

### 2.3 Reload Page
1. On any webpage, click the **Reload** button (↻)
2. **Expected**: Page reloads with progress indicator
3. Alternatively, press `Ctrl+R` or `F5`
4. **Expected**: Same reload behavior

### 2.4 Home Button
1. Navigate to any webpage
2. Click the **Home** button (🏠)
3. **Expected**: Returns to Google homepage (default home)

### 2.5 Stop Loading
1. Start loading a slow webpage
2. Click the **Stop** button (✕) that appears during loading
3. **Expected**: Loading stops immediately

---

## 3. Quick Links (New Tab Page)

### 3.1 Quick Links Display
1. Open Browser
2. **Expected**: See 6 quick links: Google, GitHub, Stack Overflow, Wikipedia, YouTube, Reddit

### 3.2 Quick Link Navigation
1. Click on **GitHub** quick link
2. **Expected**: Navigates to `https://github.com`
3. Click on **Wikipedia** quick link
4. **Expected**: Navigates to `https://www.wikipedia.org`

---

## 4. Find in Page (Mobile Only)

### 4.1 Opening Find Bar
1. Navigate to any text-heavy page (e.g., `https://en.wikipedia.org/wiki/Flutter_(software)`)
2. Press `Ctrl+F` (mobile) or tap the search icon
3. **Expected**: Find bar appears at top with search field
4. **Note**: On desktop (Windows), a message says "Find in page is not supported on desktop yet"

### 4.2 Search Text
1. In the find bar, type `Flutter`
2. **Expected**: 
   - Matches are highlighted on the page
   - Match count shows (e.g., "1 of 15")
   - Current match is scrolled into view

### 4.3 Navigate Matches
1. Click the **Down arrow** (▼) or press Enter
2. **Expected**: Moves to next match, counter updates (e.g., "2 of 15")
3. Click the **Up arrow** (▲)
4. **Expected**: Moves to previous match

### 4.4 Close Find Bar
1. Press `Escape` or click the **X** button
2. **Expected**: Find bar closes, highlights removed

---

## 5. Bookmarks

### 5.1 Add Bookmark
1. Navigate to `https://flutter.dev`
2. Open menu (⋮) → Click **Bookmark**
3. **Expected**: Snackbar shows "Bookmarked: Flutter"

### 5.2 View Bookmarks
1. Open menu (⋮) → Click **Bookmarks**
2. **Expected**: Bottom sheet opens with bookmarked pages

### 5.3 Navigate from Bookmarks
1. In bookmarks sheet, click on a bookmark
2. **Expected**: Browser navigates to that URL, sheet closes

### 5.4 Remove Bookmark
1. Open bookmarks sheet
2. Click the **Delete** icon (🗑) next to a bookmark
3. **Expected**: Bookmark removed from list

### 4.5 Bookmark Toggle
1. Navigate to a bookmarked page
2. Open menu (⋮) → Click **Bookmark** again
3. **Expected**: Snackbar shows "Bookmark removed"

### 4.6 Clear All Bookmarks
1. Open bookmarks sheet with multiple bookmarks
2. Click **Clear All**
3. Confirm in dialog
4. **Expected**: All bookmarks removed

---

## 5. History

### 5.1 View History
1. Navigate to several pages
2. Open menu (⋮) → Click **History**
3. **Expected**: Bottom sheet shows recently visited URLs

### 5.2 Navigate from History
1. Click on a history entry
2. **Expected**: Browser navigates to that URL

### 5.3 Clear History
1. Open history sheet
2. Click **Clear**
3. Confirm in dialog
4. **Expected**: History cleared

---

## 6. Share & Copy

### 6.1 Share URL (Mobile/Desktop)
1. Navigate to any page
2. Open menu (⋮) → Click **Share**
3. **Expected**: System share dialog opens (or URL copied to clipboard on desktop)

### 6.2 Copy URL
1. Navigate to any page
2. Open menu (⋮) → Click **Copy URL**
3. **Expected**: Snackbar shows "URL copied to clipboard"
4. Paste in another app to verify

---

## 7. Developer Console

### 7.1 Open Console
1. Navigate to any page
2. Press `Ctrl+Shift+J` or open menu (⋮) → Click **Console**
3. **Expected**: Console panel appears at bottom

### 7.2 View Console Logs
1. Navigate to a page with JavaScript
2. Test with: `https://www.google.com` (has console activity)
3. **Expected**: Console shows log messages with timestamps

### 7.3 Log Level Colors
1. Observe console output
2. **Expected**:
   - Red text = ERROR
   - Orange text = WARNING
   - Blue text = DEBUG
   - Grey text = LOG/TIP

### 7.4 Clear Console
1. Open console with logs
2. Click **Clear** button (🗑)
3. **Expected**: Console cleared

### 7.5 Close Console
1. Press `Escape` or click console toggle again
2. **Expected**: Console panel closes

---

## 8. Dark Mode Injection

### 8.1 Inject Dark Mode
1. Navigate to a light-colored page (e.g., `https://www.wikipedia.org`)
2. Open menu (⋮) → Click **Toggle dark mode**
3. **Expected**: Page colors invert (dark background, light text)

### 8.2 Toggle Off Dark Mode
1. Click **Toggle dark mode** again
2. **Expected**: Page returns to original colors

---

## 9. View Source

### 9.1 View Page Source
1. Navigate to any page
2. Open menu (⋮) → Click **View source**
3. **Expected**: Dialog shows HTML source code

### 9.2 Copy Source
1. In view source dialog, click **Copy**
2. **Expected**: Source copied to clipboard

---

## 10. External Browser

### 10.1 Open in External Browser
1. Navigate to any page
2. Open menu (⋮) → Click **Open in browser**
3. **Expected**: System default browser opens with the URL

---

## 11. Desktop/Mobile Mode Toggle

### 11.1 Toggle Desktop Mode
1. Open menu (⋮) → Click **Desktop mode**
2. **Expected**: Page reloads with desktop user agent
3. **Expected**: Snackbar shows "Desktop mode enabled"

### 11.2 Toggle Mobile Mode
1. Open menu (⋮) → Click **Mobile mode** (when desktop mode is active)
2. **Expected**: Page reloads with mobile user agent
3. **Expected**: Snackbar shows "Mobile mode enabled"

---

## 12. Keyboard Shortcuts (Desktop)

### 12.1 Focus URL Bar
- Press `Ctrl+L`
- **Expected**: URL bar focused, text selected

### 12.2 Toggle Find Bar
- Press `Ctrl+F`
- **Expected**: Find bar opens (shows message on Windows that it's not supported)

### 12.3 Reload Page
- Press `Ctrl+R` or `F5`
- **Expected**: Page reloads

### 12.4 Toggle Console
- Press `Ctrl+Shift+J`
- **Expected**: Console panel opens/closes

### 12.5 Close Panels
- With find bar or console open, press `Escape`
- **Expected**: Active panel closes

### 12.6 New Tab
- Press `Ctrl+T`
- **Expected**: New tab opens

### 12.7 Close Tab
- Press `Ctrl+W`
- **Expected**: Current tab closes (or resets if last tab)

### 12.8 Next Tab
- Press `Ctrl+Tab`
- **Expected**: Switches to next tab

### 12.9 Previous Tab
- Press `Ctrl+Shift+Tab`
- **Expected**: Switches to previous tab

---

## 13. Android Back Button

### 13.1 Navigate Back in History
1. On Android, navigate to multiple pages
2. Press system back button
3. **Expected**: Goes back in browser history

### 13.2 Close Panels First
1. Open find bar or console
2. Press system back button
3. **Expected**: Panel closes (doesn't navigate back)

### 13.3 Exit Browser
1. With no history and no panels open
2. Press system back button
3. **Expected**: Exits browser page

---

## 14. Permission Handling

### 14.1 Camera Permission
1. Navigate to a site requesting camera (e.g., `https://webcamtests.com`)
2. **Expected**: Permission dialog appears
3. Click **Allow** or **Deny**
4. **Expected**: Permission granted/denied accordingly

### 14.2 Microphone Permission
1. Navigate to a site requesting microphone (e.g., `https://www.onlinemictest.com`)
2. **Expected**: Permission dialog with microphone request
3. Grant or deny permission

### 14.3 Location Permission
1. Navigate to `https://www.google.com/maps`
2. Click "Your location"
3. **Expected**: Location permission dialog appears

---

## 15. Download Handling

### 15.1 Download File
1. Navigate to a page with downloadable files
2. Try to download a file
3. **Expected**: Download confirmation dialog appears
4. Click **Download**
5. **Expected**: Opens in external browser for download

---

## 16. JavaScript Dialogs

### 16.1 Alert Dialog
1. Open console and run: `javascript:alert('Test Alert')`
2. **Expected**: Native alert dialog appears with "Test Alert"

### 16.2 Confirm Dialog
1. Test with: `javascript:confirm('Are you sure?')`
2. **Expected**: Confirm dialog with OK/Cancel buttons

### 16.3 Prompt Dialog
1. Test with: `javascript:prompt('Enter your name:', 'Default')`
2. **Expected**: Prompt dialog with input field

---

## 17. Security Indicators

### 17.1 HTTPS Lock Icon
1. Navigate to `https://www.google.com`
2. **Expected**: Lock icon (🔒) appears before URL

### 17.2 HTTP (No Lock)
1. Navigate to an HTTP site (if accessible)
2. **Expected**: No lock icon (or warning indicator)

---

## 18. Progress Indicator

### 18.1 Loading Progress
1. Navigate to any page
2. **Expected**: Blue progress bar at top shows loading progress
3. **Expected**: Progress bar disappears when loading completes

---

## 19. Tabs (New Tab Feature)

### 19.1 Open New Tab
1. Open menu (⋮) → Click **New Tab**
2. **Expected**: Creates new tab, shows new tab page with quick links

---

## 20. Clear Browsing Data

### 20.1 Clear All Data
1. Open menu (⋮) → Click **Clear Data**
2. Confirm in dialog
3. **Expected**: 
   - Browsing history cleared
   - Cookies cleared
   - Cache cleared
   - Snackbar confirms "Browsing data cleared"

---

## 21. Browser Settings

### 21.1 Access Browser Settings
1. Go to Settings → scroll to "Browser" section
2. **Expected**: See browser data management options

### 21.2 Clear History from Settings
1. In Settings → Browser, tap "Clear History"
2. Confirm in dialog
3. **Expected**: History cleared, snackbar confirms

### 21.3 Clear Bookmarks from Settings
1. In Settings → Browser, tap "Clear Bookmarks"
2. Confirm in dialog
3. **Expected**: All bookmarks deleted

### 21.4 Close All Tabs from Settings
1. In Settings → Browser, tap "Close All Tabs"
2. Confirm in dialog
3. **Expected**: All tabs closed (leaves one new tab)

### 21.5 Clear Cache & Cookies from Settings
1. In Settings → Browser, tap "Clear Cache & Cookies"
2. Confirm in dialog
3. **Expected**: Browser cache and cookies cleared

### 21.6 Clear All Browser Data
1. In Settings → Browser, tap "Clear All Browser Data"
2. Confirm in dialog (warning about irreversible action)
3. **Expected**: All browser data cleared including history, bookmarks, tabs, cache

---

## Test URLs for Reference

| Purpose | URL |
|---------|-----|
| HTTPS Test | `https://www.google.com` |
| HTTP Test | `http://example.com` |
| Camera Test | `https://webcamtests.com` |
| Microphone Test | `https://www.onlinemictest.com` |
| Location Test | `https://www.google.com/maps` |
| Console Logs | `https://developer.mozilla.org/en-US/docs/Web/API/console` |
| Long Page (Find) | `https://en.wikipedia.org/wiki/Flutter_(software)` |
| Download Test | `https://www.sample-videos.com/` |
| JavaScript Test | Any page, then use console |

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| Page not loading | Check internet connection, try reload |
| Find not highlighting | Ensure search text exists on page (mobile only) |
| Console empty | Not all pages have console output |
| Dark mode looks wrong | Some pages resist CSS injection |
| Share not working | Fallback copies to clipboard |
| Bookmarks not saving | Check app permissions |
| Tabs not showing | Tab bar is at the very top |
| Desktop mode not working | Some sites detect by other means |

---

## Notes

- All keyboard shortcuts are desktop-only (Windows/macOS/Linux)
- Android back button handling is Android-only
- Some features may behave differently based on the website's security policies
- WebView2 is used on Windows, native WebView on Android
- Find in page is not supported on Windows desktop (WebView2 limitation)
- Camera, microphone, and location permissions require granting native OS permissions first
