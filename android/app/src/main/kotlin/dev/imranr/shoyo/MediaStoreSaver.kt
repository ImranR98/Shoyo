package dev.imranr.shoyo

import android.content.ContentValues
import android.content.Context
import android.os.Environment
import android.provider.MediaStore
import android.webkit.MimeTypeMap
import java.io.File
import java.io.FileInputStream

object MediaStoreSaver {
    private val DOWNLOADS_RELATIVE_PATH = "${Environment.DIRECTORY_DOWNLOADS}/"

    class SaveException(val code: String, message: String) : Exception(message)

    data class SaveResult(val displayName: String)

    fun getDownloadNames(context: Context): List<String> {
        val names = mutableListOf<String>()
        val projection = arrayOf(
            MediaStore.Downloads.DISPLAY_NAME,
            MediaStore.Downloads.RELATIVE_PATH,
        )
        context.contentResolver.query(
            MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            projection,
            null,
            null,
            null,
        )?.use { cursor ->
            val nameColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.DISPLAY_NAME)
            val pathColumn = cursor.getColumnIndexOrThrow(MediaStore.Downloads.RELATIVE_PATH)
            while (cursor.moveToNext()) {
                val relativePath = cursor.getString(pathColumn)
                if (relativePath == DOWNLOADS_RELATIVE_PATH ||
                    relativePath == Environment.DIRECTORY_DOWNLOADS
                ) {
                    cursor.getString(nameColumn)?.let { names.add(it) }
                }
            }
        }
        return names
    }

    /// Inserts a placeholder to find out whether [fileName] is already taken,
    /// then deletes it again. The placeholder is finalized before the name is
    /// read back because MediaProvider only reconciles DISPLAY_NAME with the
    /// uniquely generated file name during finalization.
    fun probeNameTaken(context: Context, fileName: String): Boolean {
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, "application/octet-stream")
            put(MediaStore.Downloads.RELATIVE_PATH, DOWNLOADS_RELATIVE_PATH)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val resolver = context.contentResolver
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values)
            ?: throw SaveException("IO_ERROR", "Could not check the destination name")
        return try {
            resolver.openOutputStream(uri)?.close()
            resolver.update(
                uri,
                ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
                null,
                null,
            )
            actualDisplayName(context, uri)?.let { it != fileName } ?: false
        } finally {
            resolver.delete(uri, null, null)
        }
    }

    fun saveFile(
        context: Context,
        sourcePath: String,
        fileName: String,
        allowProviderRename: Boolean,
    ): SaveResult {
        val source = File(sourcePath)
        if (!source.exists()) {
            throw SaveException("SOURCE_MISSING", "The shared file no longer exists")
        }
        val resolver = context.contentResolver
        val mimeType = MimeTypeMap.getSingleton()
            .getMimeTypeFromExtension(source.extension.lowercase())
            ?: "application/octet-stream"
        val values = ContentValues().apply {
            put(MediaStore.Downloads.DISPLAY_NAME, fileName)
            put(MediaStore.Downloads.MIME_TYPE, mimeType)
            put(MediaStore.Downloads.RELATIVE_PATH, DOWNLOADS_RELATIVE_PATH)
            put(MediaStore.Downloads.IS_PENDING, 1)
        }
        val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
        val uri = resolver.insert(collection, values)
            ?: throw SaveException("IO_ERROR", "Could not create the destination file")
        try {
            val output = resolver.openOutputStream(uri)
                ?: throw SaveException("IO_ERROR", "Could not open the destination file")
            output.use { out ->
                FileInputStream(source).use { input -> input.copyTo(out) }
            }
            resolver.update(
                uri,
                ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
                null,
                null,
            )
        } catch (e: Exception) {
            resolver.delete(uri, null, null)
            throw if (e is SaveException) e else SaveException("IO_ERROR", e.message ?: "Failed to save file")
        }
        val actualName = actualDisplayName(context, uri) ?: fileName
        if (!allowProviderRename && actualName != fileName) {
            resolver.delete(uri, null, null)
            throw SaveException("CONFLICT", "A file with this name already exists")
        }
        return SaveResult(actualName)
    }

    private fun actualDisplayName(context: Context, uri: android.net.Uri): String? {
        context.contentResolver.query(
            uri,
            arrayOf(MediaStore.Downloads.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                return cursor.getString(0)
            }
        }
        return null
    }
}
