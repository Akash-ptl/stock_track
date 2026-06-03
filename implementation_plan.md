# Implementation Plan - Splash Screen & Google Sign-In with BLoC

This plan details the implementation of a splash screen, a login screen with Google Sign-In (using Firebase Auth), and BLoC-based state management in the Flutter application, styling it to match the **STOCKTRACK - MOBILE APP DESIGNER BRIEF**.

## User Review Required

> [!IMPORTANT]
> - **Google Sign-In configuration**: Please ensure that Google Sign-In is enabled in your Firebase console (`Authentication > Sign-in method > Google`) and that the SHA-1 fingerprint you obtained (`ED:09:B1:01:E0:81:3B:B0:6B:12:3C:D1:B5:39:EF:94:79:E1:43:26`) is added to the Android app in the Firebase project settings.
> - **Design System Compliance**: We will integrate the design spec tokens (Colors, Corner Radius, Inter Typography, 8pt Grid System) into our custom `ThemeData` and style definitions.

## Design Specifications to Implement

From the Designer Brief:
1. **Logo**:
   - Asset path: `assets/images/logo.png`
2. **Colors**:
   - Primary Green: `#16A34A`
   - Primary Navy: `#0F172A`
   - Light Green: `#DCFCE7`
   - Light Gray: `#F1F5F9`
   - Neutral Gray: `#64748B`
3. **Typography**:
   - Font Family: **Inter** (using `google_fonts` package to load Inter dynamically)
4. **Shapes & Radius**:
   - Corner Radius: `12px` (Medium) for Cards, Buttons, and Input Fields.
   - Circular shape for Icon Buttons.
5. **Spacing & Layout**:
   - 8pt Grid System (base padding/margins = 16px).
   - Safe Area support.

---

## Proposed Changes

### Configuration & Build Settings

#### [MODIFY] [pubspec.yaml](file:///Users/akashptl/StudioProjects/stock_track/pubspec.yaml)
- Add required dependencies:
  - `firebase_core` (For initializing Firebase)
  - `firebase_auth` (For authentication)
  - `google_sign_in` (For Google Sign-In flow)
  - `flutter_bloc` (For BLoC state management)
  - `equatable` (For simplified state comparisons)
  - `google_fonts` (To load the **Inter** font dynamically)
- Configure assets:
  - Add `assets/images/logo.png` under the assets section.

#### [MODIFY] [settings.gradle.kts](file:///Users/akashptl/StudioProjects/stock_track/android/settings.gradle.kts)
- Add Google Services plugin definition:
  ```kotlin
  id("com.google.gms.google-services") version "4.4.2" apply false
  ```

#### [MODIFY] [build.gradle.kts](file:///Users/akashptl/StudioProjects/stock_track/android/app/build.gradle.kts)
- Apply the Google Services plugin:
  ```kotlin
  plugins {
      ...
      id("com.google.gms.google-services")
  }
  ```

---

### Core Services & Design Tokens

#### [NEW] [app_theme.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/core/app_theme.dart)
- Define a unified theme configuration (`AppTheme`) with the color palette:
  - Primary: `#16A34A` (Green)
  - Scaffold Background: `#F1F5F9` (Light Gray) or `#0F172A` (Navy)
  - Inter font configurations for Display, Headings, and Body typography.
  - Custom `ElevatedButtonTheme` and `InputDecorationTheme` with a `12px` corner radius.

#### [NEW] [firebase_options.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/core/firebase_options.dart)
- Define default Firebase configurations based on the values in [google-services.json](file:///Users/akashptl/StudioProjects/stock_track/android/app/google-services.json) so Firebase initializes successfully.

---

### State Management (BLoC) & Repository

#### [NEW] [auth_repository.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/features/auth/auth_repository.dart)
- Wrapper class to handle Firebase Google Sign-In logic:
  - `signInWithGoogle()`: Launches the `google_sign_in` flow, retrieves credentials, signs in to Firebase.
  - `signOut()`: Signs out from Google and Firebase.
  - `currentUser`: Stream/getter for the currently logged in user.

#### [NEW] [auth_event.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/features/auth/auth_bloc/auth_event.dart)
- Define events:
  - `AppStarted`: Fired when the app launches to check if the user is already authenticated.
  - `GoogleSignInRequested`: Fired when the user clicks the "Sign in with Google" button.
  - `SignOutRequested`: Fired when the user signs out.

#### [NEW] [auth_state.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/features/auth/auth_bloc/auth_state.dart)
- Define states:
  - `AuthInitial`: App starts, determining current state.
  - `AuthLoading`: Processing authentication/loading.
  - `Authenticated`: User is signed in (holds user object).
  - `Unauthenticated`: User is not signed in.
  - `AuthFailure`: Authentication failed (holds error message).

#### [NEW] [auth_bloc.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/features/auth/auth_bloc/auth_bloc.dart)
- Handle events and emit corresponding states based on `AuthRepository` interactions.

---

### Presentation (UI)

#### [NEW] [splash_page.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/features/auth/splash_page.dart)
- A beautiful, rich aesthetic Splash Page showing the `assets/images/logo.png` logo at the center with a smooth fade-in animation, surrounded by a light gray background (`#F1F5F9`).
- Listens to the `AuthBloc` states:
  - On `Authenticated`: Redirects to the Home screen after a short delay to allow the animation to play.
  - On `Unauthenticated`: Redirects to the `LoginPage`.

#### [NEW] [login_page.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/features/auth/login_page.dart)
- Styled using the designer brief specifications:
  - Background: Solid Primary Navy (`#0F172A`) or clean light layout (`#F1F5F9`) featuring the `logo.png` asset.
  - A custom Google Sign-In button with `#16A34A` primary styling, rounded corners (12px), and Inter font family.
  - A loading spinner during sign-in and a styled snackbar in case of errors.

#### [MODIFY] [main.dart](file:///Users/akashptl/StudioProjects/stock_track/lib/main.dart)
- Initialize Firebase on startup.
- Wrap the app with `BlocProvider<AuthBloc>`.
- Configure initial routing pointing to `SplashPage`.
- Provide a basic `HomePage` mockup where user details are displayed with a "Sign Out" button to verify the flow is working completely.

---

## Verification Plan

### Automated Tests
- Run `flutter build apk --debug` to verify the code compiles without syntax or Gradle dependency issues.

### Manual Verification
- Run the app on a connected device/emulator.
- Verify that the Splash Screen shows the logo, checks authentication, and directs to `LoginPage`.
- Perform Google Sign-In, verify it redirects to `HomePage` and displays user information.
- Log out, verify it redirects back to `LoginPage`.
