//! Model Context Protocol (MCP) Core
//!
//! Provides secure execution of AI-generated actions with proper sandboxing.
//! All file operations are restricted to the browse/ directory.
//! Lua execution is sandboxed with whitelisted functions only.

use anyhow::{anyhow, Result};
use flutter_rust_bridge::frb;
use parking_lot::Mutex;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;

// ============================================================================
// Tool Definitions
// ============================================================================

/// Available MCP tools
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[frb]
pub enum MCPTool {
    /// Read a file from browse/ directory
    ReadFile,
    /// Write/create a file in browse/ directory
    WriteFile,
    /// Delete a file in browse/ directory
    DeleteFile,
    /// Create a folder in browse/ directory
    CreateFolder,
    /// List files in browse/ directory
    ListFiles,
    /// Execute a Lua script for calendar operations
    CalendarLua,
    /// Execute a Lua script for timer operations
    TimerLua,
    /// Export AI response as markdown
    ExportMarkdown,
}

impl MCPTool {
    /// Get all available tools
    pub fn all() -> Vec<MCPTool> {
        vec![
            MCPTool::ReadFile,
            MCPTool::WriteFile,
            MCPTool::DeleteFile,
            MCPTool::CreateFolder,
            MCPTool::ListFiles,
            MCPTool::CalendarLua,
            MCPTool::TimerLua,
            MCPTool::ExportMarkdown,
        ]
    }

    /// Get tool name
    pub fn name(&self) -> &'static str {
        match self {
            MCPTool::ReadFile => "read_file",
            MCPTool::WriteFile => "write_file",
            MCPTool::DeleteFile => "delete_file",
            MCPTool::CreateFolder => "create_folder",
            MCPTool::ListFiles => "list_files",
            MCPTool::CalendarLua => "calendar_lua",
            MCPTool::TimerLua => "timer_lua",
            MCPTool::ExportMarkdown => "export_markdown",
        }
    }

    /// Get tool description
    pub fn description(&self) -> &'static str {
        match self {
            MCPTool::ReadFile => "Read contents of a file from the notes folder",
            MCPTool::WriteFile => "Write or create a file in the notes folder",
            MCPTool::DeleteFile => "Delete a file from the notes folder",
            MCPTool::CreateFolder => "Create a folder in the notes folder",
            MCPTool::ListFiles => "List files and folders in a directory",
            MCPTool::CalendarLua => "Execute a Lua script for calendar operations",
            MCPTool::TimerLua => "Execute a Lua script for timer operations",
            MCPTool::ExportMarkdown => "Export AI response as a markdown file",
        }
    }

    /// Get required parameters for the tool
    pub fn parameters(&self) -> Vec<MCPParameter> {
        match self {
            MCPTool::ReadFile => vec![MCPParameter {
                name: "path".to_string(),
                description: "Relative path to the file within browse/ folder".to_string(),
                param_type: MCPParamType::String,
                required: true,
            }],
            MCPTool::WriteFile => vec![
                MCPParameter {
                    name: "path".to_string(),
                    description: "Relative path to the file within browse/ folder".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
                MCPParameter {
                    name: "content".to_string(),
                    description: "Content to write to the file".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
                MCPParameter {
                    name: "append".to_string(),
                    description: "Whether to append to existing file (default: false)".to_string(),
                    param_type: MCPParamType::Boolean,
                    required: false,
                },
            ],
            MCPTool::DeleteFile => vec![MCPParameter {
                name: "path".to_string(),
                description: "Relative path to the file within browse/ folder".to_string(),
                param_type: MCPParamType::String,
                required: true,
            }],
            MCPTool::CreateFolder => vec![MCPParameter {
                name: "path".to_string(),
                description: "Relative path to the folder within browse/ folder".to_string(),
                param_type: MCPParamType::String,
                required: true,
            }],
            MCPTool::ListFiles => vec![
                MCPParameter {
                    name: "path".to_string(),
                    description: "Relative path to list (default: root of browse/)".to_string(),
                    param_type: MCPParamType::String,
                    required: false,
                },
                MCPParameter {
                    name: "recursive".to_string(),
                    description: "Whether to list recursively (default: false)".to_string(),
                    param_type: MCPParamType::Boolean,
                    required: false,
                },
            ],
            MCPTool::CalendarLua => vec![
                MCPParameter {
                    name: "script".to_string(),
                    description: "Lua script for calendar operations".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
                MCPParameter {
                    name: "description".to_string(),
                    description: "Human-readable description of what the script does".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
            ],
            MCPTool::TimerLua => vec![
                MCPParameter {
                    name: "script".to_string(),
                    description: "Lua script for timer operations".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
                MCPParameter {
                    name: "description".to_string(),
                    description: "Human-readable description of what the script does".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
            ],
            MCPTool::ExportMarkdown => vec![
                MCPParameter {
                    name: "path".to_string(),
                    description: "Relative path for the exported file".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
                MCPParameter {
                    name: "content".to_string(),
                    description: "Markdown content to export".to_string(),
                    param_type: MCPParamType::String,
                    required: true,
                },
                MCPParameter {
                    name: "append".to_string(),
                    description: "Whether to append to existing file (default: false)".to_string(),
                    param_type: MCPParamType::Boolean,
                    required: false,
                },
            ],
        }
    }

    /// Parse tool from string name
    pub fn from_name(name: &str) -> Option<MCPTool> {
        match name {
            "read_file" => Some(MCPTool::ReadFile),
            "write_file" => Some(MCPTool::WriteFile),
            "delete_file" => Some(MCPTool::DeleteFile),
            "create_folder" => Some(MCPTool::CreateFolder),
            "list_files" => Some(MCPTool::ListFiles),
            "calendar_lua" => Some(MCPTool::CalendarLua),
            "timer_lua" => Some(MCPTool::TimerLua),
            "export_markdown" => Some(MCPTool::ExportMarkdown),
            _ => None,
        }
    }
}

/// Parameter type for MCP tools
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub enum MCPParamType {
    String,
    Boolean,
    Integer,
    Array,
}

/// Parameter definition for MCP tools
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct MCPParameter {
    pub name: String,
    pub description: String,
    pub param_type: MCPParamType,
    pub required: bool,
}

// ============================================================================
// Tool Calls
// ============================================================================

/// A tool call request from the AI
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct MCPToolCall {
    /// The tool to execute
    pub tool: String,
    /// Parameters for the tool as JSON string (HashMap<String, Value> serialized)
    pub parameters_json: String,
    /// Human-readable description of what this call does
    pub description: String,
}

impl MCPToolCall {
    /// Parse parameters from JSON string
    pub fn get_parameters(&self) -> HashMap<String, serde_json::Value> {
        serde_json::from_str(&self.parameters_json).unwrap_or_default()
    }
}

/// Result of a tool execution
#[derive(Debug, Clone, Serialize, Deserialize)]
#[frb]
pub struct MCPToolResult {
    /// Whether execution was successful
    pub success: bool,
    /// Result data (on success) or error message (on failure)
    pub result: String,
    /// The tool that was executed
    pub tool: String,
}

// ============================================================================
// Path Validation (Security)
// ============================================================================

/// MCP Configuration
#[derive(Debug, Clone)]
pub struct MCPConfig {
    /// Base directory for file operations (browse/ folder)
    pub browse_dir: PathBuf,
    /// Maximum file size for read/write operations (default: 10MB)
    pub max_file_size: usize,
    /// Allowed file extensions
    pub allowed_extensions: Vec<String>,
}

impl Default for MCPConfig {
    fn default() -> Self {
        Self {
            browse_dir: PathBuf::new(),
            max_file_size: 10 * 1024 * 1024, // 10MB
            allowed_extensions: vec![
                "md".to_string(),
                "txt".to_string(),
                "json".to_string(),
                "yaml".to_string(),
                "yml".to_string(),
                "toml".to_string(),
                "csv".to_string(),
            ],
        }
    }
}

/// Global MCP state
static MCP_STATE: Mutex<Option<Arc<MCPConfig>>> = Mutex::new(None);

/// Initialize the MCP system with the browse directory
pub fn init_mcp(
    browse_dir: PathBuf,
    max_file_size: Option<usize>,
    allowed_extensions: Option<Vec<String>>,
) -> Result<()> {
    // Verify directory exists or create it
    if !browse_dir.exists() {
        std::fs::create_dir_all(&browse_dir)?;
    }
    
    let config = MCPConfig {
        browse_dir: browse_dir.clone(),
        max_file_size: max_file_size.unwrap_or(10 * 1024 * 1024),
        allowed_extensions: allowed_extensions.unwrap_or_else(|| {
            vec![
                "md".to_string(),
                "txt".to_string(),
                "json".to_string(),
                "yaml".to_string(),
                "yml".to_string(),
                "toml".to_string(),
                "csv".to_string(),
            ]
        }),
    };
    
    *MCP_STATE.lock() = Some(Arc::new(config));
    log::info!("MCP initialized with browse_dir: {}", browse_dir.display());
    
    Ok(())
}

/// Check if MCP is initialized
pub fn is_mcp_initialized() -> bool {
    MCP_STATE.lock().is_some()
}

/// Validate and resolve a path within the sandbox
///
/// Returns the absolute path if valid, or an error if the path
/// attempts to escape the sandbox.
pub fn validate_path(relative_path: &str) -> Result<PathBuf> {
    let guard = MCP_STATE.lock();
    let config = guard.as_ref().ok_or_else(|| anyhow!("MCP not initialized"))?;
    
    // Clean the path
    let clean_path = relative_path
        .trim()
        .trim_start_matches('/')
        .trim_start_matches('\\');
    
    // Reject paths with parent directory traversal
    if clean_path.contains("..") {
        return Err(anyhow!("Path traversal not allowed: {}", relative_path));
    }
    
    // Build the full path
    let full_path = config.browse_dir.join(clean_path);
    
    // Canonicalize and verify it's still within browse_dir
    // Note: For non-existent paths, we verify the parent exists and is within bounds
    let normalized = if full_path.exists() {
        full_path.canonicalize()?
    } else {
        // For new files, check parent directory
        if let Some(parent) = full_path.parent() {
            if parent.exists() {
                let canonical_parent = parent.canonicalize()?;
                let canonical_browse = config.browse_dir.canonicalize()?;
                if !canonical_parent.starts_with(&canonical_browse) {
                    return Err(anyhow!("Path outside sandbox: {}", relative_path));
                }
            }
        }
        full_path
    };
    
    // Final check: ensure path is within browse_dir
    if let Ok(canonical_browse) = config.browse_dir.canonicalize() {
        if normalized.exists() && !normalized.starts_with(&canonical_browse) {
            return Err(anyhow!("Path outside sandbox: {}", relative_path));
        }
    }
    
    Ok(normalized)
}

/// Validate file extension
pub fn validate_extension(path: &Path) -> Result<()> {
    let guard = MCP_STATE.lock();
    let config = guard.as_ref().ok_or_else(|| anyhow!("MCP not initialized"))?;
    
    let extension = path
        .extension()
        .and_then(|e| e.to_str())
        .unwrap_or("")
        .to_lowercase();
    
    if extension.is_empty() {
        // Allow files without extension (like plain text notes)
        return Ok(());
    }
    
    if config.allowed_extensions.contains(&extension) {
        Ok(())
    } else {
        Err(anyhow!(
            "File extension '{}' not allowed. Allowed: {:?}",
            extension,
            config.allowed_extensions
        ))
    }
}

// ============================================================================
// File Operations
// ============================================================================

/// Read a file from the browse directory
pub fn read_file(relative_path: &str) -> Result<String> {
    let path = validate_path(relative_path)?;
    
    if !path.exists() {
        return Err(anyhow!("File not found: {}", relative_path));
    }
    
    if !path.is_file() {
        return Err(anyhow!("Not a file: {}", relative_path));
    }
    
    // Check file size
    let metadata = std::fs::metadata(&path)?;
    let guard = MCP_STATE.lock();
    let config = guard.as_ref().ok_or_else(|| anyhow!("MCP not initialized"))?;
    
    if metadata.len() as usize > config.max_file_size {
        return Err(anyhow!(
            "File too large: {} bytes (max: {} bytes)",
            metadata.len(),
            config.max_file_size
        ));
    }
    drop(guard);
    
    let content = std::fs::read_to_string(&path)?;
    Ok(content)
}

/// Write a file to the browse directory
pub fn write_file(relative_path: &str, content: &str) -> Result<()> {
    let path = validate_path(relative_path)?;
    validate_extension(&path)?;
    
    // Check content size
    let guard = MCP_STATE.lock();
    let config = guard.as_ref().ok_or_else(|| anyhow!("MCP not initialized"))?;
    
    if content.len() > config.max_file_size {
        return Err(anyhow!(
            "Content too large: {} bytes (max: {} bytes)",
            content.len(),
            config.max_file_size
        ));
    }
    drop(guard);
    
    // Create parent directories if needed
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            std::fs::create_dir_all(parent)?;
        }
    }
    
    std::fs::write(&path, content)?;
    
    log::info!("File written: {}", relative_path);
    Ok(())
}

/// Write a file with optional append mode
fn write_file_with_append(relative_path: &str, content: &str, append: bool) -> Result<()> {
    let path = validate_path(relative_path)?;
    validate_extension(&path)?;
    
    // Check content size
    let guard = MCP_STATE.lock();
    let config = guard.as_ref().ok_or_else(|| anyhow!("MCP not initialized"))?;
    
    if content.len() > config.max_file_size {
        return Err(anyhow!(
            "Content too large: {} bytes (max: {} bytes)",
            content.len(),
            config.max_file_size
        ));
    }
    drop(guard);
    
    // Create parent directories if needed
    if let Some(parent) = path.parent() {
        if !parent.exists() {
            std::fs::create_dir_all(parent)?;
        }
    }
    
    if append && path.exists() {
        use std::io::Write;
        let mut file = std::fs::OpenOptions::new()
            .append(true)
            .open(&path)?;
        file.write_all(content.as_bytes())?;
    } else {
        std::fs::write(&path, content)?;
    }
    
    log::info!("File written: {}", relative_path);
    Ok(())
}

/// Delete a file from the browse directory
pub fn delete_file(relative_path: &str) -> Result<()> {
    let path = validate_path(relative_path)?;
    
    if !path.exists() {
        return Err(anyhow!("File not found: {}", relative_path));
    }
    
    if path.is_dir() {
        return Err(anyhow!("Cannot delete directory with delete_file. Use delete_folder."));
    }
    
    std::fs::remove_file(&path)?;
    log::info!("File deleted: {}", relative_path);
    
    Ok(())
}

/// Create a folder in the browse directory
pub fn create_folder(relative_path: &str) -> Result<()> {
    let path = validate_path(relative_path)?;
    
    if path.exists() {
        if path.is_dir() {
            return Ok(()); // Already exists
        } else {
            return Err(anyhow!("A file already exists at: {}", relative_path));
        }
    }
    
    std::fs::create_dir_all(&path)?;
    log::info!("Folder created: {}", relative_path);
    
    Ok(())
}

/// List files in a directory (for API use - non-recursive, root if empty path)
pub fn list_files(relative_path: &str) -> Result<Vec<String>> {
    list_files_internal(if relative_path.is_empty() { None } else { Some(relative_path) }, false)
}

/// List files in a directory (internal, with options)
fn list_files_internal(relative_path: Option<&str>, recursive: bool) -> Result<Vec<String>> {
    let path = match relative_path {
        Some(p) if !p.is_empty() => validate_path(p)?,
        _ => {
            let guard = MCP_STATE.lock();
            let config = guard.as_ref().ok_or_else(|| anyhow!("MCP not initialized"))?;
            config.browse_dir.clone()
        }
    };
    
    if !path.exists() {
        return Err(anyhow!("Directory not found"));
    }
    
    if !path.is_dir() {
        return Err(anyhow!("Not a directory"));
    }
    
    let guard = MCP_STATE.lock();
    let config = guard.as_ref().ok_or_else(|| anyhow!("MCP not initialized"))?;
    let browse_dir = config.browse_dir.clone();
    drop(guard);
    
    let mut files = Vec::new();
    collect_files(&path, &browse_dir, recursive, &mut files)?;
    
    Ok(files)
}

fn collect_files(
    dir: &Path,
    base_dir: &Path,
    recursive: bool,
    files: &mut Vec<String>,
) -> Result<()> {
    for entry in std::fs::read_dir(dir)? {
        let entry = entry?;
        let path = entry.path();
        
        // Get relative path from browse_dir
        let relative = path
            .strip_prefix(base_dir)
            .map(|p| p.to_string_lossy().to_string())
            .unwrap_or_else(|_| path.to_string_lossy().to_string());
        
        let is_dir = path.is_dir();
        let display = if is_dir {
            format!("{}/", relative)
        } else {
            relative
        };
        
        files.push(display);
        
        if recursive && is_dir {
            collect_files(&path, base_dir, true, files)?;
        }
    }
    
    files.sort();
    Ok(())
}

// ============================================================================
// Tool Schema Generation (for AI prompts)
// ============================================================================

/// Generate JSON schema for all available tools
pub fn get_tool_schemas() -> String {
    let tools: Vec<serde_json::Value> = MCPTool::all()
        .iter()
        .map(|tool| {
            let params: Vec<serde_json::Value> = tool
                .parameters()
                .iter()
                .map(|p| {
                    serde_json::json!({
                        "name": p.name,
                        "description": p.description,
                        "type": match p.param_type {
                            MCPParamType::String => "string",
                            MCPParamType::Boolean => "boolean",
                            MCPParamType::Integer => "integer",
                            MCPParamType::Array => "array",
                        },
                        "required": p.required
                    })
                })
                .collect();
            
            serde_json::json!({
                "name": tool.name(),
                "description": tool.description(),
                "parameters": params
            })
        })
        .collect();
    
    serde_json::to_string_pretty(&tools).unwrap_or_default()
}

/// Parse a tool call from JSON
pub fn parse_tool_call(json: &str) -> Result<MCPToolCall> {
    serde_json::from_str(json).map_err(|e| anyhow!("Failed to parse tool call: {}", e))
}

/// Execute a tool call
pub fn execute_tool_call(call: &MCPToolCall) -> MCPToolResult {
    let tool = match MCPTool::from_name(&call.tool) {
        Some(t) => t,
        None => {
            return MCPToolResult {
                success: false,
                result: format!("Unknown tool: {}", call.tool),
                tool: call.tool.clone(),
            };
        }
    };
    
    let parameters = call.get_parameters();
    
    let result = match tool {
        MCPTool::ReadFile => {
            let path = parameters.get("path")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            read_file(path)
        }
        MCPTool::WriteFile => {
            let path = parameters.get("path")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let content = parameters.get("content")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let append = parameters.get("append")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            write_file_with_append(path, content, append).map(|_| "File written successfully".to_string())
        }
        MCPTool::DeleteFile => {
            let path = parameters.get("path")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            delete_file(path).map(|_| "File deleted successfully".to_string())
        }
        MCPTool::CreateFolder => {
            let path = parameters.get("path")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            create_folder(path).map(|_| "Folder created successfully".to_string())
        }
        MCPTool::ListFiles => {
            let path = parameters.get("path")
                .and_then(|v| v.as_str());
            let recursive = parameters.get("recursive")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            list_files_internal(path, recursive).map(|files| files.join("\n"))
        }
        MCPTool::CalendarLua | MCPTool::TimerLua => {
            // Lua execution is handled on the Dart side
            // This just validates the request
            let script = parameters.get("script")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            if script.is_empty() {
                Err(anyhow!("Script cannot be empty"))
            } else {
                Ok(format!("Lua script ready for execution ({} bytes)", script.len()))
            }
        }
        MCPTool::ExportMarkdown => {
            let path = parameters.get("path")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let content = parameters.get("content")
                .and_then(|v| v.as_str())
                .unwrap_or("");
            let append = parameters.get("append")
                .and_then(|v| v.as_bool())
                .unwrap_or(false);
            
            // Ensure .md extension
            let path = if !path.ends_with(".md") {
                format!("{}.md", path)
            } else {
                path.to_string()
            };
            
            write_file_with_append(&path, content, append).map(|_| format!("Exported to {}", path))
        }
    };
    
    match result {
        Ok(msg) => MCPToolResult {
            success: true,
            result: msg,
            tool: call.tool.clone(),
        },
        Err(e) => MCPToolResult {
            success: false,
            result: e.to_string(),
            tool: call.tool.clone(),
        },
    }
}

// ============================================================================
// Model Routing
// ============================================================================

/// Task categories for model routing
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[frb]
pub enum TaskCategory {
    /// General conversation/reasoning - use Phi-4
    Conversation,
    /// Function/tool calling - use Functionary
    ToolUse,
    /// Code generation - use Qwen
    CodeGeneration,
}

/// Classify a user message to determine which model to use
pub fn classify_task(message: &str) -> TaskCategory {
    let lower = message.to_lowercase();
    
    // Tool use indicators (actions on files, calendar, timers)
    let tool_keywords = [
        "create file", "create a file", "write file", "delete file", "read file",
        "create folder", "create a folder", "list files", "calendar", "add event",
        "schedule", "reminder", "timer", "start timer", "stop timer",
        "export", "save as", "execute", "run script",
        "create a note", "make a file", "new file", "new folder",
        "file called", "folder called", "note called",
    ];
    
    // Code generation indicators
    let code_keywords = [
        "write code", "generate code", "implement", "function",
        "program", "algorithm", "fix the code", "debug",
        "refactor", "code review", "syntax", "compile",
        "write a script", "coding", "```",
        "python code", "javascript code", "rust code",
    ];
    
    // Check for tool use patterns first (higher priority for action phrases)
    for keyword in &tool_keywords {
        if lower.contains(keyword) {
            return TaskCategory::ToolUse;
        }
    }
    
    // Check for code generation patterns
    for keyword in &code_keywords {
        if lower.contains(keyword) {
            return TaskCategory::CodeGeneration;
        }
    }
    
    // Default to conversation
    TaskCategory::Conversation
}

/// Get recommended model type for a task category
pub fn get_model_for_task(category: TaskCategory) -> crate::inference::ModelType {
    match category {
        TaskCategory::Conversation => crate::inference::ModelType::Phi4,
        TaskCategory::ToolUse => crate::inference::ModelType::Functionary,
        TaskCategory::CodeGeneration => crate::inference::ModelType::Qwen,
    }
}

/// Get recommended model name string for a task category
pub fn get_model_name_for_task(category: TaskCategory) -> &'static str {
    match category {
        TaskCategory::Conversation => "phi4",
        TaskCategory::ToolUse => "functionary",
        TaskCategory::CodeGeneration => "qwen",
    }
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::tempdir;
    use std::sync::atomic::{AtomicUsize, Ordering};
    
    // Counter to ensure unique temp directories
    static TEST_COUNTER: AtomicUsize = AtomicUsize::new(0);
    
    fn setup_mcp() -> tempfile::TempDir {
        let temp = tempdir().unwrap();
        let _ = TEST_COUNTER.fetch_add(1, Ordering::SeqCst);
        init_mcp(temp.path().to_path_buf(), None, None).unwrap();
        temp
    }
    
    #[test]
    fn test_mcp_initialization() {
        let temp = setup_mcp();
        assert!(is_mcp_initialized());
        drop(temp);
    }
    
    #[test]
    fn test_path_validation() {
        let temp = setup_mcp();
        
        // Valid paths
        assert!(validate_path("test.md").is_ok());
        assert!(validate_path("folder/test.md").is_ok());
        assert!(validate_path("deep/nested/path/test.md").is_ok());
        
        // Invalid paths (traversal)
        assert!(validate_path("../outside.md").is_err());
        assert!(validate_path("folder/../../../etc/passwd").is_err());
        assert!(validate_path("..").is_err());
        
        drop(temp);
    }
    
    #[test]
    fn test_file_operations() {
        let temp = setup_mcp();
        
        // Unique file name to avoid test interference
        let file_name = format!("test_file_ops_{}.md", TEST_COUNTER.load(Ordering::SeqCst));
        
        // Write file
        assert!(write_file(&file_name, "# Hello\n\nWorld").is_ok());
        
        // Read file
        let content = read_file(&file_name).unwrap();
        assert_eq!(content, "# Hello\n\nWorld");
        
        // Append to file
        assert!(write_file_with_append(&file_name, "\n\nMore content", true).is_ok());
        let content = read_file(&file_name).unwrap();
        assert!(content.contains("More content"));
        
        // List files
        let files = list_files("").unwrap();
        assert!(files.iter().any(|f| f.contains("test_file_ops")));
        
        // Delete file
        assert!(delete_file(&file_name).is_ok());
        assert!(read_file(&file_name).is_err());
        
        drop(temp);
    }
    
    #[test]
    fn test_folder_operations() {
        let temp = setup_mcp();
        
        // Create folder
        assert!(create_folder("new_folder").is_ok());
        
        // Create nested folders
        assert!(create_folder("deep/nested/folder").is_ok());
        
        // Write file in folder
        assert!(write_file("new_folder/note.md", "Content").is_ok());
        
        // List files
        let files = list_files("new_folder").unwrap();
        assert!(files.iter().any(|f| f.contains("note.md")));
        
        drop(temp);
    }
    
    #[test]
    fn test_extension_validation() {
        let temp = setup_mcp();
        
        // Valid extensions
        assert!(write_file("ext_test.md", "content").is_ok());
        assert!(write_file("ext_test.txt", "content").is_ok());
        assert!(write_file("ext_test.json", "{}").is_ok());
        
        // Invalid extensions
        assert!(write_file("ext_test.exe", "content").is_err());
        assert!(write_file("ext_test.dll", "content").is_err());
        assert!(write_file("ext_test.sh", "content").is_err());
        
        drop(temp);
    }
    
    #[test]
    fn test_task_classification() {
        // Tool use
        assert_eq!(classify_task("Create a file called notes.md"), TaskCategory::ToolUse);
        assert_eq!(classify_task("Add an event to my calendar"), TaskCategory::ToolUse);
        assert_eq!(classify_task("Start a 25 minute timer"), TaskCategory::ToolUse);
        assert_eq!(classify_task("List files in the notes folder"), TaskCategory::ToolUse);
        
        // Code generation
        assert_eq!(classify_task("Write code to sort a list"), TaskCategory::CodeGeneration);
        assert_eq!(classify_task("Implement a binary search function"), TaskCategory::CodeGeneration);
        // Note: "write a Lua script" matches both patterns, but function triggers tool use in classify_task
        // These should clearly be code gen:
        assert_eq!(classify_task("Write Python code for me"), TaskCategory::CodeGeneration);
        assert_eq!(classify_task("Debug this algorithm"), TaskCategory::CodeGeneration);
        
        // Conversation
        assert_eq!(classify_task("What is machine learning?"), TaskCategory::Conversation);
        assert_eq!(classify_task("Explain quantum computing"), TaskCategory::Conversation);
        assert_eq!(classify_task("Hello, how are you?"), TaskCategory::Conversation);
    }
    
    #[test]
    fn test_model_routing() {
        assert_eq!(
            get_model_for_task(TaskCategory::Conversation),
            crate::inference::ModelType::Phi4
        );
        assert_eq!(
            get_model_for_task(TaskCategory::ToolUse),
            crate::inference::ModelType::Functionary
        );
        assert_eq!(
            get_model_for_task(TaskCategory::CodeGeneration),
            crate::inference::ModelType::Qwen
        );
    }
    
    #[test]
    fn test_tool_schemas() {
        let schemas = get_tool_schemas();
        assert!(schemas.contains("read_file"));
        assert!(schemas.contains("write_file"));
        assert!(schemas.contains("calendar_lua"));
        assert!(schemas.contains("timer_lua"));
    }
    
    #[test]
    fn test_tool_call_parsing() {
        let json = r#"{
            "tool": "write_file",
            "parameters_json": "{\"path\": \"test.md\", \"content\": \"Hello World\"}",
            "description": "Creating a test file"
        }"#;
        
        let call = parse_tool_call(json).unwrap();
        assert_eq!(call.tool, "write_file");
        let params = call.get_parameters();
        assert_eq!(
            params.get("path").and_then(|v| v.as_str()),
            Some("test.md")
        );
    }
    
    #[test]
    fn test_tool_execution() {
        let temp = setup_mcp();
        
        let params_json = serde_json::json!({
            "path": "exec_test.md",
            "content": "# Test Content"
        }).to_string();
        
        let call = MCPToolCall {
            tool: "write_file".to_string(),
            parameters_json: params_json,
            description: "Test write".to_string(),
        };
        
        let result = execute_tool_call(&call);
        assert!(result.success);
        
        // Verify file was created
        let content = read_file("exec_test.md").unwrap();
        assert_eq!(content, "# Test Content");
        
        drop(temp);
    }
}
