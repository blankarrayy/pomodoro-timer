# Focus Forge

A beautiful, minimalist Pomodoro timer application built with Flutter that helps you stay productive and focused. Track your work sessions, manage tasks, and sync across devices with cloud integration.

## ✨ Features

### 🎯 Core Functionality
- **Pomodoro Timer** - Customizable work and break intervals with visual countdown
- **Task Management** - Create, edit, and track tasks with due dates and notes
- **Session Statistics** - Detailed analytics and charts showing your productivity trends
- **Desktop Notifications** - Get notified when sessions complete (Windows native notifications)
- **System Tray Integration** - Quick access to timer status from the system tray

### ☁️ Cloud Sync & Multi-Device Support
- **Supabase Integration** - Secure cloud storage for tasks and analytics
- **Automatic Resync** - Tasks sync automatically every 5 minutes across all devices
- **Manual Resync** - Instant sync button for immediate updates
- **Conflict Resolution** - Smart "last write wins" strategy for seamless collaboration
- **Offline Support** - Works offline with local storage, syncs when connected

### 🎨 User Experience
- **Clean, Modern UI** - Distraction-free interface with glassmorphism design
- **Dark Theme** - Easy on the eyes with beautiful gradients
- **Smooth Animations** - Confetti celebrations when all tasks are completed
- **Responsive Design** - Optimized for desktop (Windows, macOS, Linux)
- **Touchpad Scrolling** - Full touchpad support on Windows

### 📊 Analytics & Tracking
- **Daily Stats** - Track focus sessions, break sessions, and total focus time
- **Weekly Charts** - Visual representation of your productivity over 7 days
- **Session History** - Complete history of all your Pomodoro sessions
- **Task Completion Tracking** - Monitor completed vs pending tasks

## 📦 Installation

### Windows

#### Option 1: MSIX Installer (Recommended)
1. Download `focusforge.msix` from the `installer` folder or releases page
2. Double-click the installer
3. Click "Install" when prompted
4. Find "Focus Forge" in your Start Menu

> **Note**: The MSIX package is signed with a test certificate. You may need to enable Developer Mode on Windows or install the certificate to run the app.

#### Option 2: Portable Executable
1. Navigate to `build\windows\x64\runner\Release\`
2. Run `focusforge.exe` directly (no installation required)

### Building from Source

#### Prerequisites
- Flutter SDK (3.5.4 or higher)
- Dart SDK
- Windows SDK (for Windows build)
- Visual Studio Build Tools with C++ support
- Git

#### Setup Steps
1. Clone this repository:
   ```bash
   git clone https://github.com/blankarray/pomodoro-timer.git
   cd pomodoro-timer
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Set up environment variables:
   - Copy `.env.example` to `.env`
   - Add your Supabase credentials (optional, for cloud sync):
     ```
     SUPABASE_URL=your_supabase_url
     SUPABASE_ANON_KEY=your_supabase_anon_key
     ```

4. Build for your platform:
   ```bash
   # Windows
   flutter build windows
   
   # macOS
   flutter build macos
   
   # Linux
   flutter build linux
   ```

5. Create Windows installer (optional):
   ```bash
   dart run msix:create
   ```

## 🚀 Usage

### Getting Started
1. Launch Focus Forge
2. (Optional) Sign in with Supabase for cloud sync
3. Set your preferred work and break durations in Settings
4. Create tasks using the "+" button
5. Start your first Pomodoro session!

### Task Management
- **Add Task**: Click the "+" button in the task list header
- **Edit Task**: Click on any task to edit title, notes, or due date
- **Complete Task**: Check the checkbox to mark as complete
- **Delete Task**: Open task editor and click "Delete Task"
- **Resync Tasks**: Click the refresh icon to sync with other devices

### Cloud Sync
- Tasks automatically sync every 5 minutes when signed in
- Click the resync button for immediate synchronization
- Sync status indicator shows current sync state
- Works seamlessly across multiple devices

## 🛠️ Development

### Project Structure
```
lib/
├── models/          # Data models (Task, DailyStats, etc.)
├── providers/       # Riverpod state management
├── screens/         # Main app screens
├── services/        # Business logic and external services
├── ui/             # Theme and styling
└── widgets/        # Reusable UI components
```

### Key Technologies
- **Flutter** - Cross-platform UI framework
- **Riverpod** - State management
- **Supabase** - Backend as a Service (authentication, database)
- **Shared Preferences** - Local storage
- **Google Fonts** - Typography (Outfit font)
- **FL Chart** - Analytics visualization
- **System Tray** - Desktop integration

### Recent Updates
- ✅ Fixed Windows system tray icon issues
- ✅ Fixed touchpad scrolling on Windows
- ✅ Added automatic 5-minute resync functionality
- ✅ Improved sync conflict resolution
- ✅ Enhanced UI with better scroll physics

## 📸 Screenshots
![Screenshot 2024-11-12 081253](https://github.com/user-attachments/assets/a0d6b610-7981-45dc-a98b-d4260c7ff75b)
![Screenshot 2024-11-12 081304](https://github.com/user-attachments/assets/818eacf4-2f0d-4c52-ba5e-c5f9138d04f1)
![Screenshot 2024-11-12 081313](https://github.com/user-attachments/assets/51695123-3936-4e5d-9915-57198cf3a195)
![Screenshot 2024-11-12 081350](https://github.com/user-attachments/assets/57a82025-b1a8-47e8-aa4f-8c700424a4ff)
![Screenshot 2024-11-12 081402](https://github.com/user-attachments/assets/90f458cb-2f8a-4ab1-8ade-db5500b68556)
![Screenshot 2024-11-12 080312](https://github.com/user-attachments/assets/937db496-bf4c-4256-a729-fea5d3c3718f)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**iamvaar-dev**
- Email: venkibvb5192@gmail.com
- GitHub: [@iamvaar-dev](https://github.com/iamvaar-dev)

## 🙏 Acknowledgments

- Built with [Flutter](https://flutter.dev/)
- Backend powered by [Supabase](https://supabase.com/)
- Icons from [Material Design Icons](https://fonts.google.com/icons)
- Font: [Outfit](https://fonts.google.com/specimen/Outfit) by Google Fonts

---

**Focus Forge** - Stay focused, stay productive! 🚀
