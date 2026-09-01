package com.example.keepinventory

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.annotation.NonNull
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.example.keepinventory/database"
    private var pendingResult: MethodChannel.Result? = null
    
    private val PICK_FILE_REQUEST_CODE = 1001
    private val SAVE_FILE_REQUEST_CODE = 1002
    private var sourceFileToSave: String? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            pendingResult = result
            when (call.method) {
                "restoreDatabase" -> {
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                    }
                    startActivityForResult(intent, PICK_FILE_REQUEST_CODE)
                }
                "saveDatabase" -> {
                    sourceFileToSave = call.argument<String>("sourcePath")
                    val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
                    val defaultName = "keep_inventory_$timestamp.db"

                    val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        putExtra(Intent.EXTRA_TITLE, defaultName)
                    }
                    startActivityForResult(intent, SAVE_FILE_REQUEST_CODE)
                }
                "shareDatabase" -> {
                    val sourcePath = call.argument<String>("sourcePath")
                    if (sourcePath != null) {
                        shareFile(sourcePath)
                        result.success(true)
                    } else {
                        result.success(false)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun shareFile(filePath: String) {
        try {
            val file = File(filePath)
            val uri = FileProvider.getUriForFile(
                context,
                "${context.packageName}.fileprovider",
                file
            )

            val intent = Intent(Intent.ACTION_SEND).apply {
                type = "application/octet-stream"
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }

            val chooser = Intent.createChooser(intent, "Compartir base de datos")
            chooser.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(chooser)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        
        if (resultCode == Activity.RESULT_OK && data != null) {
            val uri: Uri? = data.data
            when (requestCode) {
               PICK_FILE_REQUEST_CODE -> { // Restaurar
                    if (uri != null) {
                        try {
                            val databasesPath = getDatabasePath("keepinventory.db").absolutePath
                            val dbFile = File(databasesPath)
                            val walFile = File("$databasesPath-wal")
                            val shmFile = File("$databasesPath-shm")

                            if (dbFile.exists()) dbFile.delete()
                            if (walFile.exists()) walFile.delete()
                            if (shmFile.exists()) shmFile.delete()

                            dbFile.parentFile?.mkdirs()

                            contentResolver.openInputStream(uri)?.use { inputStream ->
                                FileOutputStream(dbFile).use { outputStream ->
                                    inputStream.copyTo(outputStream)
                                }
                            }

                            pendingResult?.success(true)
                        } catch (e: Exception) {
                            pendingResult?.success(false)
                        }
                    } else {
                        pendingResult?.success(false)
                    }
                }
                SAVE_FILE_REQUEST_CODE -> { // Guardar / Exportar
                    val sourcePath = sourceFileToSave
                    if (uri != null && sourcePath != null) {
                        try {
                            val sourceFile = File(sourcePath)
                            contentResolver.openOutputStream(uri)?.use { outputStream ->
                                FileInputStream(sourceFile).use { inputStream ->
                                    inputStream.copyTo(outputStream)
                                }
                            }
                            pendingResult?.success(true)
                        } catch (e: Exception) {
                            pendingResult?.success(false)
                        }
                    } else {
                        pendingResult?.success(false)
                    }
                }
            }
        } else {
            pendingResult?.success(false)
        }
    }
}