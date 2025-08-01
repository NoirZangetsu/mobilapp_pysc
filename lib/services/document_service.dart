import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import '../models/document.dart';

class DocumentService {
  // Extract text from PDF file (without saving)
  Future<String> extractTextFromPDFFile(File file) async {
    try {
      // Read PDF file
      final bytes = await file.readAsBytes();

      // Load PDF document
      final PdfDocument document = PdfDocument(inputBytes: bytes);
      final PdfTextExtractor extractor = PdfTextExtractor(document);
      final String text = extractor.extractText();
      document.dispose();

      return text;
    } catch (e) {
      throw Exception('PDF text extraction failed: $e');
    }
  }

  // Extract text from image file (OCR functionality)
  Future<String> extractTextFromImageFile(File file) async {
    try {
      // For now, return a placeholder message
      // In a real implementation, this would use OCR (Optical Character Recognition)
      // to extract text from images using services like Google Vision API or Tesseract
      
      final fileName = file.path.split('/').last;
      return 'Görüntü dosyası: $fileName\n\nBu görüntüdeki metinleri okumak için OCR (Optical Character Recognition) teknolojisi gereklidir. Bu özellik gelecekte eklenebilir.';
    } catch (e) {
      throw Exception('Image text extraction failed: $e');
    }
  }

  // Create a temporary document object for processing
  Document createTempDocument({
    required String fileName,
    required String content,
    required String userId,
  }) {
    final documentId = DateTime.now().millisecondsSinceEpoch.toString();
    
    return Document(
      id: documentId,
      userId: userId,
      fileName: fileName,
      fileUrl: '', // No file URL since we don't save
      uploadedAt: DateTime.now(),
      status: 'completed',
      content: content,
      fileSize: 0, // We don't track file size
    );
  }

  // Process PDF file and return document
  Future<Document?> processPDFFile(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      // Extract text from PDF
      final content = await extractTextFromPDFFile(file);
      
      // Create temporary document
      final document = createTempDocument(
        fileName: fileName,
        content: content,
        userId: userId,
      );

      return document;
    } catch (e) {
      print('PDF processing error: $e');
      return null;
    }
  }

  // Process image file and return document
  Future<Document?> processImageFile(String filePath, String userId) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      // Extract text from image (OCR functionality would be implemented here)
      final content = await extractTextFromImageFile(file);
      
      // Create temporary document
      final document = createTempDocument(
        fileName: fileName,
        content: content,
        userId: userId,
      );

      return document;
    } catch (e) {
      print('Image processing error: $e');
      return null;
    }
  }
} 