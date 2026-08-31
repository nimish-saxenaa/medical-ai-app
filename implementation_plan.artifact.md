# Implementation Plan - Refactor Auth Screens Error Handling and Signup Validation

This plan outlines the changes to improve error reporting in Login and Signup screens and implement password length validation for account creation.

## User Review Required

> [!NOTE]
> Errors will now appear as red text directly above the "Sign in" or "Create Account" buttons instead of in a popup dialog. The "Create Account" button will be visually disabled until the password is at least 8 characters long.

## Proposed Changes

### [Custom Widgets]

#### [MODIFY] [custom_button.dart](file:///E:/Code/medical-ai-app/lib/Custom%20Widgets/custom_button.dart)
- Update `onPressed` to be nullable to support the disabled state of the underlying `ElevatedButton`.

### [Authentication Screens]

#### [MODIFY] [login_screen.dart](file:///E:/Code/medical-ai-app/lib/Screens/Authentication/login_screen.dart)
- Add `errorMessage` state variable.
- Replace `showCustomDialog` with inline error display.
- Add error text widget above the `CustomButton`.

#### [MODIFY] [create_account_screen.dart](file:///E:/Code/medical-ai-app/lib/Screens/Authentication/create_account_screen.dart)
- Add `errorMessage` state variable.
- Implement logic to disable the `CustomButton` if `passwordController.text.length < 8`.
- Replace `showCustomDialog` with inline error display.
- Add error text widget above the `CustomButton`.
- Add listeners to controllers to clear error messages and update button state on input.

## Verification Plan

### Manual Verification
- **Login Screen**:
    - Try to log in with invalid credentials and verify that the error message appears in red above the button.
    - Verify no dialog is shown.
- **Create Account Screen**:
    - Verify the "Create Account" button is disabled (greyed out/unresponsive) when the password has fewer than 8 characters.
    - Verify it becomes enabled once 8 characters are entered.
    - Try to sign up with invalid details and verify the error message appears in red above the button.
