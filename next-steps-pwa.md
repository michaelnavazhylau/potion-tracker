# Next steps: installable Potion Puzzle PWA

The project already exports and runs as a single-threaded Godot web game from
`build/web/index.html`. The remaining work is to turn that web export into an
installable Progressive Web App (PWA), deploy it over HTTPS, and test it on real
iPhone and Android devices.

## Recommended path

1. Create square app icons at 144x144, 180x180, and 512x512 pixels. Use the
   potion artwork with an opaque background so it remains legible on a home
   screen.
2. In Godot, open **Project > Export > Web**, enable **Progressive Web App**, and
   assign all three icons. Keep the current single-threaded Web export.
3. Use **Standalone** display mode. Pick a fixed orientation only if the game is
   designed for it; otherwise allow the device orientation.
4. Optionally add a small offline page for cases where the game has never been
   loaded or its cached files have been removed.
5. Export a release build:

   ```sh
   godot --headless --path . --export-release Web build/web/index.html
   ```

6. Confirm the export includes a web app manifest and service worker, then
   deploy the complete `build/web` directory without renaming or omitting files.
7. Test the hosted HTTPS URL on Safari for iPhone and Chrome for Android. Also
   test a second launch in airplane mode after one successful online launch.

Godot's Web export documentation explains that enabling PWA support adds the
manifest and service worker used for installation and offline caching. It also
notes that production PWAs need a secure HTTPS context and that browser caches
can still be evicted: [Godot Web export and PWA documentation](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html).

The current `export_presets.cfg` intentionally leaves
`progressive_web_app/enabled=false` until the correctly sized icons are ready.

## How users install it

### iPhone or iPad

1. Open the deployed HTTPS URL in Safari.
2. Tap **Share**. If **Add to Home Screen** is not visible, tap **More** and add
   it to the available actions.
3. Tap **Add to Home Screen**.
4. Turn on **Open as Web App**, then tap **Add**.
5. Launch Potion Puzzle from its new Home Screen icon.

These steps follow Apple's current instructions: [Turn a website into an app on iPhone](https://support.apple.com/en-euro/guide/iphone/iphea86e5236/ios).

### Android

1. Open the deployed HTTPS URL in Chrome.
2. Tap the three-dot menu.
3. Tap **Add to home screen**, then **Install**.
4. Confirm the installation and launch Potion Puzzle from the new icon.

Chrome may also show an **Install** prompt automatically once the PWA meets its
installability requirements. See [Google Chrome's web app installation instructions](https://support.google.com/chrome/answer/9658361?co=GENIE.Platform%3DAndroid&hl=en).

## Hosting choices

| Provider | Free option | Fit for this project | Important notes |
| --- | --- | --- | --- |
| [GitHub Pages](https://docs.github.com/pages/getting-started-with-github-pages/github-pages-limits) | Yes, for public repositories on GitHub Free | **Recommended for automated, repo-native hosting.** A GitHub Actions workflow can export Godot and publish `build/web`. | Published sites have a 1 GB size limit and a soft 100 GB/month bandwidth limit. HTTPS is included. |
| [Netlify](https://www.netlify.com/pricing/) | Yes, with a monthly credit allowance | **Fastest first deployment.** Drag and drop `build/web`, or connect a Git workflow later. | The Free plan includes custom domains, SSL, and CDN delivery; a site can pause when its monthly credits are exhausted. |
| [Vercel](https://vercel.com/docs/plans/hobby) | Yes, for personal and non-commercial use | Good for Git-based deployments, previews, custom domains, and automatic HTTPS. | Hobby has usage limits and a 100 MB static-file upload limit, which accommodates the current 38 MB WASM file. Commercial use requires a suitable paid plan. See [Vercel limits](https://vercel.com/docs/limits). |
| [itch.io](https://itch.io/docs/creators/html5) | Yes | Excellent for game discovery and a playable browser page. Upload a ZIP with `index.html` at its root and mark it mobile-friendly. | The game runs in an iframe, so use a dedicated host above when the primary goal is a conventional installable PWA. itch.io is a useful secondary release channel. |
| [Cloudflare Pages](https://developers.cloudflare.com/pages/platform/limits/) | Yes | Not suitable for this build without changing its delivery strategy. | Free Pages permits 500 builds/month, but its 25 MiB maximum individual asset size is below the current `index.wasm` size of about 38 MB. |

### Suggested order

- Use **Netlify** to get the first mobile-test URL online with the fewest moving
  parts.
- Use **GitHub Pages** for the durable free deployment once a GitHub Actions
  export-and-publish workflow is added.
- Add **itch.io** as a separate discovery page after the direct PWA is working.
- Choose **Vercel Hobby** instead of Pages or Netlify when its preview-deployment
  workflow is useful and the project remains personal/non-commercial.

## Deployment automation to add

A future CI workflow should:

1. Check out the repository.
2. Install the matching Godot release and Web export templates.
3. Run the headless release-export command above.
4. Publish only `build/web` to the chosen host.
5. Fail if `index.html`, the `.pck`, JavaScript, WASM, manifest, or service worker
   is missing.

Do not commit generated `build/web` files to the normal source branch. They are
already ignored and should be generated by CI or uploaded as a deployment
artifact.

## Release checklist

- [ ] PWA export is enabled in `export_presets.cfg`.
- [ ] 144x144, 180x180, and 512x512 icons are configured.
- [ ] The game is served over HTTPS.
- [ ] The manifest opens without errors in browser developer tools.
- [ ] The service worker installs and controls the game page.
- [ ] The game loads, selects potions, pours, and corks correctly on touch.
- [ ] A second launch works offline after one complete online load.
- [ ] Installation works from Safari on a current iPhone/iPad.
- [ ] Installation works from Chrome on a current Android device.
- [ ] A redeployment updates an already installed copy after it is reopened.

An installed PWA is still a web app rather than an App Store or Play Store
binary. Store listing can be considered later with a wrapper or Android Trusted
Web Activity, but it is not required for users to install this version from the
browser.
