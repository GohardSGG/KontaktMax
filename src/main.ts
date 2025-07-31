import { WebviewWindow } from '@tauri-apps/api/webviewWindow';

window.addEventListener('DOMContentLoaded', () => {
  const closeBtn = document.getElementById('close-btn');
  if (closeBtn) {
    closeBtn.addEventListener('click', () => {
      const window = WebviewWindow.getCurrent();
      window.hide(); // <--- Corrected to hide()
    });
  }

  const settingsBtn = document.getElementById('settings-btn');
  if (settingsBtn) {
    settingsBtn.addEventListener('click', () => {
      // Placeholder for settings functionality
      console.log('Settings button clicked');
    });
  }
});
