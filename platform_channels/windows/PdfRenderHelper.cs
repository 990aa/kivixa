using System;
using System.Drawing;
using System.IO;
using PdfiumViewer; // Requires PdfiumViewer NuGet package

namespace Kivixa.PlatformChannels {
    public static class PdfRenderHelper {
        public static Bitmap RenderPage(string pdfPath, int pageIndex) {
            try {
                using (var document = PdfDocument.Load(pdfPath)) {
                    return document.Render(pageIndex, 300, 300, true);
                }
            } catch (Exception) {
                return null; // Fallback: rendering failed
            }
        }
    }
}
