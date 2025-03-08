# Resources

This directory contains all static resources used by the application, including assets, colors, localization files, and other constants.

## Contents

- `Assets.xcassets`: Main asset catalog containing images and icons
- `Colors.xcassets`: Asset catalog specifically for named colors
- `ColorConstants.swift`: Swift constants for colors used throughout the app
- `CalendarColors.swift`: Specific color constants for calendar views

## Implementation Notes

- All colors should be defined in Colors.xcassets and accessed through ColorConstants.swift
- Static strings should be moved to Localizable.strings for localization
- Constants should be organized by domain/feature
- Assets should be properly sized and optimized
