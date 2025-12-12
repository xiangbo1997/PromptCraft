import Foundation
import AppKit

/// A service class for interacting with the system clipboard.
/// It provides methods to copy text to and paste text from the pasteboard.
class ClipboardService {
    
    // The general pasteboard instance to interact with
    private let pasteboard = NSPasteboard.general
    
    /// Copies the given text to the system clipboard.
    /// - Parameter text: The string to be copied.
    func copy(_ text: String) {
        // Clear any existing contents on the pasteboard
        pasteboard.clearContents()
        // Set the new string content for the general pasteboard
        pasteboard.setString(text, forType: .string)
        print("[ClipboardService] Text copied to clipboard: \"\(text.prefix(50))...\"")
    }
    
    /// Retrieves the current string content from the system clipboard.
    /// - Returns: An optional string containing the clipboard content, or `nil` if no string is found.
    func paste() -> String? {
        // Attempt to retrieve a string from the pasteboard
        let content = pasteboard.string(forType: .string)
        if let content = content {
            print("[ClipboardService] Text pasted from clipboard: \"\(content.prefix(50))...\"")
        } else {
            print("[ClipboardService] No string content found on clipboard.")
        }
        return content
    }
    
    /// Checks if the system clipboard currently contains any string content.
    /// - Returns: `true` if string content is present, `false` otherwise.
    func hasText() -> Bool {
        let hasContent = pasteboard.string(forType: .string) != nil
        print("[ClipboardService] Clipboard has text: \(hasContent)")
        return hasContent
    }
}

