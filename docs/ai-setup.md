# AI Provider Setup Guide

This document explains how Kivixa's AI layer is designed to be provider-agnostic, how to configure API keys, and how to use local, free alternatives to paid cloud services.

## 1. Provider-Agnostic Architecture

Kivixa features a flexible AI layer that is not tied to a single provider (like OpenAI or Google). This is achieved through an adapter pattern, where a common interface is used for all AI actions (e.g., text generation, summarization), and specific implementations handle the communication with each provider's unique API.

The core components are:
*   `AIProvider`: An enum (`lib/ai/providers.dart`) listing all supported providers (e.g., `OpenAI`, `Google`, `Ollama`).
*   `ProviderConfigService`: (`lib/ai/provider_config_service.dart`) Manages the settings and API keys for each provider.
*   `AIActionsService`: (`lib/ai/ai_actions_service.dart`) The main entry point for any AI-powered feature. It routes requests to the currently configured provider.

This design allows users to switch between providers or even add new ones without changing the core application logic.

## 2. Configuring API Keys (Future UI)

Once the settings UI is implemented, you will be able to enter your API keys directly within the app.

1.  Navigate to `Settings > AI Providers`.
2.  Select the provider you wish to use (e.g., OpenAI).
3.  Paste your API key into the secure input field and save.

### Secure Key Storage

API keys are sensitive and are never stored in the main database or plain text. Kivixa uses the platform's native secure storage for this purpose:
*   **Windows**: `flutter_secure_storage_windows` uses the Windows Credential Manager.
*   **Android**: `flutter_secure_storage` uses the Android Keystore.

This ensures that your keys are encrypted and protected by the operating system.

## 3. Using Local Endpoints (e.g., Ollama)

You can use Kivixa's AI features without relying on paid, cloud-based services by running a local AI model server like [Ollama](https://ollama.com/).

1.  **Install Ollama**: Follow the instructions on their website to install Ollama on your Windows machine and download a model (e.g., `ollama run llama3`).
2.  **Configure Kivixa**: In the AI Provider settings, select `Ollama`.
3.  **Set the Endpoint**: Instead of an API key, you will provide the local server address. By default, this is:
    ```
    http://localhost:11434
    ```

Kivixa will then send all AI requests to your local Ollama instance, ensuring complete privacy and no external service costs.
