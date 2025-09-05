!macro customUnInstall
  MessageBox MB_YESNO|MB_ICONQUESTION "Do you want to delete all app data? (Recommended)" IDYES deleteData IDNO keepData
  deleteData:
    Delete "$APPDATA\Kivixa\*.*"
    RMDir /r "$APPDATA\Kivixa"
    goto end
  keepData:
    ; Do nothing, keep user data
  end:
!macroend
