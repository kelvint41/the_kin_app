THE KIN APP — Brand & Store Asset Kit
=====================================
Generated from: kin_logo_master_transparent.png
Palette: navy #0A101E / charcoal #1A1A1A / gold #D4AF37 / vine green
Tagline: "Stronger Together"

01_master/            Trimmed transparent logo (source of truth)
02_flutterflow/       App launcher icon + Android mipmaps + in-app logos (dark/light, 1x/2x/3x)
03_social_profile/    Square profile pics per platform (circle-safe margins)
04_social_banners/    Wide cover/banner images per platform
05_store_icons/       iOS 1024 (NO alpha) + Google Play 512 (32-bit)
06_play_feature_graphic/  REQUIRED Google Play feature graphic 1024x500 (2 variants)
07_ios_screenshots/   Branded App Store screenshot templates (with slot)
08_play_screenshots/  Branded Google Play screenshot templates (with slot)

------------------------------------------------------------------
STORE UPLOAD CHECKLIST
------------------------------------------------------------------
APPLE APP STORE (App Store Connect):
  [ ] App icon:        05_store_icons/ios_app_store_icon_1024.png   (1024x1024, no alpha, no rounded corners)
  [ ] iPhone shots:    07_ios_screenshots/ios_6.7in_*  (required tier; 6.9in also accepted)
  [ ] iPad shots:      07_ios_screenshots/ipad_13in_*  (ONLY if app supports iPad)
  Min 1 screenshot per required device size; up to 10.

GOOGLE PLAY (Play Console):
  [ ] App icon:        05_store_icons/google_play_icon_512.png      (512x512, 32-bit PNG)
  [ ] Feature graphic: 06_play_feature_graphic/play_feature_graphic_1024x500.png   (REQUIRED)
  [ ] Phone shots:     08_play_screenshots/play_phone_*  (min 2, up to 8)
  [ ] Tablet shots:    08_play_screenshots/play_*_tablet_*  (optional)

------------------------------------------------------------------
HOW TO USE THE SCREENSHOT TEMPLATES
------------------------------------------------------------------
1. Capture your real app screens (FlutterFlow Run mode, iOS Simulator,
   or Android emulator). Aim to match the slot aspect (~9:19.5 for phones).
2. Open a template in Canva / Figma / Preview / Photoshop.
3. Paste your capture and scale it to fill the gold-outlined "slot".
   The on-canvas label shows the exact slot pixel size for each file.
4. Delete the placeholder hint text + slot border, then export as PNG/JPG
   at the SAME canvas dimensions (do not resize the canvas).
5. The headline + footer stay — they're part of the marketing frame.

Tip: keep the 4 headlines in order (find / the exchange / shop / stronger)
for a clean narrative across the store listing.

Regenerate anytime: ../.logo_venv/bin/python ../generate_*.py
