// This is the core logic for our window and tray, precisely adapted from OSC-Bridge.
use tauri::{AppHandle, Manager, State, WindowEvent};
use std::sync::Mutex;
use serde::{Deserialize, Serialize};
use auto_launch::AutoLaunch;

// --- Data Structures ---

#[derive(Debug, Serialize, Deserialize, Clone)]
struct AppConfig {
    auto_start: bool,
    silent_start: bool,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            auto_start: false,
            silent_start: false,
        }
    }
}

struct AppState {
    app_config: Mutex<AppConfig>,
    auto_launch: Mutex<Option<AutoLaunch>>,
}

// --- Tauri Commands (callable from frontend) ---

#[tauri::command]
fn get_config(state: State<AppState>) -> Result<AppConfig, String> {
    let config = state.app_config.lock().map_err(|e| e.to_string())?;
    Ok(config.clone())
}

#[tauri::command]
fn set_auto_start(enabled: bool, state: State<AppState>) -> Result<(), String> {
    let mut config = state.app_config.lock().map_err(|e| e.to_string())?;
    config.auto_start = enabled;
    
    let args = if config.silent_start { vec!["--silent"] } else { vec![] };
    let app_path = &std::env::current_exe().map_err(|e| e.to_string())?.to_string_lossy().to_string();
    
    let auto_launcher = AutoLaunch::new("KontaktMax", app_path, &args);
    
    if enabled {
        auto_launcher.enable().map_err(|e| format!("Failed to enable auto-start: {}", e))?;
    } else {
        auto_launcher.disable().map_err(|e| format!("Failed to disable auto-start: {}", e))?;
    }
    
    let mut auto_launch_guard = state.auto_launch.lock().map_err(|e| e.to_string())?;
    *auto_launch_guard = Some(auto_launcher);
    
    Ok(())
}

#[tauri::command]
fn set_silent_start(enabled: bool, state: State<AppState>) -> Result<(), String> {
    let mut config = state.app_config.lock().map_err(|e| e.to_string())?;
    config.silent_start = enabled;
    
    if config.auto_start {
        let args = if enabled { vec!["--silent"] } else { vec![] };
        let app_path = &std::env::current_exe().map_err(|e| e.to_string())?.to_string_lossy().to_string();
        let new_auto_launch = AutoLaunch::new("KontaktMax", app_path, &args);
        new_auto_launch.enable().map_err(|e| format!("Failed to update auto-start config: {}", e))?;
        
        let mut auto_launch_guard = state.auto_launch.lock().map_err(|e| e.to_string())?;
        *auto_launch_guard = Some(new_auto_launch);
    }
    
    Ok(())
}

#[tauri::command]
fn save_config(app: AppHandle, state: State<AppState>) -> Result<(), String> {
    let config = state.app_config.lock().map_err(|e| e.to_string())?;
    let app_dir = app.path().app_config_dir().map_err(|e| e.to_string())?;
    std::fs::create_dir_all(&app_dir).map_err(|e| e.to_string())?;
    let config_path = app_dir.join("config.json");
    let config_json = serde_json::to_string_pretty(&*config).map_err(|e| e.to_string())?;
    std::fs::write(config_path, config_json).map_err(|e| e.to_string())?;
    Ok(())
}

// --- Utility Functions ---

fn load_app_config(app: &AppHandle) -> AppConfig {
    if let Ok(app_dir) = app.path().app_config_dir() {
        let config_path = app_dir.join("config.json");
        if config_path.exists() {
            if let Ok(content) = std::fs::read_to_string(config_path) {
                return serde_json::from_str::<AppConfig>(&content).unwrap_or_default();
            }
        }
    }
    AppConfig::default()
}

fn update_tray_menu(app: &AppHandle) {
    use tauri::menu::{Menu, MenuItem, PredefinedMenuItem};
    
    let app_state = app.state::<AppState>();
    let config = app_state.app_config.lock().unwrap();
    
    let auto_start_text = if config.auto_start { "✓ 开机自启" } else { "开机自启" };
    let silent_start_text = if config.silent_start { "✓ 静默启动" } else { "静默启动" };

    let quit_item = MenuItem::with_id(app, "quit", "退出", true, None::<&str>).unwrap();
    let show_item = MenuItem::with_id(app, "show", "显示/隐藏", true, None::<&str>).unwrap();
    let auto_start_item = MenuItem::with_id(app, "auto_start", auto_start_text, true, None::<&str>).unwrap();
    let silent_start_item = MenuItem::with_id(app, "silent_start", silent_start_text, true, None::<&str>).unwrap();
    let separator = PredefinedMenuItem::separator(app).unwrap();

    let menu = Menu::with_items(app, &[&show_item, &separator, &auto_start_item, &silent_start_item, &separator, &quit_item]).unwrap();
    if let Some(tray) = app.tray_by_id("main-tray") {
        let _ = tray.set_menu(Some(menu));
    }
}

// --- Main Application Entry Point ---

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    use tauri::{menu::{Menu, MenuItem}, tray::TrayIconBuilder};

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init()) // Keep essential plugins
        .setup(|app| {
            let window = app.get_webview_window("main").unwrap();
            
            // This is the FIX for the startup glitch.
            // The blur effect is disabled as per user request.
            // #[cfg(target_os = "windows")]
            // {
            //     use window_vibrancy::apply_blur;
            //     apply_blur(&window, Some((0, 0, 0, 0))).expect("Unsupported platform!");
            // }
            
            let app_config = load_app_config(&app.handle());
            let args = if app_config.silent_start { vec!["--silent"] } else { vec![] };
            let auto_launcher = AutoLaunch::new("KontaktMax", &std::env::current_exe().unwrap().to_string_lossy(), &args);
            
            app.manage(AppState {
                app_config: Mutex::new(app_config.clone()),
                auto_launch: Mutex::new(Some(auto_launcher)),
            });
            
            if app_config.silent_start || std::env::args().any(|arg| arg == "--silent") {
                window.hide().unwrap();
            }

            // --- Tray Icon & Menu ---
            let menu = Menu::new(app)?; // Create an empty menu to be populated later
            let _tray = TrayIconBuilder::with_id("main-tray")
                .icon(app.default_window_icon().unwrap().clone())
                .menu(&menu)
                .tooltip("KontaktMax")
                .on_menu_event(move |app, event| {
                    let app_state = app.state::<AppState>();
                    match event.id.as_ref() {
                        "quit" => app.exit(0),
                        "show" => {
                            if let Some(window) = app.get_webview_window("main") {
                                if window.is_visible().unwrap_or(false) { window.hide().unwrap(); } else { window.show().unwrap(); window.set_focus().unwrap(); }
                            }
                        }
                        "auto_start" | "silent_start" => {
                            let mut config = app_state.app_config.lock().unwrap();
                            if event.id.as_ref() == "auto_start" {
                                config.auto_start = !config.auto_start;
                                let _ = set_auto_start(config.auto_start, app_state.clone());
                            } else {
                                config.silent_start = !config.silent_start;
                                let _ = set_silent_start(config.silent_start, app_state.clone());
                            }
                            drop(config);
                            let _ = save_config(app.clone(), app_state.clone());
                            update_tray_menu(app);
                        }
                        _ => {}
                    }
                })
                .on_tray_icon_event(|tray, event| {
                    if let tauri::tray::TrayIconEvent::Click { button: tauri::tray::MouseButton::Left, .. } = event {
                        let app = tray.app_handle();
                        if let Some(window) = app.get_webview_window("main") {
                            if window.is_visible().unwrap_or(false) { window.hide().unwrap(); } else { window.show().unwrap(); window.set_focus().unwrap(); }
                        }
                    }
                })
                .build(app)?;
            
            update_tray_menu(&app.handle()); // Initial population of the menu
            // Finally, show the window to prevent the startup glitch
            window.show().unwrap();

            Ok(())
        })
        .on_window_event(|window, event| {
            if let WindowEvent::CloseRequested { api, .. } = event {
                window.hide().unwrap();
                api.prevent_close(); // This is the key
            }
        })
        .invoke_handler(tauri::generate_handler![
            get_config,
            set_auto_start,
            set_silent_start,
            save_config
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
