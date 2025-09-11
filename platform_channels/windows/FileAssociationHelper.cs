using System;
using System.Diagnostics;
using System.IO;

namespace Kivixa.PlatformChannels {
    public static class FileAssociationHelper {
        public static void OpenFile(string filePath) {
            try {
                Process.Start(new ProcessStartInfo(filePath) { UseShellExecute = true });
            } catch (Exception) {
                // Fallback: show error or use default handler
            }
        }
    }
}
