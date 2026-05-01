use clap::{Args, Parser, Subcommand, ValueEnum};
use miette::{bail, miette, Context, IntoDiagnostic, Result};
use serde::{Deserialize, Serialize};
use serde_json::{Map, Value};
use sha2::{Digest, Sha256};
use std::collections::BTreeMap;
use std::env;
use std::ffi::OsStr;
use std::fs;
use std::io::Read;
use std::path::{Path, PathBuf};

const SENSITIVE_PARTS: &[&str] = &["token", "key", "password", "secret", "auth", "cookie"];
const RUNTIME_KEYS: &[&str] = &[
    "geometry",
    "DockState",
    "LastVersion",
    "InfoIncrement",
    "CookieId",
    "LastUpdateCheck",
];
const LOCAL_PATH_PARTS: &[&str] = &["path", "dir", "directory", "file"];

#[derive(Debug, Parser)]
#[command(name = "hermesix")]
#[command(about = "Home Manager managed configuration utilities")]
struct Cli {
    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    Diff(Diff),
    Sync(Sync),
    Validate(Validate),
    Redact(Redact),
    Obs {
        #[command(subcommand)]
        command: ObsCommand,
    },
}

#[derive(Debug, Subcommand)]
enum ObsCommand {
    ExportToNix(ExportToNix),
    PluginInspect(PluginInspect),
}

#[derive(Debug, Args)]
struct ExportToNix {
    config_dir: Option<PathBuf>,

    #[command(flatten)]
    redaction: Redaction,
}

#[derive(Debug, Args)]
struct Diff {
    #[arg(long)]
    manifest: PathBuf,

    #[arg(long)]
    config_dir: PathBuf,

    #[arg(long)]
    json: bool,
}

#[derive(Debug, Args)]
struct Sync {
    #[arg(long)]
    manifest: PathBuf,

    #[arg(long)]
    config_dir: PathBuf,

    #[arg(long)]
    apply: bool,

    #[arg(long)]
    json: bool,
}

#[derive(Debug, Args)]
struct Validate {
    #[arg(long)]
    manifest: PathBuf,

    #[arg(long)]
    config_dir: PathBuf,

    #[command(flatten)]
    redaction: Redaction,
}

#[derive(Debug, Args)]
struct Redact {
    input: PathBuf,

    #[arg(long, value_enum, default_value_t = RedactFormat::Auto)]
    format: RedactFormat,

    #[command(flatten)]
    redaction: Redaction,
}

#[derive(Debug, Args)]
struct PluginInspect {
    #[command(subcommand)]
    command: Option<PluginInspectCommand>,

    #[arg(long, conflicts_with = "install_dir")]
    source_dir: Option<PathBuf>,

    #[arg(long, conflicts_with = "source_dir")]
    install_dir: Option<PathBuf>,
}

#[derive(Debug, Subcommand)]
enum PluginInspectCommand {
    Verify(PluginInspectVerify),
}

#[derive(Debug, Args)]
struct PluginInspectVerify {
    #[arg(long)]
    evidence: PathBuf,

    #[arg(long, conflicts_with = "install_dir")]
    source_dir: Option<PathBuf>,

    #[arg(long, conflicts_with = "source_dir")]
    install_dir: Option<PathBuf>,
}

#[derive(Debug, Args, Default, Clone)]
struct Redaction {
    #[arg(long)]
    include_sensitive: bool,

    #[arg(long)]
    include_runtime: bool,

    #[arg(long)]
    include_local_paths: bool,
}

#[derive(Debug, Clone, Copy, ValueEnum)]
enum RedactFormat {
    Auto,
    Json,
    Ini,
}

#[derive(Debug, Deserialize)]
struct Manifest {
    version: u64,
    module: Option<String>,
    files: Vec<ManifestFile>,
}

#[derive(Debug, Deserialize)]
struct ManifestFile {
    path: String,
    source: PathBuf,
    target: PathBuf,
    sha256: String,
    kind: FileKind,
    origin: String,
}

#[derive(Debug, Deserialize, Serialize, Clone, Copy, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
enum FileKind {
    Ini,
    Json,
    Raw,
}

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq)]
struct PluginEvidence {
    source_ids: Vec<EvidenceLine>,
    filter_ids: Vec<EvidenceLine>,
    output_ids: Vec<EvidenceLine>,
    encoder_ids: Vec<EvidenceLine>,
    registrations: Vec<EvidenceLine>,
    setting_defaults: Vec<EvidenceLine>,
    property_settings: Vec<EvidenceLine>,
}

impl PluginEvidence {
    fn empty() -> Self {
        Self {
            source_ids: Vec::new(),
            filter_ids: Vec::new(),
            output_ids: Vec::new(),
            encoder_ids: Vec::new(),
            registrations: Vec::new(),
            setting_defaults: Vec::new(),
            property_settings: Vec::new(),
        }
    }
}

#[derive(Debug, Deserialize, Serialize, PartialEq, Eq)]
struct EvidenceLine {
    file: String,
    line: usize,
    key: Option<String>,
    text: String,
}

#[derive(Debug, PartialEq, Eq, Serialize)]
#[serde(rename_all = "lowercase")]
enum FileStatus {
    Same,
    Missing,
    Changed,
}

#[derive(Debug, Serialize)]
struct DiffEntry {
    status: FileStatus,
    path: String,
}

fn main() {
    let mut args: Vec<String> = env::args().collect();
    let invoked = Path::new(args.first().map(String::as_str).unwrap_or("hermesix"))
        .file_name()
        .and_then(OsStr::to_str)
        .unwrap_or("hermesix")
        .to_string();

    if invoked == "obs-studio-export-to-nix" {
        args.insert(1, "export-to-nix".to_string());
        args.insert(1, "obs".to_string());
    } else if invoked == "obs-studio-sync"
        && matches!(
            args.get(1).map(String::as_str),
            Some("export-to-nix" | "plugin-inspect")
        )
    {
        args.insert(1, "obs".to_string());
    }

    let cli = match Cli::try_parse_from(args) {
        Ok(cli) => cli,
        Err(err) => {
            let _ = err.print();
            std::process::exit(2);
        }
    };

    match run(cli) {
        Ok(code) => std::process::exit(code),
        Err(err) => {
            eprintln!("{err:?}");
            std::process::exit(1);
        }
    }
}

fn run(cli: Cli) -> Result<i32> {
    match cli.command {
        Command::Diff(args) => diff_command(args),
        Command::Sync(args) => sync_command(args),
        Command::Validate(args) => {
            validate_command(args)?;
            Ok(0)
        }
        Command::Redact(args) => {
            redact_command(args)?;
            Ok(0)
        }
        Command::Obs { command } => match command {
            ObsCommand::ExportToNix(args) => {
                obs_export_to_nix(args)?;
                Ok(0)
            }
            ObsCommand::PluginInspect(args) => obs_plugin_inspect_command(args),
        },
    }
}

fn obs_export_to_nix(args: ExportToNix) -> Result<()> {
    let root = args.config_dir.unwrap_or_else(default_obs_config_dir);

    println!("{{");

    let global_ini = root.join("global.ini");
    if global_ini.exists() {
        emit_assignment(
            &["settings", "global"],
            ini_to_json(&global_ini, &args.redaction)?,
        )?;
    }

    let user_ini = root.join("user.ini");
    if user_ini.exists() {
        emit_assignment(
            &["settings", "user"],
            ini_to_json(&user_ini, &args.redaction)?,
        )?;
    }

    let profiles = root.join("basic/profiles");
    if profiles.exists() {
        for profile in sorted_dirs(&profiles)? {
            let profile_name = path_name(&profile)?;
            let basic_ini = profile.join("basic.ini");
            if basic_ini.exists() {
                emit_assignment(
                    &["profiles", &profile_name, "settings"],
                    ini_to_json(&basic_ini, &args.redaction)?,
                )?;
            }
            for (file_name, option) in [
                ("streamEncoder.json", "streamEncoder"),
                ("recordEncoder.json", "recordEncoder"),
            ] {
                let file = profile.join(file_name);
                if file.exists() {
                    emit_assignment(
                        &["profiles", &profile_name, option],
                        sanitized_json_file(&file, &args.redaction)?,
                    )?;
                }
            }
        }
    }

    let scenes = root.join("basic/scenes");
    if scenes.exists() {
        for scene in sorted_files_with_ext(&scenes, "json")? {
            let name = scene
                .file_stem()
                .and_then(OsStr::to_str)
                .ok_or_else(|| miette!("invalid scene filename `{}`", scene.display()))?;
            emit_assignment(
                &["sceneCollections", name, "raw"],
                sanitized_json_file(&scene, &args.redaction)?,
            )?;
        }
    }

    let plugin_config = root.join("plugin_config");
    if plugin_config.exists() {
        for file in sorted_recursive_files(&plugin_config)? {
            if file.extension().and_then(OsStr::to_str) == Some("json") {
                let rel = file
                    .strip_prefix(&plugin_config)
                    .into_diagnostic()?
                    .to_string_lossy()
                    .replace('\\', "/");
                let text =
                    serde_json::to_string_pretty(&sanitized_json_file(&file, &args.redaction)?)
                        .into_diagnostic()?
                        + "\n";
                emit_assignment(&["extraConfigFiles", &rel, "text"], Value::String(text))?;
            }
        }
    }

    println!("}}");
    Ok(())
}

fn diff_command(args: Diff) -> Result<i32> {
    let manifest = read_manifest(&args.manifest)?;
    require_valid_manifest_shape(&manifest, &args.config_dir)?;
    let entries = diff_entries(&manifest, &args.config_dir)?;
    print_diff(&entries, args.json)?;
    Ok(if entries.is_empty() { 0 } else { 1 })
}

fn sync_command(args: Sync) -> Result<i32> {
    let manifest = read_manifest(&args.manifest)?;
    require_valid_manifest_shape(&manifest, &args.config_dir)?;
    let entries = diff_entries(&manifest, &args.config_dir)?;
    print_diff(&entries, args.json)?;
    if entries.is_empty() {
        return Ok(0);
    }
    if args.apply {
        for entry in &entries {
            let file = manifest
                .files
                .iter()
                .find(|file| file.path == entry.path)
                .ok_or_else(|| miette!("manifest lost entry for {}", entry.path))?;
            verify_source_hash(file)?;
            copy_atomic(&file.source, &args.config_dir.join(&file.path))?;
        }
        Ok(0)
    } else {
        if !args.json {
            println!("dry-run: pass --apply to write changes");
        }
        Ok(1)
    }
}

fn validate_command(args: Validate) -> Result<()> {
    let manifest = read_manifest(&args.manifest)?;
    let mut errors = manifest_shape_errors(&manifest, &args.config_dir);
    for file in &manifest.files {
        if !file.source.exists() {
            errors.push(format!("{}: source does not exist", file.path));
            continue;
        }
        match verify_source_hash(file) {
            Ok(()) => {}
            Err(err) => errors.push(format!("{}: {err:?}", file.path)),
        }
        if let Err(err) = parse_by_kind(&file.source, &file.path, file.kind) {
            errors.push(format!(
                "{}: cannot parse {}: {err:?}",
                file.path,
                kind_name(file.kind)
            ));
        }
        if let Err(err) =
            portable_policy_check(&file.source, &file.path, file.kind, &args.redaction)
        {
            errors.push(format!("{}: {err:?}", file.path));
        }
    }
    if errors.is_empty() {
        println!("manifest ok");
        Ok(())
    } else {
        for err in errors {
            eprintln!("{err}");
        }
        bail!("validation failed");
    }
}

fn require_valid_manifest_shape(manifest: &Manifest, config_dir: &Path) -> Result<()> {
    let errors = manifest_shape_errors(manifest, config_dir);
    if errors.is_empty() {
        Ok(())
    } else {
        for err in errors {
            eprintln!("{err}");
        }
        bail!("invalid manifest")
    }
}

fn manifest_shape_errors(manifest: &Manifest, config_dir: &Path) -> Vec<String> {
    let mut errors = Vec::new();
    if manifest.version != 1 {
        errors.push(format!("unsupported manifest version {}", manifest.version));
    }
    if matches!(manifest.module.as_deref(), Some("")) {
        errors.push("manifest module must not be empty".to_string());
    }
    for file in &manifest.files {
        if Path::new(&file.path).is_absolute() || file.path.split('/').any(|part| part == "..") {
            errors.push(format!(
                "{} ({}): relative path escapes config root",
                file.path, file.origin
            ));
        }
        let expected_target = config_dir.join(&file.path);
        if file.target != expected_target {
            errors.push(format!(
                "{} ({}): manifest target {} does not match config dir target {}",
                file.path,
                file.origin,
                file.target.display(),
                expected_target.display()
            ));
        }
    }
    errors
}

fn verify_source_hash(file: &ManifestFile) -> Result<()> {
    match sha256_file(&file.source) {
        Ok(hash) if hash == file.sha256 => Ok(()),
        Ok(hash) => bail!("source sha256 mismatch: {hash}"),
        Err(err) => {
            Err(err).wrap_err_with(|| format!("cannot hash source {}", file.source.display()))
        }
    }
}

fn redact_command(args: Redact) -> Result<()> {
    let kind = detect_kind(&args.input, args.format);
    match kind {
        FileKind::Json => println!(
            "{}",
            serde_json::to_string_pretty(&sanitized_json_file(&args.input, &args.redaction)?)
                .into_diagnostic()?
        ),
        FileKind::Ini => print!(
            "{}",
            render_ini(&ini_to_sections(&args.input, &args.redaction)?)
        ),
        FileKind::Raw => {
            let mut text = String::new();
            fs::File::open(args.input)
                .into_diagnostic()?
                .read_to_string(&mut text)
                .into_diagnostic()?;
            print!("{text}");
        }
    }
    Ok(())
}

fn obs_plugin_inspect_command(args: PluginInspect) -> Result<i32> {
    match args.command {
        Some(PluginInspectCommand::Verify(verify)) => {
            plugin_inspect_verify(verify)?;
            Ok(0)
        }
        None => {
            let root = exactly_one_dir(args.source_dir, args.install_dir, "plugin-inspect")?;
            let evidence = inspect_plugin(&root)?;
            println!(
                "{}",
                serde_json::to_string_pretty(&evidence).into_diagnostic()?
            );
            Ok(0)
        }
    }
}

fn plugin_inspect_verify(args: PluginInspectVerify) -> Result<()> {
    let root = exactly_one_dir(args.source_dir, args.install_dir, "plugin-inspect verify")?;
    let expected: PluginEvidence = serde_json::from_reader(
        fs::File::open(&args.evidence)
            .into_diagnostic()
            .wrap_err_with(|| format!("cannot open evidence file {}", args.evidence.display()))?,
    )
    .into_diagnostic()?;
    let actual = inspect_plugin(&root)?;
    if actual == expected {
        println!("plugin evidence ok");
        Ok(())
    } else {
        eprintln!(
            "{}",
            serde_json::to_string_pretty(&actual).into_diagnostic()?
        );
        bail!("plugin evidence mismatch");
    }
}

fn exactly_one_dir(
    source_dir: Option<PathBuf>,
    install_dir: Option<PathBuf>,
    command: &str,
) -> Result<PathBuf> {
    match (source_dir, install_dir) {
        (Some(path), None) | (None, Some(path)) => Ok(path),
        (None, None) => bail!("{command} requires --source-dir or --install-dir"),
        (Some(_), Some(_)) => bail!("{command} accepts only one of --source-dir or --install-dir"),
    }
}

fn diff_entries(manifest: &Manifest, config_dir: &Path) -> Result<Vec<DiffEntry>> {
    let mut entries = Vec::new();
    for file in &manifest.files {
        let status = file_status(file, config_dir)?;
        if status != FileStatus::Same {
            entries.push(DiffEntry {
                status,
                path: file.path.clone(),
            });
        }
    }
    Ok(entries)
}

fn print_diff(entries: &[DiffEntry], json: bool) -> Result<()> {
    if json {
        println!(
            "{}",
            serde_json::to_string_pretty(entries).into_diagnostic()?
        );
    } else if entries.is_empty() {
        println!("no changes");
    } else {
        for entry in entries {
            println!("{} {}", status_name(&entry.status), entry.path);
        }
    }
    Ok(())
}

fn inspect_plugin(root: &Path) -> Result<PluginEvidence> {
    let mut evidence = PluginEvidence::empty();
    for file in sorted_recursive_files(root)? {
        if !is_text_candidate(&file) {
            continue;
        }
        let Ok(text) = fs::read_to_string(&file) else {
            continue;
        };
        let rel = file
            .strip_prefix(root)
            .unwrap_or(&file)
            .to_string_lossy()
            .to_string();
        for (idx, line) in text.lines().enumerate() {
            let trimmed = line.trim();
            let item = EvidenceLine {
                file: rel.clone(),
                line: idx + 1,
                key: quoted_key(trimmed),
                text: trimmed.to_string(),
            };
            if trimmed.contains("obs_source_info") {
                evidence.source_ids.push(item);
            } else if trimmed.contains("obs_filter_info") {
                evidence.filter_ids.push(item);
            } else if trimmed.contains("obs_output_info") {
                evidence.output_ids.push(item);
            } else if trimmed.contains("obs_encoder_info") {
                evidence.encoder_ids.push(item);
            } else if trimmed.contains("obs_register_") {
                evidence.registrations.push(item);
            } else if trimmed.contains("obs_data_set_default_") {
                evidence.setting_defaults.push(item);
            } else if trimmed.contains("obs_properties_add_") {
                evidence.property_settings.push(item);
            }
        }
    }
    Ok(evidence)
}

fn quoted_key(line: &str) -> Option<String> {
    let start = line.find('"')?;
    let rest = &line[start + 1..];
    let end = rest.find('"')?;
    Some(rest[..end].to_string())
}

fn read_manifest(path: &Path) -> Result<Manifest> {
    serde_json::from_reader(
        fs::File::open(path)
            .into_diagnostic()
            .wrap_err_with(|| format!("cannot open manifest {}", path.display()))?,
    )
    .into_diagnostic()
}

fn file_status(file: &ManifestFile, config_dir: &Path) -> Result<FileStatus> {
    let target = config_dir.join(&file.path);
    if !target.exists() {
        return Ok(FileStatus::Missing);
    }
    let target_hash = sha256_file(&target)?;
    if target_hash == file.sha256 {
        Ok(FileStatus::Same)
    } else {
        Ok(FileStatus::Changed)
    }
}

fn status_name(status: &FileStatus) -> &'static str {
    match status {
        FileStatus::Same => "same",
        FileStatus::Missing => "missing",
        FileStatus::Changed => "changed",
    }
}

fn copy_atomic(source: &Path, target: &Path) -> Result<()> {
    let parent = target
        .parent()
        .ok_or_else(|| miette!("target `{}` has no parent", target.display()))?;
    fs::create_dir_all(parent).into_diagnostic()?;
    let tmp = target.with_extension(format!(
        "{}.tmp.{}",
        target.extension().and_then(OsStr::to_str).unwrap_or("file"),
        std::process::id()
    ));
    fs::copy(source, &tmp).into_diagnostic()?;
    fs::set_permissions(&tmp, fs::Permissions::from_mode_unix(0o644)).into_diagnostic()?;
    fs::rename(tmp, target).into_diagnostic()?;
    Ok(())
}

#[cfg(unix)]
trait PermissionsExtUnix {
    fn from_mode_unix(mode: u32) -> Self;
}

#[cfg(unix)]
impl PermissionsExtUnix for fs::Permissions {
    fn from_mode_unix(mode: u32) -> Self {
        use std::os::unix::fs::PermissionsExt;
        fs::Permissions::from_mode(mode)
    }
}

fn parse_by_kind(path: &Path, rel_path: &str, kind: FileKind) -> Result<()> {
    match effective_kind(rel_path, kind) {
        FileKind::Json => {
            let _: Value = serde_json::from_reader(
                fs::File::open(path)
                    .into_diagnostic()
                    .wrap_err_with(|| format!("cannot open {}", path.display()))?,
            )
            .into_diagnostic()?;
        }
        FileKind::Ini => {
            let _ = parse_ini(path)?;
        }
        FileKind::Raw => {}
    }
    Ok(())
}

fn portable_policy_check(
    path: &Path,
    rel_path: &str,
    kind: FileKind,
    redaction: &Redaction,
) -> Result<()> {
    match effective_kind(rel_path, kind) {
        FileKind::Json => {
            let original: Value = serde_json::from_reader(
                fs::File::open(path)
                    .into_diagnostic()
                    .wrap_err_with(|| format!("cannot open {}", path.display()))?,
            )
            .into_diagnostic()?;
            let sanitized = sanitize_json(original.clone(), redaction, "");
            if sanitized != original {
                bail!("contains non-portable or sensitive JSON fields");
            }
        }
        FileKind::Ini => {
            let original = parse_ini(path)?;
            let sanitized = sanitize_ini(original.clone(), redaction);
            if sanitized != original {
                bail!("contains non-portable or sensitive INI fields");
            }
        }
        FileKind::Raw => {}
    }
    Ok(())
}

fn effective_kind(rel_path: &str, kind: FileKind) -> FileKind {
    if kind != FileKind::Raw {
        return kind;
    }
    if rel_path.ends_with(".json") {
        FileKind::Json
    } else if rel_path.ends_with(".ini") {
        FileKind::Ini
    } else {
        FileKind::Raw
    }
}

fn detect_kind(path: &Path, format: RedactFormat) -> FileKind {
    match format {
        RedactFormat::Json => FileKind::Json,
        RedactFormat::Ini => FileKind::Ini,
        RedactFormat::Auto => match path.extension().and_then(OsStr::to_str) {
            Some("json") => FileKind::Json,
            Some("ini") => FileKind::Ini,
            _ => FileKind::Raw,
        },
    }
}

fn sanitized_json_file(path: &Path, redaction: &Redaction) -> Result<Value> {
    let value: Value = serde_json::from_reader(
        fs::File::open(path)
            .into_diagnostic()
            .wrap_err_with(|| format!("cannot open {}", path.display()))?,
    )
    .into_diagnostic()?;
    Ok(sanitize_json(value, redaction, ""))
}

fn sanitize_json(value: Value, redaction: &Redaction, key: &str) -> Value {
    if should_omit(key, &value, redaction) {
        return Value::Null;
    }
    match value {
        Value::Object(map) => Value::Object(
            map.into_iter()
                .filter_map(|(child_key, child_value)| {
                    if should_omit(&child_key, &child_value, redaction) {
                        None
                    } else {
                        Some((
                            child_key.clone(),
                            sanitize_json(child_value, redaction, &child_key),
                        ))
                    }
                })
                .collect(),
        ),
        Value::Array(items) => Value::Array(
            items
                .into_iter()
                .map(|item| sanitize_json(item, redaction, key))
                .filter(|item| !item.is_null())
                .collect(),
        ),
        other => other,
    }
}

fn should_omit(key: &str, value: &Value, redaction: &Redaction) -> bool {
    let lowered = key.to_ascii_lowercase();
    if !redaction.include_sensitive && SENSITIVE_PARTS.iter().any(|part| lowered.contains(part)) {
        return true;
    }
    if !redaction.include_runtime && RUNTIME_KEYS.contains(&key) {
        return true;
    }
    if !redaction.include_local_paths && value.as_str().is_some() {
        let pathish = LOCAL_PATH_PARTS
            .iter()
            .any(|part| lowered.ends_with(part) || lowered.contains(part));
        if pathish {
            let string = value.as_str().unwrap_or_default();
            return string.starts_with('/') || string.starts_with('~');
        }
    }
    false
}

type Ini = BTreeMap<String, BTreeMap<String, String>>;

fn ini_to_json(path: &Path, redaction: &Redaction) -> Result<Value> {
    let sections = ini_to_sections(path, redaction)?;
    let mut root = Map::new();
    for (section, values) in sections {
        let mut object = Map::new();
        for (key, value) in values {
            object.insert(key, Value::String(value));
        }
        root.insert(section, Value::Object(object));
    }
    Ok(Value::Object(root))
}

fn ini_to_sections(path: &Path, redaction: &Redaction) -> Result<Ini> {
    Ok(sanitize_ini(parse_ini(path)?, redaction))
}

fn parse_ini(path: &Path) -> Result<Ini> {
    let text = fs::read_to_string(path)
        .into_diagnostic()
        .wrap_err_with(|| format!("cannot read {}", path.display()))?;
    let mut sections: Ini = BTreeMap::new();
    let mut current = String::new();
    for line in text.lines() {
        let trimmed = line.trim();
        if trimmed.is_empty() || trimmed.starts_with('#') || trimmed.starts_with(';') {
            continue;
        }
        if trimmed.starts_with('[') && trimmed.ends_with(']') {
            current = trimmed[1..trimmed.len() - 1].to_string();
            sections.entry(current.clone()).or_default();
            continue;
        }
        if let Some((key, value)) = trimmed.split_once('=') {
            sections
                .entry(current.clone())
                .or_default()
                .insert(key.trim().to_string(), value.trim().to_string());
        }
    }
    Ok(sections)
}

fn sanitize_ini(ini: Ini, redaction: &Redaction) -> Ini {
    ini.into_iter()
        .filter_map(|(section, values)| {
            let values: BTreeMap<_, _> = values
                .into_iter()
                .filter(|(key, value)| !should_omit(key, &Value::String(value.clone()), redaction))
                .collect();
            if values.is_empty() {
                None
            } else {
                Some((section, values))
            }
        })
        .collect()
}

fn render_ini(ini: &Ini) -> String {
    let mut out = String::new();
    for (section, values) in ini {
        out.push('[');
        out.push_str(section);
        out.push_str("]\n");
        for (key, value) in values {
            out.push_str(key);
            out.push('=');
            out.push_str(value);
            out.push('\n');
        }
        out.push('\n');
    }
    out
}

fn emit_assignment(path: &[&str], value: Value) -> Result<()> {
    let lhs = format!(
        "programs.obs-studio.{}",
        path.iter()
            .map(serde_json::to_string)
            .collect::<std::result::Result<Vec<_>, _>>()
            .into_diagnostic()?
            .join(".")
    );
    println!("  {lhs} = {};", to_nix(&value, 2)?);
    Ok(())
}

fn to_nix(value: &Value, indent: usize) -> Result<String> {
    let pad = " ".repeat(indent);
    let next = " ".repeat(indent + 2);
    Ok(match value {
        Value::Null => "null".to_string(),
        Value::Bool(value) => value.to_string(),
        Value::Number(value) => value.to_string(),
        Value::String(value) => serde_json::to_string(value).into_diagnostic()?,
        Value::Array(items) if items.is_empty() => "[]".to_string(),
        Value::Array(items) => {
            let rendered = items
                .iter()
                .map(|item| Ok(format!("{next}{}", to_nix(item, indent + 2)?)))
                .collect::<Result<Vec<_>>>()?
                .join("\n");
            format!("[\n{rendered}\n{pad}]")
        }
        Value::Object(map) if map.is_empty() => "{}".to_string(),
        Value::Object(map) => {
            let rendered = map
                .iter()
                .map(|(key, child)| {
                    Ok(format!(
                        "{next}{} = {};",
                        serde_json::to_string(key).into_diagnostic()?,
                        to_nix(child, indent + 2)?
                    ))
                })
                .collect::<Result<Vec<_>>>()?
                .join("\n");
            format!("{{\n{rendered}\n{pad}}}")
        }
    })
}

fn sha256_file(path: &Path) -> Result<String> {
    let mut file = fs::File::open(path)
        .into_diagnostic()
        .wrap_err_with(|| format!("cannot open {}", path.display()))?;
    let mut hasher = Sha256::new();
    let mut buffer = [0_u8; 8192];
    loop {
        let read = file.read(&mut buffer).into_diagnostic()?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    Ok(hex::encode(hasher.finalize()))
}

fn default_obs_config_dir() -> PathBuf {
    let base = env::var_os("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .or_else(|| env::var_os("HOME").map(|home| PathBuf::from(home).join(".config")))
        .unwrap_or_else(|| PathBuf::from("."));
    base.join("obs-studio")
}

fn sorted_dirs(root: &Path) -> Result<Vec<PathBuf>> {
    let mut paths = fs::read_dir(root)
        .into_diagnostic()?
        .filter_map(|entry| entry.ok().map(|entry| entry.path()))
        .filter(|path| path.is_dir())
        .collect::<Vec<_>>();
    paths.sort();
    Ok(paths)
}

fn sorted_files_with_ext(root: &Path, ext: &str) -> Result<Vec<PathBuf>> {
    let mut paths = fs::read_dir(root)
        .into_diagnostic()?
        .filter_map(|entry| entry.ok().map(|entry| entry.path()))
        .filter(|path| path.extension().and_then(OsStr::to_str) == Some(ext))
        .collect::<Vec<_>>();
    paths.sort();
    Ok(paths)
}

fn sorted_recursive_files(root: &Path) -> Result<Vec<PathBuf>> {
    let mut paths = Vec::new();
    collect_files(root, &mut paths)?;
    paths.sort();
    Ok(paths)
}

fn collect_files(root: &Path, paths: &mut Vec<PathBuf>) -> Result<()> {
    if root.is_dir() {
        for entry in fs::read_dir(root).into_diagnostic()? {
            let path = entry.into_diagnostic()?.path();
            if path.is_dir() {
                collect_files(&path, paths)?;
            } else if path.is_file() {
                paths.push(path);
            }
        }
    }
    Ok(())
}

fn path_name(path: &Path) -> Result<String> {
    path.file_name()
        .and_then(OsStr::to_str)
        .map(str::to_string)
        .ok_or_else(|| miette!("invalid path `{}`", path.display()))
}

fn kind_name(kind: FileKind) -> &'static str {
    match kind {
        FileKind::Ini => "ini",
        FileKind::Json => "json",
        FileKind::Raw => "raw",
    }
}

fn is_text_candidate(path: &Path) -> bool {
    matches!(
        path.extension().and_then(OsStr::to_str),
        Some("c" | "cc" | "cpp" | "cxx" | "h" | "hpp" | "hh" | "m" | "mm" | "json" | "ini")
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::sync::atomic::{AtomicUsize, Ordering};

    static NEXT_TEST_DIR: AtomicUsize = AtomicUsize::new(0);

    fn temp_root(name: &str) -> PathBuf {
        let id = NEXT_TEST_DIR.fetch_add(1, Ordering::Relaxed);
        let root =
            env::temp_dir().join(format!("hermesix-test-{}-{id}-{name}", std::process::id()));
        let _ = fs::remove_dir_all(&root);
        fs::create_dir_all(&root).unwrap();
        root
    }

    fn write_file(path: &Path, text: &str) {
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(path, text).unwrap();
    }

    fn write_manifest(
        root: &Path,
        config_dir: &Path,
        rel_path: &str,
        source: &Path,
        sha256: &str,
    ) -> PathBuf {
        let manifest = root.join("manifest.json");
        let value = json!({
            "version": 1,
            "module": "programs.test",
            "files": [{
                "path": rel_path,
                "source": source,
                "target": config_dir.join(rel_path),
                "sha256": sha256,
                "kind": "raw",
                "origin": "test"
            }]
        });
        fs::write(&manifest, serde_json::to_string_pretty(&value).unwrap()).unwrap();
        manifest
    }

    #[test]
    fn sync_apply_writes_valid_manifest_and_diff_cleans() {
        let root = temp_root("valid-sync");
        let source = root.join("source/settings.txt");
        let live = root.join("live");
        write_file(&source, "managed\n");
        let hash = sha256_file(&source).unwrap();
        let manifest = write_manifest(&root, &live, "settings.txt", &source, &hash);

        let diff_status = diff_command(Diff {
            manifest: manifest.clone(),
            config_dir: live.clone(),
            json: true,
        })
        .unwrap();
        assert_eq!(diff_status, 1);

        let sync_status = sync_command(Sync {
            manifest: manifest.clone(),
            config_dir: live.clone(),
            apply: true,
            json: true,
        })
        .unwrap();
        assert_eq!(sync_status, 0);
        assert_eq!(
            fs::read_to_string(live.join("settings.txt")).unwrap(),
            "managed\n"
        );

        let clean_status = diff_command(Diff {
            manifest,
            config_dir: live,
            json: true,
        })
        .unwrap();
        assert_eq!(clean_status, 0);
    }

    #[test]
    fn diff_rejects_manifest_path_traversal() {
        let root = temp_root("diff-traversal");
        let source = root.join("source/settings.txt");
        let live = root.join("live");
        write_file(&source, "managed\n");
        let hash = sha256_file(&source).unwrap();
        let manifest = write_manifest(&root, &live, "../escape.txt", &source, &hash);

        let result = diff_command(Diff {
            manifest,
            config_dir: live,
            json: true,
        });
        assert!(result.is_err());
    }

    #[test]
    fn sync_apply_rejects_manifest_path_traversal() {
        let root = temp_root("sync-traversal");
        let source = root.join("source/settings.txt");
        let live = root.join("live");
        write_file(&source, "managed\n");
        let hash = sha256_file(&source).unwrap();
        let manifest = write_manifest(&root, &live, "../escape.txt", &source, &hash);

        let result = sync_command(Sync {
            manifest,
            config_dir: live,
            apply: true,
            json: true,
        });
        assert!(result.is_err());
    }

    #[test]
    fn sync_apply_rejects_source_hash_mismatch() {
        let root = temp_root("hash-mismatch");
        let source = root.join("source/settings.txt");
        let live = root.join("live");
        write_file(&source, "managed\n");
        let manifest = write_manifest(&root, &live, "settings.txt", &source, "not-the-hash");

        let result = sync_command(Sync {
            manifest,
            config_dir: live,
            apply: true,
            json: true,
        });
        assert!(result.is_err());
    }
}
