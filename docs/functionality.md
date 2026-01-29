# All Clued In - Website Functionality

## Homepage (`/`)

- **Crossword Listing**: Fetches and displays all available crosswords from the API
- **Series Grouping**: Organizes crosswords by series (e.g., "everyman", "quick", "cryptic")
- **Chronological Display**: Within each series, crosswords are sorted by date (newest first)
- **Navigation Links**: Each crossword links to `/crossword/{series}/{id}/{teamId}` with a unique team identifier for collaborative sessions
- **Loading States**: Shows skeleton loading screens while fetching crossword data
- **Error Handling**: Displays error messages if the API request fails

## Crossword Page (`/crossword/{series}/{id}/{teamId}`)

### Core Solving Features

- **Interactive Grid**: Click cells to select them; type letters to fill them in
- **Keyboard Navigation**: Arrow keys move between white cells; Backspace deletes and moves backward
- **Auto-Advance**: Typing automatically moves to the next cell in the current clue
- **Direction Switching**: Clicking the same cell toggles between Across and Down; automatically selects direction based on available clues
- **Clue Navigation**: Click clues in the sidebar to jump to their starting cell

### Real-Time Collaboration

- **WebSocket Synchronization**: All users on the same teamId see each other's letters in real-time
- **Cursor Tracking**: Shows other users' cursor positions with colored indicators (unique color per username)
- **Visual Indicators**: Small colored dots appear on cells where other users are currently active

### Game Assistance Features

- **Check Button**: Validates the current clue and removes incorrect letters (3-second countdown to "Check All")
- **Reveal Button**: Reveals the answer for the current clue (3-second countdown to "Reveal All")
- **Clear Button**: Clears the current clue (3-second countdown to "Clear All")
- **Countdown Buttons**: First click performs the action; second click within 3 seconds performs the "All" version

### UI and Information

- **Current Clue Display**: Header shows the number and text of the currently active clue
- **Clue Highlighting**: Active clue is highlighted in the sidebar; corresponding grid cells are highlighted
- **Clue Completion**: Completed clues are visually marked in the clue list
- **Info Panel**: Toggleable panel showing:
  - Crossword metadata (series, number, date, setter)
  - Link to the original Guardian crossword
  - Shareable link with copy-to-clipboard functionality
- **Home Button**: Returns to the homepage
- **Responsive Design**: Grid scales to fit viewport (max 800px width)

### Technical Features

- **Focus Management**: Input field positioned over the selected cell for fast typing
- **HTML Clue Parsing**: Supports HTML formatting in clue text
- **Error States**: Loading and error messages for failed API requests
- **State Persistence**: Filled letters and selections maintained during the session

The application enables real-time collaborative crossword solving with visual feedback, validation tools, and a responsive interface.
