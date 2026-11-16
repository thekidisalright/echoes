package dev.alexandre.echoes

import android.content.Context
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.FileInputStream
import java.nio.ByteBuffer
import java.util.concurrent.Executors

/**
 * Operações SAF que precisam ser rápidas e que o docman faz de forma lenta:
 * - listTree: lista recursivamente uma árvore com UMA consulta por pasta.
 * - readRange: lê um trecho de um arquivo com seek real (sem ler o começo).
 */
class SafChannel(private val context: Context, messenger: BinaryMessenger) :
    MethodChannel.MethodCallHandler {

    private val channel = MethodChannel(messenger, "dev.alexandre.echoes/saf")
    private val executor = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    init {
        channel.setMethodCallHandler(this)
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "listTree" -> background(result) {
                listTree(Uri.parse(call.argument<String>("uri")!!))
            }

            "readRange" -> background(result) {
                readRange(
                    Uri.parse(call.argument<String>("uri")!!),
                    (call.argument<Number>("start")!!).toLong(),
                    call.argument<Int>("length")!!,
                )
            }

            else -> result.notImplemented()
        }
    }

    private fun background(result: MethodChannel.Result, block: () -> Any?) {
        executor.execute {
            try {
                val value = block()
                main.post { result.success(value) }
            } catch (e: SecurityException) {
                main.post { result.error("permission", e.message, null) }
            } catch (e: Exception) {
                main.post { result.error("io", e.message, e.javaClass.simpleName) }
            }
        }
    }

    private fun listTree(uri: Uri): List<Map<String, Any?>> {
        val rootId = if (DocumentsContract.isDocumentUri(context, uri)) {
            DocumentsContract.getDocumentId(uri)
        } else {
            DocumentsContract.getTreeDocumentId(uri)
        }
        val projection = arrayOf(
            Document.COLUMN_DOCUMENT_ID,
            Document.COLUMN_DISPLAY_NAME,
            Document.COLUMN_MIME_TYPE,
            Document.COLUMN_SIZE,
        )
        val out = mutableListOf<Map<String, Any?>>()
        val pending = ArrayDeque<Pair<String, String?>>() // (docId, parentUri)
        pending.add(rootId to null)
        while (pending.isNotEmpty()) {
            val (dirId, _) = pending.removeFirst()
            val dirUri = DocumentsContract.buildDocumentUriUsingTree(uri, dirId).toString()
            val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(uri, dirId)
            context.contentResolver.query(childrenUri, projection, null, null, null)?.use { c ->
                while (c.moveToNext()) {
                    val id = c.getString(0)
                    val mime = c.getString(2)
                    val isDir = mime == Document.MIME_TYPE_DIR
                    out.add(
                        mapOf(
                            "uri" to DocumentsContract.buildDocumentUriUsingTree(uri, id).toString(),
                            "parentUri" to dirUri,
                            "name" to c.getString(1),
                            "mimeType" to mime,
                            "size" to if (c.isNull(3)) 0L else c.getLong(3),
                            "isDirectory" to isDir,
                        )
                    )
                    if (isDir) pending.add(id to dirUri)
                }
            }
        }
        return out
    }

    private fun readRange(uri: Uri, start: Long, length: Int): ByteArray {
        val pfd = context.contentResolver.openFileDescriptor(uri, "r")
            ?: throw IllegalStateException("Não foi possível abrir $uri")
        pfd.use {
            FileInputStream(it.fileDescriptor).channel.use { ch ->
                val size = ch.size()
                if (start >= size) return ByteArray(0)
                val toRead = minOf(length.toLong(), size - start).toInt()
                val buffer = ByteBuffer.allocate(toRead)
                var pos = start
                while (buffer.hasRemaining()) {
                    val n = ch.read(buffer, pos)
                    if (n <= 0) break
                    pos += n
                }
                return buffer.array().copyOf(buffer.position())
            }
        }
    }
}
