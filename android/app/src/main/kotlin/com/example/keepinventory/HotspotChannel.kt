package com.example.keepinventory

import android.Manifest
import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.LocationManager
import android.net.ConnectivityManager
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.SoftApConfiguration
import android.net.wifi.WifiManager
import android.net.wifi.WifiNetworkSpecifier
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.Settings
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicBoolean

/**
 * Sincronización sin Wi‑Fi compartido.
 *
 * Emisor: crea un punto de acceso local temporal (LocalOnlyHotspot, Android 8+)
 * y devuelve su nombre/contraseña para ponerlos en el QR.
 * Receptor: se conecta a esa red (WifiNetworkSpecifier, Android 10+) y enlaza
 * el proceso a ella para que las descargas vayan por ahí y no por datos móviles.
 *
 * Errores devueltos a Dart (code): permission_denied, location_off,
 * incompatible_mode, unsupported, failed, unavailable, busy.
 */
class HotspotChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    companion object {
        const val CHANNEL = "com.example.keepinventory/hotspot"
        const val PERMISSION_REQUEST_CODE = 4711
        private const val CONNECT_TIMEOUT_MS = 60_000
    }

    private val channel = MethodChannel(messenger, CHANNEL).also {
        it.setMethodCallHandler(this)
    }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val wifiManager =
        activity.applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
    private val connectivityManager =
        activity.getSystemService(Context.CONNECTIVITY_SERVICE) as ConnectivityManager

    private var reservation: WifiManager.LocalOnlyHotspotReservation? = null
    private var pendingStart: MethodChannel.Result? = null
    private var networkCallback: ConnectivityManager.NetworkCallback? = null

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "startHotspot" -> startHotspot(result)
            "stopHotspot" -> {
                stopHotspot()
                result.success(null)
            }
            "connect" -> connect(
                call.argument<String>("ssid") ?: "",
                call.argument<String>("password"),
                call.argument<String>("security") ?: "wpa2",
                result,
            )
            "disconnect" -> {
                disconnect()
                result.success(null)
            }
            "deviceName" -> result.success(deviceName())
            "canConnectAutomatically" ->
                result.success(Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            "openLocationSettings" -> {
                activity.startActivity(Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS))
                result.success(null)
            }
            else -> result.notImplemented()
        }
    }

    /** "Xiaomi Redmi Note 12" (para que el emisor sepa quién pide los datos). */
    private fun deviceName(): String {
        val manufacturer = Build.MANUFACTURER.replaceFirstChar { it.uppercase() }
        val model = Build.MODEL
        return if (model.startsWith(Build.MANUFACTURER, ignoreCase = true)) {
            model.replaceFirstChar { it.uppercase() }
        } else {
            "$manufacturer $model"
        }
    }

    // ---------------------------------------------------------------- Emisor

    private fun requiredPermissions(): Array<String> =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(Manifest.permission.NEARBY_WIFI_DEVICES)
        } else {
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
        }

    private fun hasPermissions(): Boolean = requiredPermissions().all {
        ContextCompat.checkSelfPermission(activity, it) == PackageManager.PERMISSION_GRANTED
    }

    private fun startHotspot(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            result.error("unsupported", "LocalOnlyHotspot requires Android 8", null)
            return
        }
        if (pendingStart != null) {
            result.error("busy", "Hotspot start already in progress", null)
            return
        }
        if (hasPermissions()) {
            doStartHotspot(result)
        } else {
            pendingStart = result
            ActivityCompat.requestPermissions(
                activity, requiredPermissions(), PERMISSION_REQUEST_CODE
            )
        }
    }

    /** Llamado desde MainActivity.onRequestPermissionsResult. */
    fun onPermissionsResult(requestCode: Int, grantResults: IntArray): Boolean {
        if (requestCode != PERMISSION_REQUEST_CODE) return false
        val result = pendingStart ?: return true
        pendingStart = null
        if (grantResults.isNotEmpty() &&
            grantResults.all { it == PackageManager.PERMISSION_GRANTED }
        ) {
            doStartHotspot(result)
        } else {
            result.error("permission_denied", "Permission denied", null)
        }
        return true
    }

    private fun isLocationEnabled(): Boolean {
        val lm = activity.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            lm.isLocationEnabled
        } else {
            @Suppress("DEPRECATION")
            lm.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
                lm.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        }
    }

    @Suppress("MissingPermission")
    private fun doStartHotspot(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        // Hasta Android 12 el sistema exige la ubicación activada
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU && !isLocationEnabled()) {
            result.error("location_off", "Location services are off", null)
            return
        }
        stopHotspot()
        val replied = AtomicBoolean(false)
        try {
            wifiManager.startLocalOnlyHotspot(object : WifiManager.LocalOnlyHotspotCallback() {
                override fun onStarted(res: WifiManager.LocalOnlyHotspotReservation) {
                    reservation = res
                    val info = readHotspotInfo(res)
                    if (replied.compareAndSet(false, true)) {
                        if (info == null) {
                            result.error("failed", "Could not read hotspot config", null)
                        } else {
                            result.success(info)
                        }
                    }
                }

                override fun onFailed(reason: Int) {
                    if (!replied.compareAndSet(false, true)) return
                    val code = when (reason) {
                        ERROR_INCOMPATIBLE_MODE -> "incompatible_mode"
                        ERROR_TETHERING_DISALLOWED -> "unsupported"
                        else -> "failed"
                    }
                    result.error(code, "Hotspot failed: $reason", null)
                }

                override fun onStopped() {
                    reservation = null
                }
            }, mainHandler)
        } catch (e: SecurityException) {
            if (replied.compareAndSet(false, true)) {
                result.error("permission_denied", e.message, null)
            }
        } catch (e: IllegalStateException) {
            // Lanzado si ya hay un punto de acceso de la app activo
            if (replied.compareAndSet(false, true)) {
                result.error("incompatible_mode", e.message, null)
            }
        }
    }

    private fun readHotspotInfo(res: WifiManager.LocalOnlyHotspotReservation): Map<String, String>? {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            val config = res.softApConfiguration
            val ssid = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                config.wifiSsid?.toString()?.removeSurrounding("\"")
            } else {
                @Suppress("DEPRECATION")
                config.ssid
            } ?: return null
            val security = when (config.securityType) {
                SoftApConfiguration.SECURITY_TYPE_OPEN -> "open"
                SoftApConfiguration.SECURITY_TYPE_WPA3_SAE -> "wpa3"
                else -> "wpa2" // WPA2 y modo de transición WPA2/WPA3
            }
            return mapOf(
                "ssid" to ssid,
                "password" to (config.passphrase ?: ""),
                "security" to security,
            )
        }
        @Suppress("DEPRECATION")
        val config = res.wifiConfiguration ?: return null
        @Suppress("DEPRECATION")
        return mapOf(
            "ssid" to (config.SSID?.removeSurrounding("\"") ?: return null),
            "password" to (config.preSharedKey?.removeSurrounding("\"") ?: ""),
            "security" to "wpa2",
        )
    }

    fun stopHotspot() {
        reservation?.close()
        reservation = null
    }

    // -------------------------------------------------------------- Receptor

    private fun connect(
        ssid: String,
        password: String?,
        security: String,
        result: MethodChannel.Result,
    ) {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) {
            result.error("unsupported", "Automatic connection requires Android 10", null)
            return
        }
        disconnect()

        val specifier = WifiNetworkSpecifier.Builder().setSsid(ssid).apply {
            if (!password.isNullOrEmpty()) {
                when (security) {
                    "wpa3" -> setWpa3Passphrase(password)
                    "open" -> {}
                    else -> setWpa2Passphrase(password)
                }
            }
        }.build()

        val request = NetworkRequest.Builder()
            .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
            .removeCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .setNetworkSpecifier(specifier)
            .build()

        val replied = AtomicBoolean(false)
        val callback = object : ConnectivityManager.NetworkCallback() {
            override fun onAvailable(network: Network) {
                // Todo el tráfico de la app irá por esta red hasta disconnect()
                connectivityManager.bindProcessToNetwork(network)
                val gateway = findGateway(network)
                if (replied.compareAndSet(false, true)) {
                    mainHandler.post { result.success(mapOf("gateway" to gateway)) }
                }
            }

            override fun onUnavailable() {
                if (replied.compareAndSet(false, true)) {
                    mainHandler.post { result.error("unavailable", "Network unavailable", null) }
                }
            }
        }
        networkCallback = callback
        connectivityManager.requestNetwork(request, callback, CONNECT_TIMEOUT_MS)
    }

    private fun findGateway(network: Network): String? {
        val lp = connectivityManager.getLinkProperties(network) ?: return null
        lp.routes.firstOrNull { it.isDefaultRoute && it.gateway != null }
            ?.gateway?.hostAddress?.let { return it }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            lp.dhcpServerAddress?.hostAddress?.let { return it }
        }
        return null
    }

    fun disconnect() {
        connectivityManager.bindProcessToNetwork(null)
        networkCallback?.let {
            try {
                connectivityManager.unregisterNetworkCallback(it)
            } catch (_: IllegalArgumentException) {
            }
        }
        networkCallback = null
    }

    /** Liberar todo al cerrar la actividad. */
    fun dispose() {
        stopHotspot()
        disconnect()
        channel.setMethodCallHandler(null)
    }
}
