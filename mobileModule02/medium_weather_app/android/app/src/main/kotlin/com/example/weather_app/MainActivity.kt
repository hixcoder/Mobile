package com.example.weather_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Bundle
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "com.example.weather_app/geolocation"
    private val locationPermissionCode = 1001
    private var pendingResult: MethodChannel.Result? = null
    private var locationManager: LocationManager? = null
    private var activeListener: LocationListener? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getCurrentLocation" -> getCurrentLocation(result)
                    else -> result.notImplemented()
                }
            }
    }

    private fun getCurrentLocation(result: MethodChannel.Result) {
        if (!isLocationEnabled()) {
            result.success(mapOf("error" to "serviceDisabled"))
            return
        }

        when {
            hasLocationPermission() -> fetchLocation(result)
            else -> {
                pendingResult = result
                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(
                        Manifest.permission.ACCESS_FINE_LOCATION,
                        Manifest.permission.ACCESS_COARSE_LOCATION,
                    ),
                    locationPermissionCode,
                )
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != locationPermissionCode) {
            return
        }

        val result = pendingResult ?: return
        pendingResult = null

        if (grantResults.isNotEmpty() &&
            grantResults[0] == PackageManager.PERMISSION_GRANTED
        ) {
            fetchLocation(result)
            return
        }

        val error = if (
            !ActivityCompat.shouldShowRequestPermissionRationale(
                this,
                Manifest.permission.ACCESS_FINE_LOCATION,
            )
        ) {
            "permissionDeniedForever"
        } else {
            "permissionDenied"
        }
        result.success(mapOf("error" to error))
    }

    private fun hasLocationPermission(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION,
        ) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION,
            ) == PackageManager.PERMISSION_GRANTED
    }

    private fun isLocationEnabled(): Boolean {
        val manager = locationManager ?: return false
        return manager.isProviderEnabled(LocationManager.GPS_PROVIDER) ||
            manager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
    }

    @Suppress("MissingPermission")
    private fun fetchLocation(result: MethodChannel.Result) {
        val manager = locationManager
        if (manager == null) {
            result.success(mapOf("error" to "serviceDisabled"))
            return
        }

        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
        )

        var bestLocation: Location? = null
        for (provider in providers) {
            if (!manager.isProviderEnabled(provider)) {
                continue
            }

            val location = manager.getLastKnownLocation(provider)
            if (location != null &&
                (bestLocation == null || location.time > bestLocation.time)
            ) {
                bestLocation = location
            }
        }

        if (bestLocation != null) {
            result.success(
                mapOf(
                    "latitude" to bestLocation.latitude,
                    "longitude" to bestLocation.longitude,
                ),
            )
            return
        }

        val provider = providers.firstOrNull { manager.isProviderEnabled(it) }
        if (provider == null) {
            result.success(mapOf("error" to "serviceDisabled"))
            return
        }

        activeListener?.let { manager.removeUpdates(it) }

        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                manager.removeUpdates(this)
                activeListener = null
                result.success(
                    mapOf(
                        "latitude" to location.latitude,
                        "longitude" to location.longitude,
                    ),
                )
            }

            @Deprecated("Deprecated in Java")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {
            }

            override fun onProviderEnabled(provider: String) {
            }

            override fun onProviderDisabled(provider: String) {
                manager.removeUpdates(this)
                activeListener = null
                result.success(mapOf("error" to "serviceDisabled"))
            }
        }

        activeListener = listener
        manager.requestSingleUpdate(provider, listener, Looper.getMainLooper())
    }

    override fun onDestroy() {
        activeListener?.let { listener ->
            locationManager?.removeUpdates(listener)
        }
        activeListener = null
        super.onDestroy()
    }
}
