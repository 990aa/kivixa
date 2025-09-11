using System;
using System.Runtime.InteropServices;
using System.Windows.Forms;

namespace Kivixa.PlatformChannels {
    public static class SplitScreenHelper {
        public static bool IsInSplitScreen() {
            // Fallback: Windows does not provide direct API, so check window size
            var screen = Screen.PrimaryScreen;
            var bounds = screen.WorkingArea;
            return bounds.Width < screen.Bounds.Width || bounds.Height < screen.Bounds.Height;
        }
    }
}
