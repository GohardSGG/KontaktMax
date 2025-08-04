fn main() {
  println!("cargo:rerun-if-changed=blacklist.json");
  tauri_build::build()
}
