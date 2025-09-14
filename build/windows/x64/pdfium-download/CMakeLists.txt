# Distributed under the OSI-approved MIT License.  See accompanying
# file LICENSE or https://github.com/Crascit/DownloadProject for details.

cmake_minimum_required(VERSION 2.8.12)

project(pdfium-download NONE)

include(ExternalProject)
ExternalProject_Add(pdfium-download
                    URL;https://github.com/bblanchon/pdfium-binaries/releases/download/chromium/4690/pdfium-win-x64.tgz;DOWNLOAD_EXTRACT_TIMESTAMP;FALSE
                    SOURCE_DIR          "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/pdfium-src"
                    BINARY_DIR          "C:/Users/ahada/Documents/abdulahad/kivixa/build/windows/x64/pdfium-build"
                    CONFIGURE_COMMAND   ""
                    BUILD_COMMAND       ""
                    INSTALL_COMMAND     ""
                    TEST_COMMAND        ""
)
