// This is the core logic for our window and tray.
use tauri::{AppHandle, Manager, State, WindowEvent};
use std::sync::Mutex;
use serde::{Deserialize, Serialize};
use auto_launch::AutoLaunch;
use winreg::enums::*;
use winreg::RegKey;
use std::collections::HashSet;
use once_cell::sync::Lazy;

// --- Blacklist Definition & Loader ---

#[derive(serde::Deserialize)]
struct Blacklist {
    key_names: Vec<String>,
    value_names: Vec<String>,
}

static BLACKLIST: Lazy<Blacklist> = Lazy::new(|| {
    let blacklist_str = include_str!("../blacklist.json");
    serde_json::from_str(blacklist_str).expect("Failed to parse blacklist.json")
});

// --- Data Structures ---

#[derive(Debug, Serialize, Deserialize, Clone)]
struct AppConfig {
    auto_start: bool,
    silent_start: bool,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self { auto_start: false, silent_start: false }
    }
}

#[derive(serde::Serialize)]
struct LibraryInfo {
    name: String,
    library_type: String, 
    registration_status: String,
}

#[derive(serde::Serialize, Default)]
struct LibraryDetails {
    name: String,
    paths: Vec<String>,
}

#[derive(serde::Serialize)]
struct LibraryQueryResult {
    libraries: Vec<LibraryInfo>,
    total_count: usize,
    standard_count: usize,
    custom_count: usize,
}

struct AppState {
    app_config: Mutex<AppConfig>,
    auto_launch: Mutex<Option<AutoLaunch>>,
}

// --- Tauri Commands ---

#[tauri::command]
fn get_library_details(name: String) -> Result<LibraryDetails, String> {
    let mut details = LibraryDetails { name: name.clone(), ..Default::default() };
    let hklm = RegKey::predef(HKEY_LOCAL_MACHINE);
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);

    let paths_to_check = [
        ("HKLM\\SOFTWARE\\WOW6432Node\\Native Instruments", hklm.open_subkey("SOFTWARE\\WOW6432Node\\Native Instruments").ok()),
        ("HKLM\\SOFTWARE\\Native Instruments", hklm.open_subkey("SOFTWARE\\Native Instruments").ok()),
        ("HKCU\\SOFTWARE\\Native Instruments", hkcu.open_subkey("SOFTWARE\\Native Instruments").ok()),
    ];

    for (path_prefix, key_option) in paths_to_check.iter() {
        if let Some(key) = key_option {
            if key.open_subkey(&name).is_ok() {
                details.paths.push(format!("{}\\{}", path_prefix, name));
            }
        }
    }
    
    Ok(details)
}

#[tauri::command]
fn get_installed_libraries() -> Result<LibraryQueryResult, String> {
    let mut libraries = Vec::new();
    let mut standard_count = 0;
    let mut custom_count = 0;
    let mut library_names = HashSet::new();

    let hklm = RegKey::predef(HKEY_LOCAL_MACHINE);
    let hkcu = RegKey::predef(HKEY_CURRENT_USER);
    
    // --- Discovery Phase: Hybrid Mode ---

    // 1. Primary Source: The Content Index (most reliable)
    if let Ok(content_key) = hklm.open_subkey("SOFTWARE\\WOW6432Node\\Native Instruments\\Content") {
        for (_, value) in content_key.enum_values().filter_map(Result::ok) {
            let library_name: String = value.to_string();
            if !BLACKLIST.key_names.contains(&library_name) {
                library_names.insert(library_name);
            }
        }
    }

    // 2. Supplementary Source: Comprehensive Census (to find orphans)
    let paths_to_scan = [
        hklm.open_subkey("SOFTWARE\\WOW6432Node\\Native Instruments").ok(),
        hklm.open_subkey("SOFTWARE\\Native Instruments").ok(),
        hkcu.open_subkey("SOFTWARE\\Native Instruments").ok(),
    ];

    for path in paths_to_scan.iter().flatten() {
        for key_name_result in path.enum_keys() {
            if let Ok(key_name) = key_name_result {
                if BLACKLIST.key_names.contains(&key_name) { continue; }
                if let Ok(subkey) = path.open_subkey(&key_name) {
                    let is_plugin = BLACKLIST.value_names.iter().any(|val_name| subkey.get_value::<String, _>(val_name).is_ok());
                    if !is_plugin {
                        library_names.insert(key_name);
                    }
                }
            }
        }
    }
    
    // --- Verification and Health Check Stage ---
    let ni_key_hklm_wow64 = hklm.open_subkey("SOFTWARE\\WOW6432Node\\Native Instruments")
        .map_err(|e| format!("Failed to open HKLM WOW64 NI key: {}", e))?;
    let ni_key_hklm_native = hklm.open_subkey("SOFTWARE\\Native Instruments").ok();
    let ni_key_hkcu = hkcu.open_subkey("SOFTWARE\\Native Instruments")
        .map_err(|e| format!("Failed to open HKCU NI key: {}", e))?;

    for library_name in library_names {
        // Health Check
        let mut status_count = 0;
        if ni_key_hklm_wow64.open_subkey(&library_name).is_ok() { status_count += 1; }
        if let Some(key) = &ni_key_hklm_native {
            if key.open_subkey(&library_name).is_ok() { status_count += 1; }
        }
        if ni_key_hkcu.open_subkey(&library_name).is_ok() { status_count += 1; }
        let registration_status = format!("{}/3", status_count);
        
        // Classify Library Type (based on the most authoritative location)
        let library_type = match ni_key_hklm_wow64.open_subkey(&library_name) {
            Ok(library_key_hklm) => {
                let has_hu = library_key_hklm.get_value::<String, _>("HU").is_ok();
                let has_jdx = library_key_hklm.get_value::<String, _>("JDX").is_ok();
                if has_hu && has_jdx {
                    standard_count += 1;
                    "标准音色库".to_string()
                } else {
                    custom_count += 1;
                    "自定义音色库".to_string()
                }
            }
            Err(_) => {
                custom_count += 1;
                "自定义音色库".to_string()
            }
        };

        libraries.push(LibraryInfo {
            name: library_name,
            library_type,
            registration_status,
        });
    }

    Ok(LibraryQueryResult {
        libraries,
        total_count: standard_count + custom_count,
        standard_count,
        custom_count,
    })
}

// ... (rest of the file is unchanged)

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

#[cfg_attr(mobile, tauri::mobile_entry_point)]
pub fn run() {
    use tauri::{tray::TrayIconBuilder, menu::Menu};

    tauri::Builder::default()
        .plugin(tauri_plugin_shell::init())
        .setup(|app| {
            let window = app.get_webview_window("main").unwrap();
            
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

            let menu = Menu::new(app)?;
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
            
            update_tray_menu(&app.handle());
            window.show().unwrap();
            Ok(())
        })
        .on_window_event(|window, event| {
            if let WindowEvent::CloseRequested { api, .. } = event {
                window.hide().unwrap();
                api.prevent_close();
            }
        })
        .invoke_handler(tauri::generate_handler![
            get_config,
            set_auto_start,
            set_silent_start,
            save_config,
            get_installed_libraries,
            get_library_details
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
