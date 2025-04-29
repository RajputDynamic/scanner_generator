# scanner_generator

# QR Code Scanner & Generator - Flutter Application

## Overview
A Flutter application that allows users to both scan and generate QR codes with various functionalities including text, URL, and contact sharing.

## Features
- **QR Code Scanner**: Scan QR codes with camera functionality
- **QR Code Generator**: Create QR codes for:
    - Plain text
    - URLs
    - Contact information (vCard format)
- **Result Processing**: Automatically detect and handle different QR code types
- **Sharing**: Share scanned results or generated QR codes

## File Structure
```
lib/
├── main.dart                # Main application entry point
├── home_page.dart           # Home screen with navigation options
├── qr_scanner_screen.dart   # QR scanning functionality
└── qr_generate_screen.dart  # QR generation functionality
```

## Detailed Description

### main.dart
- **Location**: Root of the project
- **Functionality**:
    - Initializes the MaterialApp
    - Sets up the app theme (using Google's Poppins font)
    - Defines color scheme (teal primary color)
    - Sets HomeScreen as the initial route

### home_page.dart
- **Location**: lib/home_page.dart
- **UI Components**:
    - Scaffold with teal background
    - SafeArea containing:
        - App title ("QR CODE")
        - Centered feature card with two main buttons
- **Navigation**:
    - "Generate QR" button → QrGenerateScreen
    - "Scan QR" button → QrScannerScreen
- **Styling**:
    - Uses Poppins font
    - Teal color scheme with white text
    - Card with shadow effects

### qr_scanner_screen.dart
- **Location**: lib/qr_scanner_screen.dart
- **Features**:
    - Camera permission handling
    - QR scanning with MobileScanner
    - Flash toggle functionality
    - Custom QR border painter
- **Result Processing**:
    - Automatic detection of QR types (text, URL, contact)
    - Bottom sheet display for scanned results
    - Actions for:
        - Opening URLs
        - Saving contacts
        - Sharing results
        - Scanning again
- **UI Components**:
    - Custom scanning frame overlay
    - Instruction text at bottom
    - Permission request UI when needed

### qr_generate_screen.dart
- **Location**: lib/qr_generate_screen.dart
- **Features**:
    - Three generation modes (text, URL, contact)
    - Dynamic input fields based on selected mode
    - QR preview with sharing capability
- **UI Components**:
    - Segmented button for type selection
    - Dynamic form fields
    - QR display card
    - Share button
- **Functionality**:
    - Screenshot capture for sharing
    - Automatic URL formatting
    - vCard generation for contacts

## Dependencies
- google_fonts: For Poppins font
- mobile_scanner: For QR scanning
- qr_flutter: For QR generation
- share_plus: For sharing functionality
- permission_handler: For camera permissions
- flutter_contacts: For contact handling
- url_launcher: For opening URLs
- screenshot: For capturing QR codes
- path_provider: For file handling

## Usage
1. **Home Screen**: Choose between scanning or generating QR codes
2. **Scanner**:
    - Point camera at QR code
    - View results in bottom sheet
    - Take appropriate action (open, save, share)
3. **Generator**:
    - Select content type
    - Enter relevant information
    - View generated QR
    - Share the QR image

## Theme
- Primary color: Teal
- Font: Poppins
- Material 3 design enabled
- Light theme with blue seed color

## Screens
1. Home Screen (teal background with two options)
2. Scanner Screen (camera view with overlay)
3. Generator Screen (input form with QR preview)

## Error Handling
- Camera permission requests
- URL validation
- Contact saving feedback

## Platform Support
- Android
- iOS (with appropriate permissions)

This application provides a complete solution for both scanning and generating QR codes with a clean, modern interface and comprehensive functionality.
