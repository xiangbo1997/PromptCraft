# GEMINI.md - PromptCraft

## Project Overview

This is a macOS application named **PromptCraft**, designed to help users craft and optimize AI prompts. The application is built using modern Swift technologies, including SwiftUI for the user interface and SwiftData for persistence. The architecture follows the Model-View-ViewModel (MVVM) pattern, ensuring a clean separation of concerns and a scalable codebase.

**Key Technologies:**

*   **UI:** SwiftUI
*   **Data Persistence:** SwiftData
*   **Concurrency:** Swift Concurrency (`async/await`)
*   **Dependencies:**
    *   [HotKey](https://github.com/soffes/HotKey): For managing global hotkeys.

**Architecture:**

The project is structured into the following layers:

*   **Presentation Layer:** SwiftUI views for the main UI, menu bar, and settings.
*   **ViewModel Layer:** Contains the business logic and state management for the views.
*   **Service Layer:** Handles interactions with external services like AI models, storage, and system services (e.g., hotkeys, clipboard).
*   **Data Layer:** Manages data persistence using SwiftData for prompts and UserDefaults for settings.

## Building and Running

### Prerequisites

*   macOS 14.0 or later
*   Xcode 15.0 or later
*   Swift 5.9 or later

### Steps

1.  **Clone the repository:**
    ```bash
    git clone <repository_url>
    cd PromptCraftXcode
    ```

2.  **Open the project in Xcode:**
    ```bash
    xed .
    ```

3.  **Install dependencies:**
    Xcode will automatically resolve and download the Swift Package Manager dependencies.

4.  **Run the application:**
    *   Select the `PromptCraft` scheme and your Mac as the target device.
    *   Press `Cmd + R` to build and run the application.

## Development Conventions

### Code Style

*   The project follows the Swift API Design Guidelines.
*   [SwiftLint](https://github.com/realm/SwiftLint) is used to enforce code style and conventions.

### Git Workflow

*   The project uses a Gitflow-like workflow with `main`, `develop`, and feature branches.
*   Feature branches are created from `develop` and merged back into `develop` after review.
*   Pull Requests are used for code reviews.

### Testing

*   The project includes both unit tests and UI tests.
*   Tests can be run from Xcode by pressing `Cmd + U`.

### Project Structure

The project is organized into the following main directories:

*   `PromptCraft/App`: Application entry point and state management.
*   `PromptCraft/Core`: Core models and services.
*   `PromptCraft/Features`: Feature-specific views and view models.
*   `PromptCraft/Shared`: Shared components and styles.
*   `docs`: Project documentation, including architecture and development guides.
