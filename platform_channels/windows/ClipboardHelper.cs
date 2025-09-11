using System.Windows.Forms;

namespace Kivixa.PlatformChannels {
    public static class ClipboardHelper {
        public static void CopyToClipboard(string text) {
            Clipboard.SetText(text);
        }
        public static string GetFromClipboard() {
            return Clipboard.ContainsText() ? Clipboard.GetText() : null;
        }
    }
}
