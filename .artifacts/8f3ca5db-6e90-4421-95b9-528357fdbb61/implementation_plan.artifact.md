# Implement Smart Home App UI from Figma

The goal is to transform the current basic Flutter smart home app into a high-fidelity, polished application based on the provided Figma UI screenshots.

## Design Overview

The new UI features a modern, clean aesthetic with a light cream background, rounded corners, and a floating bottom navigation bar. It emphasizes real-time device control, energy monitoring, and security.

### Core Visual Elements
- **Color Palette:**
  - Background: Off-white/Cream (`#F5F5F0` approx).
  - Active/Success: Lime Green (`#D4E157`).
  - Critical/Off: Soft Red.
  - Security/Lock: Calm Blue.
  - Text/Icons: Dark Grey to Black.
- **Typography:** Modern sans-serif (likely Inter or Roboto).
- **Navigation:** Floating pill-shaped bottom navigation bar.

## Proposed Changes

I will implement the following screens and components to match the screenshots.

### 1. Requirements Blueprint
#### [NEW] [implementation_requirements.txt](file:///home/dumindu/AndroidStudioProjects/smart_home_app/implementation_requirements.txt)
A detailed technical specification of all UI elements, layout structures, and functional interactions.

### 2. Main Navigation & Layout
- **Custom Floating Bottom Nav:** A dark, rounded navigation bar with icons for Home, Camera, Analysis, Notifications, and Profile.
- **Screen Transitions:** Smooth navigation between the five primary modules.

### 3. Home & Room Control
- **Dashboard:** Header with user profile, active device count, and floor selector.
- **Quick Actions:** Large, one-tap buttons for global states (All Lights, Lock House).
- **Device Grid:** Responsive grid of device cards with status indicators and integrated power toggles.
- **Room-Specific Controls:** Specialized control panels (e.g., a full TV remote interface for the Living Room).

### 4. Advanced Features
- **All Devices Screen:** Searchable and filterable list of every connected device with real-time status and power consumption metrics.
- **Energy Analysis:** Interactive bar charts and donut charts showing usage trends and top consumers.
- **Live Camera Feed:** A security-focused screen with live streams, PTZ (Pan-Tilt-Zoom) controls, and camera thumbnails.
- **Smart Notifications:** A categorized notification center with severity-coded alerts (Smoke Detected, Iron Auto-Off).

## Verification Plan

### Automated Tests
- Unit tests for new device models and energy calculation logic.
- Widget tests for critical components like the `DeviceCard` and `RoomControlPanel`.

### Manual Verification
- **UI Match:** Side-by-side comparison of the implemented Flutter screens with the provided screenshots.
- **Real-time Sync:** Verify that toggling a device in the UI updates Firestore and reflects on other screens.

