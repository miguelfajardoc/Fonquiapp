// Loads the Google Maps JavaScript API once per page session and resolves with
// the `google.maps` namespace. Turbo navigations reuse the same promise, so the
// script tag is never injected twice.
let loading = null

export const AUTH_FAILURE_EVENT = "google-maps:auth-failure"

// Google calls this global when it rejects the key (e.g. a referrer the key is
// not restricted to); maps then render greyed out, so let the page say so.
window.gm_authFailure = () => window.dispatchEvent(new CustomEvent(AUTH_FAILURE_EVENT))

export function loadGoogleMaps(apiKey) {
  if (window.google?.maps?.importLibrary) return Promise.resolve(window.google.maps)
  if (loading) return loading

  loading = new Promise((resolve, reject) => {
    const callbackName = "__googleMapsLoaded"
    window[callbackName] = () => {
      delete window[callbackName]
      resolve(window.google.maps)
    }

    const params = new URLSearchParams({
      key: apiKey, v: "weekly", loading: "async", language: "es", region: "CO", callback: callbackName
    })
    const script = document.createElement("script")
    script.src = `https://maps.googleapis.com/maps/api/js?${params}`
    script.async = true
    script.onerror = () => {
      loading = null
      script.remove()
      reject(new Error("Google Maps failed to load"))
    }
    document.head.appendChild(script)
  })

  return loading
}
