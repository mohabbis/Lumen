# Lumen

**Lumen** is a modern smart home platform designed to make intelligent home control simple, beautiful, and reliable.

Lumen combines device management, automation, presence awareness, environmental sensing, and home intelligence into a single experience. Instead of treating smart devices as isolated accessories, Lumen treats the home as a coordinated system.

> Smart home software designed around people, not devices.

---

## Vision

Most smart homes are a collection of apps, hubs, dashboards, and automations stitched together over time.

Lumen's goal is to create a unified platform that understands the home's state, adapts to its occupants, and quietly improves everyday life.

The long-term vision is a home that:

- Understands occupancy automatically
- Responds intelligently to context
- Requires minimal manual intervention
- Protects user privacy
- Feels invisible when working correctly

---

## Current Platform Focus

Lumen is currently being built around a real-world smart home environment consisting of:

- Apple HomeKit
- Matter devices
- Thread devices
- GE Cync lighting
- Motion sensors
- Smart dimmers
- RGBIC lighting systems
- Wi-Fi connected devices
- Bluetooth Low Energy devices

Development priorities are based on solving real smart-home problems rather than building isolated demo features.

---

## Core Features

### Unified Device Control

Manage lights, sensors, switches, outlets, and accessories from one interface.

Features include:

- Room organization
- Device grouping
- Real-time status monitoring
- Scene activation
- Quick controls
- Cross-device interactions

### Presence Intelligence

Lumen is being designed around understanding occupancy and activity.

Planned capabilities include:

- Occupancy detection
- Room awareness
- Arrival and departure recognition
- Motion-based state tracking
- Multi-user support
- Adaptive automation behavior

### Automation Engine

The automation system serves as the foundation of the platform.

Supported and planned automation triggers include:

- Motion events
- Occupancy changes
- Time schedules
- Device state changes
- Environmental conditions
- Custom automation chains

Example:

Motion detected → Room occupied → Lights adjust → Scene activates → Devices respond.

### Smart Lighting

Lighting is a primary focus area.

Planned functionality includes:

- HomeKit lighting control
- GE Cync integration support
- Adaptive brightness
- Color management
- Circadian lighting routines
- Motion-based lighting
- Room-specific scenes

### Home Dashboard

A central dashboard provides visibility into the home's current state.

Areas under development include:

- Room summaries
- Device health monitoring
- Occupancy overview
- Automation status
- Sensor activity
- Home insights

---

## Technical Architecture

### Frontend

- SwiftUI
- Native iOS development
- Apple design system integration
- Real-time state updates

### Smart Home Protocols

- HomeKit
- Matter
- Thread
- Bluetooth Low Energy
- Wi-Fi

### Core Systems

- Device management layer
- Automation engine
- Presence engine
- State synchronization
- Local network discovery
- Event processing pipeline

---

## Roadmap

### Phase 1

Foundation

- Device onboarding
- HomeKit integration
- Room management
- Scene management
- Core UI

### Phase 2

Intelligence

- Presence engine
- Occupancy modeling
- Advanced automations
- Device relationships

### Phase 3

Adaptive Home

- Context-aware automation
- Behavioral learning
- Energy optimization
- Predictive routines

### Phase 4

Home Intelligence Platform

- Cross-home support
- Advanced analytics
- Extended ecosystem integrations
- Intelligent recommendations

---

## Design Principles

1. The home should feel intelligent, not complicated.
2. Controls should be fast, obvious, and reliable.
3. Automation should reduce attention, not create more work.
4. Privacy should be built into the platform from the beginning.
5. Local-first operation should be preferred whenever possible.
6. The interface should feel calm, modern, and intentional.

---

## Project Status

Lumen is under active development.

Current focus areas:

- HomeKit architecture
- Presence intelligence
- Automation engine development
- Device onboarding workflows
- Lighting experiences
- Performance optimization
- UI refinement

---

Built with SwiftUI and HomeKit.