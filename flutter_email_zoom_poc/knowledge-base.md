# Knowledge Base

## Recurring Pitfalls

- Do not gate the email-detail loader only on `InAppWebView.onLoadStop`. On iOS/WKWebView, local HTML can become visible before that callback is reported, so use `onPageCommitVisible` or progress callbacks as the UI-ready signal.
- Do not rely on JavaScript height measurement for the email body. JavaScript is intentionally disabled for email rendering, so the mobile layout should let the WebView own the available scrolling area instead of trying to auto-size it from Flutter.
- Do not inject a full sanitized HTML document inside another HTML template. Extract renderable body markup, otherwise WKWebView can end up showing a blank message body.
- The per-message pinch scale has to be wired into the rendered font size. Storing `onZoomScaleChanged` alone is not enough; the WebView must re-render with that scale and reset native page zoom, otherwise iOS only performs a visual page magnification.
- On iOS, a working pinch reflow needs `minimumZoomScale` below `1.0` and a ratio-based update (`newScale / oldScale`) into `pageZoom`. If the implementation only multiplies from a fixed base after resetting the native zoom, dezoom quickly stops working.
- On Android, use `textZoom` as the live reflow knob and keep the HTML body font at the base size. If both CSS font-size and `textZoom` apply the same zoom factor, the content double-scales and the pinch behavior becomes inconsistent.
- Physical iPhone debug builds need `NSLocalNetworkUsageDescription` plus `NSBonjourServices` entries for `_dartVmService._tcp` and `_flutterobservatory._tcp`. Keep that in a debug-only plist so release builds do not advertise Flutter debug services.

## Decisions

- Treat this proof of concept as a mobile-first Flutter app, with iOS as the current UX reference.
