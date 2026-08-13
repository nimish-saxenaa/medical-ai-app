# Handle Unhandled Network Exceptions

The goal is to handle `SocketException` and other network-related errors in the authentication flow to prevent the app from crashing and provide user feedback when the server is unreachable.

## User Review Required

> [!IMPORTANT]
> The error handling will catch `SocketException` (e.g., connection refused, no internet) and show a custom dialog to the user instead of letting the exception go unhandled.

## Proposed Changes

### Authentication Service

#### [MODIFY] [auth_service.dart](file:///E:/Code/medical-ai-app/lib/Services/Authentication/auth_service.dart)
Wrap HTTP calls in try-catch blocks or provide a unified way to handle network errors. For now, I will modify the `login`, `createAccount`, and `refreshTokens` methods to catch exceptions and return an error map if the request fails due to network issues.

### Screens

#### [MODIFY] [login_screen.dart](file:///E:/Code/medical-ai-app/lib/Screens/Authentication/login_screen.dart)
Add try-catch block around the `login` call to handle unexpected exceptions and show an error dialog.

#### [MODIFY] [create_account_screen.dart](file:///E:/Code/medical-ai-app/lib/Screens/Authentication/create_account_screen.dart)
Add try-catch block around the `createAccount` call to handle unexpected exceptions and show an error dialog.

## Verification Plan

### Manual Verification
- Attempt to login when the server is unreachable (simulating the current error).
- Verify that a dialog is shown instead of an unhandled exception in the logs.
- Verify that the loading indicator (`isTapped`) is correctly reset to `false`.
