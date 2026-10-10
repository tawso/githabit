# 🚀 GitHabit - Google Play Store Release Guide

This guide details everything required to build, test, and publish **GitHabit** to the Google Play Store.

---

## 1. App Identity & Store Metadata

* **App Name:** `GitHabit - Code & Habit Tracker`
* **Short Description (80 chars max):**
  > Build unstoppable developer momentum. GitHub streaks, habits & code heatmaps.
* **Full Description:**
  > **GitHabit** is the ultimate developer habit tracker and momentum engine designed specifically for software engineers, students, and open-source contributors.
  >
  > 🌟 **Key Features:**
  > • **Automated GitHub & LeetCode Sync:** Connect your profile to track daily commits, problem-solving streaks, and contributions on a responsive Bento heat map.
  > • **Zero-Effort Auto-Checkin:** GitHabit automatically detects your code commits and marks your coding habits completed.
  > • **Smart Streak Shield (Auto-Freeze):** Life happens. Smart auto-freeze preserves your hard-earned streak before it resets.
  > • **Deep Work Pomodoro Timer:** Integrated focus sessions with custom intervals and live progress ring.
  > • **WakaTime Coding Pulse:** Monitor real coding hours and language breakdowns directly on your dashboard.
  > • **Tactile Liquid-Glass Dark Theme:** Built with premium Obsidian and Liquid Sunset dark modes inspired by top developer tools.
  > • **100% Privacy-First:** Your data belongs to you. Stored locally on device with zero ad networks or tracking.

---

## 2. Categorization & Target Audience

* **Category:** Productivity / Tools
* **Tags / Keywords:** `github`, `developer`, `habit tracker`, `productivity`, `code`, `commit`, `leetcode`, `wakatime`, `pomodoro`, `streak`
* **Content Rating:** Everyone (PEGI 3 / ESRB Everyone)
* **Target Audience:** Age 13+ (Students, Software Engineers, Tech Enthusiasts)

---

## 3. Required Google Play Store Assets

| Asset | Size | Notes |
| :--- | :--- | :--- |
| **App Icon** | 512 x 512 px PNG (32-bit) | Use `assets/logo/app_icon.jpg` |
| **Feature Graphic** | 1024 x 500 px PNG / JPG | Dark cyberpunk/obsidian banner with GitHabit logo |
| **Screenshots** | Min 2, max 8 (1080 x 1920 or 1080 x 2400) | Dashboard, Bento Grid, Day Streak Sheet, Dev Profile |

---

## 4. Building the Production Release Artifacts

### Option A: Build Android App Bundle (.aab) — *Required by Google Play*
```bash
flutter build appbundle --release
```
* Output path: `build/app/outputs/bundle/release/app-release.aab`
* Upload this file to **Google Play Console -> Production / Closed Testing**.

### Option B: Build Release APK (.apk) — *For direct testing on physical device*
```bash
flutter build apk --release
```
* Output path: `build/app/outputs/flutter-apk/app-release.apk`
* Transfer to your Android phone to test the exact production release build.

---

## 5. Keystore Credentials (Configured & Protected)

* Keystore location: `android/app/upload-keystore.jks`
* Configuration file: `android/key.properties` (added to `.gitignore` for security)
* Alias: `githabit`
* Key validity: 10,000 days

