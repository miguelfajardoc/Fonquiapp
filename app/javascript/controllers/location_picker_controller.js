import { Controller } from "@hotwired/stimulus"
import { loadGoogleMaps, AUTH_FAILURE_EVENT } from "lib/google_maps_loader"

const BOGOTA = { lat: 4.711, lng: -74.0721 }
const DEFAULT_ZOOM = 12
const PIN_ZOOM = 16

// Lets the user place a client's location on a Google map, in both directions:
// "Ubicar en mapa" geocodes the typed address (Colombia only) and moves the pin
// there, keeping the typed text; clicking the map or dropping a dragged pin
// looks up that point's address and writes it into the address field.
// "Quitar ubicación" removes the pin. The pin writes the hidden
// latitude/longitude fields; when the address text is edited by hand after
// that, a hint asks to relocate so text and pin stay in step.
export default class extends Controller {
  static targets = ["map", "address", "latitude", "longitude", "status"]
  static values = { apiKey: String, mapId: String, autoLocate: Boolean, messages: Object }

  async connect() {
    this.onAuthFailure = () => this.showStatus(this.messagesValue.loadError)
    window.addEventListener(AUTH_FAILURE_EVENT, this.onAuthFailure)
    this.mapTarget.replaceChildren()
    this.syncedAddress = null
    this.lookup = 0

    try {
      const maps = await loadGoogleMaps(this.apiKeyValue)
      const [{ Map }, { AdvancedMarkerElement }, { Geocoder }] = await Promise.all([
        maps.importLibrary("maps"), maps.importLibrary("marker"), maps.importLibrary("geocoding")
      ])
      if (!this.element.isConnected) return

      this.AdvancedMarkerElement = AdvancedMarkerElement
      this.geocoder = new Geocoder()
      this.buildMap(Map)
      // A saved pin belongs to the address it was saved with.
      if (this.marker) this.syncedAddress = this.currentAddress()
    } catch {
      this.showStatus(this.messagesValue.loadError)
      return
    }

    if (this.autoLocateValue) this.locate()
  }

  disconnect() {
    window.removeEventListener(AUTH_FAILURE_EVENT, this.onAuthFailure)
    this.map = null
    this.marker = null
  }

  buildMap(Map) {
    const position = this.savedPosition()
    this.map = new Map(this.mapTarget, {
      center: position || BOGOTA,
      zoom: position ? PIN_ZOOM : DEFAULT_ZOOM,
      mapId: this.mapIdValue,
      streetViewControl: false,
      mapTypeControl: false
    })
    this.map.addListener("click", (event) => this.pinFromMap(event.latLng.toJSON()))
    if (position) this.setMarker(position)
  }

  // Address -> pin: the typed text is kept as written.
  async locate() {
    const address = this.currentAddress()
    if (!address || !this.geocoder) return this.showStatus(this.messagesValue.notFound)

    const lookup = ++this.lookup
    try {
      const { results } = await this.geocoder.geocode({
        address, region: "co", componentRestrictions: { country: "CO" }
      })
      if (lookup !== this.lookup) return
      if (!results.length) return this.showStatus(this.messagesValue.notFound)

      const position = results[0].geometry.location.toJSON()
      this.placePin(position)
      this.syncedAddress = address
      this.map.setCenter(position)
      this.map.setZoom(PIN_ZOOM)
      this.refreshStatus()
    } catch {
      if (lookup === this.lookup) this.showStatus(this.messagesValue.notFound)
    }
  }

  // Pin -> address: the point's address replaces whatever was typed.
  async pinFromMap(position) {
    this.placePin(position)

    const lookup = ++this.lookup
    try {
      const { results } = await this.geocoder.geocode({ location: position })
      if (lookup !== this.lookup) return
      if (!results.length) return this.showStatus(this.messagesValue.reverseNotFound)

      this.addressTarget.value = results[0].formatted_address
      this.syncedAddress = this.currentAddress()
      this.refreshStatus()
    } catch {
      if (lookup === this.lookup) this.showStatus(this.messagesValue.reverseNotFound)
    }
  }

  clear() {
    this.lookup++
    this.marker?.remove()
    this.marker = null
    this.syncedAddress = null
    this.writeFields(null)
    this.showStatus(null)
  }

  addressChanged() {
    this.refreshStatus()
  }

  placePin(position) {
    this.setMarker(position)
    this.writeFields(position)
  }

  setMarker(position) {
    if (this.marker) {
      this.marker.position = position
      return
    }

    this.marker = new this.AdvancedMarkerElement({ map: this.map, position, gmpDraggable: true })
    this.marker.addEventListener("gmp-dragend", () => this.pinFromMap(this.markerPosition()))
  }

  markerPosition() {
    const { lat, lng } = this.marker.position
    return typeof lat === "function" ? { lat: lat(), lng: lng() } : { lat, lng }
  }

  refreshStatus() {
    const outOfStep = this.marker && this.syncedAddress !== null && this.currentAddress() !== this.syncedAddress
    this.showStatus(outOfStep ? this.messagesValue.relocate : null)
  }

  currentAddress() {
    return this.addressTarget.value.trim()
  }

  savedPosition() {
    const lat = parseFloat(this.latitudeTarget.value)
    const lng = parseFloat(this.longitudeTarget.value)
    return Number.isFinite(lat) && Number.isFinite(lng) ? { lat, lng } : null
  }

  writeFields(position) {
    this.latitudeTarget.value = position ? position.lat.toFixed(6) : ""
    this.longitudeTarget.value = position ? position.lng.toFixed(6) : ""
  }

  showStatus(message) {
    this.statusTarget.textContent = message || ""
    this.statusTarget.classList.toggle("hidden", !message)
  }
}
